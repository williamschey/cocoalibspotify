//
//  SPCoreAudioController.m
//  Viva
//
//  Created by Daniel Kennett on 04/02/2012.
//  For license information, see LICENSE.markdown
//

#import "SPCoreAudioController.h"
#import "SPCircularBuffer.h"

#import <AudioUnit/AudioUnit.h>

#if TARGET_OS_IPHONE
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "CocoaLibSpotify.h"
#else
#import <CoreAudio/CoreAudio.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#endif

#if !TARGET_OS_IPHONE

@interface SPCoreAudioDevice ()

@property (nonatomic, readwrite, copy) NSString *name;
@property (nonatomic, readwrite, copy) NSString *UID;
@property (nonatomic, readwrite, copy) NSString *manufacturer;
@property (nonatomic, readwrite) AudioDeviceID deviceId;

@end

@implementation SPCoreAudioDevice

-(BOOL)isEqual:(id)object {
	if (![object isKindOfClass:[self class]])
		return NO;
	return [[object UID] isEqualToString:self.UID];
}

@end

#endif

@interface SPCoreAudioController ()

// Core Audio
-(BOOL)setupCoreAudioWithInputFormat:(AudioStreamBasicDescription)inputFormat error:(NSError **)err;
-(void)teardownCoreAudio;
-(void)startAudioQueue;
-(void)stopAudioQueue;
-(void)applyVolumeToMixerAudioUnit:(double)vol;
-(void)applyAudioStreamDescriptionToInputUnit:(AudioStreamBasicDescription)newInputDescription;

@property (readwrite, nonatomic, copy) NSArray *availableOutputDevices;

@property (readwrite, nonatomic) AudioStreamBasicDescription inputAudioDescription;

static OSStatus AudioUnitRenderDelegateCallback(void *inRefCon,
												AudioUnitRenderActionFlags *ioActionFlags,
												const AudioTimeStamp *inTimeStamp,
												UInt32 inBusNumber,
												UInt32 inNumberFrames,
												AudioBufferList *ioData);

#if !TARGET_OS_IPHONE

-(NSArray *)queryOutputDevices:(NSError **)error;

static OSStatus AOPropertyListenerProc(AudioObjectID inObjectID,
									   UInt32 inNumberAddresses,
									   const AudioObjectPropertyAddress inAddresses[],
									   void * inClientData);
#endif

@property (readwrite, strong, nonatomic) SPCircularBuffer *audioBuffer;

@end

static NSTimeInterval const kTargetBufferLength = 0.5;

@implementation SPCoreAudioController {
	
	AUGraph audioProcessingGraph;
	AudioUnit outputUnit;
	AudioUnit mixerUnit;
	AudioUnit inputConverterUnit;
	
	AUNode inputConverterNode;
	AUNode mixerNode;
	AUNode outputNode;
	
	UInt32 framesSinceLastTimeUpdate;
	
	NSMethodSignature *incrementTrackPositionMethodSignature;
	NSInvocation *incrementTrackPositionInvocation;
}

-(id)init {
	self = [super init];
	
	if (self) {
		self.volume = 1.0;
		self.audioOutputEnabled = NO; // Don't start audio playback until we're told.
		
		SEL incrementTrackPositionSelector = @selector(incrementTrackPositionWithFrameCount:);
		incrementTrackPositionMethodSignature = [SPCoreAudioController instanceMethodSignatureForSelector:incrementTrackPositionSelector];
		incrementTrackPositionInvocation = [NSInvocation invocationWithMethodSignature:incrementTrackPositionMethodSignature];
		[incrementTrackPositionInvocation setSelector:incrementTrackPositionSelector];
		[incrementTrackPositionInvocation setTarget:self];
		
		[self addObserver:self forKeyPath:@"volume" options:0 context:nil];
		[self addObserver:self forKeyPath:@"audioOutputEnabled" options:0 context:nil];

		#if !TARGET_OS_IPHONE
		self.availableOutputDevices = [self queryOutputDevices:nil];
		[self addObserver:self forKeyPath:@"currentOutputDevice" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];

		// Add observer for audio device changes
		AudioObjectPropertyAddress theAddress = { kAudioHardwarePropertyDevices,
			kAudioObjectPropertyScopeGlobal,
			kAudioObjectPropertyElementMaster };

		AudioObjectAddPropertyListener(kAudioObjectSystemObject, &theAddress, AOPropertyListenerProc, (__bridge void *)self);
		#endif
	}
	return self;
}

