//
//  CocoaLibSpotify.h
//  CocoaLibSpotify
//
//  Created by Daniel Kennett on 8/25/11.
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

/* 
 This file allows us to keep the main CocoaLibSpotify as platform-agnostic as possible.
*/

#if TARGET_OS_IPHONE
#import "api.h"
#import <UIKit/UIKit.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "SPCommon.h"
#import "SPAsyncLoading.h"
#define SPPlatformNativeImage UIImage
#else
#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudio.h>
#import <libspotify/api.h>
#import <CocoaLibSpotify/SPCommon.h>
#import <CocoaLibSpotify/SPAsyncLoading.h>
#define SPPlatformNativeImage NSImage
#endif