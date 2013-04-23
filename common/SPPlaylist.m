//
//  SPPlaylist.m
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

#import "SPPlaylist.h"
#import "SPPlaylistInternal.h"
#import "SPSession.h"
#import "SPTrack.h"
#import "SPTrackInternal.h"
#import "SPImage.h"
#import "SPUser.h"
#import "SPURLExtensions.h"
#import "SPErrorExtensions.h"
#import "SPPlaylistItem.h"
#import "SPPlaylistItemInternal.h"

@interface SPPlaylistCallbackProxy : NSObject
// SPPlaylistCallbackProxy is here to bridge the gap between -dealloc and the 
// playlist callbacks being unregistered, since that's done async.
@property (nonatomic, readwrite, weak) SPPlaylist *playlist;
@end

@implementation SPPlaylistCallbackProxy
@end

@interface SPPlaylist ()

@property (nonatomic, readwrite, getter=isUpdating) BOOL updating;
@property (nonatomic, readwrite, getter=isLoaded) BOOL loaded;
@property (nonatomic, readwrite) BOOL hasPendingChanges;
@property (nonatomic, readwrite, copy) NSString *playlistDescription;
@property (nonatomic, readwrite, copy) NSURL *spotifyURL;
@property (nonatomic, readwrite, strong) SPImage *image;
@property (nonatomic, readwrite, strong) SPUser *owner;
@property (nonatomic, readwrite, strong) NSArray *subscribers;
@property (nonatomic, readwrite) float offlineDownloadProgress;
@property (nonatomic, readwrite) sp_playlist_offline_status offlineStatus;
@property (nonatomic, readwrite) sp_playlist *playlist;
@property (nonatomic, readwrite, weak) SPSession *session;
@property (nonatomic, readwrite, strong) SPPlaylistCallbackProxy *callbackProxy;
@property (nonatomic, readwrite) NSUInteger itemCount;

@property (nonatomic, readwrite, strong) NSMutableArray *moveCallbackStack;
@property (nonatomic, readwrite, strong) NSMutableArray *addCallbackStack;
@property (nonatomic, readwrite, strong) NSMutableArray *removeCallbackStack;

-(void)loadPlaylistData;
-(void)rebuildSubscribers;

-(void)setPlaylistNameFromLibSpotifyUpdate:(NSString *)newName;
-(void)setPlaylistDescriptionFromLibSpotifyUpdate:(NSString *)newDescription;
-(void)setCollaborativeFromLibSpotifyUpdate:(BOOL)collaborative;

@end

#pragma mark Callbacks

// Called when one or more tracks have been added to a playlist
static void tracks_added(sp_playlist *pl, sp_track *const *tracks, int num_tracks, int position, void *userdata) {
    
	SPPlaylistCallbackProxy *proxy = (__bridge SPPlaylistCallbackProxy *)userdata;
	SPPlaylist *playlist = proxy.playlist;
	if (!playlist) return;

	
	SPErrorableOperationCallback callback = nil;
	if (playlist.addCallbackStack.count > 0) {
		callback = [playlist.addCallbackStack objectAtIndex:0];
		[playlist.addCallbackStack removeObjectAtIndex:0];
	}

	NSUInteger itemCount = sp_playlist_num_tracks(pl);

	dispatch_async(dispatch_get_main_queue(), ^{
		playlist.itemCount = itemCount;
		if ([[playlist delegate] respondsToSelector:@selector(playlist:didAddItemsAtIndexes:)])
			[(id <SPPlaylistDelegate>)[playlist delegate] playlist:playlist
											  didAddItemsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(position, num_tracks)]];
		if (callback) callback(nil);
	});
}

