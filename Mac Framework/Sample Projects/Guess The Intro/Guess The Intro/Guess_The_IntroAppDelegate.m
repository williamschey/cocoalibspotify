//
//  Guess_The_IntroAppDelegate.m
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

#import "Guess_The_IntroAppDelegate.h"
#import "SPArrayExtensions.h"
#import <QuartzCore/QuartzCore.h>

#error Please get an appkey.c file from developer.spotify.com and remove this error before building.
#import "appkey.c"

static NSUInteger const kLoadingTimeout = 10;
static NSTimeInterval const kRoundDuration = 20.0;
static NSTimeInterval const kGameDuration = 60 * 5; // 5 mins
static NSTimeInterval const kGameCountdownThreshold = 30.0;

@implementation Guess_The_IntroAppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {

	NSError *error = nil;
	[SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes:&g_appkey length:g_appkey_size]
											   userAgent:@"com.spotify.GuessTheIntro"
										   loadingPolicy:SPAsyncLoadingImmediate
												   error:&error];
	if (error != nil) {
		NSLog(@"CocoaLibSpotify init failed: %@", error);
		abort();
	}

	[[SPSession sharedSession] setDelegate:self];
	self.playbackManager = [[SPPlaybackManager alloc] initWithPlaybackSession:[SPSession sharedSession]];
	self.playbackManager.delegate = self;

	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSNumber numberWithBool:YES], @"CreatePlaylist",
															 [NSNumber numberWithInteger:1], @"HighMultiplier",
															 nil]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	// Insert code here to initialize your application
	
	srandom((unsigned int)time(NULL));

	self.multiplier = 1;
	
	[self.loginView.layer setBackgroundColor:CGColorCreateGenericGray(0.93, 1.0)];
	
	self.loginView.frame = ((NSView *)self.window.contentView).bounds;
	[self.window.contentView addSubview:self.loginView];
	
	if ([[self.userNameField stringValue] length] > 0)
		[self.passwordField becomeFirstResponder];
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle:NSDateFormatterShortStyle];
	[formatter setTimeStyle:NSDateFormatterShortStyle];
	[self.playlistNameField setStringValue:[NSString stringWithFormat:@"Guess The Intro: %@", [formatter stringFromDate:[NSDate date]]]];
	
	[self.window center];
	[self.window orderFrontRegardless];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	if ([SPSession sharedSession].connectionState == SP_CONNECTION_STATE_LOGGED_OUT ||
		[SPSession sharedSession].connectionState == SP_CONNECTION_STATE_UNDEFINED) 
		return NSTerminateNow;
	
	[[SPSession sharedSession] logout:^{
		[[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
	}];
	return NSTerminateLater;
}

-(void)windowWillClose:(NSNotification *)notification {
	[NSApp terminate:self];
}

- (IBAction)login:(id)sender {
	
	// Invoked by clicking the "Login" button in the UI.
	
	if ([[self.userNameField stringValue] length] > 0 &&
		[[self.passwordField stringValue] length] > 0) {
		
		[[SPSession sharedSession] attemptLoginWithUserName:[self.userNameField stringValue]
												   password:[self.passwordField stringValue]];
	} else {
		NSBeep();
	}
}

#pragma mark -
#pragma mark SPSession Delegates

-(void)sessionDidLoginSuccessfully:(SPSession *)aSession; {
	
	// Invoked by SPSession after a successful login.
	
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:0.75];
	
	[[self.loginView animator] setAlphaValue:0.0];
	
	[NSAnimationContext endGrouping];
	
	[[self loginView] performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.0];
	
	[self.countdownProgress setIndeterminate:YES];
	[self.countdownProgress startAnimation:nil];
	
	self.regionTopList = [SPToplist toplistForLocale:aSession.locale
										   inSession:aSession];
	self.userTopList = [SPToplist toplistForCurrentUserInSession:aSession];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"CreatePlaylist"])
		[[[SPSession sharedSession] userPlaylists] createPlaylistWithName:self.playlistNameField.stringValue
																 callback:^(SPPlaylist *createdPlaylist) {
																	 self.playlist = createdPlaylist;
																 }];
	
	[self waitAndFillTrackPool];
}

