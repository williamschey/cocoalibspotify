//
//  SPPlaylistFolder.m
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

/*
 In a very Matrix-y fashion, There Is No SPPlaylistFolder. Instead, SPPlaylistFolder is just a pointer to
 a range of playlists in its parent SPPlaylistContainer. 
 */

#import "SPPlaylistFolder.h"
#import "SPPlaylistContainer.h"
#import "SPSession.h"
#import "CocoaLibSpotifyPlatformImports.h"
#import "SPPlaylistContainerInternal.h"
#import "SPPlaylistFolderInternal.h"

@interface SPPlaylistFolder ()

@property (nonatomic, readwrite, weak) SPPlaylistContainer *parentContainer;
@property (nonatomic, readwrite, weak) SPSession *session;
@property (nonatomic, readwrite, strong) NSArray *playlists;
@property (nonatomic, readwrite) sp_uint64 folderId;

@end

@implementation SPPlaylistFolder

-(id)initWithPlaylistFolderId:(sp_uint64)anId
					container:(SPPlaylistContainer *)aContainer
					inSession:(SPSession *)aSession {
    
	SPAssertOnLibSpotifyThread();
	
    if ((self = [super init])) {
        self.session = aSession;
		self.parentContainer = aContainer;
		self.playlists = [NSArray array];
		self.folderId = anId;
    }
    return self;
}

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: %@ %@", [super description], self.name, [self valueForKey:@"playlists"]];
}

-(void)addObject:(id)playlistOrFolder {
	if (playlistOrFolder) self.playlists = [self.playlists arrayByAddingObject:playlistOrFolder];
}

-(void)clearAllItems {
	self.playlists = [NSArray array];
}

-(NSArray *)parentFolders {
	
	NSMutableArray *folders = [NSMutableArray array];
	SPPlaylistFolder *currentParent = self.parentFolder;
	
	while (currentParent != nil) {
		[folders addObject:currentParent];
		currentParent = currentParent.parentFolder;
	}
	
	return folders.count == 0 ? nil : [NSArray arrayWithArray:folders];
}

@end




