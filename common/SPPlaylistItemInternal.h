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
#import "CocoaLibSpotifyPlatformImports.h"

@interface SPPlaylistItem (SPPlaylistItemInternal)

-(id)initWithPlaceholderTrack:(sp_track *)track atIndex:(int)itemIndex inPlaylist:(SPPlaylist *)aPlaylist;

-(void)setDateCreatedFromLibSpotify:(NSDate *)date;
-(void)setCreatorFromLibSpotify:(SPUser *)user;
-(void)setUnreadFromLibSpotify:(BOOL)unread;
-(void)setMessageFromLibSpotify:(NSString *)msg;
-(void)setItemIndexFromLibSpotify:(int)newIndex;

@property (nonatomic, readonly) int itemIndex;

@end
