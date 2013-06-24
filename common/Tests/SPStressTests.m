//
//  SPStressTests.m
//  CocoaLibSpotify Mac Framework
//
//  Created by Daniel Kennett on 24/06/2013.
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

#import "TestConstants.h"
#import "SPStressTests.h"
#import "SPSession.h"
#import "SPPlaylist.h"
#import "SPTrack.h"
#import "SPAlbum.h"
#import "SPImage.h"
#import "SPAsyncLoading.h"
#import "SPPlaylistItem.h"

@implementation SPStressTests

-(void)testHugePlaylist {

	SPAssertTestCompletesInTimeInterval((120.0 * 2) + (kSPAsyncLoadingDefaultTimeout * 3));

	// This test loads a playlist with 10,000 tracks, then loads all of the tracks'
	// metadata. This uses a *ton* of RAM, so don't ever do this in an application.
	// In fact, this test may well crash on an iOS device due to memory restrictions.
	SPSession *session = [SPSession sharedSession];
	NSURL *playlistURL = [NSURL URLWithString:kHugePlaylistURI];
	[SPPlaylist playlistWithPlaylistURL:playlistURL inSession:session callback:^(SPPlaylist *playlist) {

		SPTestAssert(playlist != nil, @"Got nil playlist from %@", playlistURL);

		[SPAsyncLoading waitUntilLoaded:playlist timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *completelyLoadedItems, NSArray *notLoadedItems) {

			SPTestAssert(completelyLoadedItems.count > 0, @"Playlist from %@ didn't load", playlistURL);

			[playlist fetchItemsInRange:NSMakeRange(0, playlist.itemCount) callback:^(NSError *error, NSArray *items) {

				SPTestAssert(error == nil, @"Playlist gave error when fetching items: %@", error);
				SPTestAssert(items.count == playlist.itemCount, @"Playlist gave different number of items than requested (%@ vs. %@)", @(playlist.itemCount), @(items.count));

				NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:playlist.itemCount];
				for (SPPlaylistItem *item in items) {
					if (item.itemClass == [SPTrack class])
						[tracks addObject:item.item];
				}

				SPTestAssert(tracks.count > 0, @"Got 0 tracks from playlist");

				// Load all the metadata.
				// You'll most likely observe that you don't get all 10,000 tracks within the default timeout.
				// This is because 20.0 seconds typically isn't enough time to load the metadata for this many
				// artists and albums, and is expected behaviour. You're encouraged to load metadata in small
				// chunks (see the SPSparseList class) rather than doing this, but this is called the stress test suite
				// for a reason!
				[SPAsyncLoading waitUntilLoaded:tracks withKeyPaths:@[@"artists", @"album", @"album.cover"] timeout:120.0 then:^(NSArray *completelyLoadedTracks, NSArray *notLoadedTracks) {

					[completelyLoadedTracks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
						// If an item *has* a cover image, make sure it's loaded.
						SPTrack *track = obj;
						SPImage *cover = track.album.cover;
						if (cover == nil) return;
						SPTestAssert(cover.isLoaded, @"Got non-nil cover that wasn't loaded");
					}];

#define WRITE_IMAGES 0
#if !TARGET_OS_IPHONE && WRITE_IMAGES

					NSString *path = [[NSString stringWithFormat:@"~/Desktop/%@", [[NSProcessInfo processInfo] globallyUniqueString]] stringByExpandingTildeInPath];

					NSError *error = nil;
					[[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
					SPTestAssert(error == nil, @"Couldn't create directory for images with error: %@", error);

					[completelyLoadedTracks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
						SPTrack *track = obj;
						NSImage *cover = track.album.cover.image;
						[[cover TIFFRepresentation] writeToFile:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.tif", @(idx)]] atomically:YES];
					}];
#endif
					SPPassTest();
				}];
			}];
		}];
	}];
}

@end
