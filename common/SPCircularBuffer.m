//
//  SPCircularBuffer.m
//  Viva
//
//  Created by Daniel Kennett on 4/9/11.
/*
 Copyright 2013 Spotify AB

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
