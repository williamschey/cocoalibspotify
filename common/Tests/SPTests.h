//
//  SPTests.h
//  CocoaLibSpotify Mac Framework
//
//  Created by Daniel Kennett on 10/05/2012.
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

#import <Foundation/Foundation.h>

typedef enum {
	kTestStateWaiting,
	kTestStateRunning,
	kTestStatePassed,
	kTestStateFailed
} SPTestState;

@interface SPTestUIPlaceholder : NSObject

@property (nonatomic, readwrite, copy) NSString *name;
@property (nonatomic, readwrite) SPTestState state;

@end

@interface SPTests : NSObject

#define SPPassTest() [self passTest:_cmd]; return;

#define SPTestAssert(condition, desc, ...) \
if (!(condition)) {	\
[self failTest:_cmd format:(desc), ##__VA_ARGS__]; \
return; \
}

#define SPOtherTestAssert(selector, condition, desc, ...) \
if (!(condition)) {	\
[self failTest:selector format:(desc), ##__VA_ARGS__]; \
return; \
}

#define SPAssertTestCompletesInTimeInterval(t) [self failTest:_cmd afterTimeout:t];

-(void)passTest:(SEL)testSelector;
-(void)failTest:(SEL)testSelector format:(NSString *)format, ...;
-(void)failTest:(SEL)testSelector afterTimeout:(NSTimeInterval)timeout;

-(void)runTests:(void (^)(NSUInteger passCount, NSUInteger failCount))block;

@property (nonatomic, readwrite, copy) NSArray *uiPlaceholders;

@end
