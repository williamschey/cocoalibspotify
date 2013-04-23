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

/*
 This file contains protocols and other things needed throughout the library.
 */

typedef void (^SPErrorableOperationCallback)(NSError *error);

/** Call the given block synchronously on the libSpotify thread, or inline if already on that thread.

 This helper allows you to perform synchronous code on the libSpotify thread.
 It helps avoid deadlocks by checking if you're already on the thread and just calls the
 block inline if that's the case.

 @param block The block to execute.
 */
extern inline void SPDispatchSyncIfNeeded(dispatch_block_t block);

/** Call the given block asynchronously on the libSpotify thread.

 This helper allows you to perform asynchronous operations on the libSpotify thread.

 @param block The block to execute.
 */
extern inline void SPDispatchAsync(dispatch_block_t block);

/** Throw an assertion if the current execution is not on the libSpotify thread.

 This helper macro assists debugging operations on the libSpotify thread.
 */
#define SPAssertOnLibSpotifyThread() NSAssert(CFRunLoopGetCurrent() == [SPSession libSpotifyRunloop], @"Not on correct thread!");

@class SPTrack;
@protocol SPSessionPlaybackDelegate;
@protocol SPSessionAudioDeliveryDelegate;

@protocol SPPlaylistableItem <NSObject>
-(NSString *)name;
-(NSURL *)spotifyURL;
@end

@protocol SPSessionPlaybackProvider <NSObject>

@property (nonatomic, readwrite, getter=isPlaying) BOOL playing;
@property (nonatomic, readwrite, weak) id <SPSessionPlaybackDelegate> playbackDelegate;
@property (nonatomic, readwrite, weak) id <SPSessionAudioDeliveryDelegate> audioDeliveryDelegate;

-(void)preloadTrackForPlayback:(SPTrack *)aTrack callback:(SPErrorableOperationCallback)block;
-(void)playTrack:(SPTrack *)aTrack callback:(SPErrorableOperationCallback)block;
-(void)seekPlaybackToOffset:(NSTimeInterval)offset;
-(void)unloadPlayback;

@end
