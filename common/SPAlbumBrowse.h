//
//  SPAlbumBrowse.h
//  CocoaLibSpotify
//
//  Created by Daniel Kennett on 4/24/11.
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

/** Represents an "album browse" of an album on the Spotify service. 
 
 An "album browse" fetches detailed information about an album from the Spotify 
 service, including a review, copyright information and a list of the album's tracks.
 
 Artist or album browses are required for certain SPTrack metadata to be available - 
 see the SPTrack documentation for details. 
 */

#import <Foundation/Foundation.h>
#import "CocoaLibSpotifyPlatformImports.h"

@class SPAlbum;
@class SPSession;
@class SPArtist;

@interface SPAlbumBrowse : NSObject <SPAsyncLoading>

///----------------------------
/// @name Creating and Initializing Album Browses
///----------------------------

/** Creates an SPAlbumBrowse from the given SPAlbum.
 
 This convenience method is simply returns a new, autoreleased SPAlbumBrowse
 object. No caching is performed.
 
 @param anAlbum The SPAlbum to make an SPAlbumBrowse for.
 @param aSession The SPSession the browse should exist in.
 @return Returns the created SPAlbumBrowse object. 
 */
+(SPAlbumBrowse *)browseAlbum:(SPAlbum *)anAlbum inSession:(SPSession *)aSession;

/** Creates an SPAlbumBrowse from the given album URL. 
 
 This convenience method is simply returns a new, autoreleased SPAlbumBrowse
 object. No caching is performed.
 
 @warning If you pass in an invalid album URL (i.e., any URL not
 starting `spotify:album:`, this method will return `nil`.
 
 @param albumURL The album URL to make an SPAlbumBrowse for.
 @param aSession The SPSession the browse should exist in.
 @param block The block to be called with the created SPAlbumBrowse object. 
 */
+(void)browseAlbumAtURL:(NSURL *)albumURL inSession:(SPSession *)aSession callback:(void (^)(SPAlbumBrowse *albumBrowse))block;

/** Initializes a new SPAlbumBrowse from the given SPAlbum. 
 
 @param anAlbum The SPAlbum to make an SPAlbumBrowse for.
 @param aSession The SPSession the browse should exist in.
 @return Returns the created SPAlbumBrowse object. 
 */
-(id)initWithAlbum:(SPAlbum *)anAlbum inSession:(SPSession *)aSession;

///----------------------------
/// @name Properties
///----------------------------

/** Returns `YES` if the album metadata has finished loading. */ 
@property (nonatomic, readonly, getter=isLoaded) BOOL loaded;

/** Returns the error that occurred during loading, or `nil` if no error occurred. */
@property (nonatomic, readonly, copy) NSError *loadError;

/** Returns the session the album's metadata is loaded in. */
@property (nonatomic, readonly, strong) SPSession *session;

///----------------------------
/// @name Metadata
///----------------------------

/** Returns the browse operation's album. */
@property (nonatomic, readonly, strong) SPAlbum *album;

/** Returns the album's artist, or `nil` if the metadata isn't loaded yet. */
@property (nonatomic, readonly, strong) SPArtist *artist;

/** Returns the album's copyrights as an array of NSString, or `nil` if the metadata isn't loaded yet. */
@property (nonatomic, readonly, strong) NSArray *copyrights;

/** Returns the album's review, or `nil` if the metadata isn't loaded yet. */
@property (nonatomic, readonly, copy) NSString *review;

/** Returns the album's tracks, or `nil` if the metadata isn't loaded yet. */
@property (nonatomic, readonly, strong) NSArray *tracks;

@end
