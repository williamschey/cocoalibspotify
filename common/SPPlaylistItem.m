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

#import "SPPlaylistItem.h"
#import "SPPlaylist.h"
#import "SPSession.h"
#import "SPUser.h"
#import "SPTrack.h"
#import "SPURLExtensions.h"

@interface SPPlaylistItem ()

@property (nonatomic, readwrite, strong) id <SPPlaylistableItem, SPAsyncLoading> item;
@property (nonatomic, readwrite, copy) NSDate *dateAdded;
@property (nonatomic, readwrite, strong) SPUser *creator;
@property (nonatomic, readwrite, copy) NSString *message;
@property (nonatomic, readwrite, weak) SPPlaylist *playlist;
@property (nonatomic, readwrite) int itemIndex;

@end

@implementation SPPlaylistItem (SPPlaylistItemInternal)

-(id)initWithPlaceholderTrack:(sp_track *)track atIndex:(int)index inPlaylist:(SPPlaylist *)aPlaylist {
	
	SPAssertOnLibSpotifyThread();
	
	if ((self = [super init])) {
		self.playlist = aPlaylist;
		self.itemIndex = index;
		if (sp_track_is_placeholder(track)) {
			[self.playlist.session objectRepresentationForSpotifyURL:[NSURL urlWithSpotifyLink:sp_link_create_from_track(track, 0)]
			 callback:^(sp_linktype linkType, id objectRepresentation) {
				 self.item = objectRepresentation;
			 }];
		} else {
			self.item = [SPTrack trackForTrackStruct:track inSession:self.playlist.session];
		}
		
		self.dateAdded = [NSDate dateWithTimeIntervalSince1970:sp_playlist_track_create_time(self.playlist.playlist, index)];
		self.creator = [SPUser userWithUserStruct:sp_playlist_track_creator(self.playlist.playlist, index)
										inSession:self.playlist.session];
		[self setUnreadFromLibSpotify:!sp_playlist_track_seen(self.playlist.playlist, index)];
		
		const char *msg = sp_playlist_track_message(self.playlist.playlist, index);
		if (msg != NULL)
			self.message = [NSString stringWithUTF8String:msg];
		
	}
	return self;
}

-(void)setDateCreatedFromLibSpotify:(NSDate *)date {
	self.dateAdded = date;
}

-(void)setCreatorFromLibSpotify:(SPUser *)user {
	self.creator = user;
}

-(void)setUnreadFromLibSpotify:(BOOL)unread {
	[self willChangeValueForKey:@"unread"];
	_unread = unread;
	[self didChangeValueForKey:@"unread"];
}

-(void)setMessageFromLibSpotify:(NSString *)msg {
	self.message = msg;
}

-(void)setItemIndexFromLibSpotify:(int)newIndex {
	self.itemIndex = newIndex;
}

@end

@implementation SPPlaylistItem

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: %@", [super description], [self.item description]];
}

+(NSSet *)keyPathsForValuesAffectingItemURL {
	return [NSSet setWithObject:@"item"];
}

-(NSURL *)itemURL {
	return [self.item spotifyURL];
}

+(NSSet *)keyPathsForValuesAffectingItemURLType {
	return [NSSet setWithObject:@"item"];
}

-(sp_linktype)itemURLType {
	return [[self.item spotifyURL] spotifyLinkType]; 
}

+(NSSet *)keyPathsForValuesAffectingItemClass {
	return [NSSet setWithObject:@"item"];
}

-(Class)itemClass {
	return [self.item class];
}

-(void)setUnread:(BOOL)unread {
	SPDispatchAsync(^() { sp_playlist_track_set_seen(self.playlist.playlist, self.itemIndex, !unread); });
	_unread = unread;
}

@end