// Called when one or more tracks have been removed from a playlist
static void	tracks_removed(sp_playlist *pl, const int *tracks, int num_tracks, void *userdata) {

	SPPlaylistCallbackProxy *proxy = (__bridge SPPlaylistCallbackProxy *)userdata;
	SPPlaylist *playlist = proxy.playlist;
	if (!playlist) return;
	
	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
	
	for (NSUInteger currentIndex = 0; currentIndex < num_tracks; currentIndex++)
		[indexes addIndex:tracks[currentIndex]];
	
	SPErrorableOperationCallback callback = nil;
	if (playlist.removeCallbackStack.count > 0) {
		callback = [playlist.removeCallbackStack objectAtIndex:0];
		[playlist.removeCallbackStack removeObjectAtIndex:0];
	}

	NSUInteger itemCount = sp_playlist_num_tracks(pl);
	
	dispatch_async(dispatch_get_main_queue(), ^{
		playlist.itemCount = itemCount;
		if ([[playlist delegate] respondsToSelector:@selector(playlist:didRemoveItemsAtIndexes:)])
			[(id <SPPlaylistDelegate>)[playlist delegate] playlist:playlist
										   didRemoveItemsAtIndexes:indexes];
		if (callback) callback(nil);
	});
}

// Called when one or more tracks have been moved within a playlist
static void	tracks_moved(sp_playlist *pl, const int *tracks, int num_tracks, int new_position, void *userdata) {
    
	SPPlaylistCallbackProxy *proxy = (__bridge SPPlaylistCallbackProxy *)userdata;
	SPPlaylist *playlist = proxy.playlist;
	if (!playlist) return;

	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
	NSUInteger newStartIndex = new_position;

		for (NSUInteger currentIndex = 0; currentIndex < num_tracks; currentIndex++) {
			int thisIndex = tracks[currentIndex];
			[indexes addIndex:thisIndex];
			if (thisIndex < new_position) {
				newStartIndex--;
		}
	}
	
	SPErrorableOperationCallback callback = nil;
	if (playlist.moveCallbackStack.count > 0) {
		callback = [playlist.moveCallbackStack objectAtIndex:0];
		[playlist.moveCallbackStack removeObjectAtIndex:0];
	}

	NSUInteger itemCount = sp_playlist_num_tracks(pl);

	dispatch_async(dispatch_get_main_queue(), ^{
		playlist.itemCount = itemCount;
		if ([[playlist delegate] respondsToSelector:@selector(playlist:didMoveItemsAtIndexes:toIndexes:)])
			[(id <SPPlaylistDelegate>)[playlist delegate] playlist:playlist
											 didMoveItemsAtIndexes:indexes
														 toIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(newStartIndex, num_tracks)]];
		if (callback) callback(nil);
	});
}

// Called when a playlist has been renamed. sp_playlist_name() can be used to find out the new name
static void	playlist_renamed(sp_playlist *pl, void *userdata) {
	
	SPPlaylistCallbackProxy *proxy = (__bridge SPPlaylistCallbackProxy *)userdata;
	SPPlaylist *playlist = proxy.playlist;
	if (!playlist) return;
	
    NSString *name = [NSString stringWithUTF8String:sp_playlist_name(pl)];
	dispatch_async(dispatch_get_main_queue(), ^{
		[playlist setPlaylistNameFromLibSpotifyUpdate:name];
	});
}

/*
 Called when state changed for a playlist.
 
 There are three states that trigger this callback:
 
 Collaboration for this playlist has been turned on or off
 The playlist started having pending changes, or all pending changes have now been committed
 The playlist started loading, or finished loading
 */
static void	playlist_state_changed(sp_playlist *pl, void *userdata) {
    
	SPPlaylistCallbackProxy *proxy = (__bridge SPPlaylistCallbackProxy *)userdata;
	SPPlaylist *playlist = proxy.playlist;
	if (!playlist) return;
	
	[playlist offlineSyncStatusMayHaveChanged];
	
	BOOL isLoaded = sp_playlist_is_loaded(pl);
	if (isLoaded) dispatch_async(dispatch_get_main_queue(), ^{ [playlist loadPlaylistData]; });
}

