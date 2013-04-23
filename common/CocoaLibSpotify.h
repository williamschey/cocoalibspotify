//
//  CocoaLibSpotify.h
//  CocoaLibSpotify
//
//  Created by Daniel Kennett on 3/7/11.
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

#if TARGET_OS_IPHONE

#import "SPErrorExtensions.h"
#import "SPURLExtensions.h"
#import "SPAlbum.h"
#import "SPArtist.h"
#import "SPImage.h"
#import "SPUser.h"
#import "SPSession.h"
#import "SPPlaylist.h"
#import "SPPlaylistFolder.h"
#import "SPPlaylistItem.h"
#import "SPTrack.h"
#import "SPPlaylistContainer.h"
#import "SPSearch.h"
#import "SPPostTracksToInboxOperation.h"
#import "SPArtistBrowse.h"
#import "SPAlbumBrowse.h"
#import "SPToplist.h"
#import "SPUnknownPlaylist.h"

#import "SPSignupViewController.h"
#import "SPLoginViewController.h"

#import "SPCircularBuffer.h"
#import "SPCoreAudioController.h"
#import "SPPlaybackManager.h"

#import "SPAsyncLoading.h"
#import "SPSparseList.h"

#else

#import <CocoaLibSpotify/SPErrorExtensions.h>
#import <CocoaLibSpotify/SPURLExtensions.h>
#import <CocoaLibSpotify/SPAlbum.h>
#import <CocoaLibSpotify/SPArtist.h>
#import <CocoaLibSpotify/SPImage.h>
#import <CocoaLibSpotify/SPUser.h>
#import <CocoaLibSpotify/SPSession.h>
#import <CocoaLibSpotify/SPPlaylist.h>
#import <CocoaLibSpotify/SPPlaylistFolder.h>
#import <CocoaLibSpotify/SPPlaylistItem.h>
#import <CocoaLibSpotify/SPTrack.h>
#import <CocoaLibSpotify/SPPlaylistContainer.h>
#import <CocoaLibSpotify/SPSearch.h>
#import <CocoaLibSpotify/SPPostTracksToInboxOperation.h>
#import <CocoaLibSpotify/SPArtistBrowse.h>
#import <CocoaLibSpotify/SPAlbumBrowse.h>
#import <CocoaLibSpotify/SPToplist.h>
#import <CocoaLibSpotify/SPUnknownPlaylist.h>
#import <CocoaLibSpotify/SPCircularBuffer.h>
#import <CocoaLibSpotify/SPCoreAudioController.h>
#import <CocoaLibSpotify/SPCoreAudioDevice.h>
#import <CocoaLibSpotify/SPPlaybackManager.h>
#import <CocoaLibSpotify/SPAsyncLoading.h>
#import <CocoaLibSpotify/SPSparseList.h>

#endif
