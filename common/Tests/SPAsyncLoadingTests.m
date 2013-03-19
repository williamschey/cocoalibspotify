//
//  SPAsyncLoadingTests.m
//  CocoaLibSpotify Mac Framework
//
//  Created by Daniel Kennett on 19/03/2013.
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

#import "SPAsyncLoadingTests.h"
#import "AsyncLoadingMockObjects.h"

@implementation SPAsyncLoadingTests

-(void)test1SingleObjectAsyncLoading {
	
	SPAssertTestCompletesInTimeInterval(20.0);

	id <SPAsyncLoading> willLoadObject = [AsyncWillLoadImmediatelyObject new];
	[SPAsyncLoading waitUntilLoaded:willLoadObject timeout:1.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
		SPTestAssert(notLoadedItems.count == 0, @"Loading timed out for %@", willLoadObject);
		SPTestAssert(loadedItems.count == 1, @"Loaded object missing for %@", willLoadObject);

		id <SPAsyncLoading> willLoadLaterObject = [AsyncWillLoadWithFixedDelayObject new];
		[SPAsyncLoading waitUntilLoaded:willLoadLaterObject timeout:5.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
			SPTestAssert(notLoadedItems.count == 0, @"Loading timed out for %@", willLoadLaterObject);
			SPTestAssert(loadedItems.count == 1, @"Loaded object missing for %@", willLoadLaterObject);

			id <SPAsyncLoading> willLoadLaterAtSomePointObject = [AsyncWillLoadWithRandomDelayObject new];
			[SPAsyncLoading waitUntilLoaded:willLoadLaterAtSomePointObject timeout:10.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
				SPTestAssert(notLoadedItems.count == 0, @"Loading timed out for %@", willLoadLaterAtSomePointObject);
				SPTestAssert(loadedItems.count == 1, @"Loaded object missing for %@", willLoadLaterAtSomePointObject);

				id <SPAsyncLoading> wontLoadObject = [AsyncWillNeverLoadObject new];
				[SPAsyncLoading waitUntilLoaded:wontLoadObject timeout:1.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
					SPTestAssert(loadedItems.count == 0, @"Shouldn't have loaded: %@", wontLoadObject);
					SPTestAssert(notLoadedItems.count == 1, @"Unloaded object missing for %@", wontLoadObject);
					SPPassTest();
				}];
			}];
		}];
	}];
}

-(void)test2MultiObjectAsyncLoading {

	SPAssertTestCompletesInTimeInterval(10.0);

	NSArray *willLoadObjects = @[[AsyncWillLoadImmediatelyObject new], [AsyncWillLoadImmediatelyObject new], [AsyncWillLoadImmediatelyObject new], [AsyncWillLoadImmediatelyObject new], [AsyncWillLoadImmediatelyObject new]];
	[SPAsyncLoading waitUntilLoaded:willLoadObjects timeout:1.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
		SPTestAssert(notLoadedItems.count == 0, @"Loading timed out for %@", willLoadObjects);
		SPTestAssert(loadedItems.count == willLoadObjects.count, @"Loaded object missing for %@", willLoadObjects);

		NSArray *willLoadLaterObjects = @[[AsyncWillLoadWithFixedDelayObject new], [AsyncWillLoadWithFixedDelayObject new], [AsyncWillLoadWithFixedDelayObject new], [AsyncWillLoadWithFixedDelayObject new], [AsyncWillLoadWithFixedDelayObject new]];
		[SPAsyncLoading waitUntilLoaded:willLoadLaterObjects timeout:5.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
			SPTestAssert(notLoadedItems.count == 0, @"Loading timed out for %@", willLoadLaterObjects);
			SPTestAssert(loadedItems.count == willLoadLaterObjects.count, @"Loaded object missing for %@", willLoadLaterObjects);

			NSArray *willLoadLaterAtSomePointObjects = @[[AsyncWillLoadWithRandomDelayObject new], [AsyncWillLoadWithRandomDelayObject new], [AsyncWillLoadWithRandomDelayObject new], [AsyncWillLoadWithRandomDelayObject new], [AsyncWillLoadWithRandomDelayObject new]];
			[SPAsyncLoading waitUntilLoaded:willLoadLaterAtSomePointObjects timeout:10.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
				SPTestAssert(notLoadedItems.count == 0, @"Loading timed out for %@", willLoadLaterAtSomePointObjects);
				SPTestAssert(loadedItems.count == willLoadLaterAtSomePointObjects.count, @"Loaded object missing for %@", willLoadLaterAtSomePointObjects);

				NSArray *wontLoadObjects = @[[AsyncWillNeverLoadObject new], [AsyncWillNeverLoadObject new], [AsyncWillNeverLoadObject new], [AsyncWillNeverLoadObject new], [AsyncWillNeverLoadObject new]];
				[SPAsyncLoading waitUntilLoaded:wontLoadObjects timeout:1.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
					SPTestAssert(loadedItems.count == 0, @"Shouldn't have loaded: %@", wontLoadObjects);
					SPTestAssert(notLoadedItems.count == wontLoadObjects.count, @"Unloaded object missing for %@", wontLoadObjects);
					SPPassTest();
				}];
			}];
		}];
	}];
}

