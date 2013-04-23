//
//  SPArtist.m
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

#import "SPArtist.h"
#import "SPURLExtensions.h"
#import "SPSession.h"
#import "SPSessionInternal.h"

@interface SPArtist ()

-(BOOL)checkLoaded;
-(void)loadArtistData;
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSURL *spotifyURL;
@property (nonatomic, readwrite) sp_artist *artist;
@property (nonatomic, readwrite, getter=isLoaded) BOOL loaded;

@end

@implementation SPArtist

static NSMutableDictionary *artistCache;

+(SPArtist *)artistWithArtistStruct:(sp_artist *)anArtist inSession:(SPSession *)aSession {
    
	SPAssertOnLibSpotifyThread();
	
    if (artistCache == nil) {
        artistCache = [[NSMutableDictionary alloc] init];
    }
    
    NSValue *ptrValue = [NSValue valueWithPointer:anArtist];
    SPArtist *cachedArtist = [artistCache objectForKey:ptrValue];
    
    if (cachedArtist != nil) {
        return cachedArtist;
    }
    
    cachedArtist = [[SPArtist alloc] initWithArtistStruct:anArtist inSession:aSession];
    
    [artistCache setObject:cachedArtist forKey:ptrValue];
    return cachedArtist;
}

+(void)artistWithArtistURL:(NSURL *)aURL inSession:(SPSession *)aSession callback:(void (^)(SPArtist *artist))block {
	
	if ([aURL spotifyLinkType] != SP_LINKTYPE_ARTIST) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^() { block(nil); });
		return;
	}
	
	SPDispatchAsync(^{
		SPArtist *newArtist = nil;
		sp_link *link = [aURL createSpotifyLink];
		if (link != NULL) {
			sp_artist *artist = sp_link_as_artist(link);
			sp_artist_add_ref(artist);
			newArtist = [self artistWithArtistStruct:artist inSession:aSession];
			sp_artist_release(artist);
			sp_link_release(link);
		}
		if (block) dispatch_async(dispatch_get_main_queue(), ^() { block(newArtist); });
	});
}

#pragma mark -

-(id)initWithArtistStruct:(sp_artist *)anArtist inSession:(SPSession *)aSession {
	
	SPAssertOnLibSpotifyThread();
	
    if ((self = [super init])) {
        self.artist = anArtist;
        sp_artist_add_ref(self.artist);
        sp_link *link = sp_link_create_from_artist(anArtist);
        if (link != NULL) {
            self.spotifyURL = [NSURL urlWithSpotifyLink:link];
            sp_link_release(link);
        }
		
		if (!sp_artist_is_loaded(self.artist)) {
            [aSession addLoadingObject:self];
        } else {
            [self loadArtistData];
        }

    }
    return self;
}



-(BOOL)checkLoaded {
	
	SPAssertOnLibSpotifyThread();
	
	BOOL isLoaded = sp_artist_is_loaded(self.artist);
	if (isLoaded) [self loadArtistData];
	
	return isLoaded;
}

-(void)loadArtistData {
	
	SPAssertOnLibSpotifyThread();
	
	NSString *newName = nil;
	
	const char *nameCharArray = sp_artist_name(self.artist);
	if (nameCharArray != NULL) {
		NSString *nameString = [NSString stringWithUTF8String:nameCharArray];
		newName = [nameString length] > 0 ? nameString : nil;
	} else {
		newName = nil;
	}
	
	BOOL isLoaded = sp_artist_is_loaded(self.artist);
	
	dispatch_async(dispatch_get_main_queue(), ^() {
		self.name = newName;
		self.loaded = isLoaded;
	});
}

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: %@", [super description], self.name];
}

-(sp_artist *)artist {
#if DEBUG
	SPAssertOnLibSpotifyThread();
#endif
	return _artist;
}

-(void)dealloc {
	sp_artist *outgoing_artist = _artist;
	_artist = NULL;
	if (outgoing_artist) SPDispatchAsync(^() { sp_artist_release(outgoing_artist); });
}

@end
