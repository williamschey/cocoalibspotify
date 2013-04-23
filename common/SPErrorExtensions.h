//
//  SPErrorExtensions.h
//  CocoaLibSpotify
//
//  Created by Daniel Kennett on 2/14/11.
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

/** Contains convenience methods for working with Spotify error codes (`sp_error`). */

#import <Foundation/Foundation.h>
#import "CocoaLibSpotifyPlatformImports.h"

static NSString * const kCocoaLibSpotifyErrorDomain = @"com.spotify.CocoaLibSpotify.error";

@interface NSError (SPErrorExtensions)

+ (NSError *)spotifyErrorWithDescription:(NSString *)msg code:(NSInteger)code;
+ (NSError *)spotifyErrorWithCode:(sp_error)code;
+ (NSError *)spotifyErrorWithDescription:(NSString *)msg;
+ (NSError *)spotifyErrorWithCode:(NSInteger)code format:(NSString *)format, ...;
+ (NSError *)spotifyErrorWithFormat:(NSString *)format, ...;

@end
