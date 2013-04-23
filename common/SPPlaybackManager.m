//
//  SPPlaybackManager.m
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

#import "SPPlaybackManager.h"
#import "SPCoreAudioController.h"
#import "SPTrack.h"
#import "SPSession.h"
#import "SPErrorExtensions.h"

@interface SPPlaybackManager ()

@property (nonatomic, readwrite, strong) SPCoreAudioController *audioController;
@property (nonatomic, readwrite, strong) SPTrack *currentTrack;
@property (nonatomic, readwrite, strong) SPSession *playbackSession;

@property (readwrite) NSTimeInterval trackPosition;

-(void)informDelegateOfAudioPlaybackStarting;

@end

static void * const kSPPlaybackManagerKVOContext = @"kSPPlaybackManagerKVOContext"; 

@implementation SPPlaybackManager {
	NSMethodSignature *incrementTrackPositionMethodSignature;
	NSInvocation *incrementTrackPositionInvocation;
}

-(id)initWithPlaybackSession:(SPSession *)aSession {
    
    if ((self = [super init])) {
        
        self.playbackSession = aSession;
		self.playbackSession.playbackDelegate = (id)self;
		self.audioController = [[SPCoreAudioController alloc] init];
		self.audioController.delegate = self;
		self.playbackSession.audioDeliveryDelegate = self.audioController;
		
		[self addObserver:self
			   forKeyPath:@"playbackSession.playing"
				  options:0
				  context:kSPPlaybackManagerKVOContext];
	}
    return self;
}

-(id)initWithAudioController:(SPCoreAudioController *)aController playbackSession:(SPSession *)aSession {
	
	self = [self initWithPlaybackSession:aSession];
	
	if (self) {
		self.audioController = aController;
		self.audioController.delegate = self;
		self.playbackSession.audioDeliveryDelegate = self.audioController;
	}
	
	return self;
}

-(void)dealloc {
	
	[self removeObserver:self forKeyPath:@"playbackSession.playing"];
	
	self.playbackSession.playbackDelegate = nil;
	self.playbackSession = nil;
	self.currentTrack = nil;
	
	self.audioController.delegate = nil;
	self.audioController = nil;
}

+(NSSet *)keyPathsForValuesAffectingVolume {
	return [NSSet setWithObject:@"audioController.volume"];
}

-(double)volume {
	return self.audioController.volume;
}

-(void)setVolume:(double)volume {
	self.audioController.volume = volume;
}

-(void)playTrack:(SPTrack *)aTrack callback:(SPErrorableOperationCallback)block {
	
	self.playbackSession.playing = NO;
	[self.playbackSession unloadPlayback];
	[self.audioController clearAudioBuffers];
	
	if (aTrack.availability != SP_TRACK_AVAILABILITY_AVAILABLE) {
		if (block) block([NSError spotifyErrorWithCode:SP_ERROR_TRACK_NOT_PLAYABLE]);
        self.currentTrack = nil;
		self.trackPosition = 0.0;
		return;
	}
		
	self.currentTrack = aTrack;
	self.trackPosition = 0.0;
	
	[self.playbackSession playTrack:self.currentTrack callback:^(NSError *error) {
		
		if (!error)
			self.playbackSession.playing = YES;
		else
			self.currentTrack = nil;
		
		if (block) {
			block(error);
		}
	}];
}

-(void)seekToTrackPosition:(NSTimeInterval)newPosition {
	if (newPosition <= self.currentTrack.duration) {
		[self.playbackSession seekPlaybackToOffset:newPosition];
		self.trackPosition = newPosition;
	}	
}

+(NSSet *)keyPathsForValuesAffectingIsPlaying {
	return [NSSet setWithObject:@"playbackSession.playing"];
}

-(BOOL)isPlaying {
	return self.playbackSession.isPlaying;
}

-(void)setIsPlaying:(BOOL)isPlaying {
	self.playbackSession.playing = isPlaying;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
	if ([keyPath isEqualToString:@"playbackSession.playing"] && context == kSPPlaybackManagerKVOContext) {
        self.audioController.audioOutputEnabled = self.playbackSession.isPlaying;
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark -
#pragma mark Audio Controller Delegate

-(void)coreAudioController:(SPCoreAudioController *)controller didOutputAudioOfDuration:(NSTimeInterval)audioDuration {
	
	if (self.trackPosition == 0.0)
		dispatch_async(dispatch_get_main_queue(), ^{ [self.delegate playbackManagerWillStartPlayingAudio:self]; });
	
	self.trackPosition += audioDuration;
}

#pragma mark -
#pragma mark Playback Callbacks

-(void)sessionDidLosePlayToken:(SPSession *)aSession {

	// This delegate is called when playback stops because the Spotify account is being used for playback elsewhere.
	// In practice, playback is only paused and you can call [SPSession -setIsPlaying:YES] to start playback again and 
	// pause the other client.

}

-(void)sessionDidEndPlayback:(SPSession *)aSession {
	
	// This delegate is called when playback stops naturally, at the end of a track.
	
	// Not routing this through to the main thread causes odd locks and crashes.
	[self performSelectorOnMainThread:@selector(sessionDidEndPlaybackOnMainThread:)
						   withObject:aSession
						waitUntilDone:NO];
}

-(void)sessionDidEndPlaybackOnMainThread:(SPSession *)aSession {
    if ([self.delegate respondsToSelector:@selector(playbackManagerIsFinishingPlayback:)])
        [self.delegate playbackManagerIsFinishingPlayback:self];
    self.currentTrack = nil;
}


-(void)informDelegateOfAudioPlaybackStarting {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:NO];
		return;
	}
	[self.delegate playbackManagerWillStartPlayingAudio:self];
}

@end