-(void)test3MixedObjectAsyncLoading {

	NSArray *willLoadObjects = @[[AsyncWillLoadImmediatelyObject new], [AsyncWillLoadImmediatelyObject new], [AsyncWillLoadImmediatelyObject new], [AsyncWillLoadImmediatelyObject new], [AsyncWillLoadImmediatelyObject new]];
	NSArray *willLoadLaterObjects = @[[AsyncWillLoadWithFixedDelayObject new], [AsyncWillLoadWithFixedDelayObject new], [AsyncWillLoadWithFixedDelayObject new], [AsyncWillLoadWithFixedDelayObject new], [AsyncWillLoadWithFixedDelayObject new]];
	NSArray *willLoadLaterAtSomePointObjects = @[[AsyncWillLoadWithRandomDelayObject new], [AsyncWillLoadWithRandomDelayObject new], [AsyncWillLoadWithRandomDelayObject new], [AsyncWillLoadWithRandomDelayObject new], [AsyncWillLoadWithRandomDelayObject new]];
	NSArray *wontLoadObjects = @[[AsyncWillNeverLoadObject new], [AsyncWillNeverLoadObject new], [AsyncWillNeverLoadObject new], [AsyncWillNeverLoadObject new], [AsyncWillNeverLoadObject new]];

	NSMutableArray *allObjects = [NSMutableArray array];
	[allObjects addObjectsFromArray:willLoadObjects];
	[allObjects addObjectsFromArray:willLoadLaterObjects];
	[allObjects addObjectsFromArray:willLoadLaterAtSomePointObjects];
	[allObjects addObjectsFromArray:wontLoadObjects];

	NSUInteger itemsThatLoadCount = willLoadObjects.count + willLoadLaterObjects.count + willLoadLaterAtSomePointObjects.count;
	NSUInteger itemsThatWontLoadCount = wontLoadObjects.count;
	
	SPAssertTestCompletesInTimeInterval(10.0);

	[SPAsyncLoading waitUntilLoaded:allObjects timeout:9.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
		SPTestAssert(notLoadedItems.count == itemsThatWontLoadCount, @"Loaded item mismatch %@", allObjects);
		SPTestAssert(loadedItems.count == itemsThatLoadCount, @"Unloaded item mismatch %@", allObjects);
		SPPassTest();
	}];
}

