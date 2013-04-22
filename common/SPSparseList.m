//
//  SPSparseArray.m
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

#import "SPSparseList.h"

static NSUInteger const kSPSparseListDefaultBatchSize = 30;

@interface SPSparseListWaitingBlock : NSObject

@property (nonatomic, readwrite, copy) dispatch_block_t block;
@property (nonatomic, readwrite) NSIndexSet *indexes;

@end

@implementation SPSparseListWaitingBlock
@end

@interface SPSparseList ()

@property (nonatomic, strong, readwrite) id <SPPartialAsyncLoading> provider;
@property (nonatomic, strong, readwrite) NSMutableDictionary *loadedItems;
@property (nonatomic, copy, readwrite) NSIndexSet *loadedIndexes;
@property (nonatomic, strong, readwrite) NSMutableArray *loadingBlocks;
@property (nonatomic, readwrite) NSUInteger batchSize;

@end

@implementation SPSparseList

-(id)init {
	return [self initWithDataSource:nil batchSize:kSPSparseListDefaultBatchSize];
}

-(id)initWithDataSource:(id<SPPartialAsyncLoading>)datasource {
	return [self initWithDataSource:datasource batchSize:kSPSparseListDefaultBatchSize];
}

-(id)initWithDataSource:(id<SPPartialAsyncLoading>)datasource batchSize:(NSUInteger)batchSize {
	self = [super init];

	if (self) {
		self.loadedItems = [NSMutableDictionary new];
		self.provider = datasource;
		self.loadedIndexes = [NSIndexSet indexSet];
		self.loadingBlocks = [NSMutableArray new];
		self.batchSize = batchSize;
	}

	return self;
}

-(BOOL)containsObject:(id)object {
	return [[self.loadedItems allValues] containsObject:object];
}

-(NSUInteger)count {
	return [self.provider itemCount];
}

-(id)lastObject {
	if (self.count == 0) return nil;
	return [self objectAtIndex:self.count - 1];
}

-(id)objectAtIndex:(NSUInteger)index {
	[self throwIfIndexInvalid:index];
	return [self.loadedItems objectForKey:@(index)];
}

-(id)objectAtIndexedSubscript:(NSUInteger)index {
	[self throwIfIndexInvalid:index];
	return [self objectAtIndex:index];
}

-(NSArray *)objectsAtIndexes:(NSIndexSet *)indexes {

	[self throwIfIndexesInvalid:indexes];

	__block NSMutableArray *objects = [NSMutableArray arrayWithCapacity:indexes.count];

	[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		id object = [self objectAtIndex:idx];
		if (object)
			[objects addObject:object];
		else
			[objects addObject:[NSNull null]];
	}];

	return [NSArray arrayWithArray:objects];
}

-(NSInteger)indexOfObject:(id)object {
	NSNumber *index = [[self.loadedItems allKeysForObject:object] lastObject];
	if (index == nil)
		return NSNotFound;

	return [index integerValue];
}

-(NSSet *)loadedObjects {
	return [NSSet setWithArray:[self.loadedItems allValues]];
}

-(NSSet *)loadedObjectsInRange:(NSRange)range {

	[self throwIfIndexesInvalid:[NSIndexSet indexSetWithIndexesInRange:range]];

	NSMutableSet *objects = [NSMutableSet setWithCapacity:range.length];

	for (NSUInteger index = range.location; index < range.location + range.length; index++) {
		id object = [self objectAtIndex:index];
		if (object)
			[objects addObject:object];
	}

	return [NSSet setWithSet:objects];
}

