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

/** This class represents an item in a playlist, be it a track, artist, album or something else. */

#import <Foundation/Foundation.h>
#import "CocoaLibSpotifyPlatformImports.h"

@class SPPlaylist;
@class SPUser;

@interface SPPlaylistItem : NSObject {
	BOOL _unread;
}

///----------------------------
/// @name Querying The Item
///----------------------------

/** Returns the `Class` of the item this object represents. */
@property (nonatomic, readonly) Class itemClass;

/** Returns the Spotify URI of the item this object represents. */
@property (nonatomic, readonly) NSURL *itemURL;

/** Returns the `sp_linktype` of the item this object represents. */
@property (nonatomic, readonly) sp_linktype itemURLType;

/** Returns the item this object represents.
 
 The item is typically a track, artist, album or playlist.
 */
@property (nonatomic, readonly, strong) id <SPPlaylistableItem, SPAsyncLoading> item;

///----------------------------
/// @name Metadata
///----------------------------

/** Returns the creator of the item this object represents. 
 
 This value is used in the user's inbox playlist and playlists that are or
 were collaborative, and represents the user that added the track to the
 playlist.
 */
@property (nonatomic, readonly, strong) SPUser *creator;

/** Returns the date that the item this object represents was added to the playlist. 
 
 This value is used in the user's inbox playlist and playlists that are or
 were collaborative, and represents the date and time the track was
 added to the playlist.
 */
@property (nonatomic, readonly, copy) NSDate *dateAdded;

/** Returns the message attached to the item this object represents. 
 
 This value is used in the user's inbox playlist and reflects the message
 the sender attached to the item when sending it.
 */
@property (nonatomic, readonly, copy) NSString *message;

/** Returns the "unread" status of the item this object represents. 
 
 This value is only normally used in the user's inbox playlist. In the
 Spotify client, unread tracks have a blue dot by them in the inbox.
 */
@property (nonatomic, readwrite, getter = isUnread) BOOL unread;

@end
