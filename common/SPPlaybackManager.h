//
//  SPPlaybackManager.h
//  Guess The Intro
//
//  Created by Daniel Kennett on 06/05/2011.
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

#import <Foundation/Foundation.h>
#import "CocoaLibSpotifyPlatformImports.h"
#import "SPCoreAudioController.h"

@class SPPlaybackManager;
@class SPCoreAudioController;
@class SPTrack;
@class SPSession;

/** Provides delegate callbacks for SPPlaybackManager. */

@protocol SPPlaybackManagerDelegate <NSObject>

/** Called when audio starts playing.
 
 @param aPlaybackManager The playback manager that started playing.
 */
-(void)playbackManagerWillStartPlayingAudio:(SPPlaybackManager *)aPlaybackManager;

/** Called when the last audio samples for the current track have been buffered.
 
 @param aPlaybackManager The playback manager that is about to finish playback.
 */
-(void)playbackManagerIsFinishingPlayback:(SPPlaybackManager *)aPlaybackManager;

@end

/**
 This class provides a very basic interface for playing a track. For advanced control of playback, 
 either subclass this class or implement your own using SPCoreAudioController for the audio pipeline.
 */

@interface SPPlaybackManager : NSObject <SPSessionPlaybackDelegate, SPCoreAudioControllerDelegate>

/** Initialize a new SPPlaybackManager object. 
 
 @param aSession The session that should stream and decode audio data.
 @return Returns the created playback manager.
*/ 
-(id)initWithPlaybackSession:(SPSession *)aSession;

/** Initialize a new SPPlaybackManager object with a custom audio controller. 
 
 @param aController The `SPCoreAudioController` this instance should use.
 @param aSession The session that should stream and decode audio data.
 @return Returns the created playback manager.
 */
-(id)initWithAudioController:(SPCoreAudioController *)aController playbackSession:(SPSession *)aSession;

/** Returns the currently playing track, or `nil` if nothing is playing. */
@property (nonatomic, readonly, strong) SPTrack *currentTrack;

/** Returns the manager's delegate. */
@property (nonatomic, readwrite, weak) id <SPPlaybackManagerDelegate> delegate;

/** Returns the session that is performing decoding and playback. */
@property (nonatomic, readonly, strong) SPSession *playbackSession;

///----------------------------
/// @name Controlling Playback
///----------------------------

/** Returns `YES` if the track is currently playing, `NO` if not.
 
 If currentTrack is not `nil`, playback is paused.
 */
@property (readwrite) BOOL isPlaying;

/** Plays the given track.
 
 @param aTrack The track that should be played.
 @param block The `SPErrorableOperationCallback` block to be called with an `NSError` if playback failed or `nil` if playback started successfully.
 */
-(void)playTrack:(SPTrack *)aTrack callback:(SPErrorableOperationCallback)block;

/** Seek the current playback position to the given time. 
 
 @param newPosition The time at which to seek to. Must be between 0.0 and the duration of the playing track.
 */
-(void)seekToTrackPosition:(NSTimeInterval)newPosition;

/** Returns the playback position of the current track, in the range 0.0 to the current track's duration. */
@property (readonly) NSTimeInterval trackPosition;

/** Returns the current playback volume, in the range 0.0 to 1.0. */
@property (readwrite) double volume;

@end
