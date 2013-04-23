//
//  SPCoreAudioDevice.h
//  CocoaLibSpotify Mac Framework
//
//  Created by Daniel Kennett on 30/11/2012.
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

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

/** Defines an audio output device for SPCoreAudioController. Mac only. */

@interface SPCoreAudioDevice : NSObject

/** Initialise a device with the given device ID. */
-(id)initWithDeviceId:(AudioDeviceID)deviceId;

/** Returns the name of the audio device. */
@property (nonatomic, readonly, copy) NSString *name;

/** Returns a name more suited for display in the user interface. */
@property (nonatomic, readonly, copy) NSString *uiName;

/** Returns the UID of the audio device, suitable for saving which device the user chose. */
@property (nonatomic, readonly, copy) NSString *UID;

/** Returns the manufacturer of the audio device. */
@property (nonatomic, readonly, copy) NSString *manufacturer;

/** Returns the Core Audio device ID of the audio device. */
@property (nonatomic, readonly) AudioDeviceID deviceId;

/** Returns an array of audio output sources the audio device provides. */
@property (nonatomic, readonly, copy) NSArray *sources;

/** Returns an array of the audio output sources that are active. */
-(NSArray *)activeSources;

/** Set the active sources of the device. 
 
 The source(s) in the passed array must be present in the `sources` property.

 @warning When setting this property, you need to provide at least one active
 source. If you pass `nil` or an empty array, no changes will be made.
 */
-(void)setActiveSources:(NSArray *)activeSources;

@end

/** Defines an audio output device source for SPCoreAudioDevice. Mac only. */

@interface SPCoreAudioDeviceSource : NSObject

/** Returns the name of the source. */
@property (nonatomic, readonly, copy) NSString *name;

/** Returns the id of the source. */
@property (nonatomic, readonly) UInt32 sourceId;

/** Returns the parent audio device of the source. */
@property (nonatomic, readonly, weak) SPCoreAudioDevice *device;

@end
