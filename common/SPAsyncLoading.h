//
//  SPAsyncLoadingObserver.h
//  CocoaLibSpotify Mac Framework
//
//  Created by Daniel Kennett on 12/04/2012.
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

static NSTimeInterval const kSPAsyncLoadingDefaultTimeout = 20.0;

/** Provides standard protocol for CocoaLibSpotify metadata objects to load. */

@protocol SPAsyncLoading <NSObject>

/** Returns `YES` if the reciever has loaded its metadata, otherwise `NO`. Must be KVO-compliant. */
@property (readonly, nonatomic, getter = isLoaded) BOOL loaded;

@end

typedef enum SPAsyncLoadingPolicy {
	SPAsyncLoadingImmediate = 0, /* Immediately load items on login. */
	SPAsyncLoadingManual /* Only load items when -startLoading is called. */
} SPAsyncLoadingPolicy;

/** Provides a standard protocol for CocoaLibSpotify metadata objects that can provide child metadata in partial ranges, like playlists. */
@protocol SPPartialAsyncLoading <NSObject>

/** Fetch child items in the given range.

 @param range The range of items to retreive. Must be in the range [0..itemCount].
 @param block Callback to be called with the requested items, or an error if one occurred.
 */
-(void)fetchItemsInRange:(NSRange)range callback:(void (^)(NSError *error, NSArray *items))block;

/** Returns the number of child items the object provides. */
-(NSUInteger)itemCount;

@end


/** Provides a standard protocol for CocoaLibSpotify metadata objects to load later. */
@protocol SPDelayableAsyncLoading <SPAsyncLoading, NSObject>

/** Starts the loading process. Has no effect if the loading process has already been started. */
-(void)startLoading;

@end

/** Helper class providing a simple callback mechanism for when objects are loaded. */ 

@interface SPAsyncLoading : NSObject

/** Call the provided callback block when all passed items are loaded or the
 given timeout is reached.
 
  This will trigger a load if the item's session's loading policy is `SPAsyncLoadingManual`.
 
 The callback block will be triggered immediately if no items are provided 
 or all provided items are already loaded.
 
 @param itemOrItems A single item of an array of items conforming to the `SPAsyncLoading` protocol.
 @param timeout Time to allow before timing out. This should be the maximum reasonable time your application can wait, or `kSPAsyncLoadingDefaultTimeout`.
 @param block The block to call when all given items are loaded or the timeout is reached.
 */
+(void)waitUntilLoaded:(id)itemOrItems timeout:(NSTimeInterval)timeout then:(void (^)(NSArray *loadedItems, NSArray *notLoadedItems))block;

/** Call the provided callback block when all passed items and properties at the given key
 paths are loaded or the given timeout is reached.

 This will trigger a load if the item's session's loading policy is `SPAsyncLoadingManual`.

 The callback block will be triggered immediately if no items are provided
 or all provided items are already loaded.

 @param itemOrItems A single item of an array of items conforming to the `SPAsyncLoading` protocol.
 @param keyPathsToLoad An array of key paths to also load. The items under these paths must also conform to `SPAsyncLoading`.
 @param timeout Time to allow before timing out. This should be the maximum reasonable time your application can wait, or `kSPAsyncLoadingDefaultTimeout`.
 @param block The block to call when all given items are loaded or the timeout is reached.
 */
+(void)waitUntilLoaded:(id)itemOrItems withKeyPaths:(NSArray *)keyPathsToLoad timeout:(NSTimeInterval)timeout then:(void (^)(NSArray *completelyLoadedItems, NSArray *notLoadedItems))block;

@end
