//
//  SPFacebookPermissionsViewController.m
//  CocoaLibSpotify iOS Library
//
//  Created by Daniel Kennett on 24/03/2012.
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

#import "SPFacebookPermissionsViewController.h"

@interface SPFacebookPermissionsViewController ()
@property (nonatomic, readwrite, copy) NSArray *permissions;
@end

@implementation SPFacebookPermissionsViewController

-(id)initWithPermissions:(NSArray *)somePermissions inSession:(SPSession *)aSession {
	
	self = [super initWithSession:aSession];
	
	if (self) {
		self.permissions = somePermissions;
		
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleBordered  target:self action:@selector(add)];
		
		NSMutableArray *jsPermissions = [NSMutableArray arrayWithCapacity:self.permissions.count];
		for (NSString *permission in self.permissions) {
			[jsPermissions addObject:[NSString stringWithFormat:@"\"%@\"", permission]];
		}
		
		[super loadDocument:@"permissions.en.html"
				   inFolder:@"mobilehulkpermissions"
					   page:0
			   stillLoading:NO
				 recentUser:nil
				   features:0];
		
		NSString *js = [NSString stringWithFormat:@"setPermissionsNeeded([%@])", [jsPermissions componentsJoinedByString:@", "]];
		[self runJSWhenLoaded:js];
		
	}
	return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Actions

-(void)add {
	SPDispatchAsync(^{
		sp_signup_userdata_success success;
		success.success = true;
		sp_session_signup_perform_action(self.session.session, SP_SIGNUP_ACTION_CONNECT_TO_FACEBOOK_COMPLETED, &success);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate signupPageDidAccept:self];
		});
	});
}

-(void)cancel {
	SPDispatchAsync(^{
		sp_signup_userdata_success success;
		success.success = false;
		sp_session_signup_perform_action(self.session.session, SP_SIGNUP_ACTION_CONNECT_TO_FACEBOOK_COMPLETED, &success);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate signupPageDidCancel:self];
		});
	});
}

@end
