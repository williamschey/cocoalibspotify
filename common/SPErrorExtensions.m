//
//  SPErrorExtensions.m
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

#import "SPErrorExtensions.h"

@implementation NSError (SCAdditions)

+ (NSError *)spotifyErrorWithDescription:(NSString *)msg code:(NSInteger)code {
	return [NSError errorWithDomain:kCocoaLibSpotifyErrorDomain code:code userInfo:[NSDictionary dictionaryWithObject:msg forKey:NSLocalizedDescriptionKey]];
}
+ (NSError *)spotifyErrorWithCode:(sp_error)code {
	return [NSError spotifyErrorWithDescription:[NSString stringWithUTF8String:sp_error_message(code)] code:code];
}
+ (NSError *)spotifyErrorWithDescription:(NSString *)msg {
	return [NSError spotifyErrorWithDescription:msg code:0];
}
+ (NSError *)spotifyErrorWithCode:(NSInteger)code format:(NSString *)format, ... {
	va_list src, dest;
	va_start(src, format);
	va_copy(dest, src);
	va_end(src);
	NSString *msg = [[NSString alloc] initWithFormat:format arguments:dest];
	return [NSError spotifyErrorWithDescription:msg code:code];
}
+ (NSError *)spotifyErrorWithFormat:(NSString *)format, ... {
	va_list src, dest;
	va_start(src, format);
	va_copy(dest, src);
	va_end(src);
	NSString *msg = [[NSString alloc] initWithFormat:format arguments:dest];
	return [NSError spotifyErrorWithDescription:msg code:0];
}

@end