-(void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error; {
    
	// Invoked by SPSession after a failed login.
	
    [NSApp presentError:error
         modalForWindow:self.window
               delegate:nil
     didPresentSelector:nil
            contextInfo:nil];
}

-(void)sessionDidLogOut:(SPSession *)aSession; {}
-(void)session:(SPSession *)aSession didEncounterNetworkError:(NSError *)error; {}
-(void)session:(SPSession *)aSession didLogMessage:(NSString *)aMessage; {}
-(void)sessionDidChangeMetadata:(SPSession *)aSession; {}

-(void)session:(SPSession *)aSession recievedMessageForUser:(NSString *)aMessage; {

	[[NSAlert alertWithMessageText:aMessage
					 defaultButton:@"OK"
				   alternateButton:@""
					   otherButton:@""
		 informativeTextWithFormat:@"This message was sent to you from the Spotify service."] runModal];
}


#pragma mark -
#pragma mark Game UI Actions

- (IBAction)guessOne:(id)sender {
	
	self.canPushOne = NO;
	[self guessTrack:self.firstSuggestion];
}

- (IBAction)guessTwo:(id)sender {
	
	self.canPushTwo = NO;
	[self guessTrack:self.secondSuggestion];
}

- (IBAction)guessThree:(id)sender {
	
	self.canPushThree = NO;
	[self guessTrack:self.thirdSuggestion];
}

- (IBAction)guessFour:(id)sender {
	
	self.canPushFour = NO;
	[self guessTrack:self.fourthSuggestion];
}

#pragma mark -
#pragma mark Finding Tracks

-(void)waitAndFillTrackPool {
	
	[SPAsyncLoading waitUntilLoaded:[SPSession sharedSession] timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedession, NSArray *notLoadedSession) {
		
		// The session is logged in and loaded — now wait for the userPlaylists to load.
		NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Session loaded.");
		
		[SPAsyncLoading waitUntilLoaded:[SPSession sharedSession].userPlaylists timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedContainers, NSArray *notLoadedContainers) {
			
			// User playlists are loaded — wait for playlists to load their metadata.
			NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Container loaded.");
			
			NSMutableArray *playlists = [NSMutableArray array];
			[playlists addObject:[SPSession sharedSession].starredPlaylist];
			[playlists addObject:[SPSession sharedSession].inboxPlaylist];
			[playlists addObjectsFromArray:[SPSession sharedSession].userPlaylists.flattenedPlaylists];

			[SPAsyncLoading waitUntilLoaded:playlists timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedPlaylists, NSArray *notLoadedPlaylists) {

				// All of our playlists have loaded their metadata — wait for all tracks to load their metadata.
				NSLog(@"[%@ %@]: %@ of %@ playlists loaded.", NSStringFromClass([self class]), NSStringFromSelector(_cmd),
					  [NSNumber numberWithInteger:loadedPlaylists.count], [NSNumber numberWithInteger:loadedPlaylists.count + notLoadedPlaylists.count]);

				[self getTracksFromPlaylists:loadedPlaylists then:^(NSSet *tracks) {

					[SPAsyncLoading waitUntilLoaded:[tracks allObjects] timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedTracks, NSArray *notLoadedTracks) {

						// All of our tracks have loaded their metadata. Hooray!
						NSLog(@"[%@ %@]: %@ of %@ tracks loaded.", NSStringFromClass([self class]), NSStringFromSelector(_cmd),
							  [NSNumber numberWithInteger:loadedTracks.count], [NSNumber numberWithInteger:loadedTracks.count + notLoadedTracks.count]);

						NSMutableArray *theTrackPool = [NSMutableArray arrayWithCapacity:loadedTracks.count];

						for (SPTrack *aTrack in loadedTracks) {
							if (aTrack.availability == SP_TRACK_AVAILABILITY_AVAILABLE && [aTrack.name length] > 0)
								[theTrackPool addObject:aTrack];
						}

						self.trackPool = [NSMutableArray arrayWithArray:[[NSSet setWithArray:theTrackPool] allObjects]];
						// ^ Thin out duplicates.

						[self startNewRound];
					}];
				}];
			}];
		}];
	}];
}

-(void)getTracksFromPlaylists:(NSArray *)playlists then:(void (^)(NSSet *tracks))block {

	__block NSMutableArray *mutablePlaylists = [NSMutableArray arrayWithArray:playlists];
	__block NSMutableSet *tracks = [NSMutableSet set];

	__block dispatch_block_t extractTracks = ^{

		if (mutablePlaylists.count == 0) {
			if (block) block([NSSet setWithSet:tracks]);
			return;
		}

		SPPlaylist *playlist = [mutablePlaylists lastObject];
		[mutablePlaylists removeObject:playlist];

		[playlist fetchItemsInRange:NSMakeRange(0, playlist.itemCount) callback:^(NSError *error, NSArray *items) {
			if (error == nil) {
				// Playlists have playlist items rather than tracks, so make sure we extract the tracks.
				[tracks addObjectsFromArray:[self tracksFromPlaylistItems:items]];
			}
			extractTracks();
		}];
	};

	extractTracks();
}

