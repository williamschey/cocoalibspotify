//
//  SPClientUpsellViewController.m
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

#import "SPClientUpsellViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "SPURLExtensions.h"
#import "SPSession.h"

#if DEBUG
static NSString * const kClientUpsellPageURL = @"http://libspotify.spotify.s3.amazonaws.com/client-upsell/client-upsell.html";
#else
static NSString * const kClientUpsellPageURL = @"http://ls.scdn.co/client-upsell/client-upsell.html";
#endif

@interface SPClientUpsellViewController ()

@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) SPSession *session;

@end

@implementation SPClientUpsellViewController

-(id)initWithSession:(SPSession *)aSession {
	self = [super init];
	if (self) {
		self.session = aSession;
		self.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	return self;
}

-(void)done {
	if (self.completionBlock) self.completionBlock();
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(UIWebView *)webView {
	return (UIWebView *)self.view;
}

-(void)loadView {
	
	self.title = @"Get Spotify!";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close"
																			  style:UIBarButtonItemStyleDone
																			 target:self
																			 action:@selector(done)];
	
	self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	self.spinner.hidesWhenStopped = YES;
	
	CGRect bounds = CGRectMake(0, 0, 320, 460);
	UIWebView *web = [[UIWebView alloc] initWithFrame:bounds];
	web.delegate = self;
	
	NSString *params = [NSString stringWithFormat:@"?userAgent=%@&platform=%@&locale=%@",
						[NSURL urlEncodedStringForString:self.session.userAgent],
						[NSURL urlEncodedStringForString:[[UIDevice currentDevice] model]],
						[NSURL urlEncodedStringForString:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]]];
	
	NSURL *url = [NSURL URLWithString:[kClientUpsellPageURL stringByAppendingString:params]];
	[web loadRequest:[NSURLRequest requestWithURL:url]];
	
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
	
	// Doh. This page isn't important enough to destroy the login flow, so just finish.
	[self done];
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
	[self.spinner startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
	[self.spinner stopAnimating];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		
		if ([request.URL.absoluteString hasPrefix:@"spotify:"]) {
			[self done];
			return NO;
		}
		
		[[UIApplication sharedApplication] openURL:[request URL]];
		return NO;
	}
	return YES;
}

@end