// Called when a playlist is updating or is done updating
static void	playlist_update_in_progress(sp_playlist *pl, bool done, void *userdata) {
   
	SPPlaylistCallbackProxy *proxy = (__bridge SPPlaylistCallbackProxy *)userdata;
	SPPlaylist *playlist = proxy.playlist;
	if (!playlist) return;

	if (playlist.updating == done)
		dispatch_async(dispatch_get_main_queue(), ^{ playlist.updating = !done; });
}

// Called when metadata for one or more tracks in a playlist has been updated.
static void	playlist_metadata_updated(sp_playlist *pl, void *userdata) {

	SPPlaylistCallbackProxy *proxy = (__bridge SPPlaylistCallbackProxy *)userdata;
	SPPlaylist *playlist = proxy.playlist;
	if (!playlist) return;

	@autoreleasepool {
		if ([[playlist delegate] respondsToSelector:@selector(itemsInPlaylistDidUpdateMetadata:)]) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[playlist.delegate itemsInPlaylistDidUpdateMetadata:playlist];
			});
		}
	}
}

// Called when create time and/or creator for a playlist entry changes
static void	track_created_changed(sp_playlist *pl, int position, sp_user *user, int when, void *userdata) {

	SPPlaylistCallbackProxy *proxy = (__bridge SPPlaylistCallbackProxy *)userdata;
	SPPlaylist *playlist = proxy.playlist;
	if (!playlist) return;

	if ([[playlist delegate] respondsToSelector:@selector(itemsInPlaylistDidUpdateMetadata:)]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[playlist.delegate itemsInPlaylistDidUpdateMetadata:playlist];
		});
	}
}

// Called when seen attribute for a playlist entry changes
static void	track_seen_changed(sp_playlist *pl, int position, bool seen, void *userdata) {
    
	SPPlaylistCallbackProxy *proxy = (__bridge SPPlaylistCallbackProxy *)userdata;
	SPPlaylist *playlist = proxy.playlist;
	if (!playlist) return;
	
	if ([[playlist delegate] respondsToSelector:@selector(itemsInPlaylistDidUpdateMetadata:)]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[playlist.delegate itemsInPlaylistDidUpdateMetadata:playlist];
		});
	}
}

// Called when playlist description has changed
static void	description_changed(sp_playlist *pl, const char *desc, void *userdata) {
   
	SPPlaylistCallbackProxy *proxy = (__bridge SPPlaylistCallbackProxy *)userdata;
	SPPlaylist *playlist = proxy.playlist;
	if (!playlist) return;
	
	NSString *newDesc = [NSString stringWithUTF8String:desc];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[playlist setPlaylistDescriptionFromLibSpotifyUpdate:newDesc];
	});
}

static void	image_changed(sp_playlist *pl, const byte *image, void *userdata) {
    
	SPPlaylistCallbackProxy *proxy = (__bridge SPPlaylistCallbackProxy *)userdata;
	SPPlaylist *playlist = proxy.playlist;
	if (!playlist) return;
	
	SPImage *spImage = [SPImage imageWithImageId:image inSession:playlist.session];
	dispatch_async(dispatch_get_main_queue(), ^{ playlist.image = spImage; });
}

// Called when message attribute for a playlist entry changes
static void	track_message_changed(sp_playlist *pl, int position, const char *message, void *userdata) {

	SPPlaylistCallbackProxy *proxy = (__bridge SPPlaylistCallbackProxy *)userdata;
	SPPlaylist *playlist = proxy.playlist;
	if (!playlist) return;
	
	if ([[playlist delegate] respondsToSelector:@selector(itemsInPlaylistDidUpdateMetadata:)]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[playlist.delegate itemsInPlaylistDidUpdateMetadata:playlist];
		});
	}
}

