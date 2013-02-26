//
//  Playlist.h
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SongCollection.h"

@class Song;

// This class represents a read-only playlist.

@interface Playlist : NSObject<SongCollection>
{
@protected
	
	// Note: these ivars are populated by subclasses.
	
	NSMutableArray* songs;
	NSMutableSet*	songIDsInPlaylist;
    NSString*       _identifier;
}

@property (nonatomic, readonly) NSString	*name;

@property (nonatomic, readonly) NSArray		*songs;		// All Song objects for this playlist.

@property (nonatomic, readonly) NSArray		*songIDs;	// All persistent Song IDs for this playlist.

@property (nonatomic, readonly) BOOL isEmpty;					// Returns YES if this playlist contans no songs.

@property (nonatomic, readonly) BOOL readonly;				// Returns YES if this playlist (or a subclass) is read-only.

@property (nonatomic, readonly) NSUInteger count;           // Returns number of songs in this playlist.
                                                            // This method is potentially faster than sending a count message to the songs array.

@property (nonatomic, readonly) NSString* identifier;   // Unique identifier for this playlist.

@property (nonatomic, strong) NSData* imageData;    // Image data for this playlist

- (BOOL) containsSong:(Song*)aSong;

- (id) initWithName:(NSString*)name;							// Designated initializer.

// SongCollection Methods

- (id) songCollection;

@end