-(void)dealloc {

	#if !TARGET_OS_IPHONE
	// Remove observer for audio device changes
	AudioObjectPropertyAddress theAddress = { kAudioHardwarePropertyDevices,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster };

	AudioObjectRemovePropertyListener(kAudioObjectSystemObject, &theAddress, AOPropertyListenerProc, (__bridge void *)self);

	[self removeObserver:self forKeyPath:@"currentOutputDevice"];
	#endif

	[self removeObserver:self forKeyPath:@"volume"];
	[self removeObserver:self forKeyPath:@"audioOutputEnabled"];
	
	[self clearAudioBuffers];
	self.audioOutputEnabled = NO;
	[self teardownCoreAudio];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	if ([keyPath isEqualToString:@"volume"]) {
		[self applyVolumeToMixerAudioUnit:self.volume];

	#if !TARGET_OS_IPHONE
	} else if ([keyPath isEqualToString:@"currentOutputDevice"]) {

		if (outputUnit == NULL)
			return;

		id oldSelection = [change valueForKey:NSKeyValueChangeOldKey];
		id newSelection = [change valueForKey:NSKeyValueChangeNewKey];

		if ((oldSelection == [NSNull null] && newSelection != [NSNull null]) ||
			(oldSelection != [NSNull null] && newSelection == [NSNull null])) {
			// If the device is shifting to/from NULL, we need to change the output unit
			[self stopAudioQueue];
			NSError *error = nil;
			if (![self setupAudioOutputFromBus:0 ofNode:mixerNode inGraph:audioProcessingGraph error:&error])
				NSLog(@"Couldn't change output audio unit: %@", error);
			[self startAudioQueue];
		} else if (self.currentOutputDevice != nil) {
			NSError *error = nil;
			if (![self applyOutputDeviceWithUIDToAudioOutput:self.currentOutputDevice.UID error:&error])
				NSLog(@"Couldn't change output device: %@", error);
		}
	#endif

	} else if ([keyPath isEqualToString:@"audioOutputEnabled"]) {
		if (self.audioOutputEnabled)
			[self startAudioQueue];
		else
			[self stopAudioQueue];
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@synthesize volume;
@synthesize audioOutputEnabled;
@synthesize audioBuffer;
@synthesize inputAudioDescription;
@synthesize delegate;

#pragma mark -
#pragma mark CocoaLS Audio Delivery

-(NSInteger)session:(id <SPSessionPlaybackProvider>)aSession shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount streamDescription:(AudioStreamBasicDescription)audioDescription {
	
	if (frameCount == 0) {
		[self clearAudioBuffers];
		return 0; // Audio discontinuity!
	}
	
    if (audioProcessingGraph == NULL) {
        NSError *error = nil;
        if (![self setupCoreAudioWithInputFormat:audioDescription error:&error]) {
            NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
            return 0;
        }
    }
	
	AudioStreamBasicDescription currentAudioInputDescription = self.inputAudioDescription;
	
	if (audioDescription.mBitsPerChannel != currentAudioInputDescription.mBitsPerChannel ||
		audioDescription.mBytesPerFrame != currentAudioInputDescription.mBytesPerFrame ||
		audioDescription.mChannelsPerFrame != currentAudioInputDescription.mChannelsPerFrame ||
		audioDescription.mFormatFlags != currentAudioInputDescription.mFormatFlags ||
		audioDescription.mFormatID != currentAudioInputDescription.mFormatID ||
		audioDescription.mSampleRate != currentAudioInputDescription.mSampleRate) {
		// New format. Panic!! I mean, calmly tell Core Audio that a new audio format is incoming.
		[self clearAudioBuffers];
		[self applyAudioStreamDescriptionToInputUnit:audioDescription];
	}

	NSUInteger bytesToAdd = frameCount * audioDescription.mBytesPerPacket;
	NSUInteger bytesAdded = [self.audioBuffer attemptAppendData:audioFrames
													   ofLength:bytesToAdd
													  chunkSize:audioDescription.mBytesPerPacket];

	NSUInteger framesAdded = bytesAdded / audioDescription.mBytesPerPacket;
	return framesAdded;
}


#pragma mark -
#pragma mark Audio Unit Properties

-(void)applyVolumeToMixerAudioUnit:(double)vol {
    
    if (audioProcessingGraph == NULL || mixerUnit == NULL)
        return;
	
	OSErr status = AudioUnitSetParameter(mixerUnit,
										 kMultiChannelMixerParam_Volume,
										 kAudioUnitScope_Output, 
										 0,
										 vol * vol * vol,
										 0);
	
	if (status != noErr) {
		NSError *error;
        fillWithError(&error, @"Couldn't set input format", status);
		NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
    }
}

-(void)applyAudioStreamDescriptionToInputUnit:(AudioStreamBasicDescription)newInputDescription {
	
	if (audioProcessingGraph == NULL || inputConverterUnit == NULL)
		return;
	
	OSStatus status = AudioUnitSetProperty(inputConverterUnit,
								  kAudioUnitProperty_StreamFormat,
								  kAudioUnitScope_Input,
								  0,
								  &newInputDescription,
								  sizeof(newInputDescription));
	if (status != noErr) {
		NSError *error;
        fillWithError(&error, @"Couldn't set input format", status);
		NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
    } else {
		self.inputAudioDescription = newInputDescription;
		[self clearAudioBuffers];
		self.audioBuffer = [[SPCircularBuffer alloc] initWithMaximumLength:(newInputDescription.mBytesPerFrame * newInputDescription.mSampleRate) * kTargetBufferLength];
	}
}

#pragma mark -
#pragma mark Queue Control

-(void)startAudioQueue {
    if (audioProcessingGraph == NULL)
        return;
	
	Boolean isRunning = NO;
	AUGraphIsRunning(audioProcessingGraph, &isRunning);
	if (isRunning)
		return;
	
    AUGraphStart(audioProcessingGraph);
}

-(void)stopAudioQueue {
    if (audioProcessingGraph == NULL)
        return;
    
	Boolean isRunning = NO;
	AUGraphIsRunning(audioProcessingGraph, &isRunning);
	
	if (!isRunning)
		return;

	AUGraphStop(audioProcessingGraph);
}

-(void)clearAudioBuffers {
	[self.audioBuffer clear];
}

#pragma mark -
#pragma mark Setup and Teardown

-(void)teardownCoreAudio {
    if (audioProcessingGraph == NULL)
        return;
    
    [self stopAudioQueue];
	[self disposeOfCustomNodesInGraph:audioProcessingGraph];
	
	AUGraphUninitialize(audioProcessingGraph);
	DisposeAUGraph(audioProcessingGraph);
	
#if TARGET_OS_IPHONE
	[[AVAudioSession sharedInstance] setActive:NO error:nil];
#endif
	
	audioProcessingGraph = NULL;
	outputUnit = NULL;
	mixerUnit = NULL;
	inputConverterUnit = NULL;
}

-(void)disposeOfCustomNodesInGraph:(AUGraph)graph {
	// Empty implementation — for subclasses to override.
}

-(BOOL)setupCoreAudioWithInputFormat:(AudioStreamBasicDescription)inputFormat error:(NSError **)err {
    
    if (audioProcessingGraph != NULL)
        [self teardownCoreAudio];
	
#if TARGET_OS_IPHONE
	NSError *error = nil;
	BOOL success = YES;
	success &= [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
	success &= [[AVAudioSession sharedInstance] setActive:YES error:&error];
	
	if (!success && err != NULL) {
		*err = error;
		return NO;
	}
#endif
	
	// A description of the mixer unit
	AudioComponentDescription mixerDescription;
	mixerDescription.componentType = kAudioUnitType_Mixer;
	mixerDescription.componentSubType = kAudioUnitSubType_MultiChannelMixer;
	mixerDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	mixerDescription.componentFlags = 0;
	mixerDescription.componentFlagsMask = 0;
	
	// A description for the libspotify -> standard PCM device
	AudioComponentDescription converterDescription;
	converterDescription.componentType = kAudioUnitType_FormatConverter;
	converterDescription.componentSubType = kAudioUnitSubType_AUConverter;
	converterDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	converterDescription.componentFlags = 0;
	converterDescription.componentFlagsMask = 0;
    
	// Create an AUGraph
	OSErr status = NewAUGraph(&audioProcessingGraph);
	if (status != noErr) {
        fillWithError(err, @"Couldn't init graph", status);
        return NO;
    }
	
	// Open the graph. AudioUnits are open but not initialized (no resource allocation occurs here)
	AUGraphOpen(audioProcessingGraph);
	if (status != noErr) {
        fillWithError(err, @"Couldn't open graph", status);
        return NO;
    }
	
	// Add mixer
	status = AUGraphAddNode(audioProcessingGraph, &mixerDescription, &mixerNode);
	if (status != noErr) {
        fillWithError(err, @"Couldn't add mixer node", status);
        return NO;
    }
	
	// Get mixer unit so we can change volume etc
	status = AUGraphNodeInfo(audioProcessingGraph, mixerNode, NULL, &mixerUnit);
	if (status != noErr) {
        fillWithError(err, @"Couldn't get mixer unit", status);
        return NO;
    }
	
	// Set mixer bus count
	UInt32 busCount = 1;
	status = AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &busCount, sizeof(busCount));
	if (status != noErr) {
        fillWithError(err, @"Couldn't set mixer bus count", status);
        return NO;
    }
	
	// Set mixer input volume
	status = AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 0, 1.0, 0);
	if (status != noErr) {
        fillWithError(err, @"Couldn't set mixer volume", status);
        return NO;
    }
	
	// Create PCM converter
	status = AUGraphAddNode(audioProcessingGraph, &converterDescription, &inputConverterNode);
	if (status != noErr) {
        fillWithError(err, @"Couldn't add converter node", status);
        return NO;
    }
	
	status = AUGraphNodeInfo(audioProcessingGraph, inputConverterNode, NULL, &inputConverterUnit);
	if (status != noErr) {
        fillWithError(err, @"Couldn't get input unit", status);
        return NO;
    }
	
	if (![self setupAudioOutputFromBus:0 ofNode:mixerNode inGraph:audioProcessingGraph error:err])
		return NO;
	
	if (![self connectOutputBus:0 ofNode:inputConverterNode toInputBus:0 ofNode:mixerNode inGraph:audioProcessingGraph error:err])
		return NO;
	
	// Set render callback
	AURenderCallbackStruct rcbs;
	rcbs.inputProc = AudioUnitRenderDelegateCallback;
	rcbs.inputProcRefCon = (__bridge void *)(self);
	
	status = AUGraphSetNodeInputCallback(audioProcessingGraph, inputConverterNode, 0, &rcbs);
	if (status != noErr) {
        fillWithError(err, @"Couldn't add render callback", status);
        return NO;
    }
	
	// Finally, set the kAudioUnitProperty_MaximumFramesPerSlice of each unit 
	// to 4096, to allow playback on iOS when the screen is locked.
	// Code based on http://developer.apple.com/library/ios/#qa/qa1606/_index.html
	
	UInt32 maxFramesPerSlice = 4096;
	status = AudioUnitSetProperty(inputConverterUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, sizeof(maxFramesPerSlice));
	if (status != noErr) {
		fillWithError(err, @"Couldn't set max frames per slice on input converter", status);
        return NO;
	}
	
	status = AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, sizeof(maxFramesPerSlice));
	if (status != noErr) {
		fillWithError(err, @"Couldn't set max frames per slice on mixer", status);
        return NO;
	}
	
	// Init Queue
	status = AUGraphInitialize(audioProcessingGraph);
	if (status != noErr) {
		fillWithError(err, @"Couldn't initialize graph", status);
        return NO;
	}
	
	AUGraphUpdate(audioProcessingGraph, NULL);
	
	// Apply properties and let's get going!
    [self startAudioQueue];
	[self applyAudioStreamDescriptionToInputUnit:inputFormat];
    [self applyVolumeToMixerAudioUnit:self.volume];
	
    return YES;
}

