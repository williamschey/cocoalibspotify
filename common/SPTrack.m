//
//  SPTrack.m
//  CocoaLibSpotify
//
//  Created by Daniel Kennett on 2/19/11.
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

#import "SPTrack.h"
#import "SPTrackInternal.h"
#import "SPAlbum.h"
#import "SPArtist.h"
#import "SPSession.h"
#import "SPURLExtensions.h"
#import "SPSessionInternal.h"

@interface SPTrack ()

-(BOOL)checkLoaded;
-(void)loadTrackData;

@property (nonatomic, readwrite, strong) SPAlbum *album;
@property (nonatomic, readwrite, strong) NSArray *artists;
@property (nonatomic, readwrite, copy) NSURL *spotifyURL;

@property (nonatomic, readwrite) sp_track_availability availability;
@property (nonatomic, readwrite, getter=isLoaded) BOOL loaded;
@property (nonatomic, readwrite) sp_track_offline_status offlineStatus;
@property (nonatomic, readwrite) NSUInteger discNumber;
@property (nonatomic, readwrite) NSTimeInterval duration;
@property (nonatomic, readwrite, copy) NSString *name;
@property (nonatomic, readwrite) NSUInteger popularity;
@property (nonatomic, readwrite) NSUInteger trackNumber;
@property (nonatomic, readwrite, getter = isLocal) BOOL local;
@property (nonatomic, readwrite) sp_track *track;

@property (nonatomic, readwrite, assign) __unsafe_unretained SPSession *session;
	
@end

@implementation SPTrack (SPTrackInternal)

-(void)setStarredFromLibSpotifyUpdate:(BOOL)starred {
	[self willChangeValueForKey:@"starred"];
	_starred = starred;
	[self didChangeValueForKey:@"starred"];
}

-(void)setOfflineStatusFromLibSpotifyUpdate:(sp_track_offline_status)status {
	self.offlineStatus = status;
}

-(void)updateAlbumBrowseSpecificMembers {
	
	SPAssertOnLibSpotifyThread();
	
	self.discNumber = sp_track_disc(self.track);
	self.trackNumber = sp_track_index(self.track);
}

@end

@implementation SPTrack

+(SPTrack *)trackForTrackStruct:(sp_track *)spTrack inSession:(SPSession *)aSession{
	SPAssertOnLibSpotifyThread();
    return [aSession trackForTrackStruct:spTrack];
}

+(void)trackForTrackURL:(NSURL *)trackURL inSession:(SPSession *)aSession callback:(void (^)(SPTrack *track))block {
	[aSession trackForURL:trackURL callback:block];
}

-(id)initWithTrackStruct:(sp_track *)tr inSession:(SPSession *)aSession {
	
	SPAssertOnLibSpotifyThread();

    if ((self = [super init])) {
        self.session = aSession;
        self.track = tr;
        sp_track_add_ref(self.track);
        
        if (!sp_track_is_loaded(self.track)) {
            [aSession addLoadingObject:self];
        } else {
            [self loadTrackData];
        }

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(sessionUpdatedMetadata:)
													 name:SPSessionDidUpdateMetadataNotification
												   object:self.session];
    }
    return self;
}

-(NSUInteger)hash {
	return (NSUInteger)_track;
}

-(BOOL)isEqual:(id)object {
	if (![object isKindOfClass:[self class]])
		return NO;

	return [self hash] == [object hash];
}

-(NSString *)description {
    return [NSString stringWithFormat:@"%@: %@", [super description], [self name]];
}
         
-(BOOL)checkLoaded {
	
	SPAssertOnLibSpotifyThread();
	
	BOOL isLoaded = sp_track_is_loaded(self.track);
	
    if (isLoaded)
        [self loadTrackData];

	return isLoaded;
}

