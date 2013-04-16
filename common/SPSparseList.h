//
//  SPSparseArray.h
//  CocoaLibSpotify Mac Framework
//
//  Created by Daniel Kennett on 16/04/2013.
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

#import <Foundation/Foundation.h>
#import "SPAsyncLoading.h"

/**
 Provides a helper class for working with objects that conform to the
 `SPPartialAsyncLoading` protocol, such as playlists. This class assists
 with fetching child objects from `SPPartialAsyncLoading` classes and
 managing them in a list.
 */

@interface SPSparseList : NSObject

/** Initialise the list with the given data source, which must conform
 to the `SPPartialAsyncLoading` protocol.
 
 @note This is the designated initialiser for this class.
 
 @param dataSource The data source for this list.
 @return The initialised list.
 */
-(id)initWithDataSource:(id <SPPartialAsyncLoading>)dataSource;

///----------------------------
/// @name Item Loading and Unloading
///----------------------------

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
