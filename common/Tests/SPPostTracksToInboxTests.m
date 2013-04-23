//
//  SPPostTracksToInboxTests.m
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

#import "SPPostTracksToInboxTests.h"
#import "SPSession.h"
#import "SPTrack.h"
#import "SPPostTracksToInboxOperation.h"
#import "TestConstants.h"

@implementation SPPostTracksToInboxTests

-(void)testPostTracksToInbox {

	SPAssertTestCompletesInTimeInterval(kSPAsyncLoadingDefaultTimeout * 2);
	// ^Posting to inbox can take a long time in some situations, but still work OK.
	
	[SPTrack trackForTrackURL:[NSURL URLWithString:kInboxTestTrackToSendURI] inSession:[SPSession sharedSession] callback:^(SPTrack *track) {
		
		SPTestAssert(track != nil, @"SPTrack returned nil for %@", kInboxTestTrackToSendURI);
		
		[SPPostTracksToInboxOperation sendTracks:[NSArray arrayWithObject:track]
										  toUser:kInboxTestTargetUserName
										  message:kInboxTestMessage
									   inSession:[SPSession sharedSession]
										callback:^(NSError *error) {
											SPTestAssert(error == nil, @"Post to inbox operation encountered error: %@", error);
											SPTestAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"Post tracks callback on wrong queue.");
											SPPassTest();
										}];
	}];
}

@end
