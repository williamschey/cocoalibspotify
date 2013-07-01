//
//  SPSparseArray.m
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

-(NSIndexSet *)loadedIndexesInIndexes:(NSIndexSet *)indexes {
	[self throwIfIndexesInvalid:indexes];

	NSIndexSet *loadedIndexes = self.loadedIndexes;
	return [indexes indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
		return [loadedIndexes containsIndex:idx];
	}];
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

	[self throwIfIndexesInvalid:[NSIndexSet indexSetWithIndexesInRange:range]];
	NSRange expandedRange = [self chunkedRangeEncompassingRange:range];
	NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:expandedRange];

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
			[newIndexes addIndexes:loadedIndexes];
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
	[self unloadObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
}

-(void)unloadObjectsAtIndexes:(NSIndexSet *)indexes {
	
	[self throwIfIndexesInvalid:indexes];

	[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		[self.loadedItems removeObjectForKey:@(idx)];
	}];
	
	NSMutableIndexSet *newIndexes = [self.loadedIndexes mutableCopy];
	[newIndexes removeIndexes:indexes];
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
