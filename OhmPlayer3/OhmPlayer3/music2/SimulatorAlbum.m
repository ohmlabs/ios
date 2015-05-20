//
//  SimulatorAlbum.m
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

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

@implementation SimulatorAlbum

#pragma mark Properties

@synthesize identifier;

- (NSNumber*) identifier
{	
	if (!identifier)
	{
		NSString* uniqueID = [NSString stringWithFormat:@"%@+%@", title, artistName];
		
		identifier = [NSNumber numberWithUnsignedInteger:[uniqueID hash]];
		
		// Note: we shouldn't use this implementation for DeviceAlbum subclasses because we may need to 
		// use the device-specific subclass's mediaItem in device-specific APIs.
        
	}
	
	return identifier;
}

#pragma mark Public Methods

#pragma GCC diagnostic ignored "-Wgnu"

- (void) addSimulatorSong:(SimulatorSong*)song
{
	NSParameterAssert(song);
	
	if (song) [(NSMutableArray*)self.songs addObject:song];
}

@end
