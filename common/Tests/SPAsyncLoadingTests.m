//
//  SPAsyncLoadingTests.m
//  CocoaLibSpotify Mac Framework
//
//  Created by Daniel Kennett on 19/03/2013.
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
