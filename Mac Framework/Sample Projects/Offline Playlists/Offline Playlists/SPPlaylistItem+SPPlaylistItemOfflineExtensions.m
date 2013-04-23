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

#import "SPPlaylistItem+SPPlaylistItemOfflineExtensions.h"

@implementation SPPlaylistItem (SPPlaylistItemOfflineExtensions)

+(NSSet *)keyPathsForValuesAffectingOfflineTrackStatus {
	return [NSSet setWithObject:@"item.offlineStatus"];
}

-(NSString *)offlineTrackStatus {
	
	if (self.itemClass != [SPTrack class]) {
		return @"Not A Track";
	} else {
		
		SPTrack *track = self.item;
		
		switch (track.offlineStatus) {
			case SP_TRACK_OFFLINE_DONE:
				return @"Done";
				break;
			case SP_TRACK_OFFLINE_NO:
				return @"Not Offline";
				break;
			case SP_TRACK_OFFLINE_ERROR:
				return @"Error";
				break;
			case SP_TRACK_OFFLINE_LIMIT_EXCEEDED:
				return @"Offline Limit Hit";
				break;
			case SP_TRACK_OFFLINE_DOWNLOADING:
				return @"Downloading";
				break;
			case SP_TRACK_OFFLINE_WAITING:
				return @"Waiting";
				break;
			case SP_TRACK_OFFLINE_DONE_EXPIRED:
				return @"Done, Expired";
				break;
			case SP_TRACK_OFFLINE_DONE_RESYNC:
				return @"Done, Requires Resync";
				break;
			default:
				return @"Unknown";
				break;
		}
	}
}

@end
