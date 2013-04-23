//
//  SPPostTracksToInboxOperation.h
//  CocoaLibSpotify
//
//  Created by Daniel Kennett on 4/24/11.
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

/** This class provides functionality for sending tracks to another Spotify user. */

#import <Foundation/Foundation.h>
#import "CocoaLibSpotifyPlatformImports.h"

@class SPSession;
@protocol SPPostTracksToInboxOperationDelegate;

@interface SPPostTracksToInboxOperation : NSObject

///----------------------------
/// @name Creating and Initializing Track Post Operations
///----------------------------

/** Creates an SPPostTracksToInboxOperation for the given details.
 
 This convenience method is simply returns a new, autoreleased SPPostTracksToInboxOperation
 object. No caching is performed.
 
 @warning Tracks will be posted to the given user as soon as a SPPostTracksToInboxOperation
 object is created. Be sure you want to post the tracks before creating the object!
 
 @param tracksToSend An array of SPTrack objects to send.
 @param user The username of the user to send the tracks to.
 @param aFriendlyGreeting The message to send with the tracks, if any.
 @param aSession The session to send the tracks with.
 @param block The `SPErrorableOperationCallback` block to be called with an `NSError` if the operation failed or `nil` if the operation succeeded.
 @return Returns the created SPPostTracksToInboxOperation object. 
 */
+(SPPostTracksToInboxOperation *)sendTracks:(NSArray *)tracksToSend
									 toUser:(NSString *)user 
									message:(NSString *)aFriendlyGreeting
								  inSession:(SPSession *)aSession
								   callback:(SPErrorableOperationCallback)block;

/** Initializes an SPPostTracksToInboxOperation for the given details.
 
 @warning Tracks will be posted to the given user as soon as a SPPostTracksToInboxOperation
 object is created. Be sure you want to post the tracks before creating the object!
 
 @param tracksToSend An array of SPTrack objects to send.
 @param user The username of the user to send the tracks to.
 @param aFriendlyGreeting The message to send with the tracks, if any.
 @param aSession The session to send the tracks with.
 @param block The `SPErrorableOperationCallback` block to be called with an `NSError` if the operation failed or `nil` if the operation succeeded.
 @return Returns the created SPPostTracksToInboxOperation object. 
 */
-(id)initBySendingTracks:(NSArray *)tracksToSend
				  toUser:(NSString *)user 
				 message:(NSString *)aFriendlyGreeting
			   inSession:(SPSession *)aSession
				callback:(SPErrorableOperationCallback)block;

///----------------------------
/// @name Properties
///----------------------------

/** Returns the username of the user the tracks the operation is sending tracks to. */
@property (nonatomic, readonly, copy) NSString *destinationUser;

/** Returns the opaque structure used by the C LibSpotify API. 
 
 @warning This method *must* be called on the libSpotify thread. See the
 "Threading" section of the library's readme for more information.
 
 @warning This should only be used if you plan to directly use the 
 C LibSpotify API. The behaviour of CocoaLibSpotify is undefined if you use the C
 API directly on items that have CocoaLibSpotify objects associated with them. 
 */
@property (nonatomic, readonly, assign) sp_inbox *inboxOperation;

/** Returns the message being sent. */
@property (nonatomic, readonly, copy) NSString *message;

/** Returns the session the tracks are being sent in. */
@property (nonatomic, readonly, strong) SPSession *session;

/** Returns the tracks being sent. */
@property (nonatomic, readonly, copy) NSArray *tracks;

@end