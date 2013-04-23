//
//  SPPostTracksToInboxOperation.m
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

#import "SPPostTracksToInboxOperation.h"
#import "SPSession.h"
#import "SPErrorExtensions.h"
#import "SPTrack.h"

@interface SPPostTracksToInboxOperation ()

@property (nonatomic, readwrite, strong) SPSession *session;
@property (nonatomic, readwrite, copy) NSString *destinationUser;
@property (nonatomic, readwrite, copy) NSArray *tracks;
@property (nonatomic, readwrite, copy) NSString *message;

@property (nonatomic, readwrite, assign) sp_inbox *inboxOperation;
@property (nonatomic, readwrite, copy) SPErrorableOperationCallback completionBlock;

@end

void inboxpost_complete(sp_inbox *result, void *userdata);
void inboxpost_complete(sp_inbox *result, void *userdata) {
	
	@autoreleasepool {
		SPPostTracksToInboxOperation *operation = (__bridge_transfer SPPostTracksToInboxOperation *)userdata;
		sp_error errorCode = sp_inbox_error(result);
		
		if (operation.inboxOperation != NULL) {
			sp_inbox_release(operation.inboxOperation);
			operation.inboxOperation = NULL;
		}
		
		NSError *error = nil;
		if (errorCode != SP_ERROR_OK)
			error = [NSError spotifyErrorWithCode:errorCode];

		if (operation.completionBlock) {
			dispatch_async(dispatch_get_main_queue(), ^{
				operation.completionBlock(error);
				operation.completionBlock = nil;
			});
		}
	}
}

@implementation SPPostTracksToInboxOperation

+(SPPostTracksToInboxOperation *)sendTracks:(NSArray *)tracksToSend
									 toUser:(NSString *)user 
									message:(NSString *)aFriendlyGreeting
								  inSession:(SPSession *)aSession
								   callback:(SPErrorableOperationCallback)block {
	
	return [[SPPostTracksToInboxOperation alloc] initBySendingTracks:tracksToSend
															   toUser:user
															  message:aFriendlyGreeting
															inSession:aSession
															 callback:block];
}

-(id)initBySendingTracks:(NSArray *)tracksToSend
				  toUser:(NSString *)user 
				 message:(NSString *)aFriendlyGreeting
			   inSession:(SPSession *)aSession
				callback:(SPErrorableOperationCallback)block {

	if ((self = [super init])) {
		
		if (aSession != nil && [tracksToSend count] > 0 && [user length] > 0) {
			
			self.session = aSession;
			self.destinationUser = user;
			self.message = aFriendlyGreeting;
			self.tracks = tracksToSend;
			self.completionBlock = block;
			
			SPDispatchAsync(^{
				
				int trackCount = (int)self.tracks.count;
				sp_track *trackArray[trackCount];
				
				for (NSUInteger i = 0; i < trackCount; i++) {
					trackArray[i] = [(SPTrack *)[self.tracks objectAtIndex:i] track];
				}
				
				sp_track *const *trackArrayPtr = (sp_track *const *)&trackArray;
				
				self.inboxOperation = sp_inbox_post_tracks(aSession.session, 
														   [user UTF8String],
														   trackArrayPtr, 
														   trackCount, 
														   [aFriendlyGreeting UTF8String], 
														   &inboxpost_complete, 
														   (__bridge_retained void *)(self));
			});
			
			
		} else {
			return nil;
		}
	}
	return self;
}

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: Sending to %@: %@", [super description], self.destinationUser, self.tracks];
}

-(sp_inbox *)inboxOperation {
#if DEBUG
	SPAssertOnLibSpotifyThread();
#endif
	return _inboxOperation;
}

- (void)dealloc {
	self.completionBlock = nil;
}

@end