-(void)test4SingleNestedObjectAsyncLoading {

	__block AsyncWillLoadImmediatelyObject *willLoadObj = [AsyncWillLoadImmediatelyObject new];
	willLoadObj.toOneRelationship = [AsyncWillLoadImmediatelyObject new];

	__block AsyncWillLoadImmediatelyObject *wontLoadRelationshipObj = [AsyncWillLoadImmediatelyObject new];
	wontLoadRelationshipObj.toOneRelationship = [AsyncWillNeverLoadObject new];

	__block AsyncWillNeverLoadObject *wontLoadObject = [AsyncWillNeverLoadObject new];
	wontLoadObject.toOneRelationship = [AsyncWillLoadImmediatelyObject new];

	SPAssertTestCompletesInTimeInterval(8.0);

	[SPAsyncLoading waitUntilLoaded:willLoadObj withKeyPaths:@[@"toOneRelationship"] timeout:2.0 then:^(NSArray *completelyLoadedItems, NSArray *notLoadedItems) {
		SPTestAssert(willLoadObj.isLoaded == YES, @"Root not loaded: %@", willLoadObj);
		SPTestAssert(willLoadObj.toOneRelationship.isLoaded == YES, @"To-one not loaded: %@", willLoadObj.toOneRelationship);
		SPTestAssert(completelyLoadedItems.count == 1, @"completelyLoadedItems mismatch (should be 1): %@", completelyLoadedItems);
		SPTestAssert(notLoadedItems.count == 0, @"notLoadedItems mismatch (should be 0): %@", notLoadedItems);

		[SPAsyncLoading waitUntilLoaded:wontLoadRelationshipObj withKeyPaths:@[@"toOneRelationship"] timeout:2.0 then:^(NSArray *completelyLoadedItems, NSArray *notLoadedItems) {
			SPTestAssert(wontLoadRelationshipObj.isLoaded == YES, @"Root not loaded: %@", wontLoadRelationshipObj);
			SPTestAssert(wontLoadRelationshipObj.toOneRelationship.isLoaded == NO, @"To-one loaded when it shouldn't be: %@", wontLoadRelationshipObj.toOneRelationship);
			SPTestAssert(completelyLoadedItems.count == 0, @"completelyLoadedItems mismatch (should be 0): %@", completelyLoadedItems);
			SPTestAssert(notLoadedItems.count == 1, @"notLoadedItems mismatch (should be 1): %@", notLoadedItems);

			[SPAsyncLoading waitUntilLoaded:wontLoadObject withKeyPaths:@[@"toOneRelationship"] timeout:2.0 then:^(NSArray *completelyLoadedItems, NSArray *notLoadedItems) {
				SPTestAssert(wontLoadObject.isLoaded == NO, @"Root loaded when it shouldn't be: %@", wontLoadObject);
				SPTestAssert(wontLoadObject.toOneRelationship.isLoaded == YES, @"To-one not loaded when it should be: %@", wontLoadObject.toOneRelationship);
				SPTestAssert(completelyLoadedItems.count == 0, @"completelyLoadedItems mismatch (should be 0): %@", completelyLoadedItems);
				SPTestAssert(notLoadedItems.count == 1, @"notLoadedItems mismatch (should be 1): %@", notLoadedItems);
				SPPassTest();
			}];
		}];
	}];
}

