//
//  SPAudioDeliveryTests.m
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

#import "SPAudioDeliveryTests.h"
#import "SPAsyncLoading.h"
#import "SPTrack.h"
#import "TestConstants.h"

@implementation SPAudioDeliveryTests

-(void)testAudioDelivery {

	SPAssertTestCompletesInTimeInterval(kSPAsyncLoadingDefaultTimeout + kDefaultNonAsyncLoadingTestTimeout);
	
	[SPTrack trackForTrackURL:[NSURL URLWithString:kTrackLoadingTestURI]
					inSession:[SPSession sharedSession]
					 callback:^(SPTrack *track) {
						 
						 SPTestAssert(track != nil, @"Track is nil for %@", track);
						 
						 [SPAsyncLoading waitUntilLoaded:track timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
							 SPTestAssert(notLoadedItems.count == 0, @"Track loading timed out for %@", track);
							 
							 SPSession *session = [SPSession sharedSession];
							 session.audioDeliveryDelegate = self;
							 session.playbackDelegate = self;

							 [session playTrack:track callback:^(NSError *error) {
								 SPTestAssert(error == nil, @"Track playback encountered error: %@", error);
							 }];
						 }];
					 }];
}

-(void)sessionDidLosePlayToken:(id <SPSessionPlaybackProvider>)aSession {}
-(void)sessionDidEndPlayback:(id <SPSessionPlaybackProvider>)aSession {}

-(void)session:(id <SPSessionPlaybackProvider>)aSession didEncounterStreamingError:(NSError *)error {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self failTest:@selector(testAudioDelivery) format:@"Streaming error waiting for audio delivery: %@", error];
	});
}

-(NSInteger)session:(id <SPSessionPlaybackProvider>)aSession shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount streamDescription:(AudioStreamBasicDescription)audioDescription {
	
	if (frameCount == 0) return 0;
	
	aSession.playing = NO;
	[aSession unloadPlayback];
	[(SPSession *)aSession setAudioDeliveryDelegate:nil];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self passTest:@selector(testAudioDelivery)];
	});
	return 0;
}

@end
