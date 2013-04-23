//
//  SPImage.m
//  CocoaLibSpotify
//
//  Created by Daniel Kennett on 2/20/11.
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

#import "SPImage.h"
#import "SPSession.h"
#import "SPURLExtensions.h"

@interface SPImageCallbackProxy : NSObject
// SPImageCallbackProxy is here to bridge the gap between -dealloc and the 
// playlist callbacks being unregistered, since that's done async.
@property (nonatomic, readwrite, weak) SPImage *image;
@end

@implementation SPImageCallbackProxy
@end

@interface SPImage ()

-(void) cacheSpotifyURL;

@property (nonatomic, readwrite) const byte *imageId;
@property (nonatomic, readwrite, strong) SPPlatformNativeImage *image;
@property (nonatomic, readwrite) sp_image *spImage;
@property (nonatomic, readwrite, getter=isLoaded) BOOL loaded;
@property (nonatomic, readwrite, weak) SPSession *session;
@property (nonatomic, readwrite, copy) NSURL *spotifyURL;
@property (nonatomic, readwrite, strong) SPImageCallbackProxy *callbackProxy;

@end

static void image_loaded(sp_image *image, void *userdata) {
	
	SPImageCallbackProxy *proxy = (__bridge SPImageCallbackProxy *)userdata;
	if (!proxy.image) return;
	
	BOOL isLoaded = sp_image_is_loaded(image);
	SPPlatformNativeImage *im = nil;
	
	if (isLoaded) {
		size_t size;
		const byte *data = sp_image_data(proxy.image.spImage, &size);
		
		if (size > 0)
			im = [[SPPlatformNativeImage alloc] initWithData:[NSData dataWithBytes:data length:size]];
	}

	dispatch_async(dispatch_get_main_queue(), ^{
		proxy.image.image = im;
		proxy.image.loaded = isLoaded;
	});
}

@implementation SPImage {
	BOOL hasRequestedImage;
	BOOL hasStartedLoading;
	SPPlatformNativeImage *_image;
}

static NSMutableDictionary *imageCache;

+(SPImage *)imageWithImageId:(const byte *)imageId inSession:(SPSession *)aSession {

	SPAssertOnLibSpotifyThread();
	
    if (imageCache == nil) {
        imageCache = [[NSMutableDictionary alloc] init];
    }
    
	if (imageId == NULL) {
		return nil;
	}
	
	NSData *imageIdAsData = [NSData dataWithBytes:imageId length:SPImageIdLength];
	SPImage *cachedImage = [imageCache objectForKey:imageIdAsData];
	
	if (cachedImage != nil)
		return cachedImage;
	
	cachedImage = [[SPImage alloc] initWithImageStruct:NULL
											   imageId:imageId
											 inSession:aSession];
	[imageCache setObject:cachedImage forKey:imageIdAsData];
	return cachedImage;
}

+(void)imageWithImageURL:(NSURL *)imageURL inSession:(SPSession *)aSession callback:(void (^)(SPImage *image))block {
	
	if ([imageURL spotifyLinkType] != SP_LINKTYPE_IMAGE) {
		if (block) dispatch_async(dispatch_get_main_queue(), ^() { block(nil); });
		return;
	}
	
	SPDispatchAsync(^{
		
		SPImage *spImage = nil;
		sp_link *link = [imageURL createSpotifyLink];
		sp_image *image = sp_image_create_from_link(aSession.session, link);
		
		if (link != NULL)
			sp_link_release(link);
		
		if (image != NULL) {
			spImage = [self imageWithImageId:sp_image_image_id(image) inSession:aSession];
			sp_image_release(image);
		}
		
		if (block) dispatch_async(dispatch_get_main_queue(), ^() { block(spImage); });
	});
}

#pragma mark -

-(id)initWithImageStruct:(sp_image *)anImage imageId:(const byte *)anId inSession:aSession {
	
	SPAssertOnLibSpotifyThread();
	
    if ((self = [super init])) {
		
		self.session = aSession;
		self.imageId = anId;
		
		if (anImage != NULL) {
			self.spImage = anImage;
			sp_image_add_ref(self.spImage);
			
			self.callbackProxy = [[SPImageCallbackProxy alloc] init];
			self.callbackProxy.image = self;
			
			sp_image_add_load_callback(self.spImage,
									   &image_loaded,
									   (__bridge void *)(self.callbackProxy));
			
			BOOL isLoaded = sp_image_is_loaded(self.spImage);
			SPPlatformNativeImage *im = nil;
			
			if (isLoaded) {
				size_t size;
				const byte *data = sp_image_data(self.spImage, &size);
				
				if (size > 0)
					im = [[SPPlatformNativeImage alloc] initWithData:[NSData dataWithBytes:data length:size]];
			}

			dispatch_async(dispatch_get_main_queue(), ^{
				[self cacheSpotifyURL];
				self.image = im;
				self.loaded = isLoaded;
			});
        }
    }
    return self;
}

-(sp_image *)spImage {
#if DEBUG
	SPAssertOnLibSpotifyThread();
#endif 
	return _spImage;
}

-(SPPlatformNativeImage *)image {
	if (_image == nil && !hasRequestedImage)
		[self startLoading];
	return _image;
}

-(void)setImage:(SPPlatformNativeImage *)anImage {
	if (_image != anImage) {
		_image = anImage;
	}
}

#pragma mark -

-(void)startLoading {

	if (hasStartedLoading) return;
	hasStartedLoading = YES;
	
	SPDispatchAsync(^{
		
		if (self.spImage != NULL)
			return;
		
		sp_image *newImage = sp_image_create(self.session.session, self.imageId);
		self.spImage = newImage;
		
		if (self.spImage != NULL) {
			[self cacheSpotifyURL];
			
			// Clear out previous proxy.
			self.callbackProxy.image = nil;
			self.callbackProxy = nil;
			
			self.callbackProxy = [[SPImageCallbackProxy alloc] init];
			self.callbackProxy.image = self;
			
			sp_image_add_load_callback(self.spImage, &image_loaded, (__bridge void *)(self.callbackProxy));
			BOOL isLoaded = sp_image_is_loaded(self.spImage);
			SPPlatformNativeImage *im = nil;
			
			if (isLoaded) {
				size_t size;
				const byte *data = sp_image_data(self.spImage, &size);
				
				if (size > 0)
					im = [[SPPlatformNativeImage alloc] initWithData:[NSData dataWithBytes:data length:size]];
			}
			
			dispatch_async(dispatch_get_main_queue(), ^{
				hasRequestedImage = YES;
				self.image = im;
				self.loaded = isLoaded;
			});
		}
	});
	
}

-(void)dealloc {

	sp_image *outgoing_image = _spImage;
	SPImageCallbackProxy *outgoingProxy = self.callbackProxy;
	self.callbackProxy.image = nil;
	self.callbackProxy = nil;

	if (outgoing_image == NULL) return;

    SPDispatchAsync(^() {
		sp_image_remove_load_callback(outgoing_image, &image_loaded, (__bridge void *)outgoingProxy);
		sp_image_release(outgoing_image);
	});
}

-(void)cacheSpotifyURL {
	
	SPDispatchAsync(^{

		if (self.spotifyURL != NULL)
			return;
		
		sp_link *link = sp_link_create_from_image(self.spImage);
		
		if (link != NULL) {
			NSURL *url = [NSURL urlWithSpotifyLink:link];
			sp_link_release(link);
			dispatch_async(dispatch_get_main_queue(), ^{
				self.spotifyURL = url;
			});
		}
	});
}

@end
