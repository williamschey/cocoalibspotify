//
//  main.m
//  CocoaLibSpotify Test Container
//
//  Created by Daniel Kennett on 09/05/2012.
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
#import "TestRunner.h"

@interface TestRunnerDelegateHandler : NSObject <TestRunnerDelegate>
@end

@implementation TestRunnerDelegateHandler

-(void)testRunner:(TestRunner *)runner willStartTests:(NSArray *)tests {}

-(void)testRunner:(TestRunner *)runner didCompleteTestsWithPassCount:(NSUInteger)passCount failCount:(NSUInteger)failCount {
	exit(failCount > 0 ? EXIT_FAILURE : EXIT_SUCCESS);
}

@end

int main(int argc, char *argv[])
{
	TestRunner *runner = [[TestRunner alloc] init];
	TestRunnerDelegateHandler *handler = [TestRunnerDelegateHandler new];
	@autoreleasepool {
		NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
		[runLoop addPort:[NSPort port] forMode:NSRunLoopCommonModes];
		runner.delegate = handler;
		[runner runTests];
		[runLoop run];
 	}
	return 0;
}
