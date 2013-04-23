//
//  SPURLExtensions.h
//  CocoaLibSpotify
//
//  Created by Daniel Kennett on 3/26/11.
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

/** Adds convenience methods to NSURL for working with Spotify URLs. */

#import <Foundation/Foundation.h>
#import "CocoaLibSpotifyPlatformImports.h"

@interface NSURL (SPURLExtensions)

/** Convert an sp_link from the C LibSpotify API into an NSURL object. 
 
 @param link The sp_link to convert.
 @return Returns the created NSURL, or `nil` if the link is invalid.
 */
+(NSURL *)urlWithSpotifyLink:(sp_link *)link;

/** Create an sp_link for the C LibSpotify API from an NSURL object.
 
 @return The created sp_link, or NULL if the URL is not a valid Spotify URL.
 If not NULL, this _must_ be freed with `sp_link_release()` when you're done.
 */
-(sp_link *)createSpotifyLink;

/** Returns the sp_linktype for the C LibSpotify API.
 
 Possible values:
 
 - SP_LINKTYPE_INVALID
 - SP_LINKTYPE_TRACK
 - SP_LINKTYPE_ALBUM
 - SP_LINKTYPE_ARTIST
 - SP_LINKTYPE_SEARCH
 - SP_LINKTYPE_PLAYLIST 
 - SP_LINKTYPE_PROFILE 
 - SP_LINKTYPE_STARRED 
 - SP_LINKTYPE_LOCALTRACK
 */
-(sp_linktype)spotifyLinkType;

+(NSString *)urlDecodedStringForString:(NSString *)encodedString;
+(NSString *)urlEncodedStringForString:(NSString *)plainOldString;

@end