-(BOOL)connectOutputBus:(UInt32)sourceOutputBusNumber ofNode:(AUNode)sourceNode toInputBus:(UInt32)destinationInputBusNumber ofNode:(AUNode)destinationNode inGraph:(AUGraph)graph error:(NSError **)error {
	
	// Connect converter to mixer
	OSStatus status = AUGraphConnectNodeInput(graph, sourceNode, sourceOutputBusNumber, destinationNode, destinationInputBusNumber);
	if (status != noErr) {
		fillWithError(error, @"Couldn't connect converter to mixer", status);
		return NO;
    }
	
	return YES;
}

static void fillWithError(NSError **mayBeAnError, NSString *localizedDescription, int code) {
    if (mayBeAnError == NULL)
        return;
    
    *mayBeAnError = [NSError errorWithDomain:@"com.CocoaLibSpotify.SPCoreAudioController"
                                        code:code
                                    userInfo:localizedDescription ? [NSDictionary dictionaryWithObject:localizedDescription
                                                                                                forKey:NSLocalizedDescriptionKey]
                                            : nil];
    
}

static OSStatus AudioUnitRenderDelegateCallback(void *inRefCon,
												AudioUnitRenderActionFlags *ioActionFlags,
												const AudioTimeStamp *inTimeStamp,
												UInt32 inBusNumber,
												UInt32 inNumberFrames,
												AudioBufferList *ioData) {
	
    SPCoreAudioController *self = (__bridge SPCoreAudioController *)inRefCon;
	
	AudioBuffer *buffer = &(ioData->mBuffers[0]);
	UInt32 bytesRequired = buffer->mDataByteSize;
	
	NSUInteger availableData = [self.audioBuffer length];
	if (availableData < bytesRequired) {
		buffer->mDataByteSize = 0;
		*ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
		return noErr;
    }
    
    buffer->mDataByteSize = (UInt32)[self.audioBuffer readDataOfLength:bytesRequired intoAllocatedBuffer:&buffer->mData];
    
	self->framesSinceLastTimeUpdate += inNumberFrames;
	
	if (self->framesSinceLastTimeUpdate >= 8820) {
        // Update 5 times per second
		
		@autoreleasepool {
			
			[self->incrementTrackPositionInvocation setArgument:&self->framesSinceLastTimeUpdate atIndex:2];
			[self->incrementTrackPositionInvocation performSelectorOnMainThread:@selector(invoke)
																	 withObject:nil
																  waitUntilDone:NO];
			self->framesSinceLastTimeUpdate = 0;
			
		}
	}
    
    return noErr;
}

