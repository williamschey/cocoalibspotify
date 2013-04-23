//
//  SPCircularBuffer.m
//  Viva
//
//  Created by Daniel Kennett on 4/9/11.
/*
 Copyright (c) 2011, Spotify AB
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of Spotify AB nor the names of its contributors may 
 be used to endorse or promote products derived from this software 
 without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL SPOTIFY AB BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SPCircularBuffer.h"

@implementation SPCircularBuffer {
	void *_buffer;
	NSUInteger _maximumLength;
	NSUInteger _dataStartOffset;
	NSUInteger _dataEndOffset;
	BOOL _empty;
}

-(id)init {
    return [self initWithMaximumLength:1024];
}

-(id)initWithMaximumLength:(NSUInteger)size {
	self = [super init];
    if (self) {
        // Initialization code here.
		_buffer = malloc(size);
		_maximumLength = size;
		[self clear];
    }
    
    return self;
}

-(void)clear {
	@synchronized(self) {
		memset(_buffer, 0, _maximumLength);
		_dataStartOffset = 0;
		_dataEndOffset = 0;
		_empty = YES;
	}
}

-(NSUInteger)attemptAppendData:(const void *)data ofLength:(NSUInteger)dataLength {
	return [self attemptAppendData:data ofLength:dataLength chunkSize:1];
}

-(NSUInteger)attemptAppendData:(const void *)data ofLength:(NSUInteger)dataLength chunkSize:(NSUInteger)chunkSize {

	@synchronized(self) {

		NSUInteger availableBufferSpace = self.maximumLength - self.length;
		if (chunkSize == 0) chunkSize = 1;

		// chunkSize is the minimum amount of data we can copy in
		if (availableBufferSpace < chunkSize)
			return 0;

		// First make sure we have a data length that fits into the buffer
		NSUInteger writableByteCount = MIN(dataLength, availableBufferSpace);
		// ...that also fits into our chunkSize
		writableByteCount -= (writableByteCount % chunkSize);

		NSUInteger directCopyByteCount = MIN(writableByteCount, self.maximumLength - (_empty ? 0 : _dataEndOffset + 1));
		NSUInteger wraparoundByteCount = writableByteCount - directCopyByteCount;
		
		if (directCopyByteCount > 0) {
			void *writePtr = _buffer + (_empty ? 0 : _dataEndOffset + 1);
			memcpy(writePtr, data, directCopyByteCount);
			_dataEndOffset += (_empty ? directCopyByteCount - 1 : directCopyByteCount);
		}
		
		if (wraparoundByteCount > 0) {
			memcpy(_buffer, data + directCopyByteCount, wraparoundByteCount);
			_dataEndOffset = wraparoundByteCount - 1;
		}
		
		if (writableByteCount > 0)
			_empty = NO;
		
		return writableByteCount;
	}
}

-(NSUInteger)readDataOfLength:(NSUInteger)desiredLength intoAllocatedBuffer:(void **)outBuffer {
	
	if (outBuffer == NULL || desiredLength == 0)
		return 0;
	
    NSUInteger usedBufferSpace = self.length;
    
	@synchronized(self) {
		
		if (usedBufferSpace == 0) {
			return 0;
		}
		
		NSUInteger readableByteCount = MIN(usedBufferSpace, desiredLength);
		NSUInteger directCopyByteCount = MIN(readableByteCount, self.maximumLength - _dataStartOffset);
		NSUInteger wraparoundByteCount = readableByteCount - directCopyByteCount;
		
		void *destinationBuffer = *outBuffer;
		
		if (directCopyByteCount > 0) {
			memcpy(destinationBuffer, _buffer + _dataStartOffset, directCopyByteCount);
			_dataStartOffset += directCopyByteCount;
		}
		
		if (wraparoundByteCount > 0) {
			memcpy(destinationBuffer + directCopyByteCount, _buffer, wraparoundByteCount);
			_dataStartOffset = wraparoundByteCount;
		}
		
		return readableByteCount;
	}
	
}

-(NSUInteger)length {
	// Length is the distance between the start offset (start of the data)
	// and the end offset (end).
	@synchronized(self) {
		if (_dataStartOffset == _dataEndOffset) {
			// Empty!
			return 0;
		} else if (_dataEndOffset > _dataStartOffset) {
			return (_dataEndOffset - _dataStartOffset) + 1;
		} else {
			return (_maximumLength - _dataStartOffset) + _dataEndOffset + 1;
		}
	}
}

- (void)dealloc {
	@synchronized(self) {
		memset(_buffer, 0, _maximumLength);
		free(_buffer);
	}
}

@end
