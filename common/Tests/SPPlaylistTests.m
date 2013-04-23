//
//  SPPlaylistTests.m
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

#import "SPPlaylistTests.h"
#import "SPSession.h"
#import "SPPlaylistContainer.h"
#import "SPPlaylist.h"
#import "SPPlaylistItem.h"
#import "SPPlaylistFolder.h"
#import "SPAsyncLoading.h"
#import "SPTrack.h"
#import "TestConstants.h"

@interface SPPlaylistTests ()
@property (nonatomic, readwrite, strong) SPPlaylist *playlist;
@end

@implementation SPPlaylistTests

-(void)test1InboxPlaylist {

	SPAssertTestCompletesInTimeInterval(kSPAsyncLoadingDefaultTimeout * 2);
	SPSession *session = [SPSession sharedSession];
	
	[SPAsyncLoading waitUntilLoaded:session timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedSession, NSArray *notLoadedSession) {
		
		SPTestAssert(session.inboxPlaylist != nil, @"Inbox playlist is nil");
		
		[SPAsyncLoading waitUntilLoaded:session.inboxPlaylist timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
			
			SPTestAssert(notLoadedItems.count == 0, @"Playlist loading timed out for %@", session.inboxPlaylist);
			SPPassTest();
		}];
	}];
}

-(void)test2StarredPlaylist {

	SPAssertTestCompletesInTimeInterval(kSPAsyncLoadingDefaultTimeout * 2);
	SPSession *session = [SPSession sharedSession];
	
	[SPAsyncLoading waitUntilLoaded:session timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedSession, NSArray *notLoadedSession) {
		
		SPTestAssert(session.starredPlaylist != nil, @"Starred playlist is nil");
		
		[SPAsyncLoading waitUntilLoaded:session.starredPlaylist timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
			
			SPTestAssert(notLoadedItems.count == 0, @"Playlist loading timed out for %@", session.starredPlaylist);
			SPPassTest();
		}];
	}];
}

-(void)test3PlaylistContainer {

	SPAssertTestCompletesInTimeInterval(kSPAsyncLoadingDefaultTimeout * 2);
	SPSession *session = [SPSession sharedSession];
	
	[SPAsyncLoading waitUntilLoaded:session timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedSession, NSArray *notLoadedSession) {
		
		SPPlaylistContainer *container = session.userPlaylists;
		SPTestAssert(container != nil, @"User playlists is nil");
		
		[SPAsyncLoading waitUntilLoaded:container timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
			
			SPTestAssert(notLoadedItems.count == 0, @"Playlist container loading timed out for %@", container);
			SPTestAssert(container.owner != nil, @"User playlists has nil owner");
			SPTestAssert(container.playlists != nil, @"User playlists has nil playlist tree");
			
			// Test below assumes user has > 0 playlists
			SPTestAssert(container.loaded == YES, @"userPlaylists not loaded");
			SPTestAssert(container.flattenedPlaylists.count > 0, @"No playlists loaded");

			SPPassTest();
		}];
	}];
}

-(void)test4PlaylistCreation {

	SPAssertTestCompletesInTimeInterval(kDefaultNonAsyncLoadingTestTimeout + (kSPAsyncLoadingDefaultTimeout * 3));
	SPSession *session = [SPSession sharedSession];
	
	[SPAsyncLoading waitUntilLoaded:session timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedSession, NSArray *notLoadedSession) {
		
		SPPlaylistContainer *container = session.userPlaylists;
		SPTestAssert(container != nil, @"User playlists is nil");
		
		[SPAsyncLoading waitUntilLoaded:container timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
			
			SPTestAssert(notLoadedItems.count == 0, @"Playlist container loading timed out for %@", container);
			
			[container createPlaylistWithName:kTestPlaylistName callback:^(SPPlaylist *createdPlaylist) {
				SPTestAssert(createdPlaylist != nil, @"Created nil playlist");
				SPTestAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"createPlaylistWithName callback on wrong queue.");
				
				self.playlist = createdPlaylist;
				
				[SPAsyncLoading waitUntilLoaded:createdPlaylist timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedPlaylist, NSArray *notLoadedPlaylist) {
					
					SPTestAssert(notLoadedPlaylist.count == 0, @"Playlist loading timed out for %@", createdPlaylist);
					SPTestAssert([container.flattenedPlaylists containsObject:createdPlaylist], @"Playlist container doesn't contain playlist %@", createdPlaylist);
					SPTestAssert([createdPlaylist.name isEqualToString:kTestPlaylistName], @"Created playlist has incorrect name: %@", createdPlaylist);
					SPPassTest();
				}];
			}];
		}];
	}];
}

