//
//  SPPlaylistViewController.m
//  CocoaLibSpotify iOS Library
//
//  Created by Daniel Kennett on 01/07/2013.
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

#import "SPPlaylistViewController.h"
#import "CocoaLibSpotify.h"

@interface SPPlaylistViewController ()
@property (nonatomic, readwrite, strong) SPPlaylist *playlist;
@property (nonatomic, readwrite, strong) SPSparseList *trackList;
@property (nonatomic, readwrite) CGFloat lastScrollOffset;
@end

@implementation SPPlaylistViewController

-(id)initWithPlaylist:(SPPlaylist *)playlist {
	self = [super init];
	if (self) {
		self.playlist = playlist;
		[self.playlist startLoading];
		self.trackList = [[SPSparseList alloc] initWithDataSource:playlist batchSize:50];
		self.title = self.playlist.name;
		[self addObserver:self forKeyPath:@"playlist.name" options:0 context:nil];
	}
	return self;
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"playlist.name"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"playlist.name"]) {
        self.title = self.playlist.name;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

	NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.trackList.count)];

	NSArray *visible = [self.tableView indexPathsForVisibleRows];
	for (NSIndexPath *path in visible) {
		[indexesToRemove removeIndex:path.row];
	}

	[self.trackList unloadObjectsAtIndexes:indexesToRemove];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.trackList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}

    // Configure the cell...
	SPPlaylistItem *item = self.trackList[indexPath.row];
	__weak typeof(self) weakSelf = self;

	cell.textLabel.textColor = [UIColor lightGrayColor];
	cell.textLabel.text = @"Loading…";
	
	if (item == nil) {
		[self.trackList loadObjectsInRange:NSMakeRange(indexPath.row, 1) callback:^{
			[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		}];
		return cell;
	}

	id <SPAsyncLoading> wrappedItem = item.item;
	if (!wrappedItem.loaded) {
		[SPAsyncLoading waitUntilLoaded:wrappedItem timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
			UITableViewCell *cell = [weakSelf.tableView cellForRowAtIndexPath:indexPath];
			if (wrappedItem.loaded) {
				cell.textLabel.textColor = [UIColor darkTextColor];
				cell.textLabel.text = [(SPTrack *)wrappedItem name];
			}
		}];
	} else {
		cell.textLabel.textColor = [UIColor darkTextColor];
		cell.textLabel.text = [(SPTrack *)wrappedItem name];
	}

    return cell;
}

#pragma mark - TableView Delegates

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	SPPlaylistItem *item = self.trackList[indexPath.row];
	
	id navigation = self.navigationController;
	if ([navigation isKindOfClass:[SPPlaylistPickerViewController class]]) {
		SPPlaylistPickerViewController *picker = navigation;
		if (picker.itemPickedHandler != nil) picker.itemPickedHandler(self.playlist, item);
	}
}

#pragma mark - ScrollView Delegates

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	self.lastScrollOffset = scrollView.contentOffset.y;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self unloadDistantTracksTravellingDown:scrollView.contentOffset.y > self.lastScrollOffset];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate)
        [self unloadDistantTracksTravellingDown:scrollView.contentOffset.y > self.lastScrollOffset];
}

-(void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
	[self unloadDistantTracksTravellingDown:NO];
}

-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView
					withVelocity:(CGPoint)velocity
			 targetContentOffset:(inout CGPoint *)targetContentOffset {

	// TODO: Load tracks where the scrollview will land
	
}

#pragma mark - Memory Management