-(void)incrementTrackPositionWithFrameCount:(UInt32)framesToAppend {
	[self.delegate coreAudioController:self didOutputAudioOfDuration:framesToAppend/self.inputAudioDescription.mSampleRate];
}

#pragma mark - Output devices

#if !TARGET_OS_IPHONE

static OSStatus AOPropertyListenerProc(AudioObjectID inObjectID,
									   UInt32 inNumberAddresses,
									   const AudioObjectPropertyAddress inAddresses[],
									   void * inClientData) {

	SPCoreAudioController *controller = (__bridge SPCoreAudioController *)inClientData;
	
	for (NSUInteger x = 0; x < inNumberAddresses; x++) {
		if (inAddresses[x].mSelector == kAudioHardwarePropertyDevices) {

			dispatch_async(dispatch_get_main_queue(), ^{

				NSArray *newDevices = [controller queryOutputDevices:nil];
				controller.availableOutputDevices = newDevices;
				if (controller.currentOutputDevice != nil &&
					![controller.availableOutputDevices containsObject:controller.currentOutputDevice])
					controller.currentOutputDevice = nil;
			});

		}
	}
	return noErr;
}

-(NSString *)outputDeviceStringPropertyForSelector:(AudioObjectPropertySelector)selector ofDevice:(AudioDeviceID)device {
	
	AudioObjectPropertyAddress propertyAddress;
	propertyAddress.mSelector = selector;
	propertyAddress.mScope = kAudioObjectPropertyScopeOutput;
	propertyAddress.mElement = kAudioObjectPropertyElementMaster;

	CFStringRef stringValue = NULL;
	UInt32 dataSize = sizeof(stringValue);
	OSStatus status = AudioObjectGetPropertyData(device, &propertyAddress, 0, NULL, &dataSize, &stringValue);

	if (status == kAudioHardwareNoError)
		return (__bridge_transfer NSString *)stringValue;

	return nil;
}

