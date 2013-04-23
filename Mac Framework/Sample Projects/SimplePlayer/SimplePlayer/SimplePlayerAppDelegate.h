//
//  SimplePlayerAppDelegate.h
//  SimplePlayer
//
//  Created by Daniel Kennett on 04/05/2011.
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

#import <Cocoa/Cocoa.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@interface SimplePlayerAppDelegate : NSObject  <NSApplicationDelegate, SPSessionDelegate> {
@private
	NSWindow *__unsafe_unretained window;
	NSPanel *__unsafe_unretained loginSheet;
	NSTextField *__weak userNameField;
	NSSecureTextField *__weak passwordField;
	NSTimeInterval currentTrackPosition;
	
	SPPlaybackManager *playbackManager;
	NSTextField *__weak trackURLField;
	NSSlider *__weak playbackProgressSlider;
}

@property (weak) IBOutlet NSSlider *playbackProgressSlider;
@property (weak) IBOutlet NSTextField *trackURLField;
@property (weak) IBOutlet NSTextField *userNameField;
@property (weak) IBOutlet NSSecureTextField *passwordField;
@property (unsafe_unretained) IBOutlet NSPanel *loginSheet;
@property (unsafe_unretained) IBOutlet NSWindow *window;

- (IBAction)login:(id)sender;
- (IBAction)quitFromLoginSheet:(id)sender;

#pragma mark -

@property (nonatomic, readwrite, strong) SPPlaybackManager *playbackManager;

- (IBAction)playTrack:(id)sender;
- (IBAction)seekToPosition:(id)sender;

@end
