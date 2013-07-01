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
@end

@implementation SPPlaylistViewController

-(id)initWithPlaylist:(SPPlaylist *)playlist {
	self = [super init];
	if (self) {
		self.playlist = playlist;
		[self.playlist startLoading];
		// TODO: Unload stuff from the sparse list when scrolling away from it
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

@end
