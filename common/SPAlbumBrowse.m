//
//  SPAlbumBrowse.m
//  CocoaLibSpotify
//
//  Created by Daniel Kennett on 4/24/11.
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

#import "SPAlbumBrowse.h"
#import "SPSession.h"
#import "SPAlbum.h"
#import "SPArtist.h"
#import "SPErrorExtensions.h"
#import "SPTrack.h"

// IMPORTANT: This class was implemented while enjoying a lovely spring afternoon by a lake 
// in Sweden. This is my view right now:  http://twitpic.com/4oy9zn

@interface SPAlbum (SPAlbumBrowseExtensions)
-(void)albumBrowseDidLoad;
@end

@interface SPTrack (SPAlbumBrowseExtensions)
-(void)albumBrowseDidLoad;
@end

@interface SPAlbumBrowse ()

@property (nonatomic, readwrite, getter=isLoaded) BOOL loaded;
@property (nonatomic, readwrite, copy) NSError *loadError;
@property (nonatomic, readwrite, strong) SPSession *session;

@property (nonatomic, readwrite, strong) SPAlbum *album;
@property (nonatomic, readwrite, strong) SPArtist *artist;
@property (nonatomic, readwrite, strong) NSArray *tracks;

@property (nonatomic, readwrite, strong) NSArray *copyrights;
@property (nonatomic, readwrite, copy) NSString *review;

@property (nonatomic, readwrite) sp_albumbrowse *albumBrowse;

@end

void albumbrowse_complete (sp_albumbrowse *result, void *userdata);
void albumbrowse_complete (sp_albumbrowse *result, void *userdata) {
	
	@autoreleasepool {
		
		// This called on the libSpotify thread
		
		SPAlbumBrowse *albumBrowse = (__bridge_transfer SPAlbumBrowse *)userdata;
		
		BOOL isLoaded = sp_albumbrowse_is_loaded(result);
		
		sp_error errorCode = sp_albumbrowse_error(result);
		NSError *error = errorCode == SP_ERROR_OK ? nil : [NSError spotifyErrorWithCode:errorCode];
		NSString *newReview = nil;
		SPArtist *newArtist = nil;
		NSArray *newTracks = nil;
		NSArray *newCopyrights = nil;
		
		if (isLoaded) {
			
			newReview = [NSString stringWithUTF8String:sp_albumbrowse_review(result)];
			newArtist = [SPArtist artistWithArtistStruct:sp_albumbrowse_artist(result) inSession:albumBrowse.session];
			
			int trackCount = sp_albumbrowse_num_tracks(result);
			NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:trackCount];
			for (int currentTrack =  0; currentTrack < trackCount; currentTrack++) {
				sp_track *track = sp_albumbrowse_track(result, currentTrack);
				if (track != NULL) {
					SPTrack *aTrack = [SPTrack trackForTrackStruct:track inSession:albumBrowse.session];
					[aTrack albumBrowseDidLoad];
					[tracks addObject:aTrack];
				}
			}
			
			newTracks = [NSArray arrayWithArray:tracks];
			
			int copyrightCount = sp_albumbrowse_num_copyrights(result);
			NSMutableArray *copyrights = [NSMutableArray arrayWithCapacity:copyrightCount];
			for (int currentCopyright =  0; currentCopyright < copyrightCount; currentCopyright++) {
				const char *copyright = sp_albumbrowse_copyright(result, currentCopyright);
				[copyrights addObject:[NSString stringWithUTF8String:copyright]];
			}
			
			newCopyrights = [NSArray arrayWithArray:copyrights];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			albumBrowse.loadError = error;
			albumBrowse.review = newReview;
			albumBrowse.artist = newArtist;
			albumBrowse.tracks = newTracks;
			albumBrowse.copyrights = newCopyrights;
			[albumBrowse.album albumBrowseDidLoad];
			albumBrowse.loaded = isLoaded;
		});
	}
}

@implementation SPAlbumBrowse

+(SPAlbumBrowse *)browseAlbum:(SPAlbum *)anAlbum inSession:(SPSession *)aSession {
	return [[SPAlbumBrowse alloc] initWithAlbum:anAlbum inSession:aSession];
}

+(void)browseAlbumAtURL:(NSURL *)albumURL inSession:(SPSession *)aSession callback:(void (^)(SPAlbumBrowse *albumBrowse))block {
	
	[SPAlbum albumWithAlbumURL:albumURL 
					 inSession:aSession 
					  callback:^(SPAlbum *album) {
						  if (block) dispatch_async(dispatch_get_main_queue(), ^() { block([SPAlbumBrowse browseAlbum:album inSession:aSession]); });
					  }];
}

-(id)initWithAlbum:(SPAlbum *)anAlbum inSession:(SPSession *)aSession; {
	
	if (anAlbum == nil || aSession == nil) {
		return nil;
	}
	
	if ((self = [super init])) {
		self.session = aSession;
		self.album = anAlbum;
		
		SPDispatchAsync(^{
			self.albumBrowse = sp_albumbrowse_create(aSession.session,
													 anAlbum.album,
													 &albumbrowse_complete,
													 (__bridge_retained void *)(self));
		});
	}
	
	return self;
}

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: %@", [super description], self.album];
}

-(sp_albumbrowse *)albumBrowse {
#if DEBUG
	SPAssertOnLibSpotifyThread();
#endif 
	return _albumBrowse;
}

- (void)dealloc {
	sp_albumbrowse *outgoing_browse = _albumBrowse;
	_albumBrowse = NULL;
	if (outgoing_browse) SPDispatchAsync(^() { sp_albumbrowse_release(outgoing_browse); });
}

@end
