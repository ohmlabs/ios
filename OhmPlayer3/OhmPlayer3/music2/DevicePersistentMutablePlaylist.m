//
//  DevicePersistentMutablePlaylist.m
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import "DevicePersistentMutablePlaylist.h"

#import "DeviceSong.h"
#import "DeviceAlbum.h"
#import "DevicePlaylist.h"

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

@interface MutablePlaylist (ProtectedMethods)

// The implementation for this method is defined in the MutablePlaylist subclass.

// Note: I could have added a category to NSMutableArray for this, but I wanted the music related
// files to be as dependency free as possible.

- (void) mutableArray:(NSMutableArray*)mutableArray moveObjectAtIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex;

@end

@implementation DevicePersistentMutablePlaylist

#pragma mark Protected Methods

#pragma GCC diagnostic ignored "-Wgnu"

- (NSArray*) mediaItems
{
	if (!mediaItems)
	{
		mediaItems = [[NSMutableArray alloc] init];
	}
	
	return mediaItems;
}

// Returns YES if the media items were successfully updated, otherwise NO.

- (BOOL) addSongsMediaItems:(NSArray*)newMediaItems
{	
	NSParameterAssert(newMediaItems);
    
	if (newMediaItems)
	{
		// Update the device specific collection.
        
		NSArray* targetCollectionItems = [[self mediaItems] arrayByAddingObjectsFromArray:newMediaItems];
		
		if ([targetCollectionItems count])
		{
            mediaItems = [targetCollectionItems mutableCopy];  // Creates a mutable array

            return YES;
		}
	}
	
	return NO;

}

- (BOOL) addSongMediaItem:(MPMediaItem*)item
{	
	return (item) ? [self addSongsMediaItems:[NSArray arrayWithObject:item]] : NO;
}

- (BOOL) addSongMediaItemCollection:(MPMediaItemCollection*)collection
{	
    NSArray* collectionItems = [collection items];
    
	return (collectionItems) ? [self addSongsMediaItems:collectionItems] : NO;
}


#pragma mark OhmPlaylist Methods - Overridden

- (void) addSong:(Song*)song
{
	MPMediaItem* mediaItem = ((DeviceSong*)song).mediaItem;
	
	NSParameterAssert(mediaItem);
	
	if ([self addSongMediaItem:mediaItem])
	{
		// On success, indirectly update the inherited Songs property so that this
		// playlist's songs can be displayed in a tableview.
		
		[super addSong:song];
	}
}

- (void) addSongsForAlbum:(Album*)album
{
    if (!album) return; // can happen when the device has no songs...
    
	MPMediaItemCollection* collection = ((DeviceAlbum*)album).mediaItemCollection;

	if (collection && [self addSongMediaItemCollection:collection])
	{
		// On success, indirectly update the inherited Songs property so that this
		// playlist's songs can be displayed in a tableview.
		
		[super addSongsForAlbum:album];
	}
}

- (void) addSongsForPlaylist:(Playlist*)playlist
{
	// Note: only DevicePlaylists (that represent immutable playlists synced from iTunes) have mediaPlaylists properties.
	// DevicePersistentMutablePlaylists don't.
	
	// ISSUE: This could be too slow...
	
	for (Song* song in [playlist songs])
	{
		[self addSong:song];
	}
		
}

- (void) removeSongAtIndex:(NSUInteger)index
{
    [mediaItems removeObjectAtIndex:index];
    
    [super removeSongAtIndex:index];    
}

- (void) removeAllSongs
{    
    NSMutableArray* noItems = [NSMutableArray array];
    
    if (noItems)
    {
        mediaItems = noItems;
        
        // Clear inherited state.
        [super removeAllSongs];
        
    }
}

- (void) moveSongAtIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex
{    
    [self mutableArray:(NSMutableArray*)self.songs moveObjectAtIndex:sourceIndex toIndex:destinationIndex];
    
    // We have rearranged self.songs. Now we need to rearrange mediaItems to mirror
    // the changes as well.
            
    [self mutableArray:mediaItems moveObjectAtIndex:sourceIndex toIndex:destinationIndex];
    
}

#pragma mark SongCollection Methods

- (id) songCollection
{
	return ([mediaItems count]) ? [[MPMediaItemCollection alloc] initWithItems:mediaItems] : nil;
}

@end
