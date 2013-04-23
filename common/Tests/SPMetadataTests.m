//
//  SPMetadataTests.m
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

#import "SPMetadataTests.h"
#import "SPArtist.h"
#import "SPAlbum.h"
#import "SPArtistBrowse.h"
#import "SPAlbumBrowse.h"
#import "SPTrack.h"
#import "SPImage.h"
#import "SPToplist.h"
#import "SPAsyncLoading.h"
#import "SPSession.h"
#import "TestConstants.h"

@implementation SPMetadataTests

-(void)testArtistMetadataLoading {

	SPAssertTestCompletesInTimeInterval(kSPAsyncLoadingDefaultTimeout + kDefaultNonAsyncLoadingTestTimeout);
	[SPArtist artistWithArtistURL:[NSURL URLWithString:kArtistLoadingTestURI]
						inSession:[SPSession sharedSession]
						 callback:^(SPArtist *artist) {
							 
							 SPTestAssert(artist != nil, @"%@ returned nil artist", kArtistLoadingTestURI);
							 
							 [SPAsyncLoading waitUntilLoaded:artist timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
								 SPTestAssert(notLoadedItems.count == 0, @"Artist loading timed out for %@", artist);
								 SPTestAssert(artist.name.length != 0, @"Artist has no name");
								 SPPassTest();
							 }];
						 }];
}

-(void)testAlbumMetadataLoading {

	SPAssertTestCompletesInTimeInterval(kSPAsyncLoadingDefaultTimeout + kDefaultNonAsyncLoadingTestTimeout);
	[SPAlbum albumWithAlbumURL:[NSURL URLWithString:kAlbumLoadingTestURI]
					 inSession:[SPSession sharedSession]
					  callback:^(SPAlbum *album) {
						  
						  SPTestAssert(album != nil, @"%@ returned nil album", kAlbumLoadingTestURI);
						  
						  [SPAsyncLoading waitUntilLoaded:album timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
							  SPTestAssert(notLoadedItems.count == 0, @"Album loading timed out for %@", album);
							  SPTestAssert(album.name.length != 0, @"Album has no name");
							  SPTestAssert(album.artist != nil, @"Album has no artist");
							  SPPassTest();
						  }];
					  }];
}

-(void)testArtistBrowseMetadataLoading {

	SPAssertTestCompletesInTimeInterval(kSPAsyncLoadingDefaultTimeout + kDefaultNonAsyncLoadingTestTimeout);
	[SPArtistBrowse browseArtistAtURL:[NSURL URLWithString:kArtistBrowseLoadingTestURI]
							inSession:[SPSession sharedSession]
								 type:SP_ARTISTBROWSE_NO_TRACKS
							 callback:^(SPArtistBrowse *artistBrowse) {
								 
								 SPTestAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"browseArtistAtURL callback on wrong queue.");
								 
								 [SPAsyncLoading waitUntilLoaded:artistBrowse timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
									 SPTestAssert(notLoadedItems.count == 0, @"ArtistBrowse loading timed out for %@", artistBrowse);
									 SPTestAssert(artistBrowse.loadError == nil, @"ArtistBrowse encountered load error: %@", artistBrowse.loadError);
									 SPTestAssert(artistBrowse.albums.count != 0, @"ArtistBrowse has no albums");
									 SPTestAssert(artistBrowse.topTracks.count != 0, @"ArtistBrowse has no top tracks");
									 SPPassTest();
								 }];
							 }];
}

-(void)testAlbumBrowseMetadataLoading {

	SPAssertTestCompletesInTimeInterval(kSPAsyncLoadingDefaultTimeout + kDefaultNonAsyncLoadingTestTimeout);
	[SPAlbumBrowse browseAlbumAtURL:[NSURL URLWithString:kAlbumBrowseLoadingTestURI]
						  inSession:[SPSession sharedSession]
						   callback:^(SPAlbumBrowse *albumBrowse) {
							   
							   SPTestAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"browseAlbumAtURL callback on wrong queue.");
							   
							   [SPAsyncLoading waitUntilLoaded:albumBrowse timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
								   SPTestAssert(notLoadedItems.count == 0, @"AlbumBrowse loading timed out for %@", albumBrowse);
								   SPTestAssert(albumBrowse.loadError == nil, @"AlbumBrowse encountered load error: %@", albumBrowse.loadError);
								   SPTestAssert(albumBrowse.tracks.count != 0, @"AlbumBrowse has no tracks");
								   SPTestAssert(albumBrowse.artist != 0, @"AlbumBrowse has no artist");
								   SPPassTest();
							   }];
						   }];
}

