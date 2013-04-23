//
//  SPLoginViewController.h
//  Simple Player
//
//  Created by Daniel Kennett on 10/3/11.
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
#import "CocoaLibSpotify.h"
#import "SPSignupViewController.h"

@class SPLoginViewController;

/**
 Provides a completion callback from SPLoginViewController. SPLoginViewController
 can cause multiple login and logout events during the login and signup process. This
 delegate informs you when the process is complete.
 */
@protocol SPLoginViewControllerDelegate <NSObject>

/** Called when the login/signup process has completed.
 
 @param controller The SPLoginViewController instance that generated the message.
 @param didLogin `YES` if the user successfully logged in, otherwise `NO`..
 */
-(void)loginViewController:(SPLoginViewController *)controller didCompleteSuccessfully:(BOOL)didLogin;

@end

/** This class provides a Spotify-designed login and signup flow for your application. iOS only.
 
 @warning *Important:* You must also include the provided `SPLoginResources.bundle` bundle 
 as a resource in your application to use this class.
 
 If you want to save the user's details for automatic login, use the appropriate `SPSession`
 delegate method to receive login credentials for storage (don't store the user's raw password),
 then login directly next time using the saved credentias instead of using this view controller.
 If login fails, display the appropriate error and you can then show this view controller for logging in manually again if needed.
 */
@interface SPLoginViewController : UINavigationController <SPSignupPageDelegate>

/** Returns an SPLoginViewController instance for the given session. 
 
 @param session The session to create the SPLoginViewController instance for.
 @return The created SPLoginViewController instance.
 */
+(SPLoginViewController *)loginControllerForSession:(SPSession *)session;

/** Returns whether the view controller allows the user to cancel the login process or not. Defaults to `YES`. */
@property (nonatomic, readwrite) BOOL allowsCancel;

/** Returns whether the view controller dismisses itself after the user successfully logs in. Defaults to `YES`. */
@property (nonatomic, readwrite) BOOL dismissesAfterLogin;

/** Returns the controller's loginDelegate object. */
@property (nonatomic, readwrite, unsafe_unretained) id <SPLoginViewControllerDelegate> loginDelegate;

@end

