//
//  SPSessionTeardownTests.m
//  CocoaLibSpotify Mac Framework
//
//  Created by Daniel Kennett on 11/05/2012.
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

#import "SPSessionTeardownTests.h"
#import "SPSession.h"
#import "TestConstants.h"

@implementation SPSessionTeardownTests

-(void)testSessionLogout {

	SPAssertTestCompletesInTimeInterval(kDefaultNonAsyncLoadingTestTimeout);
	
	[[SPSession sharedSession] logout:^{
		
		SPSession *session = [SPSession sharedSession];
		
		SPTestAssert(session.user == nil, @"Logged-out session still has user: %@", session.user);
		SPTestAssert(session.starredPlaylist == nil, @"Logged-out session still has starred: %@", session.starredPlaylist);
		SPTestAssert(session.userPlaylists == nil, @"Logged-out session still has user playlists: %@", session.userPlaylists);
		SPTestAssert(session.locale	== nil, @"Logged-out session still has locale: %@", session.locale);
		SPTestAssert(session.inboxPlaylist == nil, @"Logged-out session still has user: %@", session.inboxPlaylist);
		SPTestAssert(session.connectionState == SP_CONNECTION_STATE_LOGGED_OUT, @"Logged-out session has incorrect connection state: %u", session.connectionState);
		
		SPPassTest();
	}];
}


@end
