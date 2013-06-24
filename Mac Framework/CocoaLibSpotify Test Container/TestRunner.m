//
//  AppDelegate.m
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

#import "TestRunner.h"
#import "SPSessionTests.h"
#import "SPMetadataTests.h"
#import "SPSearchTests.h"
#import "SPPostTracksToInboxTests.h"
#import "SPAudioDeliveryTests.h"
#import "SPSessionTeardownTests.h"
#import "SPPlaylistTests.h"
#import "SPConcurrencyTests.h"
#import "SPAsyncLoadingTests.h"
#import "TestConstants.h"

static NSString * const kTestStatusServerUserDefaultsKey = @"StatusColorServer";

@interface TestRunner ()
@property (nonatomic, strong) SPTests *sessionTests;
@property (nonatomic, strong) SPTests *metadataTests;
@property (nonatomic, strong) SPTests *searchTests;
@property (nonatomic, strong) SPTests *inboxTests;
@property (nonatomic, strong) SPTests *audioTests;
@property (nonatomic, strong) SPTests *teardownTests;
@property (nonatomic, strong) SPTests *playlistTests;
@property (nonatomic, strong) SPTests *concurrencyTests;
@property (nonatomic, strong) SPTests *asyncTests;

@property (nonatomic, strong) dispatch_block_t runTestBlock;
@end

@implementation TestRunner

-(void)completeTestsWithPassCount:(NSUInteger)passCount failCount:(NSUInteger)failCount {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kLogForTeamCityUserDefaultsKey])
		printf("##teamcity[testSuiteFinished name='CocoaLibSpotify']\n");
	else
		printf("**** Completed %lu tests with %lu passes and %lu failures ****\n", passCount + failCount, passCount, failCount);
	[self pushColorToStatusServer:failCount > 0 ? [NSColor redColor] : [NSColor greenColor]];
	exit(failCount > 0 ? EXIT_FAILURE : EXIT_SUCCESS);
}

-(void)pushColorToStatusServer:(NSColor *)color {
	
	NSString *statusServerAddress = [[NSUserDefaults standardUserDefaults] stringForKey:kTestStatusServerUserDefaultsKey];
	if (statusServerAddress.length == 0) return;
	
	NSColor *colorToSend = [color colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]];
	
	NSString *requestUrlString = [NSString stringWithFormat:@"http://%@/push-color?red=%lu&green=%lu&blue=%lu",
								  statusServerAddress,
								  (NSUInteger)colorToSend.redComponent * 255,
								  (NSUInteger)colorToSend.greenComponent * 255,
								  (NSUInteger)colorToSend.blueComponent * 255];
	
	NSURL *requestUrl = [NSURL URLWithString:requestUrlString];							  
	NSURLRequest *request = [NSURLRequest requestWithURL:requestUrl 
											 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
										 timeoutInterval:1.0];
	
	[NSURLConnection sendSynchronousRequest:request
						  returningResponse:nil
									  error:nil];
	
}

#pragma mark - Running Tests

-(void)runTests {
	[self pushColorToStatusServer:[NSColor yellowColor]];
	
	// Make sure we have a clean cache before starting.
	NSString *aUserAgent = @"com.spotify.CocoaLSUnitTests";

	// Find the application support directory for settings
	NSString *applicationSupportDirectory = nil;
	NSArray *potentialDirectories = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
																		NSUserDomainMask,
																		YES);

	if ([potentialDirectories count] > 0) {
		applicationSupportDirectory = [[potentialDirectories objectAtIndex:0] stringByAppendingPathComponent:aUserAgent];
	} else {
		applicationSupportDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:aUserAgent];
	}

	if ([[NSFileManager defaultManager] fileExistsAtPath:applicationSupportDirectory]) {
		printf("Application support directory exists, deleting… ");
		if (![[NSFileManager defaultManager] removeItemAtPath:applicationSupportDirectory error:nil])
			printf("failed.\n");
		else
			printf("done.\n");
	}

	// Find the caches directory for cache
	NSString *cacheDirectory = nil;
	NSArray *potentialCacheDirectories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
																			 NSUserDomainMask,
																			 YES);

	if ([potentialCacheDirectories count] > 0) {
		cacheDirectory = [[potentialCacheDirectories objectAtIndex:0] stringByAppendingPathComponent:aUserAgent];
	} else {
		cacheDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:aUserAgent];
	}

	if ([[NSFileManager defaultManager] fileExistsAtPath:cacheDirectory]) {
		printf("Cache directory exists, deleting… ");
		if (![[NSFileManager defaultManager] removeItemAtPath:cacheDirectory error:nil])
			printf("failed.\n");
		else
			printf("done.\n");
	}

	self.sessionTests = [SPSessionTests new];
	self.concurrencyTests = [SPConcurrencyTests new];
	self.playlistTests = [SPPlaylistTests new];
	self.audioTests = [SPAudioDeliveryTests new];
	self.searchTests = [SPSearchTests new];
	self.inboxTests = [SPPostTracksToInboxTests new];
	self.metadataTests = [SPMetadataTests new];
	self.teardownTests = [SPSessionTeardownTests new];
	self.asyncTests = [SPAsyncLoadingTests new];

	NSArray *tests = @[self.asyncTests, self.sessionTests, self.concurrencyTests, self.playlistTests, self.audioTests, self.searchTests,
	self.inboxTests, self.metadataTests, self.teardownTests];

	__block NSUInteger totalPassCount = 0;
	__block NSUInteger totalFailCount = 0;
	__block NSUInteger currentTestIndex = 0;

	__weak typeof(self) weakSelf = self;

	// Shenanigans to allow a block to reference itself without circular references.
	self.runTestBlock = ^{

		if (currentTestIndex >= tests.count) {
			[weakSelf completeTestsWithPassCount:totalPassCount failCount:totalFailCount];
			return;
		}

		SPTests *testsToRun = tests[currentTestIndex];
		[testsToRun runTests:^(NSUInteger passCount, NSUInteger failCount) {
			totalPassCount += passCount;
			totalFailCount += failCount;

			//Special-case the first test suite since libspotify currently crashes a lot
			//if you call certain APIs without being logged in.
			if (currentTestIndex == 0 && totalFailCount > 0) {
				[weakSelf completeTestsWithPassCount:totalPassCount failCount:totalFailCount];
				return;
			}

			currentTestIndex++;
			weakSelf.runTestBlock();
		}];
	};

	if ([[NSUserDefaults standardUserDefaults] boolForKey:kLogForTeamCityUserDefaultsKey])
		printf("##teamcity[testSuiteStarted name='CocoaLibSpotify']\n");

	weakSelf.runTestBlock();
}

@end
