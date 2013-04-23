//
//  SPUser.m
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

#import "SPUser.h"
#import "SPSession.h"
#import "SPURLExtensions.h"
#import "SPSessionInternal.h"

@interface SPUser ()

-(BOOL)checkLoaded;
-(void)loadUserData;

@property (nonatomic, readwrite, copy) NSURL *spotifyURL;
@property (nonatomic, readwrite, copy) NSString *canonicalName;
@property (nonatomic, readwrite, copy) NSString *displayName;
@property (nonatomic, readwrite, getter=isLoaded) BOOL loaded;
@property (nonatomic, readwrite) sp_user *user;
@property (nonatomic, readwrite, assign) __unsafe_unretained SPSession *session;

@end

@implementation SPUser

+(SPUser *)userWithUserStruct:(sp_user *)spUser inSession:(SPSession *)aSession {
    return [aSession userForUserStruct:spUser];
}

+(void)userWithURL:(NSURL *)userUrl inSession:(SPSession *)aSession callback:(void (^)(SPUser *user))block {
	[aSession userForURL:userUrl callback:block];
}

-(id)initWithUserStruct:(sp_user *)aUser inSession:(SPSession *)aSession {
	
	if (aUser == NULL) {
		return nil;
	}
		
	SPAssertOnLibSpotifyThread();
	
    if ((self = [super init])) {
        self.user = aUser;
        self.session = aSession;

		sp_user_add_ref(self.user);

        if (!sp_user_is_loaded(self.user)) {
            [aSession addLoadingObject:self];
        } else {
            [self loadUserData];
        }
    }
    return self;
}

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: %@", [super description], self.canonicalName];
}

-(BOOL)checkLoaded {
	
	SPAssertOnLibSpotifyThread();
	
	BOOL userLoaded = sp_user_is_loaded(self.user);

    if (userLoaded)
        [self loadUserData];
	
	return userLoaded;
}

-(void)loadUserData {

    SPAssertOnLibSpotifyThread();
	
	BOOL userLoaded = sp_user_is_loaded(self.user);
	NSURL *url = nil;
	NSString *canonicalString = nil;
	NSString *displayString = nil;
	
	if (userLoaded) {
		
		sp_link *link = sp_link_create_from_user(self.user);
		if (link != NULL) {
			url = [NSURL urlWithSpotifyLink:link];
			sp_link_release(link);
		}
		
		const char *canonical = sp_user_canonical_name(self.user);
		if (canonical != NULL) {
			canonicalString = [NSString stringWithUTF8String:canonical];
		}
		
		const char *display = sp_user_display_name(self.user);
		if (display != NULL) {
			displayString = [NSString stringWithUTF8String:display];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			self.canonicalName = [canonicalString length] > 0 ? canonicalString : nil;
			self.displayName = [displayString length] > 0 ? displayString : nil;
			self.spotifyURL = url;
			self.loaded = userLoaded;
		});
	}
}

-(sp_user *)user {
#if DEBUG
	SPAssertOnLibSpotifyThread();
#endif
	return _user;
}

-(void)dealloc {
	sp_user *outgoing_user = _user;
	_user = NULL;
	if (outgoing_user) SPDispatchAsync(^() { sp_user_release(outgoing_user); });
}

@end