-(NSArray *)playlistsInFolder:(SPPlaylistFolder *)aFolder {
	
	NSMutableArray *playlists = [NSMutableArray arrayWithCapacity:[[aFolder playlists] count]];
	
	for (id playlistOrFolder in aFolder.playlists) {
		if ([playlistOrFolder isKindOfClass:[SPPlaylist class]]) {
			[playlists addObject:playlistOrFolder];
		} else {
			[playlists addObjectsFromArray:[self playlistsInFolder:playlistOrFolder]];
		}
	}
	return [NSArray arrayWithArray:playlists];
}

-(NSArray *)tracksFromPlaylistItems:(NSArray *)items {
	
	NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:items.count];
	
	for (SPPlaylistItem *anItem in items) {
		if (anItem.itemClass == [SPTrack class]) {
			[tracks addObject:anItem.item];
		}
	}
	
	return [NSArray arrayWithArray:tracks];
}

-(SPTrack *)trackForUserToGuessWithAlternativeOne:(SPTrack **)alternative two:(SPTrack **)anotherAlternative three:(SPTrack **)aThirdAlternative {
	
	SPTrack *theOne = nil;
	while ((!theOne.availability == SP_TRACK_AVAILABILITY_AVAILABLE) && theOne.duration < kRoundDuration) {
		theOne = [self.trackPool randomObject];
		[self.trackPool removeObject:theOne];
		
		if ([self.trackPool count] < 3) {
			// Eeek! Can't fill alternatives!
			if (alternative != NULL)
				*alternative = nil;
			if (anotherAlternative != NULL)
				*anotherAlternative = nil;
			if (aThirdAlternative != NULL)
				*aThirdAlternative = nil;
			
			return nil;
		}
	}	
	
	// Make sure we don't choose the same one more than once
	
	if (alternative != NULL) {
		*alternative = [self.trackPool randomObject];
		[self.trackPool removeObject:*alternative];
	}
	if (anotherAlternative != NULL) {
		*anotherAlternative = [self.trackPool randomObject];
		[self.trackPool removeObject:*anotherAlternative];
	}
	if (aThirdAlternative != NULL) {
		*aThirdAlternative = [self.trackPool randomObject];
		[self.trackPool removeObject:*aThirdAlternative];
	}
	
	if (alternative != NULL)
		[self.trackPool addObject:*alternative];
	if (anotherAlternative != NULL)
		[self.trackPool addObject:*anotherAlternative];
	if (aThirdAlternative != NULL)
		[self.trackPool addObject:*aThirdAlternative];
	
	return theOne;
}

#pragma mark -
#pragma mark Game Logic


-(NSTimeInterval)gameTimeRemaining {
	if (self.gameStartDate == nil)
		return 0.0;
	return kGameDuration -[[NSDate date] timeIntervalSinceDate:self.gameStartDate];
}

-(NSTimeInterval)roundTimeRemaining {
	if (self.roundStartDate == nil)
		return 0.0;
	return kRoundDuration -[[NSDate date] timeIntervalSinceDate:self.roundStartDate];
}

-(NSUInteger)currentRoundScore {
	if (self.roundStartDate == nil)
		return 0.0;
	NSTimeInterval remainingTime = [self roundTimeRemaining];
	return MAX(remainingTime * remainingTime * self.multiplier, 1.0);
}

+(NSSet *)keyPathsForValuesAffectingHideCountdown {
	return [NSSet setWithObject:@"gameTimeRemaining"];
}

-(BOOL)hideCountdown {
	return (self.gameStartDate == nil || self.gameTimeRemaining > kGameCountdownThreshold);
}

#pragma mark -

-(void)roundTimerDidTick:(NSTimer *)aTimer {
	
	if (self.roundTimeRemaining <= 0.0)
		[self roundTimeExpired];
	
	if (self.gameTimeRemaining <= 0.0)
		[self gameOverWithReason:@"Out of time!"];
	
	[self willChangeValueForKey:@"roundTimeRemaining"];
	[self didChangeValueForKey:@"roundTimeRemaining"];
	[self willChangeValueForKey:@"gameTimeRemaining"];
	[self didChangeValueForKey:@"gameTimeRemaining"];
	[self willChangeValueForKey:@"currentRoundScore"];
	[self didChangeValueForKey:@"currentRoundScore"];
}

-(void)roundTimeExpired {
	NSBeep();
	self.multiplier = 1;
	[self startNewRound];
}

#pragma mark -

