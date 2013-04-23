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

#import <UIKit/UIKit.h>
#import "CocoaLibSpotifyPlatformImports.h"

@class SPSession;

static NSString * const kSignupPageIntro = @"mobilehulkintro.en.html";
static NSString * const kSignupPageMerge = @"merge.en.html";

@protocol SPSignupPageDelegate <NSObject>

-(void)signupPageDidCancel:(id)page;
-(void)signupPageDidAccept:(id)page;

@end

@interface SPSignupViewController : UIViewController <UIWebViewDelegate>

+(NSString *)documentNameForSignupPage:(sp_signup_page)page;

-(id)initWithSession:(SPSession *)aSession;

-(void)runJSWhenLoaded:(NSString *)someJs;
-(void)loadDocument:(sp_signup_page)page stillLoading:(BOOL)isLoading recentUser:(NSString *)existingUser features:(NSUInteger)featureMask;
-(void)loadDocument:(NSString *)documentName inFolder:(NSString *)folderName page:(sp_signup_page)page stillLoading:(BOOL)isLoading recentUser:(NSString *)existingUser features:(NSUInteger)featureMask;

@property (nonatomic, readonly, getter = isLoaded) BOOL loaded;
@property (nonatomic, readonly) SPSession *session;
@property (nonatomic, readonly, copy) NSString *currentPage;

@end
