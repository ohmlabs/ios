//
//  GalleryViewController.m
//  OhmPlayer3
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import "GalleryViewController.h"

#import <MediaPlayer/MediaPlayer.h>

#import "MusicLibrary.h"
#import "MusicPlayer.h"
#import "MutablePlaylist.h"
#import "CharacterIndex.h"
#import "SongsTableViewSupport.h"
#import "OhmPlaylistManager.h"
#import "OhmBarButtonItems.h"
#import "OhmAppearance.h"
#import "AppState.h"

#define SHOW_CELL_SELECTION_FOR_DEBUGGING 0

static NSString* const DEFAULT_ALBUM_ARTWORK_IMAGE_NAME	= @"default_album_artwork";
static NSString* const GALLERY_SONG_CELL_REUSE_ID		= @"GallerySongCell";
static NSString* const GALLERY_ARTIST_CELL_REUSE_ID		= @"GalleryArtistCell";
static NSString* const GALLERY_ALBUM_CELL_REUSE_ID		= @"GalleryAlbumCell";
static NSString* const NAV_BAR_BACKGROUND_IMAGE         = @"gallery-nav";
static NSString* const NAV_BAR_RIGHT_BUTTON_IMAGE		= @"search_btn_up";
static NSString* const NAV_BAR_LEFT_BUTTON_IMAGE		= @"back_btn_up";
static NSString* const SHUFFLE_BUTTON_IMAGE				= @"shuffleAll_btn_up";

static NSString* const GALLERY_VIEW_STATE_SELECTED_ARTIST_NAME  = @"GALLERY_VIEW_STATE_SELECTED_ARTIST_NAME";
static NSString* const GALLERY_VIEW_STATE_SELECTED_ALBUM_NAME	= @"GALLERY_VIEW_STATE_SELECTED_ALBUM_NAME";

static NSString* const SEGUE_FROM_GALLERY_TO_NOW_PLAYING_ID		= @"GalleryToNowPlaying";
static NSString* const SEGUE_FROM_GALLERY_TO_LISTS_SCREEN_ID	= @"SegueToGalleryList";

static const NSInteger VIEW_TAG_UIIMAGE_SUBVIEW			= 1; // A UIImageView with this tag MUST appear in the xib.

static const NSUInteger SONG_TABLE_SECTION              = 0;

static const CGFloat ARTIST_TABLE_VIEW_ROTATION_IN_RADIANS           = (CGFloat)-M_PI_2;
static const CGFloat ALBUM_TABLE_VIEW_ROTATION_IN_RADIANS            = (CGFloat)-M_PI_2;

static const CGFloat ARTIST_TABLE_VIEW_CELL_ROTATION_IN_RADIANS      = -ARTIST_TABLE_VIEW_ROTATION_IN_RADIANS;
static const CGFloat ALBUM_TABLE_VIEW_CELL_ROTATION_IN_RADIANS      = -ALBUM_TABLE_VIEW_ROTATION_IN_RADIANS;

static NSString* const ArtistDidChangeNotification = @"ArtistDidChangeNotification";

@interface GalleryViewController (ForwardDeclarations)

- (void) updateSelectedArtist;
- (Artist*) selectedArtist;
- (void) registerForNotifications;
- (void) unregisterForNotifications;
- (MusicLibrary*) musicLibrary;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (void) alertSong:(Song*)song addedToPlaylist:(Playlist*)playlist;

@end

@implementation GalleryViewController

#pragma mark - Properties

@synthesize artistGallery;
@synthesize albumGallery;
@synthesize songsTableView;
@synthesize albumTitleLabel;
@synthesize characterIndex;
@synthesize buildLabel;

@synthesize prototypeAlbumCell;

#pragma mark - Accessors

- (SongsTableViewSupport*) songsTableViewSupport
{
	if (!songsTableViewSupport)
	{
		songsTableViewSupport = [[SongsTableViewSupport alloc] init];
	}
	
	return songsTableViewSupport;
}

- (NSString*) defaultSongTitle
{
    return [OhmAppearance defaultSongTitle];
}

- (NSString*) defaultAlbumTitle
{
    return [OhmAppearance defaultAlbumTitle];
}

