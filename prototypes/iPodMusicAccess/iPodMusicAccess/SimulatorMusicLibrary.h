//
//  SimulatorMusicLibrary.h
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MusicLibrary.h"

// This class represents a simulated music library.

@interface SimulatorMusicLibrary : NSObject<MusicLibrary>
{
@private
	
	NSMutableArray* allAlbums;
	NSMutableArray* allArtists;
	NSMutableArray* allSongs;
}

// Returns an array of Artist objects.
- (NSArray*) allArtists;

// Returns an array of Album objects.
- (NSArray*) allAlbums;

// Returns an array of Song objects.
- (NSArray*) allSongs;

+ (MusicLibrary*) sharedInstance;

@end
