//
//  AsyncLoadingMockObjects.m
//  CocoaLibSpotify Mac Framework
//
//  Created by Daniel Kennett on 19/03/2013.
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

#import "AsyncLoadingMockObjects.h"

@interface AsyncLoadingObject ()
@property (nonatomic, readwrite, getter = isLoaded) BOOL loaded;
@end

@implementation AsyncLoadingObject
@end

@implementation AsyncWillNeverLoadObject

-(void)startLoading {}

@end

#pragma mark -

@implementation AsyncWillLoadImmediatelyObject

-(void)startLoading {
	dispatch_async(dispatch_get_main_queue(), ^{
		self.loaded = YES;
	});
}

@end

#pragma mark -

@implementation AsyncWillLoadWithFixedDelayObject

-(void)startLoading {
	double delayInSeconds = 2.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		self.loaded = YES;
	});
}

@end

#pragma mark -

@implementation AsyncWillLoadWithRandomDelayObject

#include <stdlib.h>

-(void)startLoading {
	int random = arc4random_uniform(2.0 * 1000); // ms
	double delayInSeconds = (random / 1000.0);
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		self.loaded = YES;
	});
}

@end


