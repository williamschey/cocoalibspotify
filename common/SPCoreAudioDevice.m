//
//  SPCoreAudioDevice.m
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

#import "SPCoreAudioDevice.h"

@interface SPCoreAudioDevice ()

@property (nonatomic, readwrite, copy) NSString *name;
@property (nonatomic, readwrite, copy) NSString *UID;
@property (nonatomic, readwrite, copy) NSString *manufacturer;
@property (nonatomic, readwrite) AudioDeviceID deviceId;
@property (nonatomic, readwrite, copy) NSArray *sources;

@end

@interface SPCoreAudioDeviceSource ()

-(id)initWithId:(UInt32)sourceId inDevice:(SPCoreAudioDevice *)device;

@property (nonatomic, readwrite, copy) NSString *name;
@property (nonatomic, readwrite) UInt32 sourceId;
@property (nonatomic, readwrite, assign) __unsafe_unretained SPCoreAudioDevice *device;

-(void)updateName;

@end

static OSStatus AOSourceChangedPropertyListenerProc(AudioObjectID inObjectID,
													UInt32 inNumberAddresses,
													const AudioObjectPropertyAddress inAddresses[],
													void * inClientData);

@implementation SPCoreAudioDevice

-(id)initWithDeviceId:(AudioDeviceID)deviceId {
	self = [super init];
	if (self) {
		self.deviceId = deviceId;
		self.UID = [self outputDeviceStringPropertyForSelector:kAudioDevicePropertyDeviceUID];

		if (self.UID == nil)
			return nil;

		self.name = [self outputDeviceStringPropertyForSelector:kAudioDevicePropertyDeviceNameCFString];
		self.manufacturer = [self outputDeviceStringPropertyForSelector:kAudioDevicePropertyDeviceManufacturerCFString];
		self.sources = [self queryAudioSources];

		// Add observer for audio source changes
		AudioObjectPropertyAddress sourcesPropertyAddress;
		sourcesPropertyAddress.mSelector = kAudioDevicePropertyDataSources;
		sourcesPropertyAddress.mScope = kAudioDevicePropertyScopeOutput;
		sourcesPropertyAddress.mElement = kAudioObjectPropertyElementMaster;
		AudioObjectAddPropertyListener(self.deviceId, &sourcesPropertyAddress, AOSourceChangedPropertyListenerProc, (__bridge void *)self);

		AudioObjectPropertyAddress namePropertyAddress;
		namePropertyAddress.mSelector = kAudioDevicePropertyDataSourceNameForIDCFString;
		namePropertyAddress.mScope = kAudioDevicePropertyScopeOutput;
		namePropertyAddress.mElement = kAudioObjectPropertyElementMaster;
		AudioObjectAddPropertyListener(self.deviceId, &namePropertyAddress, AOSourceChangedPropertyListenerProc, (__bridge void *)self);



	}
	return self;
}

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: Device ID %@, %@", [super description], self.UID, self.name];
}

+(NSSet *)keyPathsForValuesAffectingUiName {
	return [NSSet setWithObjects:@"sources", @"name", nil];
}

-(NSString *)uiName {
	if (self.sources.count == 1)
		return [[self.sources lastObject] name];
	else
		return self.name;
}

-(NSString *)outputDeviceStringPropertyForSelector:(AudioObjectPropertySelector)selector {

	AudioObjectPropertyAddress propertyAddress;
	propertyAddress.mSelector = selector;
	propertyAddress.mScope = kAudioObjectPropertyScopeOutput;
	propertyAddress.mElement = kAudioObjectPropertyElementMaster;

	CFStringRef stringValue = NULL;
	UInt32 dataSize = sizeof(stringValue);
	OSStatus status = AudioObjectGetPropertyData(self.deviceId, &propertyAddress, 0, NULL, &dataSize, &stringValue);

	if (status == kAudioHardwareNoError)
		return (__bridge_transfer NSString *)stringValue;

	return nil;
}

-(NSArray *)queryAudioSources {

	AudioObjectPropertyAddress propertyAddress;
	propertyAddress.mSelector = kAudioDevicePropertyDataSources;
	propertyAddress.mScope = kAudioDevicePropertyScopeOutput;
	propertyAddress.mElement = kAudioObjectPropertyElementMaster;

	UInt32 propsize = 0;
	OSStatus status = AudioObjectGetPropertyDataSize(self.deviceId, &propertyAddress, 0, NULL, &propsize);
	if (status != kAudioHardwareNoError)
		return nil;

	// list of sourceIds
	UInt32 *sourceIds = malloc(propsize);
	status = AudioObjectGetPropertyData(self.deviceId, &propertyAddress, 0, NULL, &propsize, sourceIds);
	if (status != kAudioHardwareNoError) {
		free(sourceIds);
		return nil;
	}

	NSUInteger sourceCount = (propsize / sizeof(UInt32));
	NSMutableArray *sources = [NSMutableArray arrayWithCapacity:sourceCount];

	for (UInt32 sourceIndex = 0; sourceIndex < sourceCount; sourceIndex++) {
		SPCoreAudioDeviceSource *source = [[SPCoreAudioDeviceSource alloc] initWithId:sourceIds[sourceIndex]
																			 inDevice:self];
		if (source)
			[sources addObject:source];
	}

	free(sourceIds);

	if (sources.count > 0)
		return [NSArray arrayWithArray:sources];
	else
		return nil;
}

-(BOOL)isEqual:(id)object {
	if (![object isKindOfClass:[self class]])
		return NO;
	return [[object UID] isEqualToString:self.UID];
}

