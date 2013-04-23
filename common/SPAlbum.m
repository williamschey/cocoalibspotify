//
//  SPAlbum.m
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

#import "SPAlbum.h"
#import "SPSession.h"
#import "SPImage.h"
#import "SPArtist.h"
#import "SPURLExtensions.h"
#import "SPSessionInternal.h"

@interface SPAlbum ()

@property (nonatomic, readwrite) sp_album *album;
@property (nonatomic, readwrite, strong) SPSession *session;
@property (nonatomic, readwrite, strong) SPImage *cover; 
@property (nonatomic, readwrite, strong) SPImage *smallCover; 
@property (nonatomic, readwrite, strong) SPImage *largeCover; 
@property (nonatomic, readwrite, strong) SPArtist *artist;
@property (nonatomic, readwrite, copy) NSURL *spotifyURL;
@property (nonatomic, readwrite, getter=isLoaded) BOOL loaded;
@property (nonatomic, readwrite, getter=isAvailable) BOOL available;
@property (nonatomic, readwrite, copy) NSString *name;
@property (nonatomic, readwrite) sp_albumtype type;
@property (nonatomic, readwrite) NSUInteger year;

-(BOOL)checkLoaded;
-(void)loadAlbumData;

@end

@implementation SPAlbum

static NSMutableDictionary *albumCache;

+(SPAlbum *)albumWithAlbumStruct:(sp_album *)anAlbum inSession:(SPSession *)aSession {
    
	SPAssertOnLibSpotifyThread();
	
    if (albumCache == nil) {
        albumCache = [[NSMutableDictionary alloc] init];
    }
    
    NSValue *ptrValue = [NSValue valueWithPointer:anAlbum];
    SPAlbum *cachedAlbum = [albumCache objectForKey:ptrValue];
    
    if (cachedAlbum != nil) {
        return cachedAlbum;
    }
    
    cachedAlbum = [[SPAlbum alloc] initWithAlbumStruct:anAlbum inSession:aSession];
    
    [albumCache setObject:cachedAlbum forKey:ptrValue];
    return cachedAlbum;
}

+(void)albumWithAlbumURL:(NSURL *)aURL inSession:(SPSession *)aSession callback:(void (^)(SPAlbum *album))block {
	
	if ([aURL spotifyLinkType] != SP_LINKTYPE_ALBUM) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^() { block(nil); });
		return;
	}
	
	SPDispatchAsync(^{
		SPAlbum *newAlbum = nil;
		sp_link *link = [aURL createSpotifyLink];
		if (link != NULL) {
			sp_album *album = sp_link_as_album(link);
			sp_album_add_ref(album);
			newAlbum = [self albumWithAlbumStruct:album inSession:aSession];
			sp_link_release(link);
			sp_album_release(album);
		}
		if (block) dispatch_async(dispatch_get_main_queue(), ^() { block(newAlbum); });
	});
}

-(id)initWithAlbumStruct:(sp_album *)anAlbum inSession:(SPSession *)aSession {
	
	SPAssertOnLibSpotifyThread();
	
    if ((self = [super init])) {
        self.album = anAlbum;
        sp_album_add_ref(self.album);
        self.session = aSession;
        sp_link *link = sp_link_create_from_album(anAlbum);
        if (link != NULL) {
            self.spotifyURL = [NSURL urlWithSpotifyLink:link];
            sp_link_release(link);
        }

        if (!sp_album_is_loaded(self.album)) {
            [aSession addLoadingObject:self];
        } else {
            [self loadAlbumData];
        }
    }
    return self;
}

-(BOOL)checkLoaded {
	
	SPAssertOnLibSpotifyThread();
	
	BOOL isLoaded = sp_album_is_loaded(self.album);
	
    if (isLoaded)
        [self loadAlbumData];
		
	return isLoaded;
}

-(void)loadAlbumData {
	
	SPAssertOnLibSpotifyThread();
	
	SPImage *newCover = nil;
	SPImage *newLargeCover = nil;
	SPImage *newSmallCover = nil;
	SPArtist *newArtist = nil;
	NSString *newName = nil;
	NSUInteger newYear = sp_album_year(self.album);
	sp_albumtype newAlbumType = sp_album_type(self.album);
	BOOL newAvailable = sp_album_is_available(self.album);
	BOOL newLoaded = sp_album_is_loaded(self.album);
	
	const byte *imageId = sp_album_cover(self.album, SP_IMAGE_SIZE_NORMAL);
	
	if (imageId != NULL)
		newCover = [SPImage imageWithImageId:imageId inSession:self.session];

	const byte *smallImageId = sp_album_cover(self.album, SP_IMAGE_SIZE_SMALL);
	
	if (smallImageId != NULL)
		newSmallCover = [SPImage imageWithImageId:smallImageId inSession:self.session];

	const byte *largeImageId = sp_album_cover(self.album, SP_IMAGE_SIZE_LARGE);
	
	if (largeImageId != NULL)
		newLargeCover = [SPImage imageWithImageId:largeImageId inSession:self.session];
	
	sp_artist *spArtist = sp_album_artist(self.album);
	if (spArtist != NULL)
		newArtist = [SPArtist artistWithArtistStruct:spArtist inSession:self.session];
	
	const char *nameCharArray = sp_album_name(self.album);
	if (nameCharArray != NULL) {
		NSString *nameString = [NSString stringWithUTF8String:nameCharArray];
		newName = [nameString length] > 0 ? nameString : nil;
	} else {
		newName = nil;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		self.cover = newCover;
		self.smallCover = newSmallCover;
		self.largeCover = newLargeCover;
		self.artist = newArtist;
		self.name = newName;
		self.year = newYear;
		self.type = newAlbumType;
		self.available = newAvailable;
		self.loaded = newLoaded;
	});
}

-(void)albumBrowseDidLoad {
	SPDispatchAsync(^{
		if (self.album) {
			int aYear = sp_album_year(self.album);
			dispatch_async(dispatch_get_main_queue(), ^{
				self.year = aYear;
			});
		}
	});
}

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: %@ by %@", [super description], self.name, self.artist.name];
}

-(sp_album *)album {
#if DEBUG
	SPAssertOnLibSpotifyThread();
#endif 
	return _album;
}

+(NSSet *)keyPathsForValuesAffectingSmallestAvailableCover {
	return [NSSet setWithObjects:@"smallCover", @"cover", @"largeCover", nil];
}

-(SPImage *)smallestAvailableCover {
	if (self.smallCover) return self.smallCover;
	if (self.cover) return self.cover;
	if (self.largeCover) return self.largeCover;
	return nil;
}

+(NSSet *)keyPathsForValuesAffectingLargestAvailableCover {
	return [NSSet setWithObjects:@"smallCover", @"cover", @"largeCover", nil];
}

-(SPImage *)largestAvailableCover {
	if (self.largeCover) return self.largeCover;
	if (self.cover) return self.cover;
	if (self.smallCover) return self.smallCover;
	return nil;
}

-(void)dealloc {
	sp_album *outgoing_album = _album;
	_album = NULL;
	if (outgoing_album) SPDispatchAsync(^() { sp_album_release(outgoing_album); });
}

@end
