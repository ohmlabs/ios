//
//  MusicLibrary.h
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Artist.h"
#import "Album.h"
#import "Song.h"
#import "Playlist.h"

#import "SongCollection.h"

// This protocol abstracts the user's music library.

@protocol MusicLibrary <NSObject, SongCollection>

// Returns an array of Artist objects.
- (NSArray*) allArtists;

// Returns an array of Album objects.
- (NSArray*) allAlbums;

// Returns an array of Song objects.
- (NSArray*) allSongs;

// Returns an array of [immutable] Playlist objects synched from iTunes.
- (NSArray*) allITunesPlaylists;

- (Song*) songForSongID:(NSNumber*)songID;

- (Album*) albumForAlbumID:(NSNumber*)albumID;

#pragma mark Indexed TableView Support

// Returns the first non-empty tableview section at or after characterIndexSection.
// If not found, returns the last non-empty section.

- (NSUInteger) nearestTableViewSectionForArtistCharacterIndexSection:(NSUInteger)characterIndexSection;

#pragma mark Indexed TableView Support - Artists

- (NSUInteger) numberOfSectionsForArtists;

- (NSUInteger) numberOfRowsForArtistSection:(NSUInteger)section;

- (Artist*) artistAtIndexPath:(NSIndexPath*)indexPath;

- (NSString*) titleForHeaderInArtistSection:(NSUInteger)section;

#pragma mark Indexed TableView Support - Albums

- (NSUInteger) numberOfSectionsForAlbums;

- (NSUInteger) numberOfRowsForAlbumSection:(NSUInteger)section;

- (Album*) albumAtIndexPath:(NSIndexPath*)indexPath;

- (NSString*) titleForHeaderInAlbumSection:(NSUInteger)index;

#pragma mark Indexed TableView Support - Songs

- (NSUInteger) numberOfSectionsForSongs;

- (NSUInteger) numberOfRowsForSongSection:(NSUInteger)section;

- (Song*) songAtIndexPath:(NSIndexPath*)indexPath;

- (NSString*) titleForHeaderInSongSection:(NSUInteger)section;

#pragma mark SongCollection Methods

// Note: a MusicLibrary object implements the SongCollection protocol so that all of its
// contained songs can be represented as a single collection to a MusicPlayer.

// IMPORTANT:
//
// Simulator objects implementing this protocol MUST return an NSArray of Songs objects.
//
// Device objects implementing this protocol MUST return a MPMediaItemCollection object.

- (id) songCollection;

@end

// Posted when an album's image is available.

extern NSString* const MusicLibraryImageCacheDidChangeNotification;

#pragma mark Music Library Functions

// This function returns a music library implementation appropriate for use in the iOS Simulator
// or on an iOS device depending on the compilation target.

typedef NSObject<MusicLibrary> MusicLibrary;

MusicLibrary* musicLibrary(void);
