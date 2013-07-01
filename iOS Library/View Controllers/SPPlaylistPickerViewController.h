//
//  SPPlaylistPickerViewController.h
//  CocoaLibSpotify iOS Library
//
//  Created by Daniel Kennett on 27/06/2013.
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

#import <UIKit/UIKit.h>

@class SPSession;
@class SPPlaylist;
@class SPPlaylistItem;

typedef NS_ENUM(NSUInteger, SPPlaylistPickerMode) {
	SPPlaylistPickerModePlaylist = 0,
	SPPlaylistPickerModeTrack = 1
};

typedef void (^SPPlaylistPickerItemPickedHandler)(SPPlaylist *pickedPlaylist, SPPlaylistItem *pickedTrack);
typedef void (^SPPlaylistPickerCancelledHandler)();

/**
 This class provides a convenient view controller for presenting a playlist or track picker
 to the user. 
 */
@interface SPPlaylistPickerViewController : UINavigationController

/** Initialize a playlist picker with the given mode and session.
 
 This is the designated initializer for this class.

 @param mode The mode the picker should run in.
 @param session The session to display user playlists from.
 */
-(id)initWithMode:(SPPlaylistPickerMode)mode inSession:(SPSession *)session;

/** Reset the receiver to the default UI state (showing the root playlist list,
 scrolled to the top).
 
 @param animate Pass `YES` to animate the reset, otherwise `NO`.
 */
-(void)resetAnimated:(BOOL)animate;

/** Reset the receiver to the default UI state without animation. */
-(void)reset;

/** Returns the mode the picker is operating under. */
@property (nonatomic, readonly) SPPlaylistPickerMode mode;

/** Returns the session the picker is displaying user playlists from. */
@property (nonatomic, readonly, strong) SPSession *session;

/** Returns `YES` if the receiver supports user cancellation, otherwise `NO`.
 
 You can set this property while the receiver is visible to show/hide the
 cancel button.
 */
@property (nonatomic, readwrite) BOOL allowCancel;

/** Returns `YES` if the receiver allows the user to create new playlists, otherwise `NO`. */
@property (nonatomic, readwrite) BOOL allowPlaylistCreation;

/** Returns the `SPPlaylistPickerItemPickedHandler` block for the receiver.
 
 The handler block will be called on the main queue when an item is picked by the user.
 
 If the receiver's mode is `SPPlaylistPickerModePlaylist`, the `pickedPlaylist` parameter of
 this call will contain the picked playlist, and the `pickedTrack` parameter will be `nil`.
 
 If the receiver's mode is `SPPlaylistPickerModeTrack`, the the `pickedPlaylist` parameter of
 this call will contain the playlist containing the picked track, and the `pickedTrack` parameter
 will contain the picked track.
 
 @warning The receiver will *not* dismiss itself after this call. Your application is responsible
 for dismissing the reveiver at the appropriate time.
 */
@property (nonatomic, readwrite, strong) SPPlaylistPickerItemPickedHandler itemPickedHandler;

/** Returns the `SPPlaylistPickerCancelledHandler` block for the receiver.

 The handler block will be called on the main queue when the "Cancel" button is 
 tapped by the user.

 @warning The receiver will *not* dismiss itself after this call. Your application is responsible
 for dismissing the reveiver at the appropriate time.
 */
@property (nonatomic, readwrite, strong) SPPlaylistPickerCancelledHandler cancellationHandler;

@end