-(NSUInteger)numberOfOutputBuffersInDevice:(AudioDeviceID)device {

	NSUInteger numberOfChannels = 0;

	AudioObjectPropertyAddress propertyAddress;
	propertyAddress.mSelector = kAudioDevicePropertyStreamConfiguration;
	propertyAddress.mScope = kAudioObjectPropertyScopeOutput;
	propertyAddress.mElement = kAudioObjectPropertyElementMaster;

	// Determine if the device is an output device (it is an output device if it has output channels)
	UInt32 dataSize = 0;
	OSStatus status = AudioObjectGetPropertyDataSize(device, &propertyAddress, 0, NULL, &dataSize);
	if (status != kAudioHardwareNoError)
		return numberOfChannels;

	AudioBufferList *bufferList = malloc(dataSize);

	status = AudioObjectGetPropertyData(device, &propertyAddress, 0, NULL, &dataSize, bufferList);
	if(status == kAudioHardwareNoError)
		numberOfChannels = bufferList->mNumberBuffers;

	free(bufferList), bufferList = NULL;
	return numberOfChannels;
}

-(NSArray *)queryOutputDevices:(NSError **)error {

	AudioObjectPropertyAddress propertyAddress;
	propertyAddress.mSelector = kAudioHardwarePropertyDevices;
	propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
	propertyAddress.mElement = kAudioObjectPropertyElementMaster;

    UInt32 dataSize = 0;
    OSStatus status = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &dataSize);
	if (status != kAudioHardwareNoError) {
        fillWithError(error, @"Couldn't get data size", status);
        return nil;
    }

    UInt32 deviceCount = (dataSize / sizeof(AudioDeviceID));
    AudioDeviceID *audioDevices = malloc(dataSize);

    status = AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &dataSize, audioDevices);
	if (status != kAudioHardwareNoError) {
        fillWithError(error, @"Couldn't get audio device count", status);
        free(audioDevices), audioDevices = NULL;
		return nil;
    }

	NSMutableArray *devices = [NSMutableArray arrayWithCapacity:deviceCount];

    // Iterate through all the devices and determine which are output-capable
    for(NSUInteger i = 0; i < deviceCount; i++) {

		NSString *deviceUID = [self outputDeviceStringPropertyForSelector:kAudioDevicePropertyDeviceUID ofDevice:audioDevices[i]];
		NSString *deviceName = [self outputDeviceStringPropertyForSelector:kAudioDevicePropertyDeviceNameCFString ofDevice:audioDevices[i]];
		NSString *deviceManufacturer = [self outputDeviceStringPropertyForSelector:kAudioDevicePropertyDeviceManufacturerCFString ofDevice:audioDevices[i]];

		if (deviceName == nil || deviceUID == nil || deviceManufacturer == nil)
			continue;

        if ([self numberOfOutputBuffersInDevice:audioDevices[i]] == 0)
			continue;

		SPCoreAudioDevice *device = [SPCoreAudioDevice new];
		device.name = deviceName;
		device.UID = deviceUID;
		device.manufacturer = deviceManufacturer;
		device.deviceId = audioDevices[i];

		[devices addObject:device];
    }

    free(audioDevices), audioDevices = NULL;
    return [NSArray arrayWithArray:devices];
}

