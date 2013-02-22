//
//  DeviceMusicLibrary.m
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import "DeviceMusicLibrary.h"

#import "DeviceArtist.h"
#import "DeviceAlbum.h"
#import "DeviceSong.h"
#import "DevicePlaylist.h"

@implementation DeviceMusicLibrary

#pragma mark MusicLibrary Methods

- (NSArray*) allArtists
{	
	if (!allArtists)
	{
		allArtists = [[NSMutableArray alloc] init];
		
		MPMediaQuery *query = [MPMediaQuery artistsQuery];
		
		for (MPMediaItem* item in [query collections])
		{			
			id artist = [[DeviceArtist alloc] initWithMediaItemCollection:item];
			
			if (artist)
			{
				[allArtists addObject:artist];
			}
		}
		
	}
	
	return allArtists;
}

- (NSArray*) allAlbums
{	
	if (!allAlbums)
	{
		allAlbums = [[NSMutableArray alloc] init];
		
		MPMediaQuery *query = [MPMediaQuery albumsQuery];
		
		for (MPMediaItem* item in [query collections])
		{			
			id album = [[DeviceAlbum alloc] initWithMediaItemCollection:item];
			
			if (album)
			{
				[allAlbums addObject:album];
			}
		}
		
	}
	
	return allAlbums;
}

- (NSArray*) allSongs
{	
	if (!allSongs)
	{
		allSongs = [[NSMutableArray alloc] init];
				
		MPMediaQuery *query = [MPMediaQuery songsQuery];

		for (MPMediaItem* item in [query items]) // Not collections?
		{			
			id album = [[DeviceSong alloc] initWithMediaItem:item];
			
			if (album)
			{
				[allSongs addObject:album];
			}
		}
		
	}
	
	return allSongs;
}

- (NSArray*) allITunesPlaylists
{	
	if (!allITunesPlaylists)
	{
		allITunesPlaylists = [[NSMutableArray alloc] init];
		
		for (MPMediaPlaylist* mediaPlaylist in [[MPMediaQuery playlistsQuery] collections])
		{			
			id playlist = [[DevicePlaylist alloc] initWithMediaPlaylist:mediaPlaylist];
			
			if (playlist)
			{
				[allITunesPlaylists addObject:playlist];
			}
		}
		
	}
	
	return allITunesPlaylists;
}

- (NSArray*) artistNames
{
	if (!allArtistNames)
	{
		allArtistNames = [[NSMutableArray alloc] init];
		
		for (Artist* artist in [self allArtists])
		{
			NSString* name = artist.name;
			
			if (name)
			{
				[allArtistNames addObject:name];
			}
		}
		
	}
	
	return allArtistNames;
}

- (NSArray*) allArtistSections
{
	if (!allArtistSections)
	{
		allArtistSections = [[MPMediaQuery artistsQuery] collectionSections];
	}
	return allArtistSections;
}

- (NSArray*) allAlbumSections
{
	if (!allAlbumSections)
	{
		allAlbumSections = [[MPMediaQuery albumsQuery] collectionSections];
	}
	return allAlbumSections;
}

- (NSArray*) allSongSections
{
	if (!allSongSections)
	{
		allSongSections = [[MPMediaQuery songsQuery] collectionSections];
	}
	return allSongSections;
}

- (Song*) songForSongID:(NSNumber*)songID
{
	NSParameterAssert(songID);
	
	if (!songID) return nil;
	
	MPMediaPropertyPredicate *exactSongPredicate =
	[MPMediaPropertyPredicate predicateWithValue: songID
                                     forProperty: MPMediaItemPropertyPersistentID];
	
	MPMediaQuery *query = [[MPMediaQuery alloc] init];
	[query addFilterPredicate: exactSongPredicate];
	
	NSArray *items = [query items];

	MPMediaItem* mediaItem = [items count] ? [items objectAtIndex:0] : nil;
	
	return (mediaItem) ? [[DeviceSong alloc] initWithMediaItem:mediaItem] : nil;
}

- (Album*) albumForAlbumID:(NSNumber*)albumID
{
	NSParameterAssert(albumID);
	
	if (!albumID) return nil;

	MPMediaPropertyPredicate *exactAlbumPredicate =
	[MPMediaPropertyPredicate predicateWithValue: albumID
                                     forProperty: MPMediaItemPropertyAlbumPersistentID];
	
	MPMediaQuery *query = [MPMediaQuery albumsQuery];
	[query addFilterPredicate: exactAlbumPredicate];
	
	NSArray *items = [query items];
	
	MPMediaItemCollection* mediaItemCollection = [items count] ? [items objectAtIndex:0] : nil;
	
	return (mediaItemCollection) ? [[DeviceAlbum alloc] initWithMediaItemCollection:mediaItemCollection] : nil;
}

#pragma mark Indexed TableView Support

- (MPMediaQuerySection*) artistMediaSectionForSection:(NSUInteger)indexSection
{
	return [[self allArtistSections] objectAtIndex:indexSection];
}

- (MPMediaQuerySection*) albumMediaSectionForSection:(NSUInteger)section
{
	return [[self allAlbumSections] objectAtIndex:section];
}

- (MPMediaQuerySection*) songMediaSectionForSection:(NSUInteger)section
{
	return [[self allSongSections] objectAtIndex:section];
}

- (NSUInteger) numberOfSectionsForArtists
{
	return [[self allArtistSections] count];
}

- (NSUInteger) numberOfSectionsForAlbums
{
	return [[self allAlbumSections] count];
}

- (NSUInteger) numberOfSectionsForSongs
{
	return [[self allSongSections] count];
}

