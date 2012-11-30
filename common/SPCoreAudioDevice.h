//
//  SPCoreAudioDevice.h
//  CocoaLibSpotify Mac Framework
//
//  Created by Daniel Kennett on 30/11/2012.
/*
 Copyright (c) 2011, Spotify AB
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of Spotify AB nor the names of its contributors may
 be used to endorse or promote products derived from this software
 without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL SPOTIFY AB BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
@property (nonatomic, readonly) __unsafe_unretained SPCoreAudioDevice *device;

@end