// Called when playlist subscribers changes (count or list of names)
static void	subscribers_changed(sp_playlist *pl, void *userdata) {
    
	SPPlaylistCallbackProxy *proxy = (__bridge SPPlaylistCallbackProxy *)userdata;
	SPPlaylist *playlist = proxy.playlist;
	if (!playlist) return;
	
	[playlist rebuildSubscribers];
}

static sp_playlist_callbacks _playlistCallbacks = {
	&tracks_added,
	&tracks_removed,
	&tracks_moved,
	&playlist_renamed,
	&playlist_state_changed,
	&playlist_update_in_progress,
	&playlist_metadata_updated,
	&track_created_changed,
	&track_seen_changed,
	&description_changed,
    &image_changed,
    &track_message_changed,
    &subscribers_changed
};

#pragma mark -

static NSString * const kSPPlaylistKVOContext = @"kSPPlaylistKVOContext";

@implementation SPPlaylist (SPPlaylistInternal)

-(void)offlineSyncStatusMayHaveChanged {
	
	SPAssertOnLibSpotifyThread();
	
	sp_playlist_offline_status newStatus = sp_playlist_get_offline_status(self.session.session, self.playlist);
	float newProgress = sp_playlist_get_offline_download_completed(self.session.session, self.playlist) / 100.0;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		self.offlineStatus = newStatus;
		self.offlineDownloadProgress = newProgress;
	});
}

@end

@implementation SPPlaylist

+(SPPlaylist *)playlistWithPlaylistStruct:(sp_playlist *)pl inSession:(SPSession *)aSession {
	return [aSession playlistForPlaylistStruct:pl];
}

+(void)playlistWithPlaylistURL:(NSURL *)playlistURL inSession:(SPSession *)aSession callback:(void (^)(SPPlaylist *playlist))block {
	[aSession playlistForURL:playlistURL callback:block];
}

-(id)initWithPlaylistStruct:(sp_playlist *)pl inSession:(SPSession *)aSession {
    
	SPAssertOnLibSpotifyThread();
	
    if ((self = [super init])) {
        self.session = aSession;
        self.playlist = pl;

		// Add Observers
        
        [self addObserver:self
               forKeyPath:@"name"
                  options:0
                  context:(__bridge void *)kSPPlaylistKVOContext];
        
        [self addObserver:self
               forKeyPath:@"playlistDescription"
                  options:0
                  context:(__bridge void *)kSPPlaylistKVOContext];
        
        [self addObserver:self
               forKeyPath:@"collaborative"
                  options:0
                  context:(__bridge void *)kSPPlaylistKVOContext];
		
		if (self.playlist != NULL) {
			sp_playlist_add_ref(self.playlist);
			
			self.moveCallbackStack = [NSMutableArray new];
			self.addCallbackStack = [NSMutableArray new];
			self.removeCallbackStack = [NSMutableArray new];
		
			if (aSession.loadingPolicy == SPAsyncLoadingImmediate)
				dispatch_async(dispatch_get_main_queue(), ^() { 
					[self startLoading];
				});
		}
        
    }
    return self;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"%@: %@ (%@ items)", [super description], [self name], @(self.itemCount)];
}

-(sp_playlist *)playlist {
#if DEBUG
	SPAssertOnLibSpotifyThread();
#endif
	return _playlist;
}

-(void)setMarkedForOfflinePlayback:(BOOL)isMarkedForOfflinePlayback {
	SPDispatchAsync(^{
		sp_playlist_set_offline_mode(self.session.session, self.playlist, isMarkedForOfflinePlayback);
	});
}

-(BOOL)isMarkedForOfflinePlayback {
	return self.offlineStatus != SP_PLAYLIST_OFFLINE_STATUS_NO;
}

