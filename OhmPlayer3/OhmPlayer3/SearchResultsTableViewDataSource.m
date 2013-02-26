//
//  SearchResultsTableViewDataSource.m
//  OhmPlayer3
//
//  Copyright (c) 2012 Ohm Labs. All rights reserved.
//

#import "SearchResultsTableViewDataSource.h"

#import "MusicPlayer.h"

NSString* const SEARCH_RESULTS_CELL_REUSE_ID_ARTISTS   = @"SearchResultsCellArtists";
NSString* const SEARCH_RESULTS_CELL_REUSE_ID_ALBUMS    = @"SearchResultsCellAlbums";
NSString* const SEARCH_RESULTS_CELL_REUSE_ID_SONGS     = @"SearchResultsCellSongs";
NSString* const SEARCH_RESULTS_KEY_ARTISTS             = @"Artists";
NSString* const SEARCH_RESULTS_KEY_ALBUMS              = @"Albums";
NSString* const SEARCH_RESULTS_KEY_SONGS               = @"Songs";

static NSString* const PLACEHOLDER_ALBUM_IMAGE_NAME = @"default_album_artwork";

@implementation SearchResultsTableViewDataSource

#pragma mark Protected Methods

- (NSMutableDictionary*) searchResults
{
    if (!searchResults)
    {
        searchResults = [[NSMutableDictionary alloc] init];
    }
    
    return searchResults;
}

- (NSString*) reuseIDForSection:(NSInteger)section
{
    NSString*   sectionKey = [[[self searchResults] allKeys] objectAtIndex:(NSUInteger)section];
    
    if ([sectionKey isEqualToString:SEARCH_RESULTS_KEY_ARTISTS])
    {
        return SEARCH_RESULTS_CELL_REUSE_ID_ARTISTS;
    }
    else if ([sectionKey isEqualToString:SEARCH_RESULTS_KEY_ALBUMS])
    {
        return SEARCH_RESULTS_CELL_REUSE_ID_ALBUMS;
    }
    else if ([sectionKey isEqualToString:SEARCH_RESULTS_KEY_SONGS])
    {
        return SEARCH_RESULTS_CELL_REUSE_ID_SONGS;
    }
    else 
    {
        NSLog(@"Reuse ID requested for unknown section: %@", sectionKey);
    }
    
    return nil;
}

- (UITableViewCell*) tableViewCellForSection:(NSInteger)section
{
	return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:[self reuseIDForSection:section]];
}

- (MusicLibrary*) musicLibrary
{
	return musicLibrary();
}

- (UIImage*) placeholderAlbumImage
{
	static UIImage* placeholderImage = nil;
	
	if (!placeholderImage)
	{
		placeholderImage = [[UIImage imageNamed:PLACEHOLDER_ALBUM_IMAGE_NAME] copy];
	}
	
	return placeholderImage;
}

- (NSString*) imageCacheKeyForArtistName:(NSString*)artistName andAlbumName:(NSString*)albumName
{		
	return ([artistName length] && [albumName length]) ? [NSString stringWithFormat:@"%@+%@", artistName, albumName] : nil;
}

- (NSMutableDictionary*) imageCache
{
	if (!imageCache)
	{
		imageCache = [[NSMutableDictionary alloc] init];
	}
    
	return imageCache;
}

- (UIImage*) imageWithSize:(CGSize)aSize forAlbum:(Album*)album
{
	NSString* key = [self imageCacheKeyForArtistName:album.artistName andAlbumName:album.title];
	
	if (!key)
    {
#if DEBUG
        NSLog(@"Did not get image cache key for artist %@ and album %@", album.artistName, album.title);
#endif
        return nil;
	}
    
	NSMutableDictionary* imageCache_ = [self imageCache];
	
	UIImage* image = [imageCache_ valueForKey:key];
	
	if (!image)
	{	
		
#if 1
		// Note: on my 2009 iPhone 3GS loading images on the main thread has acceptable performance.
		// In fact, it looks better than loading placeholder images for every cache miss.
		
		// A future alternative might be to preload the entire cache in the background to minimize
		// cache misses and prevent the placeholder album art from being displayed, but for now
		// I think this is more than OK to ship.
		
		image = [album imageWithSize:aSize];
		
		[imageCache_ setValue:image forKey:key];
#else
		// If the image wasn't in the cache we should return a placholder image,
		// load the real image in the background, then post a notification when the
		// image cache has been updated so a tableview can reload its cells.
		
		image = [self placeholderAlbumImage];
		
		[imageCache_ setValue:image forKey:key];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
			
			UIImage* backgroundLoadedImage = [album imageWithSize:aSize];
            
			if (backgroundLoadedImage)
			{
				// Update the image cache on the main thread.
				
				dispatch_async(dispatch_get_main_queue(), ^{
					
					[imageCache_ setValue:backgroundLoadedImage forKey:key];
					
					[self postImageCacheDidChangeNotification];
				});
				
			}
		});
#endif
		
	}
	
	return image;
}

