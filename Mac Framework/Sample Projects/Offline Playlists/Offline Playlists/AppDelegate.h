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

@interface AppDelegate : NSObject <NSApplicationDelegate, SPSessionDelegate, NSTableViewDataSource>

@property (unsafe_unretained) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSSlider *playbackProgressSlider;
@property (weak) IBOutlet NSTextField *userNameField;
@property (weak) IBOutlet NSSecureTextField *passwordField;
@property (unsafe_unretained) IBOutlet NSPanel *loginSheet;
@property (weak) IBOutlet NSTableView *trackTable;
@property (weak) IBOutlet NSArrayController *playlistArrayController;

@property (nonatomic, strong, readwrite) SPPlaylist *selectedPlaylist;
@property (nonatomic, strong, readwrite) SPSparseList *sparseArray;

-(SPSession *)session;

- (IBAction)login:(id)sender;
- (IBAction)quitFromLoginSheet:(id)sender;

#pragma mark -

@property (nonatomic, readwrite, strong) SPPlaybackManager *playbackManager;

- (IBAction)seekToPosition:(id)sender;
- (IBAction)togglePlayPause:(id)sender;

@end