-(void)fetchItemsInRange:(NSRange)range callback:(void (^)(NSError *, NSArray *))block {

	SPDispatchAsync(^{

		if (self.playlist == NULL) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{
				block([NSError spotifyErrorWithCode:SP_ERROR_IS_LOADING], nil);
			});
			return;
		}

		NSUInteger trackCount = sp_playlist_num_tracks(self.playlist);

		if (range.location + range.length > trackCount) {
			if (block) dispatch_async(dispatch_get_main_queue(), ^{
				block([NSError spotifyErrorWithCode:SP_ERROR_INDEX_OUT_OF_RANGE], nil);
			});
			return;
		}

		NSMutableArray *items = [NSMutableArray arrayWithCapacity:range.length];

		for (int itemIndex = (int)range.location; itemIndex < range.location + range.length; itemIndex++) {
			[items addObject:[[SPPlaylistItem alloc] initWithPlaceholderTrack:sp_playlist_track(self.playlist, itemIndex)
																	  atIndex:itemIndex
																   inPlaylist:self]];
		}

		if (block) dispatch_async(dispatch_get_main_queue(), ^{
			block(nil, [NSArray arrayWithArray:items]);
		});

	});

}

#pragma mark -
#pragma mark Private Methods

-(void)loadPlaylistData {
	
	SPDispatchAsync(^() {

		if (self.playlist == NULL)
			return;
		
		BOOL isLoaded = sp_playlist_is_loaded(self.playlist);
		
		if (!isLoaded)
			return;
		
		NSURL *newURL = nil;
		NSString *newName = nil;
		NSString *newDesc = nil;
		SPImage *newImage = nil;
		SPUser *newOwner = nil;
		BOOL newCollaborative = NO;
		BOOL newHasPendingChanges = NO;
		
		sp_link *link = sp_link_create_from_playlist(self.playlist);
		if (link != NULL) {
			newURL = [NSURL urlWithSpotifyLink:link];
			sp_link_release(link);
		}
		
		const char *nameBuf = sp_playlist_name(self.playlist);
		if (nameBuf != NULL)
			newName = [NSString stringWithUTF8String:nameBuf];
		
		const char *desc = sp_playlist_get_description(self.playlist);
		if (desc != NULL)
			newDesc = [NSString stringWithUTF8String:desc];
		
		byte imageId[20];
		if (sp_playlist_get_image(self.playlist, imageId)) {
			newImage = [SPImage imageWithImageId:imageId inSession:self.session];
		}
		
		newOwner = [SPUser userWithUserStruct:sp_playlist_owner(self.playlist) inSession:self.session];
		newCollaborative = sp_playlist_is_collaborative(self.playlist);
		newHasPendingChanges = sp_playlist_has_pending_changes(self.playlist);

		NSUInteger itemCount = sp_playlist_num_tracks(self.playlist);
		
		dispatch_async(dispatch_get_main_queue(), ^() {
			self.itemCount = itemCount;
			self.spotifyURL = newURL;
			self.image = newImage;
			self.owner = newOwner;
			self.hasPendingChanges = newHasPendingChanges;
			[self setPlaylistNameFromLibSpotifyUpdate:newName];
			[self setPlaylistDescriptionFromLibSpotifyUpdate:newDesc];
			[self setCollaborativeFromLibSpotifyUpdate:newCollaborative];
			self.loaded = isLoaded;
		});
		
		[self offlineSyncStatusMayHaveChanged];
		sp_playlist_update_subscribers(self.session.session, self.playlist);
		
	});
}

