//
//  SPLicenseViewControllerViewController.m
//  CocoaLibSpotify iOS Library
//
//  Created by Daniel Kennett on 26/03/2012.
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

#import "SPLicenseViewController.h"
#import <QuartzCore/QuartzCore.h>

static NSString * const kSPLicensesNoVersionURL = @"http://www.spotify.com/mobile/end-user-agreement/?notoken";
static NSString * const kSPLicensesFormatter = @"http://www.spotify.com/mobile/end-user-agreement/?notoken&version=%@";

@interface SPLicenseViewController ()

@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, readwrite, copy) NSString *version;

@end

@implementation SPLicenseViewController

-(id)initWithVersion:(NSString *)licenseVersion {
	
	self = [super init];
	
	if (self) {
		self.version = licenseVersion;
	}
	return self;
}

-(void)done {
	
	UIViewController *parent = self.navigationController;
	
	if ([parent respondsToSelector:@selector(presentingViewController)]) {
		[parent.presentingViewController dismissModalViewControllerAnimated:YES];
	} else {
		[parent.parentViewController dismissModalViewControllerAnimated:YES];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(UIWebView *)webView {
	return (UIWebView *)self.view;
}

-(void)loadView {
	
	self.title = @"T&Cs and Privacy Policy";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																							target:self
																							action:@selector(done)];
	
	self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	self.spinner.hidesWhenStopped = YES;
	
	CGRect bounds = CGRectMake(0, 0, 320, 460);
	UIWebView *web = [[UIWebView alloc] initWithFrame:bounds];
	web.delegate = self;
	
	NSURL *licenseUrl = nil;
	
	if (self.version.length == 0)
		licenseUrl = [NSURL URLWithString:kSPLicensesNoVersionURL];
	else 
		licenseUrl = [NSURL URLWithString:[NSString stringWithFormat:kSPLicensesFormatter, self.version]];
	
	[web loadRequest:[NSURLRequest requestWithURL:licenseUrl]];
	
	for(id maybeScroll in web.subviews) {
		if ([maybeScroll respondsToSelector:@selector(setBounces:)])
			((UIScrollView *)maybeScroll).bounces = NO;
	}
	
	self.view = web;
	[self.view addSubview:self.spinner];
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	self.spinner.layer.position = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
	[self.spinner startAnimating];
}

-(void)viewDidUnload {
	self.spinner = nil;
	[super viewDidUnload];
}

#pragma mark - WebView

-(void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
	if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
        // Just ignore, this is just an async call being cancelled
        return;
    }

	// Show error page if license didn't load
	NSURL *bundlePath = [[NSBundle mainBundle] URLForResource:@"SPLoginResources" withExtension:@"bundle"];
	NSBundle *resourcesBundle = [NSBundle bundleWithURL:bundlePath];
	
	NSURL *fileUrl = [resourcesBundle URLForResource:@"toc_error" withExtension:@"xhtml" subdirectory:nil];
	NSURL *folderUrl = [fileUrl URLByDeletingLastPathComponent];
	
	NSData *fileData = [NSData dataWithContentsOfURL:fileUrl];
	[webView loadData:fileData MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:folderUrl];
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
	[self.spinner startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
	[self.spinner stopAnimating];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		[[UIApplication sharedApplication] openURL:[request URL]];
		return NO;
	}
	return YES;
}

@end
