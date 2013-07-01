//
//  SPPlaylistPickerViewController.m
//  CocoaLibSpotify iOS Library
//
//  Created by Daniel Kennett on 27/06/2013.
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

#import "SPPlaylistPickerViewController.h"
#import "SPPlaylistListViewController.h"
#import "SPSession.h"
#import "SPPlaylistContainer.h"

@interface SPPlaylistPickerViewController ()
@property (nonatomic, readwrite) SPPlaylistPickerMode mode;
@property (nonatomic, readwrite, strong) SPSession *session;
@end

@implementation SPPlaylistPickerViewController


-(id)initWithMode:(SPPlaylistPickerMode)mode inSession:(SPSession *)session {
	self = [super init];

	if (self) {
		self.mode = mode;
		self.session = session;
	}

	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

	//TODO: Make sure userplaylists has loaded before initing the rootlist.

	[SPAsyncLoading waitUntilLoaded:self.session
					   withKeyPaths:@[@"userPlaylists"]
							timeout:kSPAsyncLoadingDefaultTimeout
							   then:nil];

	SPPlaylistListViewController *rootList = [[SPPlaylistListViewController alloc] initWithPlaylistProvider:self.session.userPlaylists
																							allowTrackLists:self.mode == SPPlaylistPickerModeTrack];
	[self pushViewController:rootList animated:NO];
	[self syncCancelButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Cancelling

-(void)syncCancelButton {

	UIViewController *root = [self.viewControllers firstObject];

	if (self.allowCancel)
		root.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																							  target:self
																							  action:@selector(cancel:)];
	else
		root.navigationItem.leftBarButtonItem = nil;

}

-(void)cancel:(id)sender {
	if (self.cancellationHandler) self.cancellationHandler();
}

#pragma mark -

-(void)resetAnimated:(BOOL)animate {

	// Pop to the root view controller (which is a UITableViewController)
	// and scroll it to the top.

	[self popToRootViewControllerAnimated:animate];

	if ([[self.viewControllers firstObject] respondsToSelector:@selector(tableView)]) {
		UITableView *rootTable = [[self.viewControllers firstObject] tableView];
		[rootTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
						 atScrollPosition:UITableViewScrollPositionTop
								 animated:animate];
	}
}

-(void)reset {
	[self resetAnimated:NO];
}

@end
