//
//  Artist.h
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SongCollection.h"

// This class represents an artist.

@interface Artist : NSObject<SongCollection>
{
@protected
	
	NSMutableArray* albums;
	NSMutableArray* songs;
    
    NSMutableArray* albumNames;
    NSMutableArray* songNames;
    
    NSString* name;
}

@property (nonatomic, readonly) NSString *name;

@property (nonatomic, readonly) NSArray *albums;		// All Album for objects this artist
@property (nonatomic, readonly) NSArray *songs;			// All Song objects for this artist

@property (nonatomic, readonly) NSArray *albumNames;	// Convenience method
@property (nonatomic, readonly) NSArray *songNames;		// Convenience method

- (id) initWithName:(NSString*)name;

- (id) init; // Designated initializer.

@end
