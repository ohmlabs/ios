//
//  SimulatorAlbum.m
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import "SimulatorAlbum.h"

#import "SimulatorSong.h"

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

- (void) addSimulatorSong:(SimulatorSong*)song
{
	NSParameterAssert(song);
	
	if (song) [(NSMutableArray*)self.songs addObject:song];
}

@end
