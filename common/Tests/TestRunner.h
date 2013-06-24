//
//  AppDelegate.h
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

@class TestRunner;

@protocol TestRunnerDelegate <NSObject>

-(void)testRunner:(TestRunner *)runner willStartTests:(NSArray *)tests;
-(void)testRunner:(TestRunner *)runner didCompleteTestsWithPassCount:(NSUInteger)passCount failCount:(NSUInteger)failCount;

@end

@interface TestRunner : NSObject

@property (nonatomic, weak) id <TestRunnerDelegate> delegate;

-(void)runTests;

@end
