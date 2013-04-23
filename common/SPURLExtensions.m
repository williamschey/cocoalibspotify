//
//  SPURLExtensions.m
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

#import "SPURLExtensions.h"


@implementation NSURL (SPURLExtensions)

+(NSURL *)urlWithSpotifyLink:(sp_link *)link {
	
	if (link == NULL) 
		return nil;
	
	char buffer[1024];
	NSUInteger linkLength = sp_link_as_string(link, buffer, sizeof(buffer));
	
	if (linkLength == 0) 
		return nil;
	
	return [NSURL URLWithString:[NSString stringWithUTF8String:buffer]];
}

+(NSString *)urlDecodedStringForString:(NSString *)encodedString {
	NSString *decoded = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
																							(__bridge CFStringRef)[encodedString stringByReplacingOccurrencesOfString:@"+" withString:@" "], 
																							CFSTR(""), 
																							kCFStringEncodingUTF8);
	return decoded;
}

+(NSString *)urlEncodedStringForString:(NSString *)plainOldString {
	NSString *encoded = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
																			(__bridge CFStringRef)plainOldString,
																			NULL,
																			(CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
																			kCFStringEncodingUTF8);
	return encoded;
}

-(sp_link *)createSpotifyLink {
	sp_link *link = sp_link_create_from_string([[self absoluteString] UTF8String]);
	return link;
}
	
-(sp_linktype)spotifyLinkType {
	
	sp_link *link = [self createSpotifyLink];
	if (link != NULL) {
		sp_linktype linkType = sp_link_type(link);
		sp_link_release(link);
		return linkType;
	}
	return SP_LINKTYPE_INVALID;
}


@end