-(void)startLoading {
	
	SPDispatchAsync(^() {
		
		if (self.callbackProxy != nil) return;
		
		dispatch_async(dispatch_get_main_queue(), ^{
			SPDispatchAsync(^() {

				if (self.callbackProxy == nil) {
					// We do this check earlier on, but there's a race condition that causes a nasty crash
					self.callbackProxy = [[SPPlaylistCallbackProxy alloc] init];
					self.callbackProxy.playlist = self;
					sp_playlist_add_callbacks(self.playlist, &_playlistCallbacks, (__bridge void *)self.callbackProxy);
				}

				sp_playlist_set_in_ram(self.session.session, self.playlist, true);
				BOOL isLoaded = sp_playlist_is_loaded(self.playlist);
				if (isLoaded) dispatch_async(dispatch_get_main_queue(), ^() { [self loadPlaylistData]; });
			});
		});
	});
}
				   
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (context == (__bridge void *)kSPPlaylistKVOContext) {
        if ([keyPath isEqualToString:@"name"]) {
            SPDispatchAsync(^() { sp_playlist_rename(self.playlist, [self.name UTF8String]); });
            return;
        } else if ([keyPath isEqualToString:@"collaborative"]) {
            SPDispatchAsync(^() { sp_playlist_set_collaborative(self.playlist, self.isCollaborative); });
            return;
        }
    } 
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

-(void)setPlaylistNameFromLibSpotifyUpdate:(NSString *)newName {
	if ([newName isEqualToString:self.name])
		return;
	
    // Remove observers otherwise we'll create an infinite loop!
    [self removeObserver:self forKeyPath:@"name"];
    [self setName:newName];
    [self addObserver:self
           forKeyPath:@"name"
              options:0
              context:(__bridge void *)kSPPlaylistKVOContext];
}

-(void)setPlaylistDescriptionFromLibSpotifyUpdate:(NSString *)newDescription {
    // Remove observers otherwise we'll create an infinite loop!
    [self removeObserver:self forKeyPath:@"playlistDescription"];
    [self setPlaylistDescription:newDescription];
    [self addObserver:self
           forKeyPath:@"playlistDescription"
              options:0
              context:(__bridge void *)kSPPlaylistKVOContext];
}

-(void)setCollaborativeFromLibSpotifyUpdate:(BOOL)newCollaborative {
    // Remove observers otherwise we'll create an infinite loop!
    [self removeObserver:self forKeyPath:@"collaborative"];
    [self setCollaborative:newCollaborative];
    [self addObserver:self
           forKeyPath:@"collaborative"
              options:0
              context:(__bridge void *)kSPPlaylistKVOContext];
}

#pragma mark -

-(void)rebuildSubscribers {
	
	SPAssertOnLibSpotifyThread();
	
	NSUInteger subscriberCount = sp_playlist_num_subscribers(self.playlist);
	NSArray *newSubscribers = nil;
	
	if (subscriberCount > 0) {
	
		sp_subscribers *subs = sp_playlist_subscribers(self.playlist);
		NSUInteger actualSubscriberCount = subs->count;
		NSMutableArray *mutableSubscribers = [NSMutableArray arrayWithCapacity:actualSubscriberCount];
		
		for (NSUInteger currentSubscriber = 0; currentSubscriber < actualSubscriberCount; currentSubscriber++) {
			
			char *subscriberName = subs->subscribers[currentSubscriber];
			if (subscriberName != NULL && strlen(subscriberName) > 0) {
				NSString *subsName = [NSString stringWithUTF8String:subscriberName];
				if (subsName != nil)
					[mutableSubscribers addObject:subsName];
			}
		}
		
		newSubscribers = [NSArray arrayWithArray:mutableSubscribers];
		sp_playlist_subscribers_free(subs);
		
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		if (![self.subscribers isEqualToArray:newSubscribers])
			self.subscribers = newSubscribers;
	});
}

-(void)addItem:(SPTrack *)anItem atIndex:(NSUInteger)index callback:(SPErrorableOperationCallback)block {
	[self addItems:[NSArray arrayWithObject:anItem] atIndex:index callback:block];
}