- (NSUInteger) numberOfRowsForArtistSection:(NSUInteger)section
{
	MPMediaQuerySection* querySection = [self artistMediaSectionForSection:section];
	
	return (querySection) ? querySection.range.length : 0;
}

- (NSUInteger) numberOfRowsForAlbumSection:(NSUInteger)section
{
	MPMediaQuerySection* querySection = [self albumMediaSectionForSection:section];
	
	return (querySection) ? querySection.range.length : 0;
}

- (NSUInteger) numberOfRowsForSongSection:(NSUInteger)section
{
	MPMediaQuerySection* querySection = [self songMediaSectionForSection:section];
	
	return (querySection) ? querySection.range.length : 0;
}

- (Artist*) artistAtIndexPath:(NSIndexPath*)indexPath
{
	const NSInteger row		= [indexPath row];
	const NSInteger section = [indexPath section];
	
	if ((row >= 0) && (section >= 0))
	{
		MPMediaQuerySection* querySection = [self artistMediaSectionForSection:section];
				
        return (!querySection) ? nil : [[self allArtists] objectAtIndex:(querySection.range.location + row)];
	}
	
	return nil;
}

- (Song*) songAtIndexPath:(NSIndexPath*)indexPath
{
	const NSInteger row		= [indexPath row];
	const NSInteger section = [indexPath section];
	
	if ((row >= 0) && (section >= 0))
	{
		MPMediaQuerySection* querySection = [self songMediaSectionForSection:section];
		
        return (!querySection) ? nil : [[self allSongs] objectAtIndex:(querySection.range.location + row)];
	}
	
	return nil;
}

- (UILocalizedIndexedCollation*) currentCollation
{
    if (!currentCollation)
    {
        currentCollation = [UILocalizedIndexedCollation currentCollation];
    }
    
    return currentCollation;
}

- (NSArray*) currentCollationSectionTitles
{
    if (!currentCollationSectionTitles)
    {
        currentCollationSectionTitles = [[self currentCollation] sectionTitles];
    }
    
    return currentCollationSectionTitles;
}

- (NSUInteger) nearestTableViewSectionForArtistCharacterIndexSection:(NSUInteger)selectedCharacterIndexSection
{
    // Returns the first non-empty tableview section at or after characterIndexSection.
    // If not found, returns the last non-empty section.
    
    // For each title section, we're going to see if its in the available sections.
    // if not, we increment the index we're search on and keep going...
    // if we don't find anything? yes - we can walk backwards doing the same thing (?)

    NSArray* sectionTitles = [self currentCollationSectionTitles];
    
    const NSUInteger SectionIndexCount = [sectionTitles count];
    
    // Starting at the selected character index, walk to the end of the index
    // checking each index title for a corresponding non-empty tableview section.
    
    for (NSUInteger i = selectedCharacterIndexSection; i < SectionIndexCount; i++)
    {
        NSString* sectionIndexTitle = [sectionTitles objectAtIndex:i];
                
        // Search all the query sections for an exact match. If found, we've found
        // a non-empty section. If not, continue looking...
                
        NSUInteger nonEmptySectionIndex = 0;
        
        for (MPMediaQuerySection* section in [self allArtistSections])
        {
            if ([section.title isEqualToString:sectionIndexTitle])
            {
                return nonEmptySectionIndex; // table section matching index title.
            }
            
            nonEmptySectionIndex++;
        }
      
    }
    
    // We didn't return above, so we didn't find a match.
    // Return the last known index.
    
    const NSUInteger AvailableSectionsCount = [[self allArtistSections] count];
    return (AvailableSectionsCount) ? (AvailableSectionsCount - 1) : NSNotFound;

    // On the device, the iPod music library only provides information correspondong
    // to non-empty table view sections.
    
    // Hence, if we get an exact match, we've found the correct table view section index.
    // Otherwise, we have touched a 'hole' in the list, and we want to find the next
    // available non-empty section (?)
    
}

- (Album*) albumAtIndexPath:(NSIndexPath*)indexPath
{
	const NSInteger row		= [indexPath row];
	const NSInteger section = [indexPath section];
	
	if ((row >= 0) && (section >= 0))
	{
		MPMediaQuerySection* querySection = [self albumMediaSectionForSection:section];
				
		return [[self allAlbums] objectAtIndex:(querySection.range.location + row)];
	}
	
	return nil;
}

- (NSString*) titleForHeaderInArtistSection:(NSUInteger)section
{
	MPMediaQuerySection* querySection = [self artistMediaSectionForSection:section];
	
	return (querySection) ? querySection.title : nil;
}

- (NSString*) titleForHeaderInAlbumSection:(NSUInteger)section
{
	MPMediaQuerySection* querySection = [self albumMediaSectionForSection:section];
	
	return (querySection) ? querySection.title : nil;
}

- (NSString*) titleForHeaderInSongSection:(NSUInteger)section
{
	MPMediaQuerySection* querySection = [self songMediaSectionForSection:section];
	
	return (querySection) ? querySection.title : nil;
}

#pragma mark SongCollection Methods

- (id) songCollection
{
    NSArray* items = [MPMediaQuery songsQuery].items;
    
    NSParameterAssert([items count]);
    
	return ([items count]) ?[[MPMediaItemCollection alloc] initWithItems:items] : nil;
}

- (id) imageWithSize:(CGSize)aSize
{
	return nil; // Use the system default image for this kind of object.
}

#pragma mark Object Life Cycle

+ (MusicLibrary*) sharedInstance
{
	static id sharedInstance = nil;
	
    if (sharedInstance) return sharedInstance;
    
	@synchronized (self)
    {
        if (!sharedInstance)
        {
            sharedInstance = [[DeviceMusicLibrary alloc] init];
        }
    }
    
	return sharedInstance;
}

@end
