//
//  DevicePersistentMutablePlaylist.h
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import "PersistentMutablePlaylist.h"

#import <MediaPlayer/MediaPlayer.h>

// This class represents an on-device persistent and mutable playlist.

// Note: by design, this device-specific class is a subclass of PersistentMutablePlaylist
// NOT a subclass of an immutable DevicePlaylist. The reason is: DevicePlaylist's are read-only
// objects and implemented using immutable MPMediaPlaylist objects.
// This class inherits MutablePlaylist methods to manage mutable collections of songs.

@interface DevicePersistentMutablePlaylist : PersistentMutablePlaylist
{
@private
	
	NSMutableArray* mediaItems;
}

@end