- (NSString*) defaultArtistName
{
    return [OhmAppearance defaultArtistName];
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

#pragma mark - Overridden OhmSongTableViewController Methods

- (UITableView*) tableView
{
	return songsTableView;
}

#pragma mark - Protected Methods

- (CGFloat) heightOfAlbumsView
{
	return self.albumGallery.frame.size.height;
}

- (void) setSizeForAlbumCell:(UIView*)cell
{
	const CGFloat Side = [self heightOfAlbumsView];
	
	cell.frame = CGRectMake(0.0F, 0.0F, Side, Side);
}

- (UIImage*) defaultAlbumArtwork
{
	static UIImage* defaultAlbumArtwork = nil;
	
	if (!defaultAlbumArtwork)
	{
		defaultAlbumArtwork = [UIImage imageNamed:DEFAULT_ALBUM_ARTWORK_IMAGE_NAME];
	}
	
	return defaultAlbumArtwork;
}

- (UIImageView*) imageSubviewForCell:(UIView*)cell
{
	UIView* imageView = [cell viewWithTag:VIEW_TAG_UIIMAGE_SUBVIEW];
	
	NSAssert2([imageView isKindOfClass:[UIImageView class]], @"Expected class %@; got class %@", [UIImageView class], [imageView class]);
	
	return ([imageView isKindOfClass:[UIImageView class]]) ? (UIImageView*)imageView : nil;
}

- (NSArray*) albumNames
{
	if (!albumNames)
	{
		albumNames = [[self selectedArtist] albumNames];
	}
	
	return albumNames;
}

- (NSString*) artistNameAtIndexPath:(NSIndexPath*)indexPath
{
	return [[[self musicLibrary] artistAtIndexPath:indexPath] name];
}

- (NSString*) albumNameAtIndex:(NSUInteger)i
{
	return [[self albumNames] objectAtIndex:i];
}

- (NSInteger) indexOfSelectedRowForTableView:(UITableView*)tv
{
    NSIndexPath* indexPath = [tv indexPathForSelectedRow];
    
    return (indexPath) ? [indexPath row] : NSNotFound;
}

- (NSInteger) indexOfSelectedAlbum
{
    NSInteger i = [self indexOfSelectedRowForTableView:albumGallery];
    
    if (NSNotFound == i)
    {
        // Attempt to select the first visible cell.
         
       if ([albumGallery numberOfRowsInSection:0])
        {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
 
            // Select the cell so we can ask which cell was selected later...
            
            if (indexPath) [albumGallery selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
            
            i = [self indexOfSelectedRowForTableView:albumGallery];
        }
    }

    return i;
}

- (void) selectArtistInArtistGallery
{
    UITableView* table = artistGallery;
    
    CGPoint frameCenter = table.center;
    CGPoint boundsCenter = [table convertPoint:frameCenter fromView:table.superview];
    
    NSIndexPath* indexPath = [table indexPathForRowAtPoint:boundsCenter];
    
    if (indexPath)
    {
        [table selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        
        [self updateSelectedArtist]; // $$$$$ note: if we don't call this we can reuse this method better?
    }
}

- (void) scrollToArtistInArtistGallery
{
    UITableView* table = artistGallery;
    
    CGPoint frameCenter = table.center;
    CGPoint boundsCenter = [table convertPoint:frameCenter fromView:table.superview];
    
    NSIndexPath* indexPath = [table indexPathForRowAtPoint:boundsCenter];
    
    if (indexPath)
    {
        [table scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

- (NSIndexPath*) indexPathOfSelectedArtist
{
    NSIndexPath* indexPath = [artistGallery indexPathForSelectedRow];
    
    if (!indexPath)
    {
        [self selectArtistInArtistGallery];
    }
    
    return [artistGallery indexPathForSelectedRow];
}

- (Artist*) selectedArtist
{
    NSIndexPath* indexPath = [self indexPathOfSelectedArtist];
    
    return (indexPath) ? [[self musicLibrary] artistAtIndexPath:indexPath] : nil;
}

- (Album*) selectedAlbum
{
	const NSUInteger index = [self indexOfSelectedAlbum];
	
	return (NSNotFound == index) ? nil : [[[self selectedArtist] albums] objectAtIndex:index];
}

- (NSString*) selectedArtistName
{	
	return [self artistNameAtIndexPath:[artistGallery indexPathForSelectedRow]];
}

- (NSString*) selectedAlbumName
{
	const NSUInteger index = [self indexOfSelectedAlbum];
	
	return (NSNotFound == index) ? nil : [self albumNameAtIndex:index];
}

- (UIImage*) imageForAlbumAtIndex:(NSUInteger)albumIndex withSize:(CGSize)size
{
	NSArray* albumsForSelectedArtist = [[self selectedArtist] albums];
	
	if ([albumsForSelectedArtist count])
	{
		Album* album = [albumsForSelectedArtist objectAtIndex:albumIndex];
		
		return [album imageWithSize:size];
	}
	
	return nil;
}

- (UIImage*) albumImageAtIndex:(NSUInteger)i withSize:(CGSize)size
{
    UIImage* image = [self imageForAlbumAtIndex:i withSize:size];
	
	if (!image)
	{
		image = [self defaultAlbumArtwork];
	}

    return image;
}

- (void) invalidateAlbumNamesCache
{
	albumNames = nil;
}

- (void) invalidateSongNamesCache
{
	cachedSongs = nil;
}

- (void) reloadAlbumData
{
	[self invalidateAlbumNamesCache];
	
	[albumGallery reloadData];
}

- (void) updateAlbumTitle
{
	albumTitleLabel.text = [self selectedAlbumName];
}

- (void) reloadSongData
{
	[self invalidateSongNamesCache];
	
	[songsTableView reloadData];
		
    if ([songsTableView numberOfRowsInSection:SONG_TABLE_SECTION])
    {
        [songsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:SONG_TABLE_SECTION] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void) updateSongsList
{
	[self reloadSongData];
}

- (void) handleArtistDidChange:(NSNotification*)note
{    
    [self reloadAlbumData];
    [self updateSongsList];
}

- (void) postArtistDidChangeNotification
{
	[[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:ArtistDidChangeNotification object:nil] postingStyle:NSPostWhenIdle];
}

- (void) updateSelectedArtist
{
#if 1
    [self postArtistDidChangeNotification];
#else 
	[self reloadAlbumData];
	[self updateSongsList];
#endif
}

- (MusicLibrary*) musicLibrary
{
	return musicLibrary();
}

- (MusicPlayer*) musicPlayer
{
	return musicPlayer();
}

- (UITableViewCell*) tableViewCellForReuseID:(NSString*)reuseID
{
	// Note: this should never be called in iOS 5 or later because tablviews in story boards
	// provide prototype cells.
	
    UITableViewCell* cell = nil;
    
    if ([reuseID isEqualToString:GALLERY_SONG_CELL_REUSE_ID])
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:GALLERY_SONG_CELL_REUSE_ID];
    }
    else if ([reuseID isEqualToString:GALLERY_ARTIST_CELL_REUSE_ID])
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:GALLERY_ARTIST_CELL_REUSE_ID];
    }
    else if ([reuseID isEqualToString:GALLERY_ALBUM_CELL_REUSE_ID])
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:GALLERY_ALBUM_CELL_REUSE_ID];
    }
    
    return cell;
}

- (NSArray*) songsForArtistAndAlbum
{
	if (!cachedSongs)
	{
		[self updateAlbumTitle];
		
		cachedSongs = [self selectedAlbum].songs;
	}
	
	return cachedSongs;
}

- (UIView*) addButtonAccessoryView
{
	return [[self songsTableViewSupport] accessoryButtonViewWithTarget:self];
}

- (void) postNotificationToSelectArtistAtIdleTime
{
    [self postArtistDidChangeNotification];
}

#pragma mark - Protected Methods - Cell Configuration

- (NSString*) reuseCellIDForTableView:(UITableView*)tableView
{
    NSString* reuseID = nil;
    
    if (tableView == songsTableView)
    {
        reuseID = GALLERY_SONG_CELL_REUSE_ID;
    }
    else if (tableView == artistGallery)
    {
        reuseID = GALLERY_ARTIST_CELL_REUSE_ID; 
    }
    else if (tableView == albumGallery)
    {
        reuseID = GALLERY_ALBUM_CELL_REUSE_ID; 
    }
    
    return reuseID;
}

- (void) configureSongTableViewCell:(UITableViewCell*)cell forSong:(MusicLibrarySong*)song
{
	cell.textLabel.text = [song title];
	
	// Dim the label for cells representing songs already in the user's Queue.
	
	// Note: because cells are reused, we must re/set every property or inappropriate properties inherited from a previous
	// use might be visible on the screen.
	
	UIColor* textColor = ([[OhmPlaylistManager queue] containsSong:song]) ? [OhmAppearance queuedSongTableViewTextColor] : [OhmAppearance songTableViewTextColor];
	
	cell.textLabel.textColor = textColor;
	
	if ([[self musicPlayer] isPlayingSong:song])
	{
		cell.accessoryView = nil;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else
	{
		cell.accessoryView = nil; // We're not using + buttons anymore... [self addButtonAccessoryView];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}

}

- (UITableViewCell *)configureSongTableViewCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
	
	NSArray* songs = [self songsForArtistAndAlbum];
	
	if ([songs count])
	{
		const NSInteger row = [indexPath row];
		
		MusicLibrarySong* song = [songs objectAtIndex:row];
		if (song)
		{
			[self configureSongTableViewCell:cell forSong:song];
			cell.accessoryView.tag = row; // IMPORTANT: Tag the accessory view so we can quickly determine its row later...
		}
	}
	else
	{
		cell.textLabel.text = [self defaultSongTitle];
	}
	
	return cell;
}

- (UITableViewCell *)configureArtistTableViewCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{	
	NSString* artistName = [self artistNameAtIndexPath:indexPath];
	
	if ([artistName length])
    {
        cell.textLabel.text = artistName;
    }
    else
	{
		cell.textLabel.text = [self defaultArtistName];
	}
	
	static const CGFloat	ARTIST_CELL_FONTSIZE_MIN	= 16.0F;
		
    static UIFont* font = nil;
    static UIColor* textColor = nil;
    static UIColor* cellHighlightColor = nil;
    static UIColor* backgroundColor = nil;
    	
	if (!font)
    {
        font = [OhmAppearance artistCellFont];
    }
    
	if (!textColor)
    {
        textColor = [OhmAppearance artistCellTextColor];
	}
    
    if (!cellHighlightColor)
    {
        cellHighlightColor = [UIColor greenColor];
	}
    
	if (!backgroundColor)
    {
        backgroundColor	= [OhmAppearance artistCellBackgroundColor];
    }

	UILabel* label = cell.textLabel;

	label.font					= font;
	label.textColor				= textColor;
	label.backgroundColor		= backgroundColor;
	label.textAlignment			= NSTextAlignmentCenter;
	label.lineBreakMode			= NSLineBreakByTruncatingTail;
	//label.minimumFontSize		= ARTIST_CELL_FONTSIZE_MIN;
	label.adjustsFontSizeToFitWidth = YES;
  
#if SHOW_CELL_SELECTION_FOR_DEBUGGING
    cell.selectionStyle         = UITableViewCellSelectionStyleBlue;
#else
    cell.selectionStyle         = UITableViewCellSelectionStyleNone;
#endif
    
    cell.transform              = CGAffineTransformMakeRotation(ARTIST_TABLE_VIEW_CELL_ROTATION_IN_RADIANS);

	return cell;
}

- (UITableViewCell *)configureAlbumTableViewCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{    
    const NSInteger row = [indexPath row];
    
    if (row >= 0)
    {
        UIImage* image = [self albumImageAtIndex:row withSize:cell.frame.size];
        
        UIImageView* imageView = (UIImageView*)[cell viewWithTag:VIEW_TAG_UIIMAGE_SUBVIEW];
        
        imageView.image = image;
    }
 
#if SHOW_CELL_SELECTION_FOR_DEBUGGING
    cell.selectionStyle         = UITableViewCellSelectionStyleBlue;
#else
    cell.selectionStyle         = UITableViewCellSelectionStyleNone;
#endif
    
    cell.transform              = CGAffineTransformMakeRotation(ALBUM_TABLE_VIEW_CELL_ROTATION_IN_RADIANS);

    return cell;
}

#pragma mark -

- (NSUInteger) indexOfAlbumName:(NSString*)albumName
{
    NSArray* names = [self albumNames];
    
	return ([names count]) ? [names indexOfObject:albumName] : NSNotFound;
}

- (void) registerForCharacterIndexActions
{
	[characterIndex addTarget:self action:@selector(selectedCharacterInIndex:)];
}

- (void) setUpCharacterIndex
{
	NSArray* charArray = [self currentCollationSectionTitles];
	
	[characterIndex setCharacters:charArray];
	
	[self registerForCharacterIndexActions];
}

- (void) selectFirstRowInTableView:(UITableView*)tv inSection:(NSUInteger)section
{    
    // Note: if index path doesn't exist, the selectRowAtIndexPath:... method
    // will blow up. Unfortunately, it's expensive to ensure the path exists...
    
    // Apple doesn't document it, but asking for a section that doesn't exist returns
    // NSNotFound (not 0) rows...
    
    const NSInteger NumOfRows = [tv numberOfRowsInSection:section];

    const BOOL isValidIndex = ((NumOfRows > 0) && (NumOfRows != NSNotFound));
    
    NSParameterAssert(isValidIndex);
    
    if (isValidIndex)
    {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
        
        if (indexPath) [tv selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }

}

- (void) selectFirstArtistAtCharacterIndexSecton:(NSUInteger)i
{	
    [self selectFirstRowInTableView:artistGallery inSection:i];
    
	// The scrollviewdelegate methods are not called when
	// a gallery scroll view is programmatically scrolled by
	// setting its selected index. Hence we have to call
	// updateSelectedArtist to update the new state
	// of the artist gallery.
	
    [self updateSelectedArtist];
}

- (MutablePlaylist*) ohmQueue
{
	return [OhmPlaylistManager queue];
}

- (void) playSongInTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath
{	
	MusicLibrarySong* song = [[self songsForArtistAndAlbum] objectAtIndex:[indexPath row]];
	
	if (song)
	{
		[[self musicPlayer] playSong:song inCollection:[self selectedAlbum]];
		
		// Reload/redraw just the selected cell.
		
		NSArray* paths = [[NSArray alloc] initWithObjects:indexPath, nil];
		[tableView reloadRowsAtIndexPaths:paths withRowAnimation:NO];
	}
}

- (MusicLibrarySong*) songForIndexPath:(NSIndexPath*)indexPath
{
	return [[self songsForArtistAndAlbum] objectAtIndex:[indexPath row]];
}

- (void) playSongsInTableView:(UITableView*)tableView
{	
	[[self musicPlayer] playSongCollection:[self selectedAlbum]];
	
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:SONG_TABLE_SECTION];
        
    if (![tableView cellForRowAtIndexPath:indexPath]) return; // the index path is not valid...
    
	// Reload the first cell in the tableview to allow it to visually indicate it's playing.
	
	NSArray* paths = [[NSArray alloc] initWithObjects:indexPath, nil];
	[tableView reloadRowsAtIndexPaths:paths withRowAnimation:NO];
}

- (void) queueSongsInTableView:(UITableView*)tableView
{	
	MutablePlaylist* ohmQueue = [self ohmQueue];

	[ohmQueue addSongsForAlbum:[self selectedAlbum]];
			
	if ([self musicPlayer].isStopped)
	{
		[[self musicPlayer] playSongCollection:ohmQueue];
	}

	// Reload all cells to show they've been added to the queue.
	
	[tableView reloadData];
}

- (BOOL) isOnScreen
{
	return ([self navigationController].topViewController == self);
}

#pragma mark - Screen State Restoration

- (NSIndexPath*) indexPathForArtistName:(NSString*)name sectionName:(NSString*)sectionName
{
    if (![name length] || ![sectionName length]) return nil;
    
    // Find the index section for the name.
    // Then ask the table view for the number of rows in that section
    // and iterate the artists in that section returning a
    // matching index path, if any...
    
    UITableView* tableView = artistGallery;
    
    const NSUInteger indexSection = [[self currentCollation] sectionForObject:sectionName collationStringSelector:@selector(self)];
    
    const NSUInteger tableViewSection = [[self musicLibrary] nearestTableViewSectionForArtistCharacterIndexSection:indexSection];
    
    if (NSNotFound != tableViewSection)
    {
        const NSUInteger rows = [tableView numberOfRowsInSection:tableViewSection];
        
        for (NSUInteger row = 0; row < rows; row++)
        {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:tableViewSection];
            
            if (indexPath)
            {
                NSString* artistName = [self artistNameAtIndexPath:indexPath];
                
                if ([artistName isEqualToString:name])
                {
                    return indexPath;
                }
            }
        }
    }
    
    // We didn't find a section for section name or we didn't find the section name in the chosen section. Recurse.
    
    NSScanner* scanner = [NSScanner scannerWithString:sectionName];
    
    NSCharacterSet* WSP = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    if ([scanner scanUpToCharactersFromSet:WSP intoString:NULL])
    {
        // Note: we scanned past the first word by scanning up to whitespace. It's important that we trim the whitespace we found (if any)
        // before continuing.
        
        NSString* shorterSectionName = [[[scanner string] substringFromIndex:[scanner scanLocation]] stringByTrimmingCharactersInSet:WSP];
        
        // In case our calculation when bad due to an unfortunate parse (or an artist named Cha Cha for example)
        // make sure we don't infinitely recurse. This should never happen, but just to be safe...
        
        return (shorterSectionName && [name isEqualToString:shorterSectionName]) ? nil : [self indexPathForArtistName:name sectionName:shorterSectionName];
    }
    
    return nil;
}

- (NSIndexPath*) indexPathForArtistName:(NSString*)name
{
    return [self indexPathForArtistName:name sectionName:name];
}

- (NSString*) savedArtistName
{
	return [appState() valueForKey:GALLERY_VIEW_STATE_SELECTED_ARTIST_NAME];
}

- (NSString*) savedAlbumName
{
	return [appState() valueForKey:GALLERY_VIEW_STATE_SELECTED_ALBUM_NAME];
}

- (void) setSavedAlbumWithName:(NSString*)name
{    
	[appState() setValue:name forKey:GALLERY_VIEW_STATE_SELECTED_ALBUM_NAME];
}

- (void) setSavedArtistWithName:(NSString*)name
{    
    [appState() setValue:name forKey:GALLERY_VIEW_STATE_SELECTED_ARTIST_NAME];
}

- (void) setSavedAlbum
{
    [self setSavedAlbumWithName:[self selectedAlbumName]];
}

- (void) setSavedArtist
{
    [self setSavedArtistWithName:[self selectedArtistName]];
}

- (BOOL) restoreSavedArtist
{
    static const BOOL DidNotRestore = NO;
    static const BOOL Restored      = YES;
    
    NSString* artistName = [self savedArtistName];
    
    if (![artistName length]) return DidNotRestore;
    
    NSIndexPath* indexPath = [self indexPathForArtistName:artistName];
    
    if (indexPath)
    {
        [artistGallery selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        
        return Restored;
    }
    
    return DidNotRestore;
}

- (BOOL) restoreSavedAlbum
{
    static const BOOL DidNotRestore = NO;
    static const BOOL Restored      = YES;

    NSString* albumName = [self savedAlbumName];
    
    if (![albumName length]) return DidNotRestore;
    
    const NSUInteger i = [self indexOfAlbumName:albumName];
    
    if (NSNotFound != i)
    {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        
        if (indexPath)
        {
            [albumGallery selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];

            return Restored;
        }

    }

    return DidNotRestore;
}

#pragma mark - Public Methods

- (void) selectArtistWithName:(NSString*)artistName
{		
    [self setSavedArtistWithName:artistName];
    
    if ([self isOnScreen])
    {
        // If this view controller is already on-screen simply update the view to reflect
        // the newly selected artist.
        
        [self restoreSavedArtist];
    }
    
}

- (void) selectAlbum:(Album*)album
{    
    [self setSavedArtistWithName:[album artistName]];
    [self setSavedAlbumWithName:[album title]];
    
    if ([self isOnScreen])
    {
        // If this view controller is already on-screen simply update the view to reflect
        // the newly selected artist and album.

        [self restoreSavedArtist];
        [self restoreSavedAlbum];
    }
}

#pragma mark - Select Playlist Delegate Methods

- (void)didSelectPlaylist:(Playlist*)playlist
{	
	if (playlist && !playlist.readonly && [playlist isKindOfClass:[MutablePlaylist class]])
	{
		[(MutablePlaylist*)playlist addSong:longPressedSong];
				
		[self alertSong:longPressedSong addedToPlaylist:playlist];

		longPressedSong = nil; // Release the longPressed song.
	}
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Protected Methods

- (void) segueToListsScreen
{
	[self performSegueWithIdentifier:SEGUE_FROM_GALLERY_TO_LISTS_SCREEN_ID sender:self];
}

- (void) segueToNowPlayingScreen
{
#if OHM_TARGET_4
	[[self navigationController] popViewControllerAnimated:YES];
#else
	[self performSegueWithIdentifier:SEGUE_FROM_GALLERY_TO_NOW_PLAYING_ID sender:self];
#endif
}

#pragma mark Protected Methods - NavigationBar Setup

- (void) setUpNavigationBarAppearance
{
	UIImage* barBackgroundImage = [UIImage imageNamed:NAV_BAR_BACKGROUND_IMAGE];
	
	if (barBackgroundImage)
	{
		UINavigationBar* navBar = self.navigationController.navigationBar;
		
		[navBar setBackgroundImage:barBackgroundImage forBarMetrics:UIBarMetricsDefault];
        
		[navBar setTitleTextAttributes:[OhmAppearance defaultNavBarTextAttributes]];
	}
}

- (void) setUpRightNavigationBarButton
{	
	id target						= self;
	const SEL action				= @selector(search:);
	NSString* const	IMAGE_NAME		= NAV_BAR_RIGHT_BUTTON_IMAGE;
	
	UIBarButtonItem* barButtonItem = [OhmBarButtonItems barButtonItemWithImageNamed:IMAGE_NAME target:target action:action];
	
	if (barButtonItem) 
	{
		[self.navigationItem setRightBarButtonItem:barButtonItem];
	}
}

- (void) setUpLeftNavigationBarButton
{	
	id target						= self;
	const SEL action				= @selector(back:);
	NSString* const	IMAGE_NAME		= NAV_BAR_LEFT_BUTTON_IMAGE;
	
	UIBarButtonItem* barButtonItem = [OhmBarButtonItems barButtonItemWithImageNamed:IMAGE_NAME target:target action:action];
	
	if (barButtonItem) 
	{
		[self.navigationItem setLeftBarButtonItem:barButtonItem];
	}
}

- (void) setUpNavBar
{
    [self setUpNavigationBarAppearance];
	[self setUpRightNavigationBarButton];
	[self setUpLeftNavigationBarButton];
}

- (void) setUpArtistsTableView
{
    UITableView* table = artistGallery;
    
    NSParameterAssert(table);
    
    table.showsVerticalScrollIndicator = NO;
    
    table.pagingEnabled = NO;
    
    // Save the original tableview frame (as it's laid out in IB).
    const CGRect originalIBFrame = table.frame;
    
    // Rotate the table view on its side by rotating it Pi/2 radians (or 90 degrees clockwise).
    table.transform=CGAffineTransformMakeRotation(ARTIST_TABLE_VIEW_ROTATION_IN_RADIANS);
    
    // The frame was rotated as well, so restore it to its original IB frame.
    table.frame = originalIBFrame;
    
#if 0
    table.backgroundColor = [UIColor lightGrayColor];
#else
    table.backgroundColor = [UIColor clearColor];
#endif
    table.rowHeight = table.frame.size.width; // Each cell should span the entire width of the table.
}

- (void) setUpAlbumTableView
{
    UITableView* table = albumGallery;
    
    NSParameterAssert(table);
    
    table.showsVerticalScrollIndicator = NO;
    
    table.pagingEnabled = YES;
    
    // Save the original tableview frame (as it's laid out in IB).
    const CGRect originalIBFrame = table.frame;
    
    // Rotate the table view on its side by rotating it Pi/2 radians (or 90 degrees clockwise).
    table.transform=CGAffineTransformMakeRotation(ALBUM_TABLE_VIEW_ROTATION_IN_RADIANS);
    
    // The frame was rotated as well, so restore it to its original IB frame.
    table.frame = originalIBFrame;
    
    table.rowHeight = table.frame.size.width / 3.0F; // There should be room for up to 3 cells.
    table.separatorColor = [UIColor clearColor]; // PERFORMANCE issue when scrolling? Shouldn't be. Artists don't usually have hundreds of albums...
    
}

- (void) setUpBuildLabel
{
#if DEBUG
    buildLabel.text = [NSString stringWithFormat:@"%s\r%s", __DATE__, __TIME__];
#else
    [buildLabel removeFromSuperview];
#endif
}

- (void) alertSong:(Song*)song addedToPlaylist:(Playlist*)playlist
{
	NSLog(@"Song %@ added to playlist.name %@", song, playlist.name);
}

- (void) alertSongAddedToQueue:(Song*)song
{
	[self alertSong:song addedToPlaylist:[OhmPlaylistManager queue]];
}

- (void) queueSong:(Song*)song inTableView:(UITableView*)aTableView atIndexPath:(NSIndexPath*)indexPath
{
	[SongsTableViewSupport queueSong:song inTableView:aTableView atIndexPath:indexPath];
	[self alertSongAddedToQueue:song];
}

- (void) showPlaylistSelector
{		
	UIViewController* vc = [SelectPlaylistTableViewController selectPlaylistTableViewControllerWithDelegate:self];
	
	if (vc) [self presentViewController: vc animated:YES completion:nil];
}

#pragma mark UIActionSheetDelegate Methods

- (void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{    
    if (actionSheet == longPressActionSheet)
	{
		const NSInteger FIRST_OTHER_BUTTON_INDEX		= actionSheet.firstOtherButtonIndex;
		const NSInteger ADD_TO_PHOTO_BUTTON_INDEX		= FIRST_OTHER_BUTTON_INDEX + 0;
		const NSInteger ADD_TO_PLAYLIST_BUTTON_INDEX	= FIRST_OTHER_BUTTON_INDEX + 1;

		if (actionSheet.cancelButtonIndex == buttonIndex)
		{
			// By design, do nothing...
		}
		else if (ADD_TO_PHOTO_BUTTON_INDEX == buttonIndex)
		{
			NSIndexPath* indexPath = longPressIndexPath;
			
			MusicLibrarySong* song = [self songForIndexPath:indexPath];
			
			if (longPressIndexPath) [self queueSong:song inTableView:self.tableView atIndexPath:indexPath];
		}
		else if (ADD_TO_PLAYLIST_BUTTON_INDEX == buttonIndex)
		{
			NSIndexPath* indexPath = longPressIndexPath;

			MusicLibrarySong* song = [self songForIndexPath:indexPath];
			
			longPressedSong = song;
			
			[self showPlaylistSelector];
		}
		else
		{
			NSAssert1(NO, @"Action sheet received unknown button index %ld", (long)buttonIndex);
		}
		
		longPressActionSheet = nil, longPressIndexPath = nil; // Reset the ability to display this action sheet.

	}
	else
	{
		NSAssert1(NO, @"Unknown action sheet: %@", actionSheet);
	}
}

#pragma mark Gesture Handling Methods - Protected

- (NSIndexPath*) indexPathForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
									   inTable:(UITableView*)aTableView
{	
	const CGPoint swipeCentroid = [gestureRecognizer locationInView:aTableView];
	
	return [aTableView indexPathForRowAtPoint:swipeCentroid];
}

#pragma mark Gesture Handling Methods

- (void) handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{
	// WARNING: this handler can be called multiple times, but the alert sheet should be displayed modally.
	// We have to avoid creating and displaying more than one alert sheet at a time.
	
	if (!longPressActionSheet)
	{
		UITableView* aTableView = self.tableView;
		
		NSIndexPath* indexPath = [self indexPathForGestureRecognizer:gestureRecognizer
															 inTable:aTableView];
		
		if (indexPath)
		{
			longPressActionSheet = [SongsTableViewSupport songActionSheetForDelegate:self];
			
			NSParameterAssert(songsTableView);
			
			if (songsTableView)
			{
				[longPressActionSheet showInView:songsTableView];
				longPressIndexPath = indexPath;
			}
		}
	}
	
}

- (void) handleSwipe:(UIGestureRecognizer *)gestureRecognizer
{
	UITableView* aTableView = self.songsTableView;
	
	const CGPoint swipeCentroid = [gestureRecognizer locationInView:aTableView];
	
	NSIndexPath* indexPath = [aTableView indexPathForRowAtPoint:swipeCentroid];
	
	if (indexPath)
	{
		MusicLibrarySong* song = [self songForIndexPath:indexPath];
		
		if (song) [SongsTableViewSupport queueSong:song inTableView:aTableView atIndexPath:indexPath];
		[self alertSongAddedToQueue:song];
	}
}

#pragma mark - UIScrollViewDelegate Methods

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	// This method is called whenever the artists or albums scroll view stops.
	
	if (scrollView == artistGallery)
	{
        [self scrollToArtistInArtistGallery];
    }
	else if (scrollView == albumGallery)
	{
		// By design, do nothing. The user can browse albums but
		// nothing changes while scrolling albums, only when manually selecting them.
	}
	else if (scrollView == songsTableView)
	{
		// By design, do nothing.
	}
	else
	{
		NSAssert1(NO, @"Unknown scroll view %@", scrollView);
	}
}

- (void) scrollViewDidEndScrollingAnimation:(UIScrollView*)scrollView
{
	if (scrollView == artistGallery)
	{
        [self selectArtistInArtistGallery];
    }
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == artistGallery)
    {
        return [[self musicLibrary] numberOfSectionsForArtists];
    }
    else
    {
        return 1; // All other tableviews on this screen have 1 section.
    }

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;
    
    if (tableView == songsTableView)
    {
        rows = (NSInteger)[[self songsForArtistAndAlbum] count];
    }
    else if (tableView == artistGallery)
    {
        rows = [[self musicLibrary] numberOfRowsForArtistSection:section]; 
    }
    else if (tableView == albumGallery)
    {
        rows = [[self albumNames] count];
    }
       
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{        
    UITableViewCell *cell = nil;
    
    NSString* reuseID = [self reuseCellIDForTableView:tableView];

    NSParameterAssert(reuseID);
    
    if (reuseID)
    {
        if (!(cell = [tableView dequeueReusableCellWithIdentifier:reuseID]))
        {
            cell = [self tableViewCellForReuseID:reuseID];
        }
	}

    if (tableView == songsTableView)
    {
        [self configureSongTableViewCell:cell forRowAtIndexPath:indexPath];
    }
    else if (tableView == artistGallery)
    {
        [self configureArtistTableViewCell:cell forRowAtIndexPath:indexPath];
    }
    else if (tableView == albumGallery)
    {
        [self configureAlbumTableViewCell:cell forRowAtIndexPath:indexPath];
    }

    return cell;
}

#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == songsTableView)
    {
        [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];

        [self playSongInTableView:tableView atIndexPath:indexPath];
        
    #if OHM_TARGET_4
        // We have to manually segue to the Ohm/Now Playing screen. Otherwise, the segue is already setup in the storyboard.
        
        [self segueToNowPlayingScreen];
    #endif
    }
    else if (tableView == albumGallery)
    {    
        [self updateAlbumTitle];
        [self updateSongsList];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == songsTableView)
    {
        UIColor* backgroundColor = [OhmAppearance songTableViewCellBackgroundColor];
        
        if (backgroundColor)
        {
            cell.backgroundColor = backgroundColor;
        }        
    }

}

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
	if (!longPressActionSheet.isVisible) longPressActionSheet = nil;

}

#pragma mark - UIViewController Methods

- (void)viewDidLoad
{
	[super viewDidLoad];
	
    [self setUpArtistsTableView];
        
    [self setUpAlbumTableView];
    
	[self setUpCharacterIndex];
    
    [self setUpNavBar];
        
    [self setUpBuildLabel];
}

- (void) viewWillAppear:(BOOL)animated
{	        
    [self registerForNotifications];

    const BOOL restoredArtist = [self restoreSavedArtist];
    
    [self restoreSavedAlbum];
	
    // If there are artists, select the first one.
    
    if (!restoredArtist && [artistGallery numberOfSections])
    {
        [self selectFirstArtistAtCharacterIndexSecton:0];
    }
    
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
	// Save the current artist index so we can return to the same selected artist later.
	
	[self setSavedArtist];
	
	[self setSavedAlbum];
    
    [self unregisterForNotifications];

	[super viewWillDisappear:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.artistGallery flashScrollIndicators];
	[self.albumGallery flashScrollIndicators];
	[self.songsTableView flashScrollIndicators];
}

#pragma mark - Actions

- (IBAction) selectedCharacterInIndex:(id)sender
{
    //NSLog(@"Selected %C from index", [sender selectedCharacter]);
    
    NSString* letter = [NSString stringWithFormat:@"%C", [sender selectedCharacter]];
    
    if ([letter length])
    {        
        const NSUInteger characterIndexSection = [[self currentCollation] sectionForObject:letter collationStringSelector:@selector(self)];
         
        const NSUInteger tableViewSection = [[self musicLibrary] nearestTableViewSectionForArtistCharacterIndexSection:characterIndexSection];
        
        if (tableViewSection != NSNotFound)
        {
            [self selectFirstArtistAtCharacterIndexSecton:tableViewSection];
        }
    }
}

- (IBAction)addAlbumSongs:(id)sender
{
	[self queueSongsInTableView:songsTableView];
}

- (IBAction)addAndShuffleAlbumSongs:(id)sender
{
	[self playSongsInTableView:songsTableView];
	
    [self musicPlayer].shuffleMode = MPMusicShuffleModeSongs;
	[[self musicPlayer] shuffle:MPMusicShuffleModeSongs];
	
	[self segueToNowPlayingScreen];
}

- (IBAction)search:(id)sender
{
	[self segueToListsScreen];
}

- (IBAction)back:(id)sender
{
	[self segueToNowPlayingScreen];
}

#pragma mark - MusicLibraryImageCacheDidChangeNotification Handler

- (void) handleImageCacheUpdate: (NSNotification *)notification
{	
	[self reloadAlbumData];
}

#pragma mark - MPMusicPlayerController Notifications

- (void) nowPlayingSongDidChangeNotificationHandler:(NSNotification*)note
{
	// When a song changes, we need to update the songs table so that
	// the individual song cells can potentially draw themselves
	// with an indication that they're currently playing.
	
	[self.songsTableView reloadData];
}

#pragma mark - Notifications - Registration

- (void) registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleArtistDidChange:)
												 name:ArtistDidChangeNotification
											   object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleImageCacheUpdate:)
												 name:MusicLibraryImageCacheDidChangeNotification
											   object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(nowPlayingSongDidChangeNotificationHandler:)
												 name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
											   object:nil];
}

- (void) unregisterForNotifications
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
