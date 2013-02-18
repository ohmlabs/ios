//
//  SongsTableViewDataSource.m
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import "SongsTableViewDataSource.h"

#import "MusicLibrary.h"
#import "MusicPlayer.h"

static NSString* const CELL_REUSE_ID = @"SongsCell";

@implementation SongsTableViewDataSource

#pragma mark - Protected Methods

- (UITableViewCell*) tableViewCell
{
	return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CELL_REUSE_ID];
}

- (MusicLibrary*) musicLibrary
{
	return musicLibrary();
}

- (void) configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
	const NSInteger row = [indexPath row];
	
	if (row >= 0)
	{
		Song* song = [[self musicLibrary] songAtIndexPath:indexPath];
		
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
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
 	return [[self musicLibrary] numberOfSectionsForSongs];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[self musicLibrary] numberOfRowsForSongSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_REUSE_ID];
	
	if (!cell)
	{
		cell = [self tableViewCell];
	}
	
	// Configure the cell...
	
	[self configureCell:cell atIndexPath:indexPath];
	
	return cell;
}

#pragma mark UITableViewDataSource Methods - Table Index

- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [[self musicLibrary] titleForHeaderInSongSection:section];
}

- (NSInteger) tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
}

@end