+(NSSet *)keyPathsForValuesAffectingActiveSources {
	return [NSSet setWithObject:@"sources"];
}

-(void)setActiveSources:(NSArray *)sources {

	if (sources.count < 1)
		return;

	for (SPCoreAudioDeviceSource *source in sources) {
		if (![self.sources containsObject:source]) {
			[[NSException exceptionWithName:@"com.spotify.SPCoreAudioController.InvalidSource"
									 reason:@"sources array contained a source not present in this device."
								   userInfo:nil] raise];
			return;
		}
	}

	UInt32 sourcesSize = (UInt32)(sizeof(UInt32) * sources.count);
	UInt32 *sourceIds = malloc(sourcesSize);

	for (NSUInteger i = 0; i < sources.count; i++)
		sourceIds[i] = ((SPCoreAudioDeviceSource *)sources[i]).sourceId;

	AudioObjectPropertyAddress addr;
	addr.mSelector = kAudioDevicePropertyDataSource;
	addr.mScope = kAudioDevicePropertyScopeOutput;
	addr.mElement = kAudioObjectPropertyElementMaster;

	AudioObjectSetPropertyData(self.deviceId, &addr, 0, NULL, sourcesSize, sourceIds);

	free(sourceIds);
}

-(NSArray *)activeSources {

	AudioObjectPropertyAddress propertyAddress;
	propertyAddress.mSelector = kAudioDevicePropertyDataSource;
	propertyAddress.mScope = kAudioDevicePropertyScopeOutput;
	propertyAddress.mElement = kAudioObjectPropertyElementMaster;

	UInt32 dataSize = 0;
	OSStatus status = AudioObjectGetPropertyDataSize(self.deviceId, &propertyAddress, 0, NULL, &dataSize);
	if (status != kAudioHardwareNoError)
		return nil;

	UInt32 *activeSourceIds = malloc(dataSize);

	status = AudioObjectGetPropertyData(self.deviceId, &propertyAddress, 0, NULL, &dataSize, activeSourceIds);
	if(status != kAudioHardwareNoError) {
		free(activeSourceIds);
		return nil;
	}

	NSUInteger numberOfActiveSources = dataSize / sizeof(UInt32);
	NSMutableArray *activeSources = [NSMutableArray arrayWithCapacity:numberOfActiveSources];

	for (int i = 0; i < numberOfActiveSources; i++) {

		UInt32 sourceId = activeSourceIds[i];
		SPCoreAudioDeviceSource *source = nil;
		for (SPCoreAudioDeviceSource *potentialSource in self.sources) {
			if (potentialSource.sourceId == sourceId) {
				source = potentialSource;
				break;
			}
		}

		if (source != nil)
			[activeSources addObject:source];
		else
			NSLog(@"[%@ %@]: Source id %@ not found!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @(sourceId));

	}

	free(activeSourceIds);

	if (activeSources.count > 0)
		return [NSArray arrayWithArray:activeSources];
	else
		return nil;
}

static OSStatus AOSourceChangedPropertyListenerProc(AudioObjectID inObjectID,
													UInt32 inNumberAddresses,
													const AudioObjectPropertyAddress inAddresses[],
													void * inClientData) {

	SPCoreAudioDevice *device = (__bridge SPCoreAudioDevice *)inClientData;

	for (NSUInteger x = 0; x < inNumberAddresses; x++) {
		if (inAddresses[x].mSelector == kAudioDevicePropertyDataSources) {
			device.sources = [device queryAudioSources];

		} else if (inAddresses[x].mSelector == kAudioDevicePropertyDataSourceNameForIDCFString) {
			for (SPCoreAudioDeviceSource *source in device.sources)
				[source updateName];
		}
	}
	return noErr;
}


@end

@implementation SPCoreAudioDeviceSource

-(id)initWithId:(UInt32)sourceId inDevice:(SPCoreAudioDevice *)device {
	self = [super init];
	if (self) {
		self.sourceId = sourceId;
		self.device = device;
		[self updateName];
	}
	return self;
}

-(BOOL)isEqual:(id)object {
	if (![object isKindOfClass:[self class]])
		return NO;
	return ([self sourceId] == [object sourceId]) && ([self device] == [object device]);
}

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: Source Id %@: %@", [super description], @(self.sourceId), self.name];
}

-(void)updateName {

	AudioObjectPropertyAddress nameAddr;
	nameAddr.mSelector = kAudioDevicePropertyDataSourceNameForIDCFString;
	nameAddr.mScope = kAudioObjectPropertyScopeOutput;
	nameAddr.mElement = kAudioObjectPropertyElementMaster;

	CFStringRef value = NULL;
	UInt32 sourceId = self.sourceId;

	AudioValueTranslation audioValueTranslation;
	audioValueTranslation.mInputDataSize = sizeof(UInt32);
	audioValueTranslation.mOutputData = (void *)&value;
	audioValueTranslation.mOutputDataSize = sizeof(CFStringRef);
	audioValueTranslation.mInputData = (void *)&sourceId;

	UInt32 propsize = sizeof(AudioValueTranslation);

	OSStatus status = AudioObjectGetPropertyData(self.device.deviceId, &nameAddr, 0, NULL, &propsize, &audioValueTranslation);
	if (status == kAudioHardwareNoError) {
		NSString *newName = (__bridge_transfer NSString *)value;
		if (![newName isEqualToString:self.name])
			self.name = newName;
	}
}

@end
