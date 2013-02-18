//
//  OhmPlaylistManager.m
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import "OhmPlaylistManager.h"

#import "OhmTargetConditionals.h"
#import "DevicePersistentMutablePlaylist.h"
#import "PersistentMutablePlaylist.h"
#import "FilePaths.h"

@implementation OhmPlaylistManager

#pragma mark Protected Methods

- (id) persistentMutablePlaylistClass
{
#if !OHM_TARGET_SIMULATE
	return [DevicePersistentMutablePlaylist class];
#else
	return [PersistentMutablePlaylist class];
#endif
}

- (MutablePlaylist*) createQueue
{
    NSDictionary* dict = [PersistentMutablePlaylist queueMemento];
	
	MutablePlaylist* ohmQueue =
	
	[[[self persistentMutablePlaylistClass] alloc] initWithMemento:dict];
	
	return ohmQueue;
}

- (NSMutableArray*) loadPlaylists
{
    // Look in the file system for playlist property lists (i.e. serialized NSDictionary objects).
    // Then instantiate an PersistentMutablePlaylist for each.
    
    NSArray* fullPathsToPlaylists = [[FilePaths sharedInstance] fullPathsToPlaylists];
    
    NSMutableArray* lists = [NSMutableArray array];
    
    for (NSString* fullPath in fullPathsToPlaylists)
    {
        NSDictionary* plist = [NSDictionary dictionaryWithContentsOfFile:fullPath];
        
		//NSLog(@"Reading playlist from : %@", fullPath);

        if (plist)
        {
            id playlist = [[[self persistentMutablePlaylistClass] alloc] initWithMemento:plist];
            
            if (playlist)
            {				
				// If the playlist is the special queue, remember it but don't add it to
				// the list of non-queue playlists returned to callers; the queue is separate
				// from other playlists.
				
				if ([playlist isQueue])
				{
					queue = playlist;
				}
				else
				{
					[lists addObject:playlist];
				}
            }
        }
    }
	
	hasLoadedPlaylists = YES;

    return lists;
}

- (NSString*) pathToPersistentMutablePlaylist:(PersistentMutablePlaylist*)playlist
{
    NSParameterAssert(playlist);
            
    NSError* error = nil;
    
    NSString* path = [[FilePaths sharedInstance] pathToPlaylistsDirectory:&error];

    NSString* filename = [playlist filename];

    if ([filename length] && path)
    {
        return [path stringByAppendingPathComponent:filename];
    }
    
    return nil;
}

- (void) savePlaylists
{
	// Get the directory.
	// For each playlist, get its name and write it into the playlists directory...
	
	NSError* error = nil;
	
	NSString* path = [[FilePaths sharedInstance] pathToPlaylistsDirectory:&error];
	
	if (!path)
	{
		NSLog(@"%@", error);
		return;
	}
	
	NSArray* nonQueuePlaylists = [self persistentMutablePlaylists];
	
	NSMutableArray* listsToSave = (nonQueuePlaylists) ? [NSMutableArray arrayWithArray:nonQueuePlaylists] : [NSMutableArray array];
	
	if (queue) [listsToSave addObject:queue];
	
	for (PersistentMutablePlaylist* playlist in listsToSave)
	{		
		NSString* filePath = [self pathToPersistentMutablePlaylist:playlist];
		
		if (filePath)
		{			
			//NSLog(@"Writing playlist to : %@", filePath);

			if (![[playlist memento] writeToFile:filePath atomically:YES])
            {
                NSAssert1(NO, @"Could not write playlist to path. Path = %@", filePath);
            }
		}
	}
	
	
}

- (NSMutableArray*) playlists
{
    if (!playlists)
    {
        playlists = [self loadPlaylists];
    }
    
    return playlists;
}

- (void) deletePlaylist:(MutablePlaylist*)aPlaylist
{
    NSParameterAssert(aPlaylist);
    
    if (aPlaylist)
    {        
        if ([aPlaylist isKindOfClass:[PersistentMutablePlaylist class]])
        {
            // Remove persistent playlists from the file system.
            
            NSString* filePath = [self pathToPersistentMutablePlaylist:(PersistentMutablePlaylist*)aPlaylist];
            
            if (filePath)
            {
                NSFileManager* fm = [[NSFileManager alloc] init];
                
                NSError* error = nil;
                
                if ([fm removeItemAtPath:filePath error:&error])
                {
                    // Successful deletion of file.
                    
                    [[self playlists] removeObject:aPlaylist];
                }
                else if ([fm fileExistsAtPath:filePath])
                {
                    // We couldn't remove the file, but it does exists - error.
                    
                    NSLog(@"ERROR: %@ - %@", NSStringFromSelector(_cmd), [error localizedDescription]);
                }
                else
                {
                    // The file couldn't be removed, but it also doesn't exist. Possibly, it was never
                    // saved to the file system. In any case, remove it from memory.
                    
                    [[self playlists] removeObject:aPlaylist];
                }
                
            }
        }
        else
        {
            // Actually, this should never happen because MutablePlayist is abstract by design.
            // Not even in the simulator?
            NSAssert(NO, @"This should never happen. MutablePlaylist should be abstract class.", nil);
            
            [[self playlists] removeObject:aPlaylist];
        }
        
		[self savePlaylists];
    }
    
}

#pragma mark Public Methods

- (MutablePlaylist*) queue
{
	if (!queue)
	{		
		// Loading the playlists has the side-effect of initializing the queue...
		
		if (!hasLoadedPlaylists)
		{
			[self playlists];
		}
		
		if (!queue)
		{
			// The playlists were loaded but no queue was found.
			// We need to initially create one.
			// Note: this should happen only once per app installation.
			
			queue = [self createQueue];
		
		}
		
	}
	
	return queue;
}

+ (MutablePlaylist*) queue
{
	return [[OhmPlaylistManager sharedInstance] queue];
}

- (NSArray*) persistentMutablePlaylists
{
	// Note: the queue is NOT included in the returned result.
	
    return [self playlists]; // Don't let the caller know the result is mutable.
}

- (MutablePlaylist*) createEmptyPlaylistWithName:(NSString*)name
{
    NSParameterAssert([name length]);
    
    if (![name length]) return nil;
    
    id playlist = [[[self persistentMutablePlaylistClass] alloc] initWithName:name];
    
    // Add to the top...
    if (playlist) [[self playlists] insertObject:playlist atIndex:0]; // Add to the list of all known playlists.
    //    if (playlist) [[self playlists] addObject:playlist]; // Add to the list of all known playlists.
    
	[self savePlaylists];
	
    return playlist;
}

- (MutablePlaylist*) copyPlaylist:(Playlist*)otherPlaylist withName:(NSString*)name
{    
    NSParameterAssert([name length]);
    
    if (![name length]) return nil;

    PersistentMutablePlaylist* playlist = [[[self persistentMutablePlaylistClass] alloc] initWithPlaylist:otherPlaylist];
    
    playlist.name = name;
    
    if (playlist) [[self playlists] insertObject:playlist atIndex:0];  // Add (leftmost) to the list of all known playlists.

	[self savePlaylists];

    return playlist;
}

#pragma mark Object Life Cycle

+ (id) sharedInstance
{
	static id sharedInstance = nil;
	
    if (sharedInstance) return sharedInstance;
    
	@synchronized (self)
    {
        if (!sharedInstance)
        {
            sharedInstance = [[OhmPlaylistManager alloc] init];
        }
    }

	return sharedInstance;
}

@end
