//
//  SPSparseArray.h
//  CocoaLibSpotify Mac Framework
//
//  Created by Daniel Kennett on 16/04/2013.
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
#import "SPAsyncLoading.h"

/**
 Provides a helper class for working with objects that conform to the
 `SPPartialAsyncLoading` protocol, such as playlists. This class assists
 with fetching child objects from `SPPartialAsyncLoading` classes and
 managing them in a list.
 */

@interface SPSparseList : NSObject

/** Initialise the list with a default batch size with the given data source, 
 which must conform to the `SPPartialAsyncLoading` protocol.
 
 @param dataSource The data source for this list.
 @return The initialised list.
 */
-(id)initWithDataSource:(id <SPPartialAsyncLoading>)dataSource;

/** Initialise the list with the given data source, which must conform
 to the `SPPartialAsyncLoading` protocol.
 
 The batch size parameter defines the minimum suggested number of
 items to request at a time from the data source. This is done to increase
 performance when a large number of small loading requests are made,
 such as from a table view data source. For best results, set the value to
 a number slightly larger than a "screenful" of data for your application. If 
 you're unsure, simply call `initWithDataSource:` instead and the class will
 choose a sensible default.

 @note This is the designated initialiser for this class.

 @param dataSource The data source for this list.
 @param batchSize The batch size to use.
 @return The initialised list.
 */
-(id)initWithDataSource:(id <SPPartialAsyncLoading>)dataSource batchSize:(NSUInteger)batchSize;

///----------------------------
/// @name Item Loading and Unloading
///----------------------------

/** Returns the batch size of the instance — that is, the typical minimum number of objects the list will request from its data source at once. */
@property (nonatomic, readonly) NSUInteger batchSize;

/** Load objects in the given range.
 
 @note Objects in the given range that are already loaded will be replaced. This
 is useful if you know the object in the list's data source has changed.
 
 @param range The range to load objects in.
 @param block The block to be called when the objects are loaded.
 */
-(void)loadObjectsInRange:(NSRange)range callback:(dispatch_block_t)block;

/** Unload objects in the given range.
 
 For memory usage reasons, it's wise to unload objects you no longer need.

 @param range The range of the objects to unload. Items in this range that aren't loaded will be unaffected.
 */
-(void)unloadObjectsInRange:(NSRange)range;

/** Unload objects at the given indexes.

 For memory usage reasons, it's wise to unload objects you no longer need.

 @param indexes The indexes of the objects to unload. Items in these indexes that aren't loaded will be unaffected.
 */
-(void)unloadObjectsAtIndexes:(NSIndexSet *)indexes;

///----------------------------
/// @name Accessing Objects
///----------------------------

/** Returns `YES` if the list contains a loaded object that's equal to the given object. */
-(BOOL)containsObject:(id)object;

/** Returns the number of items the list represents, including both loaded and unloaded items. */
-(NSUInteger)count;

/** Returns the last object in the list, or `nil` if that item hasn't been loaded yet. */
-(id)lastObject;

/** Returns the object in the list at the given `index`, or `nil` if that item hasn't been loaded yet. */
-(id)objectAtIndex:(NSUInteger)index;

/** Returns the object in the list at the given `index`, or `nil` if that item hasn't been loaded yet. */
-(id)objectAtIndexedSubscript:(NSUInteger)index;

/** Returns the objects in the list at the given indexes. Items will be `NSNull` if they're not loaded yet. */
-(NSArray *)objectsAtIndexes:(NSIndexSet *)indexes;

/** Returns the index of the given loaded object in the list. */
-(NSInteger)indexOfObject:(id)object;

///----------------------------
/// @name Querying Loaded Items
///----------------------------

/** Returns the indexes of the loaded objects in the list. */
-(NSIndexSet *)loadedIndexes;

/** Returns a set containing all loaded objects in the list. */
-(NSSet *)loadedObjects;

/** Returns a set containing all loaded objects within the given range of the list. */
-(NSSet *)loadedObjectsInRange:(NSRange)range;

@end
