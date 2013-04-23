//
//  SPArrayExtensions.m
//  Guess The Intro
//
//  Created by Daniel Kennett on 05/05/2011.
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

#import "SPArrayExtensions.h"

@implementation NSArray (SPArrayExtensions)

+(void)initialize {
    srandom((unsigned int)time(NULL));
}

-(id)randomObject {
	
	if ([self count] == 0)
		return nil;
	
	NSUInteger index = random() % [self count];
	
	if (index <= ([self count] - 1)) {
		return [self objectAtIndex:index];
	} else {
		return nil;
	}
	
}

@end
