//
//  SPAsyncLoadingObserver.m
//  CocoaLibSpotify Mac Framework
//
//  Created by Daniel Kennett on 12/04/2012.
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

#import "SPAsyncLoading.h"

static void * const kSPAsyncLoadingObserverKVOContext = @"SPAsyncLoadingObserverKVO";
static NSMutableArray *observerCache;

@interface SPAsyncLoading ()
@property (nonatomic, readwrite, copy) NSArray *observedItems;
@property (nonatomic, readwrite, copy) void (^loadedWithTimeoutHandler) (NSArray *, NSArray *);
@end

@interface SPAsyncLoading (SPAsyncLoadingNested)
+(void)loadKeyPath:(NSString *)keyPath ofLoadedItems:(NSArray *)rootItems timeout:(NSTimeInterval)timeout callback:(dispatch_block_t)doneBlock;
+(void)loadKeyPaths:(NSArray *)keyPaths ofItems:(NSArray *)rootItems timeout:(NSTimeInterval)timeout callback:(void (^)(NSArray *completelyLoadedItems, NSArray *notLoadedItems))block;
@end

@implementation SPAsyncLoading

+(void)waitUntilLoaded:(id)itemOrItems withKeyPaths:(NSArray *)keyPathsToLoad timeout:(NSTimeInterval)timeout then:(void (^)(NSArray *completelyLoadedItems, NSArray *notLoadedItems))block {
	
	if (keyPathsToLoad == nil) {
		[self waitUntilLoaded:itemOrItems timeout:timeout then:block];
		return;
	}
	
	NSArray *itemArray = [itemOrItems isKindOfClass:[NSArray class]] ? itemOrItems : [NSArray arrayWithObject:itemOrItems];
	[self loadKeyPaths:keyPathsToLoad ofItems:itemArray timeout:timeout callback:block];
}


+(void)waitUntilLoaded:(id)itemOrItems timeout:(NSTimeInterval)timeout then:(void (^)(NSArray *, NSArray *))block {

	NSArray *itemArray = [itemOrItems isKindOfClass:[NSArray class]] ? itemOrItems : [NSArray arrayWithObject:itemOrItems];

	SPAsyncLoading *observer = [[SPAsyncLoading alloc] initWithItems:itemArray
															 timeout:timeout
														 loadedBlock:block];
	
	if (observer) {
		if (observerCache == nil) observerCache = [[NSMutableArray alloc] init];
		
		@synchronized(observerCache) {
			[observerCache addObject:observer];
		}
	}
}
	
-(id)initWithItems:(NSArray *)items timeout:(NSTimeInterval)timeout loadedBlock:(void (^)(NSArray *, NSArray *))block {
	
	BOOL allLoaded = YES;
	for (id <SPAsyncLoading> item in items)
		allLoaded &= item.isLoaded;
	
	if (allLoaded) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^() { block(items, nil); });
		return nil;
	}
	
	self = [super init];
	
	if (self) {
		self.observedItems = items;
		self.loadedWithTimeoutHandler = block;

		for (id <SPAsyncLoading> item in self.observedItems) {
			[(id)item addObserver:self
					   forKeyPath:@"loaded"
						  options:0
						  context:kSPAsyncLoadingObserverKVOContext];
			
			if ([item conformsToProtocol:@protocol(SPDelayableAsyncLoading)])
				[(id <SPDelayableAsyncLoading>)item startLoading];
		}
		
		// Since the items async load, an item may have loaded in the meantime.
		[self observeValueForKeyPath:@"loaded"
							ofObject:self.observedItems.lastObject
							  change:nil
							 context:kSPAsyncLoadingObserverKVOContext];

		[self performSelector:@selector(triggerTimeout)
				   withObject:nil
				   afterDelay:timeout];
	}
	
	return self;
}

-(void)dealloc {

	// Cancel previous delayed calls to this
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(triggerTimeout)
											   object:nil];

	for (id <SPAsyncLoading> item in self.observedItems)
		[(id)item removeObserver:self forKeyPath:@"loaded"];
}

@synthesize observedItems;
@synthesize loadedWithTimeoutHandler;