-(void)addItems:(NSArray *)newItems atIndex:(NSUInteger)index callback:(SPErrorableOperationCallback)block {
	
	SPDispatchAsync(^{
		
		if (newItems.count == 0) {
			dispatch_async(dispatch_get_main_queue(), ^{
				if (block) block([NSError spotifyErrorWithCode:SP_ERROR_INVALID_INDATA]);
			});
			return;
		}
		
		sp_track **tracks = malloc(sizeof(sp_track *) * newItems.count);
		
		// libSpotify iterates through the array and inserts each track at the given index, 
		// which ends up reversing the expected order. Defeat this by constructing a backwards
		// array.
		for (int currentTrack = (int)newItems.count - 1; currentTrack >= 0; currentTrack--) {
			
			sp_track *track;
			id item = [newItems objectAtIndex:currentTrack];
			
			if ([item isKindOfClass:[SPTrack class]])
				track = [item track];
			else
				track = [(SPTrack *)((SPPlaylistItem *)item).item track];
			
			tracks[currentTrack] = track;
		}
		sp_track *const *trackPointer = tracks;
		
		if (block)
			[self.addCallbackStack addObject:block];
		
		sp_error errorCode = sp_playlist_add_tracks(self.playlist, trackPointer, (int)newItems.count, (int)index, self.session.session);
		free(tracks);
		tracks = NULL;
		
		NSError *error = nil;
		if (errorCode != SP_ERROR_OK)
			error = [NSError spotifyErrorWithCode:errorCode];
		
		if (error && block) {
			[self.addCallbackStack removeObject:block];
			dispatch_async(dispatch_get_main_queue(), ^{ block(error); });
		}
	});
}

-(void)removeItemAtIndex:(NSUInteger)index callback:(SPErrorableOperationCallback)block {

	SPDispatchAsync(^{
		
		if (block)
			[self.removeCallbackStack addObject:block];
		
		int intIndex = (int)index; 
		const int *indexPtr = &intIndex;
		sp_error errorCode = sp_playlist_remove_tracks(self.playlist, indexPtr, 1);
		
		NSError *error = nil;
		if (errorCode != SP_ERROR_OK)
			error = [NSError spotifyErrorWithCode:errorCode];
		
		if (error && block) {
			[self.removeCallbackStack removeObject:block];
			dispatch_async(dispatch_get_main_queue(), ^{ block(error); });
		}
	});

}

-(void)moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)newLocation callback:(SPErrorableOperationCallback)block {
	
	SPDispatchAsync(^{
		
		int count = (int)[indexes count];
		int indexArray[count];
		
		NSUInteger index = [indexes firstIndex];
		for (NSUInteger i = 0; i < [indexes count]; i++) {
			indexArray[i] = (int)index;
			index = [indexes indexGreaterThanIndex:index];
		}
		
		if (block)
			[self.moveCallbackStack addObject:block];
		
		const int *indexArrayPtr = (const int *)&indexArray;
		sp_error errorCode = sp_playlist_reorder_tracks(self.playlist, indexArrayPtr, count, (int)newLocation);
		
		NSError *error = nil;
		if (errorCode != SP_ERROR_OK)
			error = [NSError spotifyErrorWithCode:errorCode];
		
		if (error && block) {
			[self.moveCallbackStack removeObject:block];
			dispatch_async(dispatch_get_main_queue(), ^{ block(error); });
		}
	});
}

-(void)dealloc {
    
    [self removeObserver:self forKeyPath:@"name"];
    [self removeObserver:self forKeyPath:@"playlistDescription"];
    [self removeObserver:self forKeyPath:@"collaborative"];
    
    self.delegate = nil;
    self.session = nil;
	
	sp_playlist *outgoing_playlist = _playlist;
	
	self.callbackProxy.playlist = nil;
	
	SPPlaylistCallbackProxy *outgoingProxy = self.callbackProxy;
	self.callbackProxy = nil;

	if (outgoing_playlist != NULL) return;

	SPDispatchAsync(^() {
		sp_playlist_remove_callbacks(outgoing_playlist, &_playlistCallbacks, (__bridge void *)outgoingProxy);
		sp_playlist_release(outgoing_playlist);
	});
}


@end
