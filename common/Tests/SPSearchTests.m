//
//  SPSearchTests.m
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

#import "SPSearchTests.h"
#import "SPAsyncLoading.h"
#import "SPSession.h"
#import "SPSearch.h"
#import "TestConstants.h"

@implementation SPSearchTests

-(void)testStandardSearch {

	SPAssertTestCompletesInTimeInterval(kSPAsyncLoadingDefaultTimeout);
	SPSearch *search = [SPSearch searchWithSearchQuery:kStandardSearchQuery inSession:[SPSession sharedSession]];
	
	[SPAsyncLoading waitUntilLoaded:search timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
		SPTestAssert(notLoadedItems.count == 0, @"Search loading timed out for %@", search);
		SPTestAssert(search.searchError == nil, @"Search encountered loading error: %@", search.searchError);
		SPTestAssert(search.tracks.count > 0, @"Search has no tracks.");
		SPTestAssert(search.artists.count > 0, @"Search has no artists.");
		SPTestAssert(search.albums.count > 0, @"Search has no albums.");
		SPTestAssert(search.playlists.count > 0, @"Search has no playlists.");
		SPPassTest();
	}];
}

-(void)testLiveSearch {

	SPAssertTestCompletesInTimeInterval(kSPAsyncLoadingDefaultTimeout);
	SPSearch *search = [SPSearch liveSearchWithSearchQuery:kLiveSearchQuery inSession:[SPSession sharedSession]];
	
	[SPAsyncLoading waitUntilLoaded:search timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
		SPTestAssert(notLoadedItems.count == 0, @"Live search loading timed out for %@", search);
		SPTestAssert(search.searchError == nil, @"Live search encountered loading error: %@", search.searchError);
		SPTestAssert(search.tracks.count > 0, @"Live search has no tracks.");
		SPTestAssert(search.artists.count > 0, @"Live search has no artists.");
		SPTestAssert(search.albums.count > 0, @"Live search has no albums.");
		SPTestAssert(search.playlists.count > 0, @"Live search has no playlists.");
		SPPassTest();
	}];
}

@end