-(void)test5PlaylistTrackManagement {
	
	__weak SPPlaylistTests *sself = self;

	SPAssertTestCompletesInTimeInterval((kDefaultNonAsyncLoadingTestTimeout * 2) + kSPAsyncLoadingDefaultTimeout);
	SPTestAssert(self.playlist != nil, @"Test playlist is nil - cannot run test");
	
	[SPAsyncLoading waitUntilLoaded:self.playlist timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
		
		SPTestAssert(notLoadedItems.count == 0, @"Playlist loading timed out for %@", self.playlist);
		
		[SPTrack trackForTrackURL:[NSURL URLWithString:kPlaylistTestTrack1TestURI] inSession:[SPSession sharedSession] callback:^(SPTrack *track1) {
			[SPTrack trackForTrackURL:[NSURL URLWithString:kPlaylistTestTrack2TestURI] inSession:[SPSession sharedSession] callback:^(SPTrack *track2) {
				
				SPTestAssert(track1 != nil, @"SPTrack returned nil for %@", kPlaylistTestTrack1TestURI);
				SPTestAssert(track2 != nil, @"SPTrack returned nil for %@", kPlaylistTestTrack2TestURI);
				SPTestAssert(![track1 isEqual:track2], @"track1 shouldn't be equal to track2");
				
				[sself.playlist addItems:[NSArray arrayWithObjects:track1, track2, nil] atIndex:0 callback:^(NSError *error) {
					
					SPTestAssert(error == nil, @"Got error when adding to playlist: %@", error);
					SPTestAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"addItems callback on wrong queue.");
					
					// Tracks get converted to items.
					[sself.playlist fetchItemsInRange:NSMakeRange(0, sself.playlist.itemCount) callback:^(NSError *error, NSArray *originalPlaylistTracks) {

						SPTestAssert(error == nil, @"Got error when fetching tracks: %@", error);
						SPTestAssert(originalPlaylistTracks.count == 2, @"Playlist doesn't have 2 tracks, instead has: %u", originalPlaylistTracks.count);
						SPTestAssert([[(SPPlaylistItem *)[originalPlaylistTracks objectAtIndex:0] item] isEqual:track1], @"Playlist track 0 should be %@, is actually %@", track1, [originalPlaylistTracks objectAtIndex:0]);
						SPTestAssert([[(SPPlaylistItem *)[originalPlaylistTracks objectAtIndex:1] item] isEqual:track2], @"Playlist track 1 should be %@, is actually %@", track2, [originalPlaylistTracks objectAtIndex:1]);

						[sself.playlist moveItemsAtIndexes:[NSIndexSet indexSetWithIndex:0] toIndex:2 callback:^(NSError *moveError) {

							SPTestAssert(moveError == nil, @"Move operation returned error: %@", moveError);
							SPTestAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"moveItemsAtIndexes callback on wrong queue.");

							[sself.playlist fetchItemsInRange:NSMakeRange(0, sself.playlist.itemCount) callback:^(NSError *error, NSArray *movedPlaylistTracks) {

								SPTestAssert(error == nil, @"Got error when fetching tracks: %@", error);
								SPTestAssert(movedPlaylistTracks.count == 2, @"Playlist doesn't have 2 tracks after move, instead has: %u", movedPlaylistTracks.count);
								SPTestAssert([[(SPPlaylistItem *)[movedPlaylistTracks objectAtIndex:0] item] isEqual:track2], @"Playlist track 0 should be %@ after move, is actually %@", track2, [movedPlaylistTracks objectAtIndex:0]);
								SPTestAssert([[(SPPlaylistItem *)[movedPlaylistTracks objectAtIndex:1] item] isEqual:track1], @"Playlist track 1 should be %@ after move, is actually %@", track1, [movedPlaylistTracks objectAtIndex:1]);

								[sself.playlist removeItemAtIndex:0 callback:^(NSError *deletionError) {

									SPTestAssert(deletionError == nil, @"Removal operation returned error: %@", deletionError);
									SPTestAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"removeItemAtIndex		callback on wrong queue.");

									[sself.playlist fetchItemsInRange:NSMakeRange(0, sself.playlist.itemCount) callback:^(NSError *error, NSArray *afterDeletionPlaylistTracks) {

										SPTestAssert(error == nil, @"Got error when fetching tracks: %@", error);
										SPTestAssert(afterDeletionPlaylistTracks.count == 1, @"Playlist doesn't have 1 tracks after track remove, instead has: %u", afterDeletionPlaylistTracks.count);
										SPTestAssert([[(SPPlaylistItem *)[afterDeletionPlaylistTracks objectAtIndex:0] item] isEqual:track1], @"Playlist track 0 should be %@ after track remove, is actually %@", track1, [afterDeletionPlaylistTracks objectAtIndex:0]);
										SPPassTest();
									}];
								}];
							}];
						}];
					}];
				}];
			}];
		}];
	}];
}

-(void)test6PlaylistDeletion {

	SPAssertTestCompletesInTimeInterval(kDefaultNonAsyncLoadingTestTimeout + (kSPAsyncLoadingDefaultTimeout * 2));
	SPTestAssert(self.playlist != nil, @"Test playlist is nil - cannot remove");
	
	// Removing playlist
	SPSession *session = [SPSession sharedSession];
	
	[SPAsyncLoading waitUntilLoaded:session timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedSession, NSArray *notLoadedSession) {
		
		SPPlaylistContainer *container = session.userPlaylists;
		SPTestAssert(container != nil, @"User playlists is nil");
		
		[SPAsyncLoading waitUntilLoaded:container timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
			
			SPTestAssert(notLoadedItems.count == 0, @"Playlist container loading timed out for %@", container);
			
			[container removeItem:self.playlist callback:^(NSError *error) {
				
				SPTestAssert(error == nil, @"Removal operation returned error: %@", error);
				SPTestAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"removeItem callback on wrong queue.");
				SPTestAssert(![container.flattenedPlaylists containsObject:self.playlist], @"Playlist container still contains playlist: %@", self.playlist);
				self.playlist = nil;
				SPPassTest();
			}];
		}];
	}];
}

@end