-(void)loadTrackData {
	
	SPAssertOnLibSpotifyThread();
	
	NSURL *trackURL = nil;
	SPAlbum *newAlbum = nil;
	NSString *newName = nil;
	BOOL newLocal = sp_track_is_local(self.session.session, self.track);
	NSUInteger newTrackNumber = sp_track_index(self.track);
	NSUInteger newDiscNumber = sp_track_disc(self.track);
	NSUInteger newPopularity = sp_track_popularity(self.track);
	NSTimeInterval newDuration = (NSTimeInterval)sp_track_duration(self.track) / 1000.0;
	sp_track_availability newAvailability = sp_track_get_availability(self.session.session, self.track);
	sp_track_offline_status newOfflineStatus = sp_track_offline_get_status(self.track);
	BOOL newLoaded = sp_track_is_loaded(self.track);
	BOOL newStarred = sp_track_is_starred(self.session.session, self.track);
	
	sp_link *link = sp_link_create_from_track(self.track, 0);
	if (link != NULL) {
		trackURL = [NSURL urlWithSpotifyLink:link];
		sp_link_release(link);
	}
	
	sp_album *spAlbum = sp_track_album(self.track);
	if (spAlbum != NULL)
		newAlbum = [SPAlbum albumWithAlbumStruct:spAlbum inSession:self.session];
	
	const char *nameCharArray = sp_track_name(self.track);
	if (nameCharArray != NULL) {
		NSString *nameString = [NSString stringWithUTF8String:nameCharArray];
		newName = [nameString length] > 0 ? nameString : nil;
	} else {
		newName = nil;
	}
	
	NSUInteger artistCount = sp_track_num_artists(self.track);
	NSArray *newArtists = nil;
	
	if (artistCount > 0) {
		NSMutableArray *array = [NSMutableArray arrayWithCapacity:artistCount];
		NSUInteger currentArtist = 0;
		for (currentArtist = 0; currentArtist < artistCount; currentArtist++) {
			sp_artist *artist = sp_track_artist(self.track, (int)currentArtist);
			if (artist != NULL) {
				[array addObject:[SPArtist artistWithArtistStruct:artist inSession:self.session]];
			}
		}
		
		if ([array count] > 0) {
			newArtists = [NSArray arrayWithArray:array];
		}
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		self.spotifyURL = trackURL;
		self.album = newAlbum;
		self.name = newName;
		self.local = newLocal;
		self.trackNumber = newTrackNumber;
		self.discNumber = newDiscNumber;
		self.popularity = newPopularity;
		self.duration = newDuration;
		self.availability = newAvailability;
		self.offlineStatus = newOfflineStatus;
		[self setStarredFromLibSpotifyUpdate:newStarred];
		self.artists = newArtists;
		self.loaded = newLoaded;
	});
}

-(void)sessionUpdatedMetadata:(NSNotification *)notification {

	SPDispatchAsync(^{

		BOOL newLocal = sp_track_is_local(self.session.session, self.track);
		NSUInteger newPopularity = sp_track_popularity(self.track);
		sp_track_availability newAvailability = sp_track_get_availability(self.session.session, self.track);
		sp_track_offline_status newOfflineStatus = sp_track_offline_get_status(self.track);
		BOOL newStarred = sp_track_is_starred(self.session.session, self.track);
		sp_track_offline_status status = sp_track_offline_get_status(self.track);

		dispatch_async(dispatch_get_main_queue(), ^{
			if (self.isLocal != newLocal) self.local = newLocal;
			if (self.popularity != newPopularity) self.popularity = newPopularity;
			if (self.availability != newAvailability) self.availability = newAvailability;
			if (self.offlineStatus != newOfflineStatus) self.offlineStatus = newOfflineStatus;
			if (self.starred != newStarred) [self setStarredFromLibSpotifyUpdate:newStarred];
			if (self.offlineStatus != status) [self setOfflineStatusFromLibSpotifyUpdate:status];
		});
	});
}

-(void)albumBrowseDidLoad {
	if (self.track) self.discNumber = sp_track_disc(self.track);
}

-(SPTrack *)playableTrack {
	
	if (!self.track) return nil;

	sp_track *linked = sp_track_get_playable(self.session.session, self.track);
	if (!linked) return nil;
	
	return [SPTrack trackForTrackStruct:linked inSession:self.session];
	
}

#pragma mark -
#pragma mark Properties 

-(sp_track *)track {
#if DEBUG
	SPAssertOnLibSpotifyThread();
#endif 
	return _track;
}

+(NSSet *)keyPathsForValuesAffectingConsolidatedArtists {
	return [NSSet setWithObject:@"artists"];
}

-(NSString *)consolidatedArtists {
	if (self.artists.count == 0)
		return nil;
	
	NSMutableArray *artistNames = [[self.artists valueForKey:@"name"] mutableCopy];
	[artistNames removeObjectIdenticalTo:[NSNull null]];
	
	return [[artistNames sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] componentsJoinedByString:@", "];
}

-(void)setStarred:(BOOL)starred {
    SPDispatchAsync(^() {
		sp_track *track = self.track;
		sp_track_set_starred(self.session.session, (sp_track *const *)&track, 1, starred);
	});
	_starred = starred;
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	sp_track *outgoing_track = _track;
	_track = NULL;
    if (outgoing_track) SPDispatchAsync(^() { sp_track_release(outgoing_track); });
    _session = nil;
}

@end
