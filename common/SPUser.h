//
//  SPUser.h
//  CocoaLibSpotify
//
//  Created by Daniel Kennett on 2/21/11.
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

/** Represents a user of the Spotify service.
 
 SPUser  is roughly analogous to the sp_user struct in the C LibSpotify API.
 */

#import <Foundation/Foundation.h>
#import "CocoaLibSpotifyPlatformImports.h"

@class SPSession;

@interface SPUser : NSObject <SPAsyncLoading>

///----------------------------
/// @name Creating and Initializing Users
///----------------------------

/** Creates an SPUser from the given opaque sp_user struct. 
 
 This convenience method creates an SPUser object if one doesn't exist, or 
 returns a cached SPUser if one already exists for the given struct.
 
 @param spUser The sp_user struct to create an SPUser for.
 @param aSession The SPSession the user should exist in.
 @return Returns the created SPUser object. 
 */
+(SPUser *)userWithUserStruct:(sp_user *)spUser inSession:(SPSession *)aSession;

/** Creates an SPUser from the given Spotify user URL. 
 
 This convenience method creates an SPUser object if one doesn't exist, or 
 returns a cached SPUser if one already exists for the given URL.
 
 @warning If you pass in an invalid user URL (i.e., any URL not
 starting `spotify:user:`, this method will return `nil`.
 
 @param userUrl The user URL to create an SPUser for.
 @param aSession The SPSession the user should exist in.
 @param block The block to be called with the created SPUser object, or `nil` if given an invalid user URL. 
 */
+(void)userWithURL:(NSURL *)userUrl inSession:(SPSession *)aSession callback:(void (^)(SPUser *user))block;

/** Initializes a new SPUser from the given opaque sp_user struct. 
 
 @warning This method *must* be called on the libSpotify thread. See the
 "Threading" section of the library's readme for more information.
 
 @warning For better performance and built-in caching, it is recommended
 you create SPUser objects using +[SPUser userWithUserStruct:inSession:], 
 +[SPUser userWithURL:inSession:callback:] or the instance methods on SPSession.
 
 @param aUser The sp_user struct to create an SPUser for.
 @param aSession The SPSession the user should exist in.
 @return Returns the created SPUser object. 
 */
-(id)initWithUserStruct:(sp_user *)aUser inSession:(SPSession *)aSession;

///----------------------------
/// @name Properties
///----------------------------

/** Returns the user's canonical username. */
@property (nonatomic, readonly, copy) NSString *canonicalName;

/** Returns the user's display name. If this information isn't available yet, returns the same as canonicalName. */
@property (nonatomic, readonly, copy) NSString *displayName;

/** Returns `YES` if the user has finished loading and all data is available. */ 
@property (nonatomic, readonly, getter=isLoaded) BOOL loaded;

/** Returns the Spotify URI of the user's profile, for example: `spotify:user:ikenndac` */
@property (nonatomic, readonly, copy) NSURL *spotifyURL;

/** Returns the opaque structure used by the C LibSpotify API. 
 
 @warning This method *must* be called on the libSpotify thread. See the
 "Threading" section of the library's readme for more information.
 
 @warning This should only be used if you plan to directly use the 
 C LibSpotify API. The behaviour of CocoaLibSpotify is undefined if you use the C
 API directly on items that have CocoaLibSpotify objects associated with them. 
 */
@property (nonatomic, readonly) sp_user *user;

@end
