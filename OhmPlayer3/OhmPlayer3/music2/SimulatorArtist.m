//
//  SimulatorArtist.m
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import "SimulatorArtist.h"

#import "SimulatorAlbum.h"
#import "SimulatorSong.h"

// FIXME: Used to silence Xcode 6.3 beta - should be eventually removed.
#undef NSParameterAssert
#define NSParameterAssert(condition)	({\
do {\
_Pragma("clang diagnostic push")\
_Pragma("clang diagnostic ignored \"-Wcstring-format-directive\"")\
NSAssert((condition), @"Invalid parameter not satisfying: %s", #condition);\
_Pragma("clang diagnostic pop")\
} while(0);\
})

@implementation SimulatorArtist

#pragma GCC diagnostic ignored "-Wgnu"

- (void) addSimulatorAlbum:(SimulatorAlbum*)album
{
	NSParameterAssert(album);
	
	if (album) [(NSMutableArray*)self.albums addObject:album];
	
	// Conditionally add an All Songs album.
	
	// Note: we check for exactly 2, instead of > 1, because this method is called several times
	// and we want to add the All Songs album only once...
	
	if ([self.albums count] == 2)
	{
		// If there's more than one album, add a synthetic "All Songs" album...
		
		[(NSMutableArray*)self.albums insertObject:self atIndex:0];
		
		// Note: we should NOT register/add the songs for this artist because they're
		// already added for each 'real' album.
	}
	
	// Add songs from each [real] album.

	NSMutableArray* songs_ = (NSMutableArray*)self.songs;
	
	for (SimulatorSong* song in album.songs)
	{
		[songs_ addObject:song];
	}
	
}

@end
