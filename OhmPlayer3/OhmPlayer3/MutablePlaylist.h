//
//  MutablePlaylist.h
//  OhmPlayer3
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import "Playlist.h"

@class Song;
@class Album;

// This class represents an abstract mutable playlist.

// Note: Although iOS 5 doesn't support mutable playlists, the
// simulator needs this functionality to create read-only playlists...

@interface MutablePlaylist : Playlist

@property (nonatomic, strong, readwrite) NSString *name;

- (void) addSong:(Song*)song; // Adds the song to the end of this playlist.

- (void) addSongsForAlbum:(Album*)song;

- (void) addSongsForPlaylist:(Playlist*)playlist;

- (void) removeSongAtIndex:(NSUInteger)index;

- (void) removeAllSongs;

- (void) moveSongAtIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex;

@end
