//
//  SimulatorAlbum.h
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Album.h"

@class SimulatorSong;

// This class represents a simulated album.

@interface SimulatorAlbum : Album

@property (nonatomic, readonly)	NSNumber *identifier;		// Only used in simulator to map albumID provided by Song objects to Album objects.

- (void) addSimulatorSong:(SimulatorSong*)song;

@end
