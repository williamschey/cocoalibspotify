//
//  SPTests.m
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

#import "SPTests.h"
#import <objc/runtime.h>
#import "TestConstants.h"

@implementation SPTestUIPlaceholder

-(id)init {
	self = [super init];
	if (self) {
		self.state = kTestStateWaiting;
	}
return self;
}

@end

@interface SPTests ()
@property (nonatomic, readwrite, copy) NSArray *testSelectorNames;
@property (nonatomic, readwrite, copy) void (^completionBlock)(NSUInteger, NSUInteger);
@end

@implementation SPTests {
	NSUInteger nextTestIndex;
	NSUInteger passCount;
	NSUInteger failCount;
}

-(id)init {
	self = [super init];
	if (self) {
		[self setup];
	}
	return self;
}

-(void)passTest:(SEL)testSelector {

	NSString *testName = [self prettyNameForTestSelectorName:NSStringFromSelector(testSelector)];
	for (SPTestUIPlaceholder *placeHolder in self.uiPlaceholders) {
		if ([placeHolder.name isEqualToString:testName]) {
			if (placeHolder.state != kTestStateRunning)
				// Now we have timeouts for all tests, this is expected.
				return;
		}
	}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:kLogForTeamCityUserDefaultsKey])
		printf("##teamcity[testFinished name='%s']\n", [testName UTF8String]);
	else
		printf(" Passed.\n");
	
	passCount++;

	NSUInteger testThatPassedIndex = nextTestIndex - 1;
	SPTestUIPlaceholder *placeholder = [self.uiPlaceholders objectAtIndex:testThatPassedIndex];
	placeholder.state = kTestStatePassed;

	[self runNextTest];
}

-(void)failTest:(SEL)testSelector format:(NSString *)format, ... {

	NSString *testName = [self prettyNameForTestSelectorName:NSStringFromSelector(testSelector)];
	for (SPTestUIPlaceholder *placeHolder in self.uiPlaceholders) {
		if ([placeHolder.name isEqualToString:testName]) {
			if (placeHolder.state != kTestStateRunning)
				// Now we have timeouts for all tests, this is expected.
				return;
		}
	}

	va_list src, dest;
	va_start(src, format);
	va_copy(dest, src);
	va_end(src);
	NSString *msg = [[NSString alloc] initWithFormat:format arguments:dest];

	if ([[NSUserDefaults standardUserDefaults] boolForKey:kLogForTeamCityUserDefaultsKey]) {
		printf("##teamcity[testFailed name='%s' message='%s']\n", [testName UTF8String], [msg UTF8String]);
		printf("##teamcity[testFinished name='%s']\n", [testName UTF8String]);
	} else {
		printf(" Failed. Reason: %s\n", msg.UTF8String);
	}
	
	failCount++;

	NSUInteger testThatPassedIndex = nextTestIndex - 1;
	SPTestUIPlaceholder *placeholder = [self.uiPlaceholders objectAtIndex:testThatPassedIndex];
	placeholder.state = kTestStateFailed;

	[self runNextTest];
}

-(void)failTest:(SEL)testSelector afterTimeout:(NSTimeInterval)timeout {
	NSDictionary *info = @{ @"SelString" : NSStringFromSelector(testSelector),
							@"TimeoutValue" : @(timeout) };

	[self performSelector:@selector(testTimeoutPopped:) withObject:info afterDelay:timeout];
}

-(void)testTimeoutPopped:(NSDictionary *)testInfo {
	NSNumber *timeout = testInfo[@"TimeoutValue"];
	SEL testSelector = NSSelectorFromString(testInfo[@"SelString"]);
	[self failTest:testSelector format:@"Test failed to complete after timeout: %@", timeout];
}

-(NSString *)prettyNameForTestSelectorName:(NSString *)selString {

	if ([selString hasPrefix:@"test"])
		selString = [selString stringByReplacingCharactersInRange:NSMakeRange(0, @"test".length) withString:@""];

	// Skip leading digits
	NSScanner *scanner = [NSScanner scannerWithString:selString];
	[scanner scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
	return [selString substringFromIndex:[scanner scanLocation]];
}

-(void)setup {
	
	unsigned int methodCount = 0;
	Method *testList = class_copyMethodList([self class], &methodCount);

	NSMutableArray *testMethods = [NSMutableArray arrayWithCapacity:methodCount];

	for (unsigned int currentMethodIndex = 0; currentMethodIndex < methodCount; currentMethodIndex++) {
		Method method = testList[currentMethodIndex];
		SEL methodSel = method_getName(method);
		NSString *methodName = NSStringFromSelector(methodSel);
		if ([methodName hasPrefix:@"test"])
			[testMethods addObject:methodName];
	}

	self.testSelectorNames = [testMethods sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	nextTestIndex = 0;
	passCount = 0;
	failCount = 0;
	free(testList);

	NSMutableArray *placeholders = [NSMutableArray arrayWithCapacity:testMethods.count];
	for (NSString *name in self.testSelectorNames) {
		SPTestUIPlaceholder *placeholder = [SPTestUIPlaceholder new];
		placeholder.name = [self prettyNameForTestSelectorName:name];
		[placeholders addObject:placeholder];
	}

	self.uiPlaceholders = [NSArray arrayWithArray:placeholders];
}

#pragma mark - Automatic Running

-(void)runTests:(void (^)(NSUInteger passCount, NSUInteger failCount))block {

	self.completionBlock = block;
	if (![[NSUserDefaults standardUserDefaults] boolForKey:kLogForTeamCityUserDefaultsKey])
		printf("---- Starting %lu tests in %s ----\n", (unsigned long)self.testSelectorNames.count, NSStringFromClass([self class]).UTF8String);
	[self runNextTest];
}

-(void)runNextTest {

	if (self.testSelectorNames == nil)
		return; // Not part of auto-running

	if (nextTestIndex >= self.testSelectorNames.count) {

		self.testSelectorNames = nil;
		nextTestIndex = 0;

		[self testsCompleted];
		return;
	}

	NSString *methodName = [self.testSelectorNames objectAtIndex:nextTestIndex];
	SEL methodSelector = NSSelectorFromString(methodName);
	SPTestUIPlaceholder *placeHolder = [self.uiPlaceholders objectAtIndex:nextTestIndex];
	nextTestIndex++;

	if ([methodName hasPrefix:@"test"]) {
		placeHolder.state = kTestStateRunning;
		if ([[NSUserDefaults standardUserDefaults] boolForKey:kLogForTeamCityUserDefaultsKey])
			printf("##teamcity[testStarted name='%s' captureStandardOutput='true']\n", [self prettyNameForTestSelectorName:methodName].UTF8String);
		else
			printf("Running test %s...", [self prettyNameForTestSelectorName:methodName].UTF8String);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[self performSelector:methodSelector];
#pragma clang diagnostic pop
	} else {
		[self runNextTest];
	}
}

-(void)testsCompleted {
	if (![[NSUserDefaults standardUserDefaults] boolForKey:kLogForTeamCityUserDefaultsKey])
		printf("---- Tests in %s complete with %lu passed, %lu failed ----\n", NSStringFromClass([self class]).UTF8String, (unsigned long)passCount, (unsigned long)failCount);
	if (self.completionBlock) self.completionBlock(passCount, failCount);
}

@end
