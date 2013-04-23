//
//  SPPlaylistFolder.h
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

/** This class represents a playlist folder in the user's playlist list.
 
 @see SPPlaylistContainer
 */

#import <Foundation/Foundation.h>
#import "CocoaLibSpotifyPlatformImports.h"

@class SPPlaylistContainer;
@class SPSession;

@interface SPPlaylistFolder : NSObject

///----------------------------
/// @name Properties
///----------------------------

/** Returns the folder's ID, as used in the C LibSpotify API. 
 
 @warning This should only be used if you plan to directly use the 
 C LibSpotify API. The behaviour of CocoaLibSpotify is undefined if you use the C
 API directly on items that have CocoaLibSpotify objects associated with them. 
 */
@property (nonatomic, readonly) sp_uint64 folderId;

/** Returns the name of the folder. */
@property (nonatomic, readonly, copy) NSString *name;

/** Returns the folder's containing SPPlaylistContainer. */
@property (nonatomic, readonly, weak) SPPlaylistContainer *parentContainer;

/* Returns the folder's parent folder, or `nil` if the folder is at the top level of its container. */
@property (nonatomic, readonly, weak) SPPlaylistFolder *parentFolder;

/* Returns the folder's parent folder stack, or `nil` if the folder is at the top level of its container. */
-(NSArray *)parentFolders;

/** Returns an array of SPPlaylist and/or SPPlaylistFolders representing the folder's child playlists.
  
 @warning If you need to move a playlist from one location in this list to another,
 use `-[SPPlaylistContainer moveItem:toIndex:ofNewParent:callback:]`.
 
 @see [SPPlaylistContainer moveItem:toIndex:ofNewParent:callback:]
 */
@property (nonatomic, readonly, strong) NSArray *playlists;

/** Returns the session the folder is loaded in. */
@property (nonatomic, readonly, weak) SPSession *session;

@end
