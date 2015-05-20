//
//  MutablePlaylist.m
//  OhmPlayer3
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import "MutablePlaylist.h"

#import "Album.h"
#import "Song.h"

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

@interface Playlist (ProtectedMethods)

- (NSMutableSet*) songIDsInPlaylist;

// These declarations redefine inherited readonly properites as writable by this subclass.

@property (nonatomic, strong, readwrite) NSArray		*songs;		// All Song objects for this playlist.
@property (nonatomic, strong, readwrite) NSArray		*songIDs;	// All persistent Song IDs for this playlist.
@property (nonatomic, strong, readwrite) NSString        *name;

@end


@implementation MutablePlaylist

#pragma GCC diagnostic ignored "-Wgnu"

- (void) setName:(NSString*)aName
{
    super.name = aName;
}

- (NSString*) name
{
    return super.name;
}

- (void) addSong:(Song*)song
{
	NSParameterAssert(song);
	
	if (song)
	{
		[(NSMutableArray*)self.songs addObject:song];
		
		// Record the song's ID in a set so we can implement containsSong...
		
		NSNumber* identifier = song.identifier;
		
		if (identifier) [[super songIDsInPlaylist] addObject:identifier];
		
	}
}

- (void) addSongs:(NSArray*)songCollection
{
	NSParameterAssert(songCollection);
	
	if (songCollection)
	{
		for (Song* song in songCollection)
		{
			[self addSong:song];
		}
		
	}
	
}

- (void) addSongsForAlbum:(Album*)album
{
	[self addSongs:[album songs]];
}

- (void) addSongsForPlaylist:(Playlist*)playlist
{
	[self addSongs:[playlist songs]];
}

- (void) removeSongAtIndex:(NSUInteger)index
{
    NSMutableArray* songs_ = (NSMutableArray*)self.songs;
    
    Song* song = [songs_ objectAtIndex:index];
    
    [songs_ removeObjectAtIndex:index];
    
    if (![songs_ containsObject:song])
    {
        // There might have been dups in the original list. If there are no more references
        // then remove it from the songs ID set so we can correctly implement containsSong...
        
        NSNumber* identifier = song.identifier;
        
        if (identifier) [[super songIDsInPlaylist] removeObject:identifier];
    }
    
}

- (void) removeAllSongs
{
    // Release inherited songs and song IDs.
    
    songs = [NSMutableArray array];
    songIDsInPlaylist = [NSMutableSet set];
}

- (void) mutableArray:(NSMutableArray*)mutableArray moveObjectAtIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex
{
    if (destinationIndex != sourceIndex)
    {        
        id obj = [mutableArray objectAtIndex:(NSUInteger)sourceIndex];
        
        [mutableArray removeObjectAtIndex:(NSUInteger)sourceIndex];
        
        if (destinationIndex >= (NSInteger)[mutableArray count])
        {
            [mutableArray addObject:obj]; // Append to the end.
        }
        else
        {
            [mutableArray insertObject:obj atIndex:(NSUInteger)destinationIndex];
        }
    }
}

- (void) moveSongAtIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex
{    
    [self mutableArray:(NSMutableArray*)self.songs moveObjectAtIndex:sourceIndex toIndex:destinationIndex];
}

#pragma mark Playlist Methods -- Overriden

- (BOOL) readonly
{	
	return NO;
}

@end
