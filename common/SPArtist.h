//
//  SPArtist.h
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

/** Represents an artist on Spotify.
 
 SPArtist  is roughly analogous to the sp_artist struct in the C LibSpotify API.
 */

#import <Foundation/Foundation.h>
#import "CocoaLibSpotifyPlatformImports.h"

@class SPSession;

@interface SPArtist : NSObject <SPPlaylistableItem, SPAsyncLoading>

///----------------------------
/// @name Creating and Initializing Artists
///----------------------------

/** Creates an SPArtist from the given opaque sp_artist struct. 
 
 This convenience method creates an SPArtist object if one doesn't exist, or 
 returns a cached SPArtist if one already exists for the given struct.
 
 @warning This method *must* be called on the libSpotify thread. See the
 "Threading" section of the library's readme for more information.
 
 @param anArtist The sp_artist struct to create an SPArtist for.
 @param aSession The session to create the artist in.
 @return Returns the created SPArtist object. 
 */
+(SPArtist *)artistWithArtistStruct:(sp_artist *)anArtist inSession:(SPSession *)aSession;

/** Creates an SPArtist from the given Spotify artist URL. 
 
 This convenience method creates an SPArtist object if one doesn't exist, or 
 returns a cached SPArtist if one already exists for the given URL.
 
 @warning If you pass in an invalid artist URL (i.e., any URL not
 starting `spotify:artist:`, this method will return `nil`.
 
 @param aURL The artist URL to create an SPArtist for.
 @param aSession The session to create the artist in.
 @param block The block to be called with the created SPArtist object, or `nil` if given an invalid artist URL. 
 */
+(void)artistWithArtistURL:(NSURL *)aURL inSession:(SPSession *)aSession callback:(void (^)(SPArtist *artist))block;

/** Initializes a new SPArtist from the given opaque sp_artist struct. 
 
 @warning This method *must* be called on the libSpotify thread. See the
 "Threading" section of the library's readme for more information.
 
 @warning For better performance and built-in caching, it is recommended
 you create SPArtist objects using +[SPArtist artistWithArtistStruct:inSession:], 
 +[SPArtist artistWithArtistURL:inSession:callback:] or the instance methods on SPSession.
 
 @param anArtist The sp_artist struct to create an SPArtist for.
 @param aSession The session to create the artist in.
 @return Returns the created SPArtist object. 
 */
-(id)initWithArtistStruct:(sp_artist *)anArtist inSession:(SPSession *)aSession;

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
@property (nonatomic, readonly) sp_artist *artist;

///----------------------------
/// @name Metadata
///----------------------------

/** Returns the artist's name. */
@property (nonatomic, readonly, copy) NSString *name;

/** Returns the Spotify URI of the track, for example: `spotify:artist:12EtLdLfJ41vUOoVzPZIUy` */
@property (nonatomic, readonly, copy) NSURL *spotifyURL;

/** Returns `YES` if the artist metadata has finished loading. */ 
@property (nonatomic, readonly, getter=isLoaded) BOOL loaded;

@end