- (void) configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    const NSInteger section = [indexPath section];
	const NSInteger row = [indexPath row];
    
    NSString*   sectionKey = [[[self searchResults] allKeys] objectAtIndex:(NSUInteger)section];
    NSArray*    sectionContents = [[self searchResults] valueForKey:sectionKey];
	
	if ([sectionKey isEqualToString:SEARCH_RESULTS_KEY_ARTISTS])
	{
        Artist* artist = [sectionContents objectAtIndex:(NSUInteger)row];
        
        cell.textLabel.text = artist.name;
    }
    else if ([sectionKey isEqualToString:SEARCH_RESULTS_KEY_ALBUMS])
    {
		Album* album = [sectionContents objectAtIndex:(NSUInteger)row];
		
		UIImage* image = [self imageWithSize:CGSizeMake(cell.frame.size.height, cell.frame.size.height) forAlbum:album];
		
		if (!image)
		{
			image = [self placeholderAlbumImage];
		}
		
		cell.imageView.image = image;
		cell.imageView.opaque = YES;
		cell.textLabel.text = album.title;
		cell.detailTextLabel.text = album.persistentArtistName;
    }
    else if ([sectionKey isEqualToString:SEARCH_RESULTS_KEY_SONGS])
    {
		Song* song = [sectionContents objectAtIndex:(NSUInteger)row];
		
		cell.textLabel.text = song.title;
		
		NSString* albumAndArtist = nil;
		
		if (song.artistName && song.albumName)
		{
			albumAndArtist = [NSString stringWithFormat:@"%@ - %@", song.albumName, song.artistName];
		}
		else if (song.artistName)
		{
			albumAndArtist = [NSString stringWithFormat:@"%@", song.artistName];
		}
		else if (song.albumName)
		{
			albumAndArtist = [NSString stringWithFormat:@"%@", song.albumName];
		}
		
		cell.detailTextLabel.text = albumAndArtist;
	}
    else
    {
        NSLog(@"Configure cell for unknown section: %@", sectionKey);
    }
}

#pragma mark Public Methods

- (Artist*) artistResultForIndexPath:(NSIndexPath*)indexPath
{
    NSArray* artistResults = [searchResults valueForKey:SEARCH_RESULTS_KEY_ARTISTS];
    
	return ([artistResults count] && indexPath) ? [artistResults objectAtIndex:(NSUInteger)indexPath.row] : nil;
}

- (Album*) albumResultForIndexPath:(NSIndexPath*)indexPath
{
    NSArray* albumResults = [searchResults valueForKey:SEARCH_RESULTS_KEY_ALBUMS];
    
	return ([albumResults count] && indexPath) ? [albumResults objectAtIndex:(NSUInteger)indexPath.row] : nil;
}

- (MusicLibrarySong*) songResultForIndexPath:(NSIndexPath*)indexPath
{
    NSArray* songResults = [searchResults valueForKey:SEARCH_RESULTS_KEY_SONGS];
    
	return ([songResults count] && indexPath) ? [songResults objectAtIndex:(NSUInteger)indexPath.row] : nil;
}

- (NSString*) sectionNameForIndexPath:(NSIndexPath*)indexPath
{
    return [[searchResults allKeys] objectAtIndex:(NSUInteger)indexPath.section];
}

#pragma mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
 	return (NSInteger)[[self searchResults] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[[self searchResults] allKeys] objectAtIndex:(NSUInteger)section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray*    sectionList = [[self searchResults] valueForKey:[[[self searchResults] allKeys] objectAtIndex:(NSUInteger)section]];
    
	return (NSInteger)[sectionList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[self reuseIDForSection:indexPath.section]];
	
	if (!cell)
	{
		cell = [self tableViewCellForSection:indexPath.section];
	}
	
	// Configure the cell...
	
	[self configureCell:cell atIndexPath:indexPath];
	
	return cell;
}

#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText
{
	// Update the filtered array based on the search text
	
    // First clear the filtered arrays.
	[[self searchResults] removeAllObjects];
	
	// Search each of our lists for matches to searchText; add items that match to the corresponding filtered array.
    
    NSArray*    allArtists = [[self musicLibrary] allArtists];
    NSArray*    allAlbums = [[self musicLibrary] allAlbums];
    NSArray*    allSongs = [[self musicLibrary] allSongs];
    
    NSMutableArray* filteredArtistContent = [NSMutableArray array];
    NSMutableArray* filteredAlbumContent = [NSMutableArray array];
    NSMutableArray* filteredSongContent = [NSMutableArray array];
    
	for (Artist *artist in allArtists)
	{
        NSRange range = [artist.name rangeOfString:searchText options:(NSStringCompareOptions)(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)];
        
        if (range.location != NSNotFound)
        {
            [filteredArtistContent addObject:artist];
        }
    }
    
	for (Album *album in allAlbums)
	{
        NSRange range = [album.title rangeOfString:searchText options:(NSStringCompareOptions)(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)];
        
        if (range.location != NSNotFound)
        {
            [filteredAlbumContent addObject:album];
        }
    }
    
	for (Song *song in allSongs)
	{
        NSRange range = [song.title rangeOfString:searchText options:(NSStringCompareOptions)(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)];
        
        if (range.location != NSNotFound)
        {
            [filteredSongContent addObject:song];
        }
    }
    
    if ([filteredArtistContent count])
    {
        [searchResults setValue:filteredArtistContent forKey:SEARCH_RESULTS_KEY_ARTISTS];
    }
    
    if ([filteredAlbumContent count])
    {
        [searchResults setValue:filteredAlbumContent forKey:SEARCH_RESULTS_KEY_ALBUMS];
    }
    
    if ([filteredSongContent count])
    {
        [searchResults setValue:filteredSongContent forKey:SEARCH_RESULTS_KEY_SONGS];
    }
}

#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

@end