-(void)test5MultiNestedObjectAsyncLoading {

	NSArray *willLoadLaterAtSomePointObjects = @[[AsyncWillLoadWithRandomDelayObject new], [AsyncWillLoadWithRandomDelayObject new], [AsyncWillLoadWithRandomDelayObject new], [AsyncWillLoadWithRandomDelayObject new], [AsyncWillLoadWithRandomDelayObject new]];
	[willLoadLaterAtSomePointObjects makeObjectsPerformSelector:@selector(setToManyRelationship:) withObject:willLoadLaterAtSomePointObjects];
	NSArray *unionArray = [willLoadLaterAtSomePointObjects valueForKeyPath:@"@unionOfArrays.toManyRelationship"];
	[unionArray makeObjectsPerformSelector:@selector(setToManyRelationship:)
								withObject:@[[AsyncWillLoadWithRandomDelayObject new], [AsyncWillLoadWithRandomDelayObject new], [AsyncWillLoadWithRandomDelayObject new], [AsyncWillLoadWithRandomDelayObject new], [AsyncWillLoadWithRandomDelayObject new]]];
	[willLoadLaterAtSomePointObjects makeObjectsPerformSelector:@selector(setToManyRelationship:) withObject:unionArray];

	[SPAsyncLoading waitUntilLoaded:willLoadLaterAtSomePointObjects withKeyPaths:@[@"toManyRelationship.toManyRelationship"] timeout:10.0 then:^(NSArray *completelyLoadedItems, NSArray *notLoadedItems) {
		SPTestAssert(completelyLoadedItems.count == 5, @"completelyLoadedItems mismatch (should be 5): %@", completelyLoadedItems);
		SPTestAssert(notLoadedItems.count == 0, @"notLoadedItems mismatch (should be 0): %@", notLoadedItems);

		[SPAsyncLoading waitUntilLoaded:willLoadLaterAtSomePointObjects withKeyPaths:@[@"toManyRelationship.toOneRelationship"] timeout:10.0 then:^(NSArray *completelyLoadedItems, NSArray *notLoadedItems) {
			// ^ The to-one relationship on that lot is nil, so shouldn't load.
			SPTestAssert(completelyLoadedItems.count == 0, @"completelyLoadedItems mismatch (should be 0): %@", completelyLoadedItems);
			SPTestAssert(notLoadedItems.count == 5, @"notLoadedItems mismatch (should be 5): %@", notLoadedItems);

			NSArray *loadImmediatelyObjects = @[[AsyncWillLoadImmediatelyObject new], [AsyncWillLoadImmediatelyObject new], [AsyncWillLoadImmediatelyObject new], [AsyncWillLoadImmediatelyObject new], [AsyncWillLoadImmediatelyObject new]];
			[loadImmediatelyObjects makeObjectsPerformSelector:@selector(setToManyRelationship:) withObject:loadImmediatelyObjects];
			[loadImmediatelyObjects makeObjectsPerformSelector:@selector(setToOneRelationship:) withObject:[AsyncWillLoadImmediatelyObject new]];
			[SPAsyncLoading waitUntilLoaded:loadImmediatelyObjects withKeyPaths:@[@"toManyRelationship", @"toOneRelationship"] timeout:2.0 then:^(NSArray *completelyLoadedItems, NSArray *notLoadedItems) {
				SPTestAssert(completelyLoadedItems.count == loadImmediatelyObjects.count, @"completelyLoadedItems mismatch (should be 5): %@", completelyLoadedItems);
				SPTestAssert(notLoadedItems.count == 0, @"notLoadedItems mismatch (should be 0): %@", notLoadedItems);

				NSArray *loadImmediatelyObjects = @[[AsyncWillLoadImmediatelyObject new], [AsyncWillLoadImmediatelyObject new], [AsyncWillLoadImmediatelyObject new], [AsyncWillLoadImmediatelyObject new], [AsyncWillLoadImmediatelyObject new]];
				[loadImmediatelyObjects makeObjectsPerformSelector:@selector(setToManyRelationship:) withObject:loadImmediatelyObjects];
				[loadImmediatelyObjects makeObjectsPerformSelector:@selector(setToOneRelationship:) withObject:[AsyncWillNeverLoadObject new]];
				[SPAsyncLoading waitUntilLoaded:loadImmediatelyObjects withKeyPaths:@[@"toManyRelationship", @"toOneRelationship"] timeout:2.0 then:^(NSArray *completelyLoadedItems, NSArray *notLoadedItems) {
					SPTestAssert(completelyLoadedItems.count == 0, @"completelyLoadedItems mismatch (should be 0): %@", completelyLoadedItems);
					SPTestAssert(notLoadedItems.count == loadImmediatelyObjects.count, @"notLoadedItems mismatch (should be 5): %@", notLoadedItems);


					AsyncWillLoadImmediatelyObject *thisWillLoad = [AsyncWillLoadImmediatelyObject new];
					thisWillLoad.toOneRelationship = [AsyncWillLoadImmediatelyObject new];

					AsyncWillLoadImmediatelyObject *thisWontLoadToOne = [AsyncWillLoadImmediatelyObject new];
					thisWontLoadToOne.toOneRelationship = [AsyncWillNeverLoadObject new];

					AsyncWillNeverLoadObject *thisWontLoadSelf = [AsyncWillNeverLoadObject new];
					thisWontLoadSelf.toOneRelationship = [AsyncWillLoadImmediatelyObject new];

					[SPAsyncLoading waitUntilLoaded:@[thisWillLoad, thisWontLoadToOne, thisWontLoadSelf] withKeyPaths:@[@"toOneRelationship"] timeout:2.0 then:^(NSArray *completelyLoadedItems, NSArray *notLoadedItems) {
						SPTestAssert(completelyLoadedItems.count == 1, @"completelyLoadedItems mismatch (should be 1): %@", completelyLoadedItems);
						SPTestAssert(notLoadedItems.count == 2, @"notLoadedItems mismatch (should be 2): %@", notLoadedItems);
						SPPassTest();
					}];
				}];
			}];
		}];
	}];
}

@end
