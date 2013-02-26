//
//  Song.h
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

// This class represents a song.

@interface Song : NSObject {
	
@protected
	NSString* title;
	NSString* artistName;
	NSString* albumName;
}

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *artistName;
@property (nonatomic, readonly) NSString *albumName;
@property (nonatomic, readonly) NSNumber *playbackDuration;

// Uniquely identifies a song so we can check if this song
// is already in a queue.
@property (nonatomic, readonly)	NSNumber* identifier;
@property (nonatomic, readonly)	NSNumber* albumIdentifier;

- (id) imageWithSize:(CGSize)aSize;	// Returns artwork for this song.

- (id) initWithTitle:(NSString*)title artist:(NSString*)artist album:(NSString*)album;

- (id) init; // Designated initializer.

@end

typedef Song MusicLibrarySong; // Historical name used in previous source.
