//
//  SPSessionTests.m
//  CocoaLibSpotify Mac Framework
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

#import "SPSessionTests.h"
#import "SPSession.h"
#import "SPUser.h"
#import "TestConstants.h"
#import "NSData+Base64.h"

@implementation SPSessionTests {
	BOOL _didGetLoginBlob;
	BOOL _shouldValidateBlobs;
	NSString *_loginBlobUsername;
	NSString *_loginBlob;
}

#pragma mark - Initialising SPSession

-(void)test1InvalidSessionInit {

	SPAssertTestCompletesInTimeInterval(kDefaultNonAsyncLoadingTestTimeout);
    NSError *error = nil;
    [SPSession initializeSharedSessionWithApplicationKey:nil
                                               userAgent:@"com.spotify.CocoaLSUnitTests"
                                           loadingPolicy:SPAsyncLoadingManual
                                                   error:&error];

    SPTestAssert(error != nil, @"Session initialisation should have provided an error.");
    SPTestAssert([SPSession sharedSession] == nil, @"Session should be nil: %@", [SPSession sharedSession]);

    error = nil;
    [SPSession initializeSharedSessionWithApplicationKey:nil
                                               userAgent:@""
                                           loadingPolicy:SPAsyncLoadingManual
                                                   error:&error];

    SPTestAssert(error != nil, @"Session initialisation should have provided an error.");
    SPTestAssert([SPSession sharedSession] == nil, @"Session should be nil: %@", [SPSession sharedSession]);
    SPPassTest();
}

-(void)test2ValidSessionInit {

	SPAssertTestCompletesInTimeInterval(kDefaultNonAsyncLoadingTestTimeout);

	NSString *base64AppKeyString = [[NSUserDefaults standardUserDefaults] stringForKey:kAppKeyUserDefaultsKey];
	SPTestAssert(base64AppKeyString.length != 0, @"Appkey cannot be empty.");
	NSData *appKey = [NSData dataFromBase64String:base64AppKeyString];
	SPTestAssert(appKey.length != 0, @"Appket is invalid.");

	NSError *error = nil;
    [SPSession initializeSharedSessionWithApplicationKey:appKey
                                               userAgent:@"com.spotify.CocoaLSUnitTests"
                                           loadingPolicy:SPAsyncLoadingManual
                                                   error:&error];

    SPTestAssert(error == nil, @"Error should be nil: %@.", error);
    SPTestAssert([SPSession sharedSession] != nil, @"Session should not be be nil.");

    [SPSession sharedSession].delegate = self;

    [[SPSession sharedSession] fetchLoginUserName:^(NSString *loginUserName) {
        SPTestAssert(loginUserName == nil, @"loginUserName should be nil: %@.", loginUserName);
        SPPassTest();
    }];
}

#pragma mark - Logging In

-(void)test3SessionLogin {

	SPAssertTestCompletesInTimeInterval(kDefaultNonAsyncLoadingTestTimeout);
	SPTestAssert([SPSession sharedSession] != nil, @"Session should not be be nil.");
	
	NSString *userName = [[NSUserDefaults standardUserDefaults] valueForKey:kTestUserNameUserDefaultsKey];
	NSString *password = [[NSUserDefaults standardUserDefaults] valueForKey:kTestPasswordUserDefaultsKey];
	
	SPTestAssert(userName.length > 0, @"Test username is nil.");
	SPTestAssert(password.length > 0, @"Test password is nil.");
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(loginDidSucceed:)
												 name:SPSessionLoginDidSucceedNotification
                                             object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(loginDidFail:)
                                               name:SPSessionLoginDidFailNotification
                                             object:nil];
	
	[[SPSession sharedSession] attemptLoginWithUserName:userName
                                             password:password];
}

-(void)loginDidSucceed:(NSNotification *)notification {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[[SPSession sharedSession] fetchLoginUserName:^(NSString *loginUserName) {
		SPOtherTestAssert(@selector(test3SessionLogin), loginUserName != nil, @"loginUserName was nil after login");
		[self passTest:@selector(test3SessionLogin)];
	}];
}

-(void)loginDidFail:(NSNotification *)notification {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self failTest:@selector(test3SessionLogin) format:@"Login failed: %@", [[notification userInfo] valueForKey:SPSessionLoginDidFailErrorKey]];
}

#pragma mark - Misc

-(void)test4UserDetails {

	SPAssertTestCompletesInTimeInterval(kSPAsyncLoadingDefaultTimeout * 2);
	SPTestAssert([SPSession sharedSession] != nil, @"Session should not be be nil.");
	
	[SPAsyncLoading waitUntilLoaded:[SPSession sharedSession] timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
		
		SPTestAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"SPAsyncLoading callback on wrong queue.");
		SPTestAssert(notLoadedItems.count == 0, @"Session loading timed out for %@", [SPSession sharedSession]);
		
		[SPAsyncLoading waitUntilLoaded:[SPSession sharedSession].user timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedUsers, NSArray *notLoadedUsers) {
			
			SPTestAssert(notLoadedUsers.count == 0, @"User loading timed out for %@", [SPSession sharedSession].user);
			
			SPUser *user = [SPSession sharedSession].user;
			SPTestAssert(user.canonicalName.length > 0, @"User has no canonical name: %@", user);
			SPTestAssert(user.displayName.length > 0, @"User has no display name: %@", user);
			SPTestAssert(user.spotifyURL != nil, @"User has no Spotify URI: %@", user);
			SPPassTest();
		}];
	}];
}

-(void)test5SessionLocale {

	SPAssertTestCompletesInTimeInterval(kSPAsyncLoadingDefaultTimeout);
	SPTestAssert([SPSession sharedSession] != nil, @"Session should not be be nil.");
	
	[SPAsyncLoading waitUntilLoaded:[SPSession sharedSession] timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
		
		SPTestAssert(notLoadedItems.count == 0, @"Session loading timed out for %@", [SPSession sharedSession]);
		SPTestAssert([SPSession sharedSession].locale != nil, @"Session has no locale.");
		SPPassTest();
	}];
}

-(void)test6CredentialBlobs {

	SPAssertTestCompletesInTimeInterval(kDefaultNonAsyncLoadingTestTimeout);
	_shouldValidateBlobs = YES;
	
	if (_didGetLoginBlob)
		[self validateReceivedBlobs];
}

-(void)validateReceivedBlobs {
	[SPSession sharedSession].delegate = nil;
	
	SEL selector = @selector(test6CredentialBlobs);
	NSString *userName = [[NSUserDefaults standardUserDefaults] valueForKey:kTestUserNameUserDefaultsKey];
	
	SPOtherTestAssert(selector, [_loginBlobUsername caseInsensitiveCompare:userName] == NSOrderedSame, @"Got incorrect user for blob: %@", _loginBlobUsername);
	SPOtherTestAssert(selector, _loginBlob.length > 0, @"Got empty login blob");
	[self passTest:selector];
}

-(void)session:(SPSession *)session didGenerateLoginCredentials:(NSString *)credential forUserName:(NSString *)userName {
	_loginBlobUsername = userName;
	_loginBlob = credential;
	_didGetLoginBlob = YES;
	if (_shouldValidateBlobs)
		[self validateReceivedBlobs];
}

@end
