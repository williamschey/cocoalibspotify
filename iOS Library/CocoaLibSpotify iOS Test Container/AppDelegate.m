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
#import "TestConstants.h"
#import "TestRunner.h"

@interface AppDelegate ()

@property (nonatomic, readwrite, strong) TestRunner *testRunner;

@end

@implementation AppDelegate

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
	self.viewController = [[TestsViewController alloc] initWithStyle:UITableViewStyleGrouped];
	UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:self.viewController];
	self.window.rootViewController = navigation;
    [self.window makeKeyAndVisible];

	
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

	} else {
		self.testRunner = [TestRunner new];
		self.testRunner.delegate = self.viewController;
		[self.testRunner runTests];
	}

	return YES;
}

@end
