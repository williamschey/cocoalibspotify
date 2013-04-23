//
//  Guess_The_IntroAppDelegate.h
//  Guess The Intro
//
//  Created by Daniel Kennett on 05/05/2011.
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

@interface Guess_The_IntroAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, SPSessionDelegate, SPPlaybackManagerDelegate> {
	
@private
	
	NSTextField *__weak userNameField;
	NSSecureTextField *__weak passwordField;
	NSTextField *__weak playlistNameField;
	NSView *__weak loginView;
	
	NSWindow *__unsafe_unretained window;
	NSButton *__weak oneButton;
	NSButton *__weak twoButton;
	NSButton *__weak threeButton;
	NSButton *__weak fourButton;
	NSProgressIndicator *__weak countdownProgress;
	
	NSUInteger loginAttempts;
	
	SPPlaylist *playlist;
	
	SPPlaybackManager *playbackManager;
	
	SPToplist *regionTopList;
	SPToplist *userTopList;
	
	NSMutableArray *trackPool;
	SPTrack *firstSuggestion;
	SPTrack *secondSuggestion;
	SPTrack *thirdSuggestion;
	SPTrack *fourthSuggestion;
	
	BOOL canPushOne;
	BOOL canPushTwo;
	BOOL canPushThree;
	BOOL canPushFour;
	
	NSTimer *roundTimer;
	
	NSUInteger multiplier; // Reset every time a wrong guess is made.
	NSUInteger score; // The current score
	NSDate *roundStartDate; // The time at which the current round started. Round score = (kRoundTime - seconds from this date) * multiplier.
	NSDate *gameStartDate;
}

@property (weak) IBOutlet NSTextField *userNameField;
@property (weak) IBOutlet NSSecureTextField *passwordField;
@property (weak) IBOutlet NSTextField *playlistNameField;
@property (weak) IBOutlet NSView *loginView;

@property (nonatomic, readwrite, strong) SPPlaybackManager *playbackManager;

@property (nonatomic, readwrite, strong) SPPlaylist	*playlist;

- (IBAction)login:(id)sender;

@property (unsafe_unretained) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *oneButton;
@property (weak) IBOutlet NSButton *twoButton;
@property (weak) IBOutlet NSButton *threeButton;
@property (weak) IBOutlet NSButton *fourButton;
@property (weak) IBOutlet NSProgressIndicator *countdownProgress;

@property (nonatomic, strong, readwrite) SPToplist *regionTopList;
@property (nonatomic, strong, readwrite) SPToplist *userTopList;

@property (nonatomic, strong, readwrite) SPTrack *firstSuggestion;
@property (nonatomic, strong, readwrite) SPTrack *secondSuggestion;
@property (nonatomic, strong, readwrite) SPTrack *thirdSuggestion;
@property (nonatomic, strong, readwrite) SPTrack *fourthSuggestion;

@property (nonatomic, readwrite) BOOL canPushOne;
@property (nonatomic, readwrite) BOOL canPushTwo;
@property (nonatomic, readwrite) BOOL canPushThree;
@property (nonatomic, readwrite) BOOL canPushFour;

@property (nonatomic, readwrite) NSUInteger multiplier;
@property (nonatomic, readwrite) NSUInteger score;
@property (nonatomic, readwrite, copy) NSDate *roundStartDate;
@property (nonatomic, readwrite, copy) NSDate *gameStartDate;
@property (nonatomic, readwrite, strong) NSMutableArray *trackPool;
@property (nonatomic, readwrite, strong) NSTimer *roundTimer;

// Calculated Properties
@property (nonatomic, readonly) NSTimeInterval roundTimeRemaining;
@property (nonatomic, readonly) NSTimeInterval gameTimeRemaining;
@property (nonatomic, readonly) NSUInteger currentRoundScore;
@property (nonatomic, readonly) BOOL hideCountdown;

- (IBAction)guessOne:(id)sender;
- (IBAction)guessTwo:(id)sender;
- (IBAction)guessThree:(id)sender;
- (IBAction)guessFour:(id)sender;

// Getting tracks 

-(void)waitAndFillTrackPool;
-(NSArray *)playlistsInFolder:(SPPlaylistFolder *)aFolder;
-(NSArray *)tracksFromPlaylistItems:(NSArray *)items;

// Getting tracks

-(SPTrack *)trackForUserToGuessWithAlternativeOne:(SPTrack **)alternative two:(SPTrack **)anotherAlternative three:(SPTrack **)aThirdAlternative;

// Game logic

-(void)guessTrack:(SPTrack *)itsTotallyThisOne;
-(void)roundTimeExpired;
-(void)startNewRound;
-(void)gameOverWithReason:(NSString *)reason;

-(void)startPlaybackOfTrack:(SPTrack *)aTrack;

@end
