CocoaLibSpotify 3.0 for libspotify 12, currently in development
===============================================================

## New Features

### SPAsyncLoading

* `SPAsyncLoading` now accepts `NSSet` instances.

* `SPAsyncLoading` now has support for nested loading through `+waitUntilLoaded:withKeyPaths:timeout:then:`. For example, passing in an array of `SPTrack` objects and the key paths `@[@“album”, @“album.cover” @“artists”]` will load the given tracks along with their albums, album covers and artists before triggering the loaded callback.

### Audio Playback

* Add `playbackManagerWillStartPlayingAudio:` to `SPPlaybackManagerDelegate`.

* On Mac OS X, `SPCoreAudioController` now has the `currentOutputDevice` and `availableOutputDevices` properties. This allows control over which audio device is used for output, including AirPlay devices on Mac OS X 10.8 and newer.

### SPSparseList

The `SPSparseList` class is a helper class for dealing with classes that implement the new `SPPartialAsyncLoading` protocol to fetch their child items, such as playlists. `SPSparseList` behaves somewhat like an array, except that only parts of it are loaded and filled with data. You can request missing parts of the array to be filled in and unneeded parts of the array to be unloaded, allowing efficient memory usage as the user, for example, scrolls through a long playlist. See the `SPSparseList` documentation and sample projects for more information.

## SPSession

* Add properties for defining offline syncing bitrate. (Thanks to Kristian Trenskow).

* Add `connectionType` property. (Thanks to Kristian Trenskow).

* `-playlistForURL:callback:` now handles starred playlists. (Thanks to Leo Lobato).

## Breaking Changes

### Playlists

* The API for dealing with playlist items has been rewritten. The `SPPlaylist` class no longer maintains an array of items (the `items` property) for performance and memory reasons. Instead, you must request the items you want using the `fetchItemsAtRange:callback:` method and refetch needed items if the playlist notifies you of any changes from its delegate methods. There is a new helper class, `SPSparseList`, to help with this.

* A number of `SPPlaylistDelegate` methods have been removed.

### Misc.

* CocoaLibSpotify is now licensed under the Apache 2.0 license. Please make sure you accept this license before using version 3.0 of CocoaLibSpotify.

* For memory usage reasons, `SPTrack` instances are no longer cached — it’s now possible to have two `SPTrack` instances representing the same track. This means that it’s no longer safe to use `==` to compare `SPTrack` instances — instead, use `isEqual:`.

* All block-based callbacks will be called on the main queue. This was the typical behaviour in version 2.x, but now it’s enforced everywhere.

* All members previously delared as deprecated have been removed, including `[SPArtistBrowse -tracks]` and the `session:shouldDeliverAudioFrames:ofCount:format:` delegate method.

* All members previously declared as `unsafe_unretained` are now declared `weak`, increasing the minimum iOS deployment target to iOS 5.0 and the mimimum Mac OS X deployment target to Mac OS X 10.7.

## Other Bug Fixes and Changes

* The library should be less “spiky” in memory usage, especially with users with large playlists.

* The playlist changes have considerably reduced the amount of RAM and CPU used by the library, especially with users with large playlists.

* The `flattenedPlaylists` property on `SPPlaylistContainer` can now be observed with KVO.

* Many other minor fixes, improvements and tweaks.

CocoaLibSpotify 2.4.2 for libspotify 12, released January 29th 2012
===================================================================

* Fixes build on Xcode 4.6.

CocoaLibSpotify 2.4.1 for libspotify 12, released January 28th 2012
===================================================================