-(void)unloadDistantTracksTravellingDown:(BOOL)goingDown {
	
	/*
	 This is the most important method of this class — it ensures memory
	 usage is kept in check by unloading playlist items that are a long way
	 away from the visible part of the tableview.

	It's important to note that there is an overhead when deallocating objects,
	and SPTrack objects in particular have internal observers that need to be
	unregistered. For reference, deallocating 10,000 SPTrack instances has been
	measured as taking 1,900 milliseconds (~0.2ms per track) on an iPhone 5.

	However, keeping a lot of tracks in memory isn't a great idea either, since
	mobile devices have a limited amount of resources compared to desktop systems.

	Therefore, we want to limit the number of tracks in RAM, but don't want to
	deallocate too many at once. In addition, we can't do this while the scroll
	view is scrolling as it'll cause the animation to stutter. Just after scrolling
	is finished is a great time to do this since the user will likely be reorienting
	themselves after the scroll and not trying to interact with the device, allowing
	us to spend a few milliseconds cleaning up.
	 
	Since this method has a hard maximum on the number of objects it will unload,
	it relies on a couple of other details that will keep memory under control:

		- UITableViewDataSource misses out rows when the user is quickly scrolling
		through a large number of items, meaning we don't load all the tracks when
		the user scrolls to the the end of the list.

		- When memory conditions are tight enough to be a concern, memory warnings
		are triggered. At this point, we unload *everything* not currently visible.
	 */

	// At 0.2ms per dealloc, 150 deallocations is around the interval between
	// frames at 30 fps, which should keep stutter at a minimum.
	static NSUInteger const kMaximumUnloadsPerInvocation = 150;

	// Tracks use around 1-2Kb of RAM each. We can handle 3-600Kb of RAM usage
	// just fine so unloading tracks closer than that has a limited benefit. Memory warnings
	// will unload more tracks if we're constrained.
	static NSUInteger const kMinimumDistanceBeforeUnloading = 300;

	NSArray *visibleRows = [self.tableView indexPathsForVisibleRows];
	NSMutableIndexSet *visibleIndexes = [NSMutableIndexSet indexSet];
	for (NSIndexPath *item in visibleRows)
		[visibleIndexes addIndex:item.row];

	if (visibleIndexes.count == 0) return;

	NSInteger smallestSafeIndex = visibleIndexes.firstIndex - kMinimumDistanceBeforeUnloading;
	NSInteger largestSafeIndex = visibleIndexes.lastIndex + kMinimumDistanceBeforeUnloading;

	NSUInteger safeLength = largestSafeIndex - smallestSafeIndex;
	NSUInteger safeStart = 0;
	if (smallestSafeIndex < 0) {
		safeLength -= (smallestSafeIndex * -1);
	} else {
		safeStart = smallestSafeIndex;
	}

	if ((safeStart + safeLength) > self.trackList.count)
		safeLength = self.trackList.count - safeStart;

	NSRange safeRange = NSMakeRange(safeStart, safeLength);

	NSMutableIndexSet *unsafeIndexes = [NSMutableIndexSet indexSet];
	[unsafeIndexes addIndexesInRange:NSMakeRange(0, self.trackList.count)];
	[unsafeIndexes removeIndexesInRange:safeRange];

	// This index set contains the indexes of loaded items that are far enough away to be unloaded.
	NSIndexSet *indexesToUnload = [self.trackList loadedIndexesInIndexes:unsafeIndexes];

	if (indexesToUnload.count == 0) return;

	if (indexesToUnload.count > kMaximumUnloadsPerInvocation) {
		// Too many loaded indexes! Unload the items that are furthest away first.
		NSMutableIndexSet *highPriorityIndexesToUnload = [NSMutableIndexSet indexSet];

		__block NSUInteger indexesRemaining = kMaximumUnloadsPerInvocation;

		// Collect the indexes furthest away in the wrong direction (i.e., if we're scrolling down,
		// we want to remove the objects above the current scroll position first)
		NSEnumerationOptions firstIterationOptions = goingDown ? 0 : NSEnumerationReverse;
		NSIndexSet *firstIndexes = [indexesToUnload indexesWithOptions:firstIterationOptions passingTest:^BOOL(NSUInteger idx, BOOL *stop) {

			if (goingDown && idx > smallestSafeIndex) {
				*stop = YES;
			} else if (!goingDown && (idx < largestSafeIndex)) {
				*stop = YES;
			}

			if (*stop) return NO;

			indexesRemaining--;

			if (indexesRemaining == 0)
				*stop = YES;

			return YES;
		}];

		[highPriorityIndexesToUnload addIndexes:firstIndexes];

		if (indexesRemaining > 0) {

			// At this point, we have the least useful of the candidates collected, but there's still some left.
			NSEnumerationOptions secondIterationOptions = goingDown ? NSEnumerationReverse : 0;
			NSIndexSet *secondIndexes = [indexesToUnload indexesWithOptions:secondIterationOptions passingTest:^BOOL(NSUInteger idx, BOOL *stop) {
				indexesRemaining--;
				if (indexesRemaining == 0) *stop = YES;
				return YES;
			}];

			[highPriorityIndexesToUnload addIndexes:secondIndexes];
		}

#if 0
		NSLog(@"Going down: %@", @(goingDown));
		NSLog(@"Discriminatingly unloading %@", highPriorityIndexesToUnload);
		NSLog(@"Sample for discrimination was %@", indexesToUnload);
#endif
		[self.trackList unloadObjectsAtIndexes:highPriorityIndexesToUnload];

	} else {
#if 0
		NSLog(@"Going down: %@", @(goingDown));
		NSLog(@"Indiscriminatingly unloading %@", indexesToUnload);
#endif
		[self.trackList unloadObjectsAtIndexes:indexesToUnload];
	}
}

@end
