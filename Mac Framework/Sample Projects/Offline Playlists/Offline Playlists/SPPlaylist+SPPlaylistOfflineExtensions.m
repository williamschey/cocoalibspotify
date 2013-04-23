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

#import "SPPlaylist+SPPlaylistOfflineExtensions.h"

@implementation SPPlaylist (SPPlaylistOfflineExtensions)

+(NSSet *)keyPathsForValuesAffectingOfflineStatusString {
	return [NSSet setWithObject:@"offlineStatus"];
}

-(NSString *)offlineStatusString {
	
	switch (self.offlineStatus) {
		case SP_PLAYLIST_OFFLINE_STATUS_YES:
			return @"Marked offline";
			break;
		case SP_PLAYLIST_OFFLINE_STATUS_NO:
			return @"Not marked offline";
			break;
		case SP_PLAYLIST_OFFLINE_STATUS_DOWNLOADING:
			return @"Downloading…";
			break;
		case SP_PLAYLIST_OFFLINE_STATUS_WAITING:
			return @"Waiting…";
			break;
		default:
			return @"Unknown";
			break;
	}
}

@end

@implementation SPPlaylistFolder (SPPlaylistFolderOfflineExtensions)

-(NSString *)offlineStatusString {
	return @"N/A";
}

-(BOOL)markedForOfflinePlayback { return NO; }
-(void)setMarkedForOfflinePlayback:(BOOL)marked {}

@end