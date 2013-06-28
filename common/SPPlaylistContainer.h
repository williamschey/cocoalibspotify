//
//  SPPlaylistContainer.h
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

/** This class represents a list of playlists. In practice, it is only found when dealing with a user's playlist 
 list and can't be created manually. */

#import <Foundation/Foundation.h>
#import "CocoaLibSpotifyPlatformImports.h"

@class SPUser;
@class SPSession;
@class SPPlaylist;
@class SPPlaylistFolder;

@interface SPPlaylistContainer : NSObject <SPAsyncLoading, SPDelayableAsyncLoading, SPPlaylistProvider>

///----------------------------
/// @name Properties
///----------------------------

/** Returns the opaque structure used by the C LibSpotify API. 
 
 @warning This method *must* be called on the libSpotify thread. See the
 "Threading" section of the library's readme for more information.
 
 @warning This should only be used if you plan to directly use the 
 C LibSpotify API. The behaviour of CocoaLibSpotify is undefined if you use the C
 API directly on items that have CocoaLibSpotify objects associated with them. 
 */
@property (nonatomic, readonly, assign) sp_playlistcontainer *container;

/* Returns `YES` if the playlist container has loaded all playlist and folder data, otherwise `NO`. */
@property (nonatomic, readonly, getter=isLoaded) BOOL loaded;

/** Returns the owner of the playlist list. */
@property (nonatomic, readonly, strong) SPUser *owner;

/** Returns an array of SPPlaylist and/or SPPlaylistFolders representing the owner's playlist list. */
@property (nonatomic, readonly, strong) NSArray *playlists;

/** Returns a flattened array of the `SPPlaylist` objects in the playlists tree, without folders. 
 
 This array is computed each time this method is called, so be careful if you're in a performance-critical section.
*/
-(NSArray *)flattenedPlaylists;

/** Returns the session the list is loaded in. */
@property (nonatomic, readonly, weak) SPSession *session;

///----------------------------
/// @name Working with Playlists and Folders
///----------------------------

/** Create a new, empty folder. 
 
 @param name The name of the new folder.
 @param block The callback block to call when the operation is complete.
 */
-(void)createFolderWithName:(NSString *)name callback:(void (^)(SPPlaylistFolder *createdFolder, NSError *error))block;

/** Create a new, empty playlist. 
 
 @param name The name of the new playlist. Must be shorter than 256 characters and not consist of only whitespace.
 @param block The callback block to call when the operation is complete.
 */
-(void)createPlaylistWithName:(NSString *)name callback:(void (^)(SPPlaylist *createdPlaylist))block;

/** Remove the given playlist or folder. 
 
 @param playlistOrFolder The Playlist or Folder to remove.
 @param block The callback block to execute when the operation has completed.
 */
-(void)removeItem:(id)playlistOrFolder callback:(SPErrorableOperationCallback)block;

/** Move a playlist or folder to another location in the list. 
 
 @warning This operation can fail, for example if you give invalid indexes or try to move 
 a folder into itself. Please make sure you check the result in the completion callback.
 
 @param playlistOrFolder A playlist or folder to move.
 @param newIndex The desired destination index in the destination parent folder (or root list if there's no parent).
 @param aParentFolderOrNil The new parent folder, or nil if there is no parent.
 @param block The callback block to call when the operation is complete.
 */
-(void)moveItem:(id)playlistOrFolder
		toIndex:(NSUInteger)newIndex 
	ofNewParent:(SPPlaylistFolder *)aParentFolderOrNil
	   callback:(SPErrorableOperationCallback)block;

/** Subscribe to the given playlist.

 The operation will fail if the given playlist is owned by the current user or is 
 already subscribed (i.e., you can't subscribe to a playlist twice). To unsubscibe,
 user `-[SPPlaylistContainer removeItem:callback:]`.

 @param playlist The Playlist to subscribe to.
 @param block The callback block to execute when the operation has completed.
 */
-(void)subscribeToPlaylist:(SPPlaylist *)playlist callback:(SPErrorableOperationCallback)block;

@end
