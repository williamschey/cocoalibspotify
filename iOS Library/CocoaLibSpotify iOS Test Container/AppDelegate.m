//
//  AppDelegate.m
//  CocoaLibSpotify iOS Test Container
//
//  Created by Daniel Kennett on 22/05/2012.
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

#import "AppDelegate.h"
#import "TestsViewController.h"

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

@interface AppDelegate ()
@property (nonatomic, strong) SPTests *sessionTests;
@property (nonatomic, strong) SPTests *metadataTests;
@property (nonatomic, strong) SPTests *searchTests;
@property (nonatomic, strong) SPTests *inboxTests;
@property (nonatomic, strong) SPTests *audioTests;
@property (nonatomic, strong) SPTests *teardownTests;
@property (nonatomic, strong) SPTests *playlistTests;
@property (nonatomic, strong) SPTests *concurrencyTests;
@property (nonatomic, strong) SPTests *asyncTests;
@end

@implementation AppDelegate

-(void)completeTestsWithPassCount:(NSUInteger)passCount failCount:(NSUInteger)failCount {
	printf("**** Completed %lu tests with %lu passes and %lu failures ****\n", (unsigned long)(passCount + failCount), (unsigned long)passCount, (unsigned long)failCount);
	[self pushColorToStatusServer:failCount > 0 ? [UIColor redColor] : [UIColor greenColor]];
	self.viewController.title = failCount > 0 ? @"Test(s) failed" : @"All tests passed";
}

-(void)pushColorToStatusServer:(UIColor *)color {
	
	NSString *statusServerAddress = [[NSUserDefaults standardUserDefaults] stringForKey:kTestStatusServerUserDefaultsKey];
	if (statusServerAddress.length == 0) return;
	
	CGFloat red = 0.0;
	CGFloat green = 0.0;
	CGFloat blue = 0.0;
	
	[color getRed:&red green:&green blue:&blue alpha:NULL];
	
	NSString *requestUrlString = [NSString stringWithFormat:@"http://%@/push-color?red=%u&green=%u&blue=%u",
								  statusServerAddress,
								  (NSUInteger)red * 255,
								  (NSUInteger)green * 255,
								  (NSUInteger)blue * 255];
	
	NSURL *requestUrl = [NSURL URLWithString:requestUrlString];							  
	NSURLRequest *request = [NSURLRequest requestWithURL:requestUrl 
											 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
										 timeoutInterval:1.0];
	
	[NSURLConnection sendSynchronousRequest:request
						  returningResponse:nil
									  error:nil];
	
}

#pragma mark - Running Tests

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	printf("Unit tests starting with libspotify version %s.\n", [[SPSession libSpotifyBuildId] UTF8String]);
	
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
	self.viewController = [[TestsViewController alloc] initWithStyle:UITableViewStyleGrouped];
	UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:self.viewController];
	self.window.rootViewController = navigation;
    [self.window makeKeyAndVisible];
    
	[self pushColorToStatusServer:[UIColor yellowColor]];

	//Warn if username and password aren't available
	NSString *userName = [[NSUserDefaults standardUserDefaults] stringForKey:kTestUserNameUserDefaultsKey];
	NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:kTestPasswordUserDefaultsKey];

	if (userName.length == 0 || password.length == 0) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Details Missing"
														message:@"The username, password or both are missing. Please consult the testing part of the readme file."
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
	}

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

	self.viewController.tests = tests;

	__block NSUInteger totalPassCount = 0;
	__block NSUInteger totalFailCount = 0;
	__block NSUInteger currentTestIndex = 0;

	__block void (^runNextTest)(void) = ^ {

		if (currentTestIndex >= tests.count) {
			[self completeTestsWithPassCount:totalPassCount failCount:totalFailCount];
			return;
		}

		SPTests *testsToRun = tests[currentTestIndex];
		[testsToRun runTests:^(NSUInteger passCount, NSUInteger failCount) {
			totalPassCount += passCount;
			totalFailCount += failCount;

			//Special-case the first test suite since libspotify currently crashes a lot
			//if you call certain APIs without being logged in.
			if (currentTestIndex == 0 && totalFailCount > 0) {
				[self completeTestsWithPassCount:totalPassCount failCount:totalFailCount];
				return;
			}

			currentTestIndex++;
			runNextTest();
		}];
	};

	runNextTest();
	return YES;
}

@end
