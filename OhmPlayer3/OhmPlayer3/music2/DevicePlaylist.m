//
//  DevicePlaylist.m
//  OhmPlayer3
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import "DevicePlaylist.h"

#import "DeviceSong.h"

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

@end

@implementation DevicePlaylist

#pragma mark Properties

@synthesize mediaPlaylist;
@synthesize identifier; // NOTE: this declaration hides the base class's identifier property.

- (NSString*) identifier
{	
	if (!identifier)
	{
		NSNumber* persistentID = [mediaPlaylist valueForProperty:MPMediaPlaylistPropertyPersistentID];
        identifier = [persistentID stringValue];
	}
	
	return identifier;
}

#pragma mark Protected Methods
#pragma GCC diagnostic ignored "-Wgnu"


- (void) addSong:(Song*)song
{
	NSParameterAssert(song);
	
	if (song)
	{
		[(NSMutableArray*)super.songs addObject:song];
		
		// Record the song's ID in a set so containsSong can be implemented...
		
		NSNumber* songID = song.identifier;
		
		if (songID) [[super songIDsInPlaylist] addObject:songID];
		
	}
}

#pragma mark Playlist Methods - Overriden

- (NSArray*) songs
{
	if (![super.songs count])
	{
		// If the songs list is empty, try to compute it. Playlist should never be empty...
		
        // PERFORMANCE: the items method below is slow, but it's no slower than Apple's own Music app.
        // For example, a playlist of 2500 songs takes about 40 seconds to load on an iPhone 3GS
        // for both Ohm Player and Apple's Music.app.
        
		for (MPMediaItem* item in [mediaPlaylist items])
		{
			Song* song = [[DeviceSong alloc] initWithMediaItem:item];
			
			if (song) [self addSong:song];
		}
		
	}
	
	return super.songs;
}

- (NSUInteger) count
{
    return [mediaPlaylist count];
}

- (id) imageWithSize:(CGSize)aSize
{
	MPMediaItemArtwork* artwork = [mediaPlaylist valueForProperty:MPMediaItemPropertyArtwork];
	
	return [artwork imageWithSize:aSize];
}

#pragma mark SongCollection Methods

- (id) songCollection
{
	return ([mediaPlaylist.items count]) ? [[MPMediaItemCollection alloc] initWithItems:mediaPlaylist.items] : nil;
}

#pragma mark Object Life Cycle

- (id) initWithMediaPlaylist:(id)aMediaPlaylist
{
	NSParameterAssert(aMediaPlaylist);
	
	NSString* aName	= [aMediaPlaylist valueForProperty:MPMediaPlaylistPropertyName];
	
	if ((self = [self initWithName:aName]))
	{
		mediaPlaylist = aMediaPlaylist;
	}
	
	return self;
}

- (id) init
{
	return [self initWithMediaPlaylist:nil];
}

@end