-(void)guessTrack:(SPTrack *)itsTotallyThisOne {

	if (self.playbackManager.currentTrack == nil || itsTotallyThisOne == nil)
		return;
	
	if (itsTotallyThisOne == self.playbackManager.currentTrack) {
		self.score += self.currentRoundScore;
		
		if ([[NSUserDefaults standardUserDefaults] integerForKey:@"HighScore"] < self.score)
			[[NSUserDefaults standardUserDefaults] setInteger:self.score forKey:@"HighScore"];
		
		self.multiplier++;
		
		if ([[NSUserDefaults standardUserDefaults] integerForKey:@"HighMultiplier"] < self.multiplier)
			[[NSUserDefaults standardUserDefaults] setInteger:self.multiplier forKey:@"HighMultiplier"];
		
		[self startNewRound];
	} else {
		NSBeep();
		self.multiplier = 1;
		self.roundStartDate = [NSDate dateWithTimeInterval:-(kRoundDuration / 4) sinceDate:self.roundStartDate];
	}
}

-(void)startNewRound {
	
	if (self.playbackManager.currentTrack != nil) {
		[self.playlist addItem:self.playbackManager.currentTrack atIndex:self.playlist.itemCount callback:^(NSError *error) {
			if (error) NSLog(@"%@", error);
		}];
	}
	
	// Starting a new round means resetting, selecting tracks then starting the timer again 
	// when the audio starts playing.
	
	self.playbackManager.isPlaying = NO;
	self.firstSuggestion = nil;
	self.secondSuggestion = nil;
	self.thirdSuggestion = nil;
	self.fourthSuggestion = nil;
	self.roundStartDate = nil;
	
	[self.countdownProgress setIndeterminate:YES];
	
	[self.roundTimer invalidate];
	self.roundTimer = nil;
	
	SPTrack *one = nil;
	SPTrack *two = nil;
	SPTrack *three = nil;
	SPTrack *theOne = [self trackForUserToGuessWithAlternativeOne:&one two:&two three:&three];
	
	if (theOne != nil) {
		
		NSMutableArray *array = [NSMutableArray arrayWithObjects:theOne, one, two, three, nil];
		self.firstSuggestion = [array randomObject];
		[array removeObject:self.firstSuggestion];
		self.secondSuggestion = [array randomObject];
		[array removeObject:self.secondSuggestion];
		self.thirdSuggestion = [array randomObject];
		[array removeObject:self.thirdSuggestion];
		self.fourthSuggestion = [array randomObject];
		[array removeObject:self.fourthSuggestion];
		
		//Disable buttons until playback starts
		self.canPushOne = NO;
		self.canPushTwo = NO;
		self.canPushThree = NO;
		self.canPushFour = NO;
		
		[self startPlaybackOfTrack:theOne];
		
	} else {
		
		[self gameOverWithReason:@"Out of tracks!"];
	}
}

-(void)gameOverWithReason:(NSString *)reason {
	
	self.playbackManager.isPlaying = NO;
	self.firstSuggestion = nil;
	self.secondSuggestion = nil;
	self.thirdSuggestion = nil;
	self.fourthSuggestion = nil;
	self.roundStartDate = nil;
	self.gameStartDate = nil;
	
	[self.countdownProgress setIndeterminate:YES];
	
	[self.roundTimer invalidate];
	self.roundTimer = nil;

	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	[formatter setFormat:@"#,###,###,###,##0"];
	
	NSInteger result = [[NSAlert alertWithMessageText:reason
					 defaultButton:@"Again!"
				   alternateButton:@"Quit"
					   otherButton:@""
		 informativeTextWithFormat:@"You scored %@ points!", [formatter stringFromNumber:[NSNumber numberWithInteger:self.score]]]
	 runModal];
	
	if (result == NSAlertDefaultReturn) {
		self.score = 0;
		self.multiplier = 1;
		[self waitAndFillTrackPool];
	} else {
		[NSApp terminate:self];
	}
}

#pragma mark -
#pragma mark Playback

- (void)startPlaybackOfTrack:(SPTrack *)aTrack {
	
	[SPAsyncLoading waitUntilLoaded:aTrack timeout:5.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
		[self.playbackManager playTrack:aTrack callback:^(NSError *error) {
			if (error) [self.window presentError:error];
		}];
	}];
}

-(void)playbackManagerWillStartPlayingAudio:(SPPlaybackManager *)aPlaybackManager {

	[self.countdownProgress setIndeterminate:NO];
	
	self.roundStartDate = [NSDate date];
	if (self.gameStartDate == nil)
		self.gameStartDate = self.roundStartDate;
	
	self.roundTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
													   target:self
													 selector:@selector(roundTimerDidTick:)
													 userInfo:nil
													  repeats:YES];
	
	self.canPushOne = YES;
	self.canPushTwo = YES;
	self.canPushThree = YES;
	self.canPushFour = YES;

}

-(void)playbackManagerIsFinishingPlayback:(SPPlaybackManager *)aPlaybackManager {}

@end