-(void)testTrackMetadataLoading {

	SPAssertTestCompletesInTimeInterval(kSPAsyncLoadingDefaultTimeout + kDefaultNonAsyncLoadingTestTimeout);
	[SPTrack trackForTrackURL:[NSURL URLWithString:kTrackLoadingTestURI]
					inSession:[SPSession sharedSession]
					 callback:^(SPTrack *track) {
						 
						 [SPAsyncLoading waitUntilLoaded:track timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
							 SPTestAssert(notLoadedItems.count == 0, @"Track loading timed out for %@", track);
							 SPTestAssert(track.artists.count != 0, @"Track has no artists");
							 SPTestAssert(track.album != nil, @"Track has no album");
							 SPTestAssert(track.name.length != 0, @"Track has no name");
							 SPPassTest();
						 }];
					 }];
}

-(void)testImageLoading {

	SPAssertTestCompletesInTimeInterval((kSPAsyncLoadingDefaultTimeout * 2) + kDefaultNonAsyncLoadingTestTimeout);
	[SPAlbum albumWithAlbumURL:[NSURL URLWithString:kAlbumLoadingTestURI]
					 inSession:[SPSession sharedSession]
					  callback:^(SPAlbum *album) {
						  
						  SPTestAssert(album != nil, @"%@ returned nil album", kAlbumLoadingTestURI);
						  
						  [SPAsyncLoading waitUntilLoaded:album timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
							  SPTestAssert(notLoadedItems.count == 0, @"Album loading timed out for %@", album);
							
							  [SPAsyncLoading waitUntilLoaded:album.cover timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedCover, NSArray *notLoadedCover) {
								  SPTestAssert(notLoadedCover.count == 0, @"Cover loading timed out for %@", album.cover);
								  SPTestAssert(album.cover.image != nil, @"Cover is loaded but has no image");
								  SPPassTest();
							  }];
						  }];
					  }];
}

-(void)testUserTopListLoading {

	SPAssertTestCompletesInTimeInterval(kSPAsyncLoadingDefaultTimeout + kDefaultNonAsyncLoadingTestTimeout);
	SPToplist *userToplist = [SPToplist toplistForCurrentUserInSession:[SPSession sharedSession]];
	
	[SPAsyncLoading waitUntilLoaded:userToplist timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
		SPTestAssert(notLoadedItems.count == 0, @"TopList loading timed out for %@", userToplist);
		SPTestAssert(userToplist.loadError == nil, @"TopList encountered loading error: %@", userToplist.loadError);
		// User can disable publishing of parts of their toplist, so we can't depend on there being anything in it.
		SPPassTest();
	}];
	
}

-(void)testLocaleToplistLoading {

	SPAssertTestCompletesInTimeInterval(kSPAsyncLoadingDefaultTimeout);
	SPToplist *localeToplist = [SPToplist toplistForLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"SE"] inSession:[SPSession sharedSession]];
	
	[SPAsyncLoading waitUntilLoaded:localeToplist timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
		SPTestAssert(notLoadedItems.count == 0, @"TopList loading timed out for %@", localeToplist);
		SPTestAssert(localeToplist.loadError == nil, @"TopList encountered loading error: %@", localeToplist.loadError);
		SPTestAssert(localeToplist.artists.count > 0, @"TopList has no artists");
		SPTestAssert(localeToplist.albums.count > 0, @"TopList has no albums");
		SPTestAssert(localeToplist.tracks.count > 0, @"TopList has no tracks");
		SPPassTest();
	}];
}

@end