-(void)triggerTimeout {
	
	NSMutableArray *loadedItems = [NSMutableArray arrayWithCapacity:self.observedItems.count];
	NSMutableArray *notLoadedItems = [NSMutableArray arrayWithCapacity:self.observedItems.count];
	
	for (id <SPAsyncLoading> item in self.observedItems) {
		if (item.isLoaded) {
			[loadedItems addObject:item];
		} else {
			[notLoadedItems addObject:item];
		}
	}
	
	if (self.loadedWithTimeoutHandler) dispatch_async(dispatch_get_main_queue(), ^() {
		self.loadedWithTimeoutHandler([NSArray arrayWithArray:loadedItems], [NSArray arrayWithArray:notLoadedItems]);
		self.loadedWithTimeoutHandler = nil;
		@synchronized(observerCache) {
			[observerCache removeObject:self];
		}
	});
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == kSPAsyncLoadingObserverKVOContext) {

		BOOL allLoaded = YES;
		for (id <SPAsyncLoading> item in self.observedItems)
			allLoaded &= item.isLoaded;
		
		if (allLoaded) {
			
			[NSObject cancelPreviousPerformRequestsWithTarget:self
													 selector:@selector(triggerTimeout)
													   object:nil];

			if (self.loadedWithTimeoutHandler) dispatch_async(dispatch_get_main_queue(), ^() {

				if (self.loadedWithTimeoutHandler)
					self.loadedWithTimeoutHandler(self.observedItems, nil);

				self.loadedWithTimeoutHandler = nil;
				@synchronized(observerCache) {
					[observerCache removeObject:self];
				}
			});
		}
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end

#pragma mark - With Key Paths

@implementation SPAsyncLoading (SPAsyncLoadingNested)

+(void)loadKeyPaths:(NSArray *)keyPaths ofItems:(NSArray *)rootItems timeout:(NSTimeInterval)timeout callback:(void (^)(NSArray *completelyLoadedItems, NSArray *notLoadedItems))block {

	[SPAsyncLoading waitUntilLoaded:rootItems timeout:timeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {

		NSMutableArray *waitingKeyPaths = [keyPaths mutableCopy];
		NSMutableArray *doneKeyPaths = [NSMutableArray arrayWithCapacity:waitingKeyPaths.count];

		// Shenanigans to allow a block to reference itself without circular references.
		dispatch_block_t loadNextPathBlock;
		__block dispatch_block_t loadNextPath;
		loadNextPath = loadNextPathBlock = [^{

			NSString *keyPath = [waitingKeyPaths objectAtIndex:0];
			[waitingKeyPaths removeObjectAtIndex:0];
			[doneKeyPaths addObject:keyPath];

			[self loadKeyPath:keyPath ofLoadedItems:rootItems timeout:timeout callback:^{

				if (waitingKeyPaths.count > 0) {
					loadNextPath();
				} else {

					NSMutableArray *notLoadedRootItems = [NSMutableArray arrayWithCapacity:rootItems.count];

					for (NSString *keyPath in keyPaths) {

						NSMutableArray *potentialLoadedItems = [rootItems mutableCopy];
						[potentialLoadedItems removeObjectsInArray:notLoadedRootItems];

						NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."];

						for (id rootObject in potentialLoadedItems) {

							if (![rootObject isLoaded]) {
								[notLoadedRootItems addObject:rootObject];
								continue;
							}

							for (NSUInteger pathIndex = 0; pathIndex < keyPathComponents.count; pathIndex++) {

								NSString *thisLevelOfKeyPath = [[keyPathComponents subarrayWithRange:NSMakeRange(0, pathIndex + 1)] componentsJoinedByString:@"."];
								id child = [rootObject valueForKeyPath:thisLevelOfKeyPath];

								if ([child conformsToProtocol:@protocol(SPAsyncLoading)] && ![child isLoaded]) {
									[notLoadedRootItems addObject:rootObject];
									continue;
								} else if ([child isKindOfClass:[NSArray class]]) {
									NSArray *childArray = child;
									if (childArray.count == 0)
										continue;

									NSMutableArray *itemsToCheck = [NSMutableArray array];

									if ([childArray[0] conformsToProtocol:@protocol(SPAsyncLoading)]) {
										[itemsToCheck addObjectsFromArray:childArray];
									} else if ([childArray[0] isKindOfClass:[NSArray class]]) {
										for (NSArray *containedArray in childArray) {
											[itemsToCheck addObjectsFromArray:containedArray];
										}
									} else if (childArray[0] == [NSNull null]) {
										[notLoadedRootItems addObject:rootObject];
										continue;
									}

									for (id item in itemsToCheck) {
										if (![item isLoaded]) {
											[notLoadedRootItems addObject:rootObject];
											continue;
										}
									}
								} else if (child == [NSNull null]) {
									[notLoadedRootItems addObject:rootObject];
									continue;
								}
							}
						}
					}

					NSMutableArray *completelyLoadedItems = [rootItems mutableCopy];
					[completelyLoadedItems removeObjectsInArray:notLoadedRootItems];

					if (block) block([NSArray arrayWithArray:completelyLoadedItems], [NSArray arrayWithArray:notLoadedRootItems]);
					return;
				}
			}];

		} copy];
		
		loadNextPath();

	}];
}

+(void)loadKeyPath:(NSString *)keyPath ofLoadedItems:(NSArray *)rootItems timeout:(NSTimeInterval)timeout callback:(dispatch_block_t)doneBlock {

	if (rootItems.count == 0) {
		if (doneBlock) doneBlock();
		return;
	}

	__block NSMutableArray *waitingKeyPathComponents = [[keyPath componentsSeparatedByString:@"."] mutableCopy];
	__block NSMutableArray *completedKeyPathComponents = [NSMutableArray arrayWithCapacity:waitingKeyPathComponents.count];

	// Shenanigans to allow a block to reference itself without circular references.
	dispatch_block_t loadNextLevelBlock;
	__block dispatch_block_t loadNextLevel;
	loadNextLevel = loadNextLevelBlock = [^{

		if (waitingKeyPathComponents.count == 0) {
			if (doneBlock) doneBlock();
			return;
		}

		NSString *key = [waitingKeyPathComponents objectAtIndex:0];
		[waitingKeyPathComponents removeObjectAtIndex:0];
		[completedKeyPathComponents addObject:key];

		// Part of the key path might be an array!
		NSArray *items = rootItems;
		for (NSString *keyPathComponent in completedKeyPathComponents) {
			NSArray *item = [items valueForKey:keyPathComponent];
			if (item.count > 0 && [item[0] isKindOfClass:[NSArray class]]) {
				NSMutableArray *extractedItems = [NSMutableArray array];
				for (NSArray *childArray in item)
					[extractedItems addObjectsFromArray:childArray];
				items = extractedItems;
			} else {
				items = item;
			}
		}

		NSMutableArray *finalItems = [items mutableCopy];
		[finalItems removeObject:[NSNull null]];

		[SPAsyncLoading waitUntilLoaded:finalItems timeout:timeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
			loadNextLevel();
		}];

	} copy];

	loadNextLevel();
}

@end