#endif

-(BOOL)setupAudioOutputFromBus:(UInt32)sourceOutputBusNumber ofNode:(AUNode)sourceNode inGraph:(AUGraph)graph error:(NSError *__autoreleasing *)error {

	// First, remove the output node

	if (outputNode != 0) {

		// Disconnect mixer from output
		OSStatus status = AUGraphDisconnectNodeInput(graph, outputNode, 0);
		if (status != noErr) {
			fillWithError(error, @"Couldn't disconnect old output node", status);
			return NO;
		}

		status = AUGraphRemoveNode(graph, outputNode);
		if (status != noErr) {
			fillWithError(error, @"Couldn't remove old output node", status);
			return NO;
		}

		AUGraphUpdate(graph, NULL);

		outputUnit = NULL;
	}

	// A description of the output device we're looking for.
    AudioComponentDescription outputDescription;
	outputDescription.componentType = kAudioUnitType_Output;
#if TARGET_OS_IPHONE
	outputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
#else
    outputDescription.componentSubType = self.currentOutputDevice == nil ? kAudioUnitSubType_DefaultOutput : kAudioUnitSubType_HALOutput;
#endif
    outputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    outputDescription.componentFlags = 0;
    outputDescription.componentFlagsMask = 0;

	// Add audio output...
	OSStatus status = AUGraphAddNode(graph, &outputDescription, &outputNode);
	if (status != noErr) {
        fillWithError(error, @"Couldn't add output node", status);
        return NO;
    }

	// Get output unit
	status = AUGraphNodeInfo(graph, outputNode, NULL, &outputUnit);
	if (status != noErr) {
        fillWithError(error, @"Couldn't get output unit", status);
        return NO;
    }

	// Connect mixer to output
	status = AUGraphConnectNodeInput(graph, sourceNode, sourceOutputBusNumber, outputNode, 0);
	if (status != noErr) {
        fillWithError(error, @"Couldn't connect mixer to output", status);
        return NO;
    }

	UInt32 maxFramesPerSlice = 4096;
	status = AudioUnitSetProperty(outputUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, sizeof(maxFramesPerSlice));
	if (status != noErr) {
		fillWithError(error, @"Couldn't set max frames per slice on output", status);
        return NO;
	}

	#if !TARGET_OS_IPHONE
	if (self.currentOutputDevice != nil) {
		if (![self applyOutputDeviceWithUIDToAudioOutput:self.currentOutputDevice.UID error:error])
			return NO;
	}
	#endif

	AUGraphUpdate(graph, NULL);

	return YES;
}

#if !TARGET_OS_IPHONE

-(BOOL)applyOutputDeviceWithUIDToAudioOutput:(NSString *)uid error:(NSError **)error {

	if (outputUnit == NULL) {
		fillWithError(error, @"Can't apply output device to NULL output unit", 0);
		return NO;
	}

	AudioDeviceID deviceId = kAudioObjectUnknown;

	for (SPCoreAudioDevice *device in self.availableOutputDevices)
		if ([device.UID isEqualToString:uid])
			deviceId = device.deviceId;

	if (deviceId == kAudioObjectUnknown) {
		fillWithError(error, @"Can't find output device", deviceId);
        return NO;
	}

	//set AudioDeviceID of desired device
	OSStatus status = AudioUnitSetProperty(outputUnit,
										   kAudioOutputUnitProperty_CurrentDevice,
										   kAudioUnitScope_Output,
										   0,
										   &deviceId,
										   sizeof(deviceId));

	if (status != noErr) {
		fillWithError(error, @"Can't apply new output device to audio unit", status);
        return NO;
	}

	return YES;
}

#endif

@end