* Adds a build script that corrects a problem in libspotify 12 preventing submission of CocoaLibSpotify applications to the Mac App Store (GitHub issue #136).

CocoaLibSpotify 2.4.0 for libspotify 12, released November 14th 2012
====================================================================

* Improvements to packaging of sample projects, including an updated `USER_HEADER_SEARCH_PATHS` setting that allows archiving of iOS projects.

* Large rewrite of the library's internal threading. This shouldn't affect your project, but please test your application thoroughly before releasing with this version.

* Add to and document threading helper macros.

* Improve `SPCoreAudioController` and `SPCircularBuffer`, fixing a bug that could result in corrupted audio playback.

* `-[SPSession -trackForTrackStruct:]` no longer crashes on a `NULL` struct.

* Improved unit tests to never hang during run, and to accept an appkey at the command line.

* Other minor improvements and fixes.

CocoaLibSpotify 2.3.0 for libspotify 12, released October 11th 2012
===================================================================

* Fix potential crash in `[SPSession -logout:]`.

* Set `[SPPlaylistItem -unread]` correctly (GitHub issue #98).

* Fix potential race in `[SPImage -startLoading]` that could allow the image to be loaded multiple times.

* Add property to control dismissal of `SPLoginViewController`.

* Fix login breakage when merging accounts on iOS.

* Increase robustness of `[SPTrack -dealloc]`.

* Greatly improve iOS unit tests, including a UI to see test progress.

* Fix KVO chaining in `SPToplist` that would cause `SPAsyncLoading` to time out even though the top list had loaded.

* The `subscribers` property of `SPPlaylist` is now set correctly.


CocoaLibSpotify 2.2.0 for libspotify 12, released August 27th 2012
==================================================================

* Fix problem in playlist callbacks that could cause a crash (GitHub issue #88).

* `availability` property on `SPTrack` is now updated correctly (GitHub issue #83).

* SPToplist now correctly behaves when being used with `SPAsyncLoading`.

* Add `[SPSession -subscribeToPlaylist:callback:]` (GitHub issue #67).

* Add `[SPSession -objectRepresentationForSpotifyURL:linkType:]`.

* Fix race condition that could cause incorrect state for a short period of time after login (GitHub issue #62, perhaps others).


CocoaLibSpotify 2.1.0 for libspotify 12, released August 20th 2012
==================================================================

* First release under semantic versioning. Contains a few buxfixes and changes since 2.0.


CocoaLibSpotify 2.0 for libspotify 12, released May 23rd 2012
=============================================================

* Huge re-engineering of CocoaLibSpotify to run libspotify in its own background thread. This has brought on a large set of API changes, and you must now be aware of potential threading issues. See the project's README file for more information.

* Added small and large cover images to `SPAlbum`, as well as `smallestAvailableCover` and `largestAvailableCover` convenience methods.

* Added `fetchLoginUserName:` method to `SPSession` to get the username used to log into the current session. This also fixes `[SPSessionDelegate -session:didGenerateLoginCredentials:forUserName]` giving an incorrect username for users logging in with Facebook details.

* Added the ability to control scrobbling to various social services, including Last.fm and the user's connected Facebook account.

* Added `SPAsyncLoading` and `SPDelayableAsyncLoading`, a new way of working with objects that load asynchonously. If you pass `SPAsyncLoadingManual` to `[SPSession -initWithApplicationKey:userAgent:loadingPolicy:error:]`, anything conforming to `SPDelayableAsyncLoading` (such as user playlists, etc) won't be loaded until you want them to load. See the README file and sample projects for examples.

* Added a number of unit tests.


CocoaLibSpotify for libspotify 11, released March 27th 2012
===========================================================

* SPSearch can now search for playlists.

* SPSearch can now do a "live search", appropriate for showing a "live search" menu when the user is typing. See `[SPSearch +liveSearchWithSearchQuery:inSession:]` for details.

* Added `[SPTrack -playableTrack]`. Use this to get the actual track that will be played instead of the receiver if the receiver is unplayable in the user's locale.  Normally, your application does not need to worry about this but the method is here for completeness.

* Added the `topTracks` property to `SPArtistBrowse`. All browse modes fill in this property, and the `tracks` property has been deprecated and will be removed in a future release.

* Added `[SPSession -attemptLoginWithUserName:existingCredential:rememberCredentials:]` and `[<SPSessionDelegate> -session:didGenerateLoginCredentials:forUserName:]`. Every time a user logs in you'll be given a safe credential "blob" to store as you wish (no encryption is required). This blob can be used to log the user in again. Use this if you want to save login details for multiple users.

* Added `[SPSession -flushCaches]`, appropriate for use when iOS applications go into the background. This will ensure libspotify's caches are flushed to disk so saved logins and so on will be saved.

* Added the `audioDeliveryDelegate` property to `SPSession`, which conforms to the `<SPSessionAudioDeliveryDelegate>` protocol, which allows you more freedom in your audio pipeline. The new protocol also uses standard Core Audio types to ease integration.

* Added SPLoginViewController to the iOS library. This view controller provides a Spotify-designed login and signup flow.