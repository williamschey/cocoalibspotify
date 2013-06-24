//
//  SPSparseListTests.m
//  CocoaLibSpotify Mac Framework
//
//  Created by Daniel Kennett on 24/06/2013.
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

#import "SPSparseListTests.h"
#import "SPSparseList.h"
#import "SparseListArrayAdapter.h"

@interface SPSparseListTests ()
@property (nonatomic, readwrite, strong) NSArray *source;
@end

@implementation SPSparseListTests

-(void)ensureSourceIsInitialized {
	if (self.source != nil) return;
	self.source = @[@"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h"];
}

-(SPSparseList *)generateListWithBatching {
	return [[SPSparseList alloc] initWithDataSource:[[SparseListArrayAdapter alloc] initWithSource:self.source]];
}

-(SPSparseList *)generateListWithNoBatching {
	return [[SPSparseList alloc] initWithDataSource:[[SparseListArrayAdapter alloc] initWithSource:self.source] batchSize:1];
}

-(void)testNoBatchingAllObjects {
	[self ensureSourceIsInitialized];
	SPAssertTestCompletesInTimeInterval(5.0);

	SPSparseList *list = [self generateListWithNoBatching];
	NSRange range = NSMakeRange(0, self.source.count);

	[list loadObjectsInRange:range callback:^{
		SPTestAssert([list.loadedIndexes isEqual:[NSIndexSet indexSetWithIndexesInRange:range]], @"Loaded range isn't what was requested");
		SPTestAssert([list.loadedObjects isEqualToSet:[NSSet setWithArray:self.source]], @"Loaded objects don't match source");
		SPTestAssert([[list objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]] isEqual:[self.source subarrayWithRange:range]], @"Objects at requested range don't match source");

		[list unloadObjectsInRange:range];
		SPTestAssert([list.loadedIndexes isEqual:[NSIndexSet new]], @"List has loaded indexes when it should be empty");
		SPTestAssert(list.loadedObjects.count == 0, @"List contains items when it should be empty");
		SPPassTest();
	}];
}

-(void)testNoBatchingOneObject {
	[self ensureSourceIsInitialized];
	SPAssertTestCompletesInTimeInterval(5.0);

	SPSparseList *list = [self generateListWithNoBatching];
	NSRange range = NSMakeRange(0, 1);

	[list loadObjectsInRange:range callback:^{
		SPTestAssert([list.loadedIndexes isEqualToIndexSet:[NSIndexSet indexSetWithIndexesInRange:range]], @"Loaded range isn't what was requested");
		SPTestAssert([list.loadedObjects isEqualToSet:[NSSet setWithArray:[self.source subarrayWithRange:range]]], @"Loaded objects don't match source");
		SPTestAssert([[list objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]] isEqual:[self.source subarrayWithRange:range]], @"Objects at requested range don't match source");

		[list unloadObjectsInRange:range];
		SPTestAssert([list.loadedIndexes isEqualToIndexSet:[NSIndexSet indexSet]], @"List has loaded indexes when it should be empty");
		SPTestAssert(list.loadedObjects.count == 0, @"List contains items when it should be empty");
		SPPassTest();
	}];
}

-(void)testNoBatchingOutOfBounds {
	[self ensureSourceIsInitialized];
	SPAssertTestCompletesInTimeInterval(5.0);

	SPSparseList *list = [self generateListWithNoBatching];
	NSRange range = NSMakeRange(self.source.count, 10);

	@try {
		[list loadObjectsInRange:range callback:^{
			[self failTest:_cmd format:@"Call succeeded with invalid range"];
		}];
	}
	@catch (NSException *exception) {
		SPPassTest();
	}
	
}

-(void)testNoBatchingBoundaries {
	[self ensureSourceIsInitialized];
	SPAssertTestCompletesInTimeInterval(5.0);

	SPSparseList *list = [self generateListWithNoBatching];
	NSRange lastObjectRange = NSMakeRange(self.source.count - 1, 1);

	@try {
		[list loadObjectsInRange:lastObjectRange callback:^{
			SPTestAssert([list.loadedIndexes isEqualToIndexSet:[NSIndexSet indexSetWithIndexesInRange:lastObjectRange]], @"Loaded range isn't what was requested");
			SPTestAssert([list.loadedObjects isEqualToSet:[NSSet setWithArray:[self.source subarrayWithRange:lastObjectRange]]], @"Loaded objects don't match source");
			SPTestAssert([[list objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:lastObjectRange]] isEqual:[self.source subarrayWithRange:lastObjectRange]], @"Objects at requested range don't match source");

			[list unloadObjectsInRange:lastObjectRange];
			SPTestAssert([list.loadedIndexes isEqualToIndexSet:[NSIndexSet indexSet]], @"List has loaded indexes when it should be empty");
			SPTestAssert(list.loadedObjects.count == 0, @"List contains items when it should be empty");

			@try {
				NSRange beyondObjectRange = NSMakeRange(self.source.count, 1);
				[list loadObjectsInRange:beyondObjectRange callback:^{
					[self failTest:_cmd format:@"Call succeeded when it should have failed"];
				}];
			}
			@catch (NSException *exception) {
				SPPassTest();
			}
		}];
	}
	@catch (NSException *exception) {
		[self failTest:_cmd format:@"Call failed when it should have passed"];
	}
}

