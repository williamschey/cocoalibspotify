//
//  SPPlaylistListViewController.m
//  CocoaLibSpotify iOS Library
//
//  Created by Daniel Kennett on 28/06/2013.
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

#import "SPPlaylistListViewController.h"
#import "SPPlaylist.h"
#import "SPPlaylistFolder.h"
#import "SPPlaylistPickerViewController.h"
#import "SPPlaylistViewController.h"

@interface SPPlaylistListViewController ()
@property (nonatomic, readwrite, strong) id <SPPlaylistProvider> provider;
@property (nonatomic, readwrite) BOOL allowTrackLists;
@end

@implementation SPPlaylistListViewController

-(id)initWithPlaylistProvider:(id <SPPlaylistProvider>)provider allowTrackLists:(BOOL)allowTrackLists {
	self = [super initWithStyle:UITableViewStylePlain];
	if (self) {
		self.provider = provider;
		self.allowTrackLists = allowTrackLists;

		[self addObserver:self forKeyPath:@"provider.playlists" options:0 context:nil];

	}
	return self;
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"provider.playlists"];
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"provider.playlists"]) {
        [self.tableView reloadData];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.provider.playlists.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
    
    // Configure the cell...
	id playlistOrFolder = self.provider.playlists[indexPath.row];
	cell.textLabel.text = [playlistOrFolder name];

	if (self.allowTrackLists || [playlistOrFolder isKindOfClass:[SPPlaylistFolder class]])
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	else
		cell.accessoryType = UITableViewCellAccessoryNone;

	if ([playlistOrFolder conformsToProtocol:@protocol(SPAsyncLoading)]) {
		id <SPAsyncLoading> loadable = playlistOrFolder;
		if (!loadable.loaded) {
			__weak typeof(self) weakSelf = self;
			[SPAsyncLoading waitUntilLoaded:loadable timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
				[weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			}];
		}
	}
    
    return cell;
}

#pragma mark - TableView Delegates

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	id playlistOrFolder = self.provider.playlists[indexPath.row];

	if ([playlistOrFolder isKindOfClass:[SPPlaylistFolder class]]) {
		UIViewController *controller = [[SPPlaylistListViewController alloc] initWithPlaylistProvider:playlistOrFolder
																					  allowTrackLists:self.allowTrackLists];
		[self.navigationController pushViewController:controller animated:YES];

	} else if (self.allowTrackLists) {
		UIViewController *controller = [[SPPlaylistViewController alloc] initWithPlaylist:playlistOrFolder];
		[self.navigationController pushViewController:controller animated:YES];
		
	} else {

		id navigation = self.navigationController;
		if ([navigation isKindOfClass:[SPPlaylistPickerViewController class]]) {
			SPPlaylistPickerViewController *picker = navigation;
			if (picker.itemPickedHandler != nil) picker.itemPickedHandler(playlistOrFolder, nil);
		}
		
	}
}

@end
