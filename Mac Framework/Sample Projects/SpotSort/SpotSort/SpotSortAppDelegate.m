//
//  SimplePlayerAppDelegate.m
//  SimplePlayer
//
//  Created by Daniel Kennett on 04/05/2011.
/*
 Copyright (c) 2011, Spotify AB
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of Spotify AB nor the names of its contributors may 
 be used to endorse or promote products derived from this software 
 without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL SPOTIFY AB BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SpotSortAppDelegate.h"
#include "appkey.c"

@implementation SpotSortAppDelegate

@synthesize trackURLField;
@synthesize userNameField;
@synthesize passwordField;
@synthesize loginSheet;
@synthesize window;
@synthesize playbackManager;

@synthesize playlists;
@synthesize playlistController;
@synthesize sortButton;
@synthesize logWindow;

-(void)applicationWillFinishLaunching:(NSNotification *)notification {

	NSError *error = nil;
	[SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes:&g_appkey length:g_appkey_size]
											   userAgent:@"com.spotify.SimplePlayer"
										   loadingPolicy:SPAsyncLoadingManual
												   error:&error];
	if (error != nil) {
		NSLog(@"CocoaLibSpotify init failed: %@", error);
		abort();
	}

	[[SPSession sharedSession] setDelegate:self];
	self.playbackManager = [[SPPlaybackManager alloc] initWithPlaybackSession:[SPSession sharedSession]];

	[self.window center];
	[self.window orderFront:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
	
	[self addObserver:self
		   forKeyPath:@"playbackManager.trackPosition"
			  options:0
			  context:nil];
	
	[NSApp beginSheet:self.loginSheet
	   modalForWindow:self.window
		modalDelegate:nil
	   didEndSelector:nil 
		  contextInfo:nil];
    
    NSArray *usernames = [SSKeychain accountsForService:@"SpotSort"];
    NSDictionary *usernameDic = [usernames objectAtIndexedSubscript:0];
    NSString *username = [usernameDic objectForKey:@"acct"];
    if (username != nil) {
        [userNameField setStringValue:username];
    
        NSString *password = [SSKeychain passwordForService:@"SpotSort" account:username];
        if (password != nil)
            [passwordField setStringValue:password];
    }
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	// Invoked when the current playback position changed (see below). This is a bit of a workaround
	// to make sure we don't update the position slider while the user is dragging it around. If the position
	// slider was read-only, we could just bind its value to playbackManager.trackPosition.
	
    if ([keyPath isEqualToString:@"userPlaylists"]) {
        playlistContainer = [session userPlaylists];
        
        [session flushCaches:nil];
        [playlistContainer startLoading];
        
        [playlistContainer addObserver:self
               forKeyPath:@"playlists"
                  options:0
                  context:nil];
        
        
        [session removeObserver:self forKeyPath:@"userPlaylists"];
        
        //[playlists bind:@"arrangedObjects" toObject:@"playlistContainer.playlists" withKeyPath:@"name" options:nil];
        
    } else if ([keyPath isEqualToString:@"playlists"]) {
        
        [self loadPlaylists:[playlistContainer playlists]];
        
        [playlistContainer removeObserver:self forKeyPath:@"playlists"];
        
        //[playlists bind:@"arrangedObjects" toObject:@"playlistContainer.playlists" withKeyPath:@"name" options:nil];
        
    } else if ([keyPath isEqualToString:@"name"]) {
        
        if ([(SPPlaylist *)object owner] == [session user]) {
        
            [playlists addObject:(SPPlaylist *)object];
            
            [playlistController setContent:playlists];
            
            [sortButton setEnabled:true];
        }
        
        [(SPPlaylist *)object removeObserver:self forKeyPath:@"name"];
        
        
        //[playlists bind:@"arrangedObjects" toObject:@"playlistContainer.playlists" withKeyPath:@"name" options:nil];
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)loadPlaylists:(NSArray *)playlistItems {
    for (id playlist in playlistItems) {
        if ([playlist class] == [SPPlaylist class]) {
            [playlist startLoading];
            [playlist addObserver:self
                       forKeyPath:@"name"
                          options:0
                          context:nil];
        }
        if ([playlist class] == [SPPlaylistFolder class]) {
            [self loadPlaylists:[(SPPlaylistFolder *)playlist playlists]];
        }
    }
    
}

-(void)logToWindow:(NSString *)msg; {    
    NSAttributedString* attr = [[NSAttributedString alloc] initWithString:[msg stringByAppendingString:@"\n"]];
    [[logWindow textStorage] appendAttributedString:attr];
    [logWindow scrollRangeToVisible:NSMakeRange([[logWindow string] length], 0)];
}

- (IBAction)quitFromLoginSheet:(id)sender {
	
	// Invoked by clicking the "Quit" button in the UI.
	
	[NSApp endSheet:self.loginSheet];
	[NSApp terminate:self];
}

- (IBAction)login:(id)sender {
	
	// Invoked by clicking the "Login" button in the UI.
	
	if ([[userNameField stringValue] length] > 0 && 
		[[passwordField stringValue] length] > 0) {
		
		[[SPSession sharedSession] attemptLoginWithUserName:[userNameField stringValue]
												   password:[passwordField stringValue]];
	} else {
		NSBeep();
	}
}

#pragma mark -
#pragma mark SPSessionDelegate Methods

-(void)sessionDidLoginSuccessfully:(SPSession *)aSession; {
    
    // Save Info
    NSError *error = nil;
    [SSKeychain setPassword:[passwordField stringValue] forService:@"SpotSort" account:[userNameField stringValue] error:&error];
	
	// Invoked by SPSession after a successful login.
	
	[self.loginSheet orderOut:self];
	[NSApp endSheet:self.loginSheet];
    
    //[playlists addObjectsFromArray:[[aSession userPlaylists] playlists]];
    
    [self logToWindow:@"Logged in Successfully"];
    
    session = aSession;
    
    [session addObserver:self
		   forKeyPath:@"userPlaylists"
			  options:0
			  context:nil];
    
    playlists = [[NSMutableArray alloc] init];
    
    [playlistController setContent:playlists];
    
}

-(void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error; {
    
	// Invoked by SPSession after a failed login.
	
    [NSApp presentError:error
         modalForWindow:self.loginSheet
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

- (IBAction)sortPlaylistsAction:(id)sender {
    do {
        usleep(200);
    } while (![playlistContainer isLoaded]);
    [self sortPlaylists:[playlistContainer playlists] withParent:playlistContainer];
    
}

- (void)sortPlaylists:(NSArray *)playlistItems withParent:(id)parent {
    NSMutableArray *unsortedItems = [playlistItems mutableCopy];
    
    NSArray *sortedItems = [unsortedItems sortedArrayUsingComparator:
                            ^NSComparisonResult(id obj1, id obj2) {
                                
                                NSString *itm1Name = nil;
                                
                                NSString *itm2Name = nil;
                                
                                if ([obj1 class] == [SPPlaylist class]) {
                                    itm1Name = [(SPPlaylist *)obj1 name];
                                    
                                }
                                
                                if ([obj1 class] == [SPPlaylistFolder class]) {
                                    itm1Name = [(SPPlaylistFolder *)obj1 name];
                                    
                                }
                                
                                if ([obj2 class] == [SPPlaylist class]) {
                                    itm2Name = [(SPPlaylist *)obj2 name];
                                    
                                }
                                if ([obj2 class] == [SPPlaylistFolder class]) {
                                    itm2Name = [(SPPlaylistFolder *)obj2 name];
                                    
                                }
                                
                                return [itm1Name caseInsensitiveCompare:itm2Name];
                            }];
    
    [self sortTheseTracksFrom:unsortedItems to:sortedItems atIndex:0 withParent:parent andChangesOccured:false];
}


- (void)sortTheseTracksFrom:(NSMutableArray *)unsortedItems to:(NSArray *)sortedItems atIndex:(NSUInteger)currentIndex withParent:(id)parent andChangesOccured:(Boolean) changesOccured {
    Boolean isMoving = false;
    
    NSString *parentName = nil;
    
    if ([parent class] == [SPPlaylist class]) {
        parentName = [(SPPlaylist *)parent name];
        
    }
    
    if ([parent class] == [SPPlaylistFolder class]) {
        parentName = [(SPPlaylistFolder *)parent name];
    }
    
    [self logToWindow:[NSString stringWithFormat:@"Sorting '%@'",parentName]];
    
    while ((!isMoving) && (currentIndex < [unsortedItems count])) {
        
        id item = [unsortedItems objectAtIndex:currentIndex];
        NSUInteger newIndex = [sortedItems indexOfObject:item];
        
        NSString *itmName = nil;
        
        if ([item class] == [SPPlaylist class]) {
            itmName = [(SPPlaylist *)item name];
            
        }
        
        if ([item class] == [SPPlaylistFolder class]) {
            itmName = [(SPPlaylistFolder *)item name];
        }
        
        
        if (currentIndex != newIndex) {
            NSLog(@"moving playlist from %zd to %zd",currentIndex, newIndex);
            
            __block NSUInteger currentIndexCopy = currentIndex;
            __block NSMutableArray *unsortedItemsCopy = [unsortedItems copy];
            NSUInteger newIndexCopy = newIndex+1;
            
            id parentCopy = nil;
            if ([parent class] != [SPPlaylistContainer class]) {
                parentCopy = parent;
            }
            
            [self logToWindow:[NSString stringWithFormat:@"Moving playlist '%@' from %zd to %zd with parent '%@'",itmName, currentIndex, newIndex, parentName]];
            [playlistContainer moveItem:item toIndex:newIndexCopy ofNewParent:parentCopy callback:^(NSError * error)
             {
                 [session flushCaches:nil];
                 [playlistContainer startLoading];
                 do {
                     usleep(200);
                 } while (![playlistContainer isLoaded]);
                 
                 unsortedItemsCopy = [[parent playlists] mutableCopy];
                 
                 currentIndexCopy++;
                 [self sortTheseTracksFrom:unsortedItemsCopy to:sortedItems atIndex:currentIndexCopy withParent:parent andChangesOccured:true];
             }];
            
            if (newIndex < [unsortedItems count]) {
                [unsortedItems removeObjectAtIndex:currentIndex];
                [unsortedItems insertObject:item atIndex:newIndex];
            }
            isMoving = true;
        }
        currentIndex++;
    }
    
    if (currentIndex >= [unsortedItems count]) {
        if (changesOccured) {
            [self sortTheseTracksFrom:unsortedItems to:sortedItems atIndex:0 withParent:parent andChangesOccured:false]; //keep sorting until all changes have bubbled up
        } else {
            for (id item in unsortedItems) {
                if ([item class] == [SPPlaylistFolder class]) {
                    [self sortPlaylists:[(SPPlaylistFolder *)item playlists] withParent:item];
                }
            }
        }
    }
}


- (IBAction)sortTracks:(id)sender {
    
    NSArray *selectPlaylists = [playlistController selectedObjects];
    
    for (SPPlaylist *playlist in selectPlaylists) {
        
        NSLog(@"Sorting playlist %@", [playlist name]);
        
        
        [self logToWindow:[NSString stringWithFormat:@"Sorting playlist %@", [playlist name]]];
        
        
        NSMutableArray *unsortedItems = [[playlist items] mutableCopy];
        
        NSArray *sortedItems = [unsortedItems sortedArrayUsingComparator:
                                ^NSComparisonResult(id obj1, id obj2) {
                                    
                                    SPPlaylistItem *itm1 = (SPPlaylistItem *)obj1;
                                    SPPlaylistItem *itm2 = (SPPlaylistItem *)obj2;
                                    
                                    NSString *itm1Artist = nil;
                                    NSString *itm1Album = nil;
                                    NSUInteger *itm1Track = nil;
                                    
                                    NSString *itm2Artist = nil;
                                    NSString *itm2Album = nil;
                                    NSUInteger *itm2Track = nil;
                                    
                                    if ([itm1 itemClass] == [SPTrack class]) {
                                        itm1Artist = [[[(SPTrack *)[itm1 item] album] artist] name];
                                        itm1Album = [[(SPTrack *)[itm1 item] album] name];
                                        itm1Track = [(SPTrack *)[itm1 item] trackNumber];
                                        
                                    }
                                    
                                    if ([itm1 itemClass] == [SPAlbum class]) {
                                        itm1Artist = [[(SPAlbum *)[itm1 item] artist] name];
                                        itm1Album = [(SPAlbum *)[itm1 item] name];
                                        
                                    }
                                    
                                    if ([itm2 itemClass] == [SPTrack class]) {
                                        itm2Artist = [[[(SPTrack *)[itm2 item] album] artist] name];
                                        itm2Album = [[(SPTrack *)[itm2 item] album] name];
                                        itm2Track = [(SPTrack *)[itm2 item] trackNumber];
                                        
                                    }
                                    
                                    if ([itm2 itemClass] == [SPAlbum class]) {
                                        itm2Artist = [[(SPAlbum *)[itm2 item] artist] name];
                                        itm2Album = [(SPAlbum *)[itm2 item] name];
                                    }
                                    
                                    if ([itm1Artist compare:itm2Artist] == NSOrderedSame) {
                                        if ([itm1Album compare:itm2Album] == NSOrderedSame) {
                                            if (itm1Track < itm2Track) {
                                                return NSOrderedAscending;
                                            } else if (itm1Track == itm2Track) {
                                                return NSOrderedSame;
                                            } else {
                                                return NSOrderedDescending;
                                            }
                                        } else {
                                            return [itm2Album compare:itm2Album];
                                        }
                                    } else {
                                        return [itm1Artist compare:itm2Artist];
                                    }
                                    
                                    return NSOrderedSame;
                                }];
        
        for (SPPlaylistItem *item in sortedItems) {
            NSUInteger *currentIndex = [unsortedItems indexOfObject:item];
            NSUInteger *newIndex = [sortedItems indexOfObject:item];
            if (currentIndex != newIndex) {
                NSLog(@"moving item from %zd to %zd",currentIndex, newIndex);
                
                NSString *itmArtist = nil;
                NSString *itmAlbum = nil;
                NSUInteger *itmTrack = nil;
                
                if ([item itemClass] == [SPTrack class]) {
                    itmArtist = [[[(SPTrack *)[item item] album] artist] name];
                    itmAlbum = [[(SPTrack *)[item item] album] name];
                    itmTrack = [(SPTrack *)[item item] trackNumber];
                    
                }
                
                if ([item itemClass] == [SPAlbum class]) {
                    itmArtist = [[(SPAlbum *)[item item] artist] name];
                    itmAlbum = [(SPAlbum *)[item item] name];
                }
                
                [self logToWindow:[NSString stringWithFormat:@"Moving '%@'-'%@' (%zd) from %zd to %zd",itmArtist, itmAlbum, itmTrack, currentIndex, newIndex]];
                NSIndexSet *currentIndexSet = [NSIndexSet indexSetWithIndex:currentIndex];
                [playlist moveItemsAtIndexes:currentIndexSet toIndex:newIndex callback:nil];
                [unsortedItems removeObjectAtIndex:currentIndex];
                [unsortedItems insertObject:item atIndex:newIndex];
            }
        }
        NSLog(@"Finished sorting playlist %@", [playlist name]);
        
    }
	
	
	NSBeep();
}

@end
