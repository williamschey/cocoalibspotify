//
//  SparseListArrayAdapter.m
//  CocoaLibSpotify Mac Framework
//
//  Created by Daniel Kennett on 24/06/2013.
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

#import "SparseListArrayAdapter.h"
#import "SPCommon.h"
#import "CocoaLibSpotifyPlatformImports.h"
#import "SPErrorExtensions.h"

@interface SparseListArrayAdapter ()
@property (nonatomic, readwrite, copy) NSArray *sourceArray;
@end

@implementation SparseListArrayAdapter

-(id)initWithSource:(NSArray *)source {
	self = [super init];
	if (self) {
		self.sourceArray = source;
	}
	return self;
}

-(NSUInteger)itemCount {
	return self.sourceArray.count;
}

-(void)fetchItemsInRange:(NSRange)range callback:(void (^)(NSError *, NSArray *))block {

	SPDispatchAsync(^{

		if (range.location + range.length > self.sourceArray.count) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{
				block([NSError spotifyErrorWithCode:SP_ERROR_INDEX_OUT_OF_RANGE], nil);
			});
			return;
		}

		if (block) dispatch_async(dispatch_get_main_queue(), ^{
			block(nil, [self.sourceArray subarrayWithRange:range]);
		});
	});
}

@end