-(void)testWithBatchingAllObjects {
	[self ensureSourceIsInitialized];
	SPAssertTestCompletesInTimeInterval(5.0);

	SPSparseList *list = [self generateListWithBatching];
	NSRange range = NSMakeRange(0, self.source.count);

	[list loadObjectsInRange:range callback:^{
		SPTestAssert([list.loadedIndexes containsIndexesInRange:range], @"Loaded range doesn't contain what was requested");
		SPTestAssert([[NSSet setWithArray:self.source] isSubsetOfSet:list.loadedObjects], @"Loaded objects don't contain source");
		SPTestAssert([[list objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]] isEqual:[self.source subarrayWithRange:range]], @"Objects at requested range don't match source");

		[list unloadObjectsInRange:range];
		SPTestAssert(![list.loadedIndexes containsIndexesInRange:range], @"List has loaded indexes that intersect source");
		SPPassTest();
	}];
}

-(void)testWithBatchingOneObject {
	[self ensureSourceIsInitialized];
	SPAssertTestCompletesInTimeInterval(5.0);

	SPSparseList *list = [self generateListWithBatching];
	NSRange range = NSMakeRange(0, 1);

	[list loadObjectsInRange:range callback:^{
		SPTestAssert([list.loadedIndexes containsIndexesInRange:range], @"Loaded range doesn't contain what was requested");
		SPTestAssert([[NSSet setWithArray:[self.source subarrayWithRange:range]] isSubsetOfSet:list.loadedObjects], @"Loaded objects don't contain source");
		SPTestAssert([[list objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]] isEqual:[self.source subarrayWithRange:range]], @"Objects at requested range don't match source");

		[list unloadObjectsInRange:range];
		SPTestAssert(![list.loadedIndexes containsIndexesInRange:range], @"List has loaded indexes that intersect source");
		SPPassTest();
	}];
}

-(void)testWithBatchingOutOfBounds {
	[self ensureSourceIsInitialized];
	SPAssertTestCompletesInTimeInterval(5.0);

	SPSparseList *list = [self generateListWithBatching];
	NSRange range = NSMakeRange(self.source.count, 10);

	@try {
		[list loadObjectsInRange:range callback:^{
			[self failTest:_cmd format:@"Call succeeded with invalid range"];
		}];
	}
	@catch (NSException *exception) {
		SPPassTest();
	}

}

-(void)testWithBatchingBoundaries {
	[self ensureSourceIsInitialized];
	SPAssertTestCompletesInTimeInterval(5.0);

	SPSparseList *list = [self generateListWithBatching];
	NSRange lastObjectRange = NSMakeRange(self.source.count - 1, 1);

	@try {
		[list loadObjectsInRange:lastObjectRange callback:^{
			SPTestAssert([list.loadedIndexes containsIndexesInRange:lastObjectRange], @"Loaded range doesn't contain what was requested");
			SPTestAssert([[NSSet setWithArray:[self.source subarrayWithRange:lastObjectRange]] isSubsetOfSet:list.loadedObjects], @"Loaded objects don't contain source");
			SPTestAssert([[list objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:lastObjectRange]] isEqual:[self.source subarrayWithRange:lastObjectRange]], @"Objects at requested range don't match source");

			[list unloadObjectsInRange:lastObjectRange];
			SPTestAssert(![list.loadedIndexes containsIndexesInRange:lastObjectRange], @"List has loaded indexes that intersect source");

			@try {
				NSRange beyondObjectRange = NSMakeRange(self.source.count, 1);
				[list loadObjectsInRange:beyondObjectRange callback:^{
					[self failTest:_cmd format:@"Call succeeded when it should have failed"];
				}];
			}
			@catch (NSException *exception) {
				SPPassTest();
			}
		}];
	}
	@catch (NSException *exception) {
		[self failTest:_cmd format:@"Call failed when it should have passed"];
	}
}


@end
