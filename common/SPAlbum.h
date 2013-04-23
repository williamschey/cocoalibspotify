//
//  SPAlbum.h
//  CocoaLibSpotify
//
//  Created by Daniel Kennett on 2/20/11.
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

/** Represents an album on Spotify.
 
 SPAlbum  is roughly analogous to the sp_album struct in the C LibSpotify API.
 */

#import <Foundation/Foundation.h>
#import "CocoaLibSpotifyPlatformImports.h"

@class SPSession;
@class SPImage;
@class SPArtist;

@interface SPAlbum : NSObject <SPPlaylistableItem, SPAsyncLoading>

///----------------------------
/// @name Creating and Initializing Albums
///----------------------------

/** Creates an SPAlbum from the given opaque sp_album struct. 
 
 This convenience method creates an SPAlbum object if one doesn't exist, or 
 returns a cached SPAlbum if one already exists for the given struct.
 
@warning This method *must* be called on the libSpotify thread. See the
 "Threading" section of the library's readme for more information.
 
 @param anAlbum The sp_album struct to create an SPAlbum for.
 @param aSession The SPSession the album should exist in.
 @return Returns the created SPAlbum object. 
 */
+(SPAlbum *)albumWithAlbumStruct:(sp_album *)anAlbum inSession:(SPSession *)aSession;

/** Creates an SPAlbum from the given Spotify album URL. 
 
 This convenience method creates an SPAlbum object if one doesn't exist, or 
 returns a cached SPAlbum if one already exists for the given URL.
 
 @warning If you pass in an invalid album URL (i.e., any URL not
 starting `spotify:album:`, this method will return `nil`.
 
 @param aURL The album URL to create an SPAlbum for.
 @param aSession The SPSession the album should exist in.
 @param block Block to be called with the created SPAlbum object, or `nil` if given an invalid album URL. 
 */
+(void)albumWithAlbumURL:(NSURL *)aURL inSession:(SPSession *)aSession callback:(void (^)(SPAlbum *album))block;

/** Initializes a new SPAlbum from the given opaque sp_album struct. 
 
 @warning This method *must* be called on the libSpotify thread. See the
 "Threading" section of the library's readme for more information.
 
 @warning For better performance and built-in caching, it is recommended
 you create SPAlbum objects using +[SPAlbum albumWithAlbumStruct:inSession:], 
 +[SPAlbum albumWithAlbumURL:inSession:callback:] or the instance methods on SPSession.
 
 @param anAlbum The sp_album struct to create an SPAlbum for.
 @param aSession The SPSession the album should exist in.
 @return Returns the created SPAlbum object. 
 */
-(id)initWithAlbumStruct:(sp_album *)anAlbum inSession:(SPSession *)aSession;

///----------------------------
/// @name Properties
///----------------------------

/** Returns the opaque structure used by the C LibSpotify API. 
 
 @warning This method *must* be called on the libSpotify thread. See the
 "Threading" section of the library's readme for more information.
 
 @warning This should only be used if you plan to directly use the 
 C LibSpotify API. The behaviour of CocoaLibSpotify is undefined if you use the C
 API directly on items that have CocoaLibSpotify objects associated with them. 
 */
@property (nonatomic, readonly) sp_album *album;

/** Returns `YES` if the album metadata has finished loading. */ 
@property (nonatomic, readonly, getter=isLoaded) BOOL loaded;

/** Returns the session the album's metadata is loaded in. */
@property (nonatomic, readonly, strong) SPSession *session;

///----------------------------
/// @name Metadata
///----------------------------

/** Returns the album's artist, or `nil` if the metadata isn't loaded yet. */
@property (nonatomic, readonly, strong) SPArtist *artist; 

/** Returns the album's cover image. Returns `nil` if the metadata isn't loaded yet, or if the album doesn't have a cover image. */
@property (nonatomic, readonly, strong) SPImage *cover;

/** Returns a thumbnail version of the album's cover image. Returns `nil` if the metadata isn't loaded yet, or if the album doesn't have a cover image. */
@property (nonatomic, readonly, strong) SPImage *smallCover;

/** Returns a large version of the album's cover image. Returns `nil` if the metadata isn't loaded yet, or if the album doesn't have a cover image. */
@property (nonatomic, readonly, strong) SPImage *largeCover;

/** Returns a largest available version of the album's cover image. Returns `nil` if the metadata isn't loaded yet, or if the album doesn't have a cover image. */
@property (nonatomic, readonly, strong) SPImage *largestAvailableCover;

/** Returns a smallest available version of the album's cover image. Returns `nil` if the metadata isn't loaded yet, or if the album doesn't have a cover image. */
@property (nonatomic, readonly, strong) SPImage *smallestAvailableCover;

/** Returns `YES` if the album is available in the logged-in user's region. */
@property (nonatomic, readonly, getter=isAvailable) BOOL available;

/** Returns the name of the album. */
@property (nonatomic, readonly, copy) NSString *name;

/** Returns the Spotify URI of the track, for example: `spotify:album:43p5dnBeVx4H2bzy0W1cGL` */
@property (nonatomic, readonly, copy) NSURL *spotifyURL;

/** Returns the album type.
 
 Possible values:
 
 SP_ALBUMTYPE_ALBUM 	
 Normal album.
 
 SP_ALBUMTYPE_SINGLE 	
 Single.
 
 SP_ALBUMTYPE_COMPILATION 	
 Compilation.
 
 SP_ALBUMTYPE_UNKNOWN 	
 Unknown type. 
 */
@property (nonatomic, readonly) sp_albumtype type;

/** Returns the release year of the album. */
@property (nonatomic, readonly) NSUInteger year;

@end