-(void)loadObjectsInRange:(NSRange)range callback:(dispatch_block_t)block {

	/*
	 Intelligently deal with incoming requests by keeping a list of the indexes being loaded.
	 That way, if a load request comes in for something already being requested, we don't
	 fire off multiple requests to the data source.
	 
	 Additionally, this allows us to implement batching (loading objects in batches rather
	 than individually) meaning the user of this class can request exactly which indexes
	 they require (say, from a table view data source) and still get the performance benefits
	 of loading in larger batches.
	 */

	NSRange expandedRange = [self chunkedRangeEncompassingRange:range];
	NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:expandedRange];
	[self throwIfIndexesInvalid:indexes];

	SPSparseListWaitingBlock *waitingBlock = [SPSparseListWaitingBlock new];
	waitingBlock.block = block;
	waitingBlock.indexes = indexes;

	BOOL indexesAlreadyBeingLoaded = [[self loadingIndexes] containsIndexes:indexes];
	[self.loadingBlocks addObject:waitingBlock];

	if (indexesAlreadyBeingLoaded) return;

	[self.provider fetchItemsInRange:expandedRange callback:^(NSError *error, NSArray *items) {

		NSIndexSet *loadedIndexes = [NSIndexSet indexSetWithIndexesInRange:expandedRange];

		if (error == nil) {
			NSAssert(items.count == expandedRange.length, @"Got wrong number of items for range");
			for (NSUInteger index = 0; index < items.count; index++)
				self.loadedItems[@(index + expandedRange.location)] = items[index];

			NSMutableIndexSet *newIndexes = [self.loadedIndexes mutableCopy];
			[newIndexes removeIndexes:loadedIndexes];
			self.loadedIndexes = newIndexes;
		}

		NSArray *blocks = [self.loadingBlocks copy];
		for (SPSparseListWaitingBlock *waitingBlock in blocks) {
			if ([loadedIndexes containsIndexes:waitingBlock.indexes]) {
				dispatch_async(dispatch_get_main_queue(), ^{ waitingBlock.block(); });
				[self.loadingBlocks removeObject:waitingBlock];
			}
		}
	}];	
}

-(void)unloadObjectsInRange:(NSRange)range {

	[self throwIfIndexesInvalid:[NSIndexSet indexSetWithIndexesInRange:range]];
	
	for (NSUInteger index = range.location; index < range.location + range.length; index++)
		[self.loadedItems removeObjectForKey:@(index)];

	NSMutableIndexSet *newIndexes = [self.loadedIndexes mutableCopy];
	[newIndexes removeIndexesInRange:range];
	self.loadedIndexes = newIndexes;
}

#pragma mark - Internal Helpers

-(NSRange)chunkedRangeEncompassingRange:(NSRange)range {

	double floatChunk = self.batchSize;

	NSRange chunkedRange = NSMakeRange(0, 0);
	chunkedRange.location = floor(range.location / floatChunk) * floatChunk;
	chunkedRange.length = ceil(range.length / floatChunk) * floatChunk;

	if (chunkedRange.location + chunkedRange.length >= self.count)
		chunkedRange.length = self.count - chunkedRange.location;

	return chunkedRange;
}

-(NSIndexSet *)loadingIndexes {
	NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
	for (SPSparseListWaitingBlock *waitingBlock in self.loadingBlocks)
		[set addIndexes:waitingBlock.indexes];

	return [set copy];
}

-(void)throwIfIndexInvalid:(NSInteger)index {
	if (index >= self.count) {
		NSString *description = self.count == 0 ? @"of empty list" : [NSString stringWithFormat:@"0-%@", @(self.count - 1)];
		[NSException raise:NSRangeException format:@"%@: Index %@ outside range %@", NSStringFromClass([self class]), @(index), description];
	}
}

-(void)throwIfIndexesInvalid:(NSIndexSet *)indexes {
	if ([indexes indexGreaterThanIndex:self.count - 1] != NSNotFound) {
		NSString *description = self.count == 0 ? @"of empty list" : [NSString stringWithFormat:@"0-%@", @(self.count - 1)];
		[NSException raise:NSRangeException format:@"%@: Index %@ outside range %@", NSStringFromClass([self class]), @([indexes indexGreaterThanIndex:self.count - 1]), description];
	}
}

@end
