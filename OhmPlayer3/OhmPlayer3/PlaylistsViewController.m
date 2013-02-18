//
//  PlaylistsViewController.m
//  OhmPlayer3
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import "PlaylistsViewController.h"

#import <QuartzCore/QuartzCore.h> // For CALayer access...
//#import <MobileCoreServices/MobileCoreServices.h> // for UTCoreTypes (kUTTypeImage)

#import "MusicLibrary.h"
#import "MusicPlayer.h"
#import "OhmPlaylistManager.h"
#import "OhmAppearance.h"
#import "OhmBarButtonItems.h"
#import "AppState.h"
#import "MutablePlaylist.h"
#import "SongsTableViewSupport.h"
#import "DevicePlaylist.h"
#import "SelectPlaylistTableViewController.h"
#import "PlaylistsTutorialViewController.h"

@interface PlaylistColors : NSObject

@property (nonatomic, strong) NSArray* colors;

+ (PlaylistColors*) sharedInstance;

@end

@implementation PlaylistColors

@synthesize colors;

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.colors = [NSArray arrayWithObjects:[UIColor colorWithRed:178.0f/255.0f green:122.0f/255.0f blue:180.0f/255.0f alpha:1.0f], // #b27ab4
                                                [UIColor colorWithRed:192.0f/255.0f green:225.0f/255.0f blue:192.0f/255.0f alpha:1.0f], // #c0e1c0
                                                [UIColor colorWithRed:255.0f/255.0f green:225.0f/255.0f blue:146.0f/255.0f alpha:1.0f], // #ffe192
                                                [UIColor colorWithRed:158.0f/255.0f green:203.0f/255.0f blue:207.0f/255.0f alpha:1.0f], // #9ECBCF
                                                [UIColor colorWithRed:135.0f/255.0f green:129.0f/255.0f blue:189.0f/255.0f alpha:1.0f], // #8781bd
                                                [UIColor colorWithRed:233.0f/255.0f green:188.0f/255.0f blue:216.0f/255.0f alpha:1.0f], // #e9bcd8
                                                [UIColor colorWithRed:199.0f/255.0f green:108.0f/255.0f blue:171.0f/255.0f alpha:1.0f], // #c76cab
                                                [UIColor colorWithRed:247.0f/255.0f green:160.0f/255.0f blue:139.0f/255.0f alpha:1.0f], // #f7a08b
                                                [UIColor colorWithRed:157.0f/255.0f green:220.0f/255.0f blue:249.0f/255.0f alpha:1.0f], // #9ddcf9
                                                [UIColor colorWithRed:204.0f/255.0f green:204.0f/255.0f blue:255.0f/255.0f alpha:1.0f], // #CCCCFF
                                                [UIColor colorWithRed:137.0f/255.0f green:207.0f/255.0f blue:240.0f/255.0f alpha:1.0f], // #89CFF0
                                                [UIColor colorWithRed:000.0f/255.0f green:103.0f/255.0f blue:165.0f/255.0f alpha:1.0f], // #0067A5
                                                [UIColor colorWithRed:027.0f/255.0f green:163.0f/255.0f blue:190.0f/255.0f alpha:1.0f], // #1BA3BE
//                                                [UIColor colorWithRed:227.0f/255.0f green:103.0f/255.0f blue:092.0f/255.0f alpha:1.0f], // #E3675C
                                                nil];
    }
    
    return self;
}

+ (PlaylistColors*) sharedInstance
{
    static id sharedInstance = nil;
    
    if (sharedInstance) return sharedInstance;
    
    @synchronized (self)
    {
        if (!sharedInstance)
        {
            sharedInstance = [[PlaylistColors alloc] init];
        }
    }
    
    return sharedInstance;
}

@end


static NSString* const PLAYLIST_SONG_CELL_REUSE_ID		= @"PlaylistCell";
static NSString* const PLAYLIST_WIRE_CELL_REUSE_ID		= @"PlaylistWireCell";
static NSString* const PLAYLIST_HEADER_VIEW				= @"ReadOnlyPlaylistHeaderView";
static NSString* const OHM_PLAYLIST_HEADER_VIEW			= @"OhmPlaylistHeaderView";

static NSString* const NAV_BAR_BACKGROUND_IMAGE			= @"titlebar";
static NSString* const NAV_BAR_RIGHT_BUTTON_IMAGE		= @"fwd_btn_up";
static NSString* const NAV_BAR_LEFT_BUTTON_IMAGE        = @"plus-btn-dwn";

static NSString* const PLAYLIST_VIEW_STATE_SELECTED_PLAYLIST_INDEX	= @"PLAYLIST_VIEW_STATE_SELECTED_PLAYLIST_INDEX";
static NSString* const SEGUE_FROM_PLAYLISTS_TO_MUSIC_SCREEN_ID		= @"PlaylistsToMusicSegue";

static NSString* const PLACEHOLDER_ALBUM_IMAGE_NAME     = @"default_album_artwork";

static const CGFloat WIRE_TABLE_VIEW_ROTATION_IN_RADIANS           = (CGFloat)-M_PI_2;

static const CGFloat WIRE_TABLE_VIEW_CELL_ROTATION_IN_RADIANS      = -WIRE_TABLE_VIEW_ROTATION_IN_RADIANS;

static NSString* const USER_DEFAULTS_PLAYLISTS_TUTORIAL_WAS_SEEN = @"USER_DEFAULTS_PLAYLISTS_TUTORIAL_WAS_SEEN";

enum {imageViewTag = 1, fullShadeTag = 2, halfShadeTag = 3, playlistTitleTag = 4, overlayTag = 5};

@interface PlaylistsViewController (ForwardDeclarations)

- (Playlist*) selectedPlaylist;
- (IBAction) doneEditingPlaylist:(id)sender;
- (void) selectPlaylistAtIndex:(NSUInteger)i;
- (void) showMutablePlaylistActionSheet;
- (void) showReadOnlyPlaylistActionSheet;
- (void) showChangePhotoActionSheet;
- (IBAction)segueToMusicScreen:(id)sender;

@end

@implementation PlaylistsViewController

#pragma mark Properties

@synthesize wire;
@synthesize tableView;
@synthesize playlistHeaderView;
@synthesize ohmPlaylistHeaderView;
@synthesize playlistNameLabel;
@synthesize playlistSongCountLabel;
@synthesize tutorialController;

#pragma mark Protected Methods

- (MusicLibrary*) musicLibrary
{
	return musicLibrary();
}

- (MusicPlayer*) musicPlayer
{
	return musicPlayer();
}

- (MutablePlaylist*) ohmQueue
{
	return [OhmPlaylistManager queue];
}

- (NSArray*) ohmPlaylists
{
	// Note: the Ohm Queue appears on a separate screen in Ohm4
    // so the queue is not returned by this method.
    
	return [[OhmPlaylistManager sharedInstance] persistentMutablePlaylists];
}

- (NSArray*) musicLibraryPlaylists
{
	return [[self musicLibrary] allITunesPlaylists];
}

- (UIColor*) tableViewBackgroundColor
{
	return [OhmAppearance playlistTableViewBackgroundColor];
}

- (NSArray*) playlists
{
	if (!compositePlaylists)
	{
		NSArray* ohmLists		= [self ohmPlaylists];
		NSArray* libraryLists	= [self musicLibraryPlaylists];
				
		if (ohmLists && libraryLists)
		{
			compositePlaylists = [ohmLists arrayByAddingObjectsFromArray:libraryLists];
		}
		else if (!libraryLists)
		{
			compositePlaylists = ohmLists;
		}
		else if (!ohmLists)
		{
			compositePlaylists = libraryLists;
		}
		
		// $$$$$ ISSUE: sort the composite list by name (?)!
	}
	
	return compositePlaylists;
}

- (void) updateDisplayedPlaylists
{
    NSParameterAssert(self.wire);
    
    compositePlaylists = nil;
    
    // This reloads the tableview data
    [self selectPlaylistAtIndex:0];
}

- (UITableViewCell*) tableViewCell
{
	return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:PLAYLIST_SONG_CELL_REUSE_ID];
}

- (UITableViewCell*) wireViewCell
{
	return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:PLAYLIST_WIRE_CELL_REUSE_ID];
}

- (CGFloat) heightOfWire
{
	return wire.frame.size.height;
}

- (void) setSizeForWireCell:(UIView*)cell
{
	const CGFloat Side = [self heightOfWire];
	
	cell.frame = CGRectMake(0.0F, 0.0F, Side, Side);
}

- (UIColor*) colorForIdentifier:(NSString*)identifier
{
    PlaylistColors* sharedInstance = [PlaylistColors sharedInstance];
    NSUInteger      index = identifier.hash % sharedInstance.colors.count;
    
    return [sharedInstance.colors objectAtIndex:index];
}

- (void) configurePlaylistCell:(UITableViewCell*)cell forPlaylist:(Playlist*)playlist
{
    NSParameterAssert(cell && playlist);
    
    // The table view has been rotated 90 degrees to the right, so we have to rotate its tableview cells
    // 90 degrees to the left.
    
    cell.transform  = CGAffineTransformMakeRotation(WIRE_TABLE_VIEW_CELL_ROTATION_IN_RADIANS);

//    [cell.layer setBorderColor:[UIColor greenColor].CGColor];
	[cell.layer setBorderWidth:1.0F];

#if 1
    
    UIImageView* imageView = (UIImageView*)[cell viewWithTag:imageViewTag];
    UIView* fullShade = [cell viewWithTag:fullShadeTag];
    UIView* halfShade = [cell viewWithTag:halfShadeTag];
    UIView* overlay = [cell viewWithTag:overlayTag];
    
    NSParameterAssert(imageView && fullShade && halfShade && overlay);
    
    // Make sure all these views are the same size at runtime.
    
    [self setSizeForWireCell:cell];
    [self setSizeForWireCell:imageView];
    [self setSizeForWireCell:fullShade];
    [self setSizeForWireCell:overlay];
    
    // Set background color of image if we don't have an image for the playlist
    NSData* imageData = playlist.imageData;
    
    imageView.image = nil;
    
    if (imageData)
    {
        imageView.image = [UIImage imageWithData:imageData];
    }
    
    if (!imageView.image)
    {
        imageView.layer.backgroundColor = [self colorForIdentifier:playlist.identifier].CGColor;
    }
    
    // Make sure the half-shaded area is half the height of, but still congruent to, the other
    // subviews at runtime.
    
    const CGFloat Side = [self heightOfWire];
	
	halfShade.frame = CGRectMake(0.0F, Side / 2, Side, Side / 2);
    
    // Hide the overlay if the cell is selected.
    
    const BOOL PlaylistIsSelected = [self selectedPlaylist] == playlist;
        
    overlay.hidden = PlaylistIsSelected;
    
    if (!PlaylistIsSelected)
    {
    UILabel* label = (UILabel*)[cell viewWithTag:playlistTitleTag];
    
    NSString*	CELL_FONTNAME                   = [OhmAppearance defaultFontName];
	static const CGFloat	CELL_FONTSIZE		= 14.0F;
	static const CGFloat	CELL_FONTSIZE_MIN	= 10.0F;
	static		UIFont*		font = nil;
    
	if (!font)
	{
		font = [UIFont fontWithName:CELL_FONTNAME size:CELL_FONTSIZE];
	}
		
	UIColor* textColor              = [UIColor whiteColor];
		
	label.text				= playlist.name;
	label.font				= font;
	label.textColor			= textColor;
	label.textAlignment		= UITextAlignmentLeft;
	label.lineBreakMode		= UILineBreakModeTailTruncation;
	label.minimumFontSize	= CELL_FONTSIZE_MIN;
    }

#endif
}

- (void) configureSongCell:(UITableViewCell*)cell forSong:(Song*)song
{	
	if ([[self musicPlayer] isPlayingSong:song])
	{
		cell.textLabel.textColor = [UIColor lightGrayColor];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else
	{
		cell.textLabel.textColor = [UIColor darkGrayColor];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	cell.textLabel.text = song.title;
	
	const CGSize imageSize = CGSizeMake(cell.frame.size.height, cell.frame.size.height);
    UIImage*     songImage = [song imageWithSize:imageSize];
    
	cell.imageView.image = songImage ? songImage : [UIImage imageNamed:PLACEHOLDER_ALBUM_IMAGE_NAME];

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

- (Playlist*) selectedPlaylist
{
	return selectedPlaylist;
}

- (MutablePlaylist*) selectedMutablePlaylist
{
	return  (selectedPlaylist.readonly) ? nil : (MutablePlaylist*)selectedPlaylist;
}

- (void) setSelectedPlaylist:(Playlist*)playlist
{
	selectedPlaylist = playlist;
	
	if (selectedPlaylist)
	{
		self.tableView.tableHeaderView = (selectedPlaylist.readonly) ? [self playlistHeaderView] : [self ohmPlaylistHeaderView];
	}
	else
	{
		self.tableView.tableHeaderView = nil;
	}
    
    playlistNameLabel.text = playlist.name;
    playlistSongCountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%ld songs", @"%ld songs"), (long)playlist.count];
}

- (NSArray*) songs
{
	return [[self selectedPlaylist] songs];
}

- (MusicLibrarySong*) songForIndexPath:(NSIndexPath*)indexPath
{
	const NSInteger row = [indexPath row];
	
	return (row >= 0) ? [[self songs] objectAtIndex:row] : nil;
}

- (void) playSongInTableView:(UITableView*)aTableView atIndexPath:(NSIndexPath*)indexPath
{	
	MusicLibrarySong* song = [self songForIndexPath:indexPath];
	
	if (song && [self selectedPlaylist])
	{
		[[self musicPlayer] playSong:song inCollection:[self selectedPlaylist]];
		
		// Reload/redraw just the selected cell.
		
		NSArray* paths = [[NSArray alloc] initWithObjects:indexPath, nil];
		[aTableView reloadRowsAtIndexPaths:paths withRowAnimation:NO];
	}
}

- (void) setSavedPlaylistIndex:(NSUInteger)i
{
	[appState() setValue:[NSNumber numberWithUnsignedInteger:i] forKey:PLAYLIST_VIEW_STATE_SELECTED_PLAYLIST_INDEX];
}

- (NSUInteger) savedPlaylistIndex
{
	return [[appState() valueForKey:PLAYLIST_VIEW_STATE_SELECTED_PLAYLIST_INDEX] unsignedIntegerValue];
}

- (void) selectPlaylistAtIndex:(NSUInteger)i
{
    NSArray* playlists = [self playlists];
    
    if ([playlists count])
    {
        [self setSelectedPlaylist:[playlists objectAtIndex:i]];
	}
    
	[[self tableView] reloadData];
    
    // We want to de/select any visible de/selected cells.
	    
	// $$$$$ This causes a crash. It doesn't matter if this is called
	// during viewWillAppear: or viewDidAppear:, it still crashes...
	//    [[self wire] reloadRowsAtIndexPaths:[[self wire] indexPathsForVisibleRows] withRowAnimation:NO];
	
	// Reload instead...
	
	[[self wire] reloadData];

	[[self wire] selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] 
							 animated:NO 
					   scrollPosition:UITableViewScrollPositionNone];

}

- (void) segueToNowPlayingScreen
{
	[self segueToMusicScreen:nil];
}

- (void) createPlaylist
{
    UIAlertView* alert = addPlaylistAlert;
    
    if (!alert)
    {
        NSString* title             = NSLocalizedString(@"New Playlist", @"New Playlist");
        NSString* message           = nil;
        NSString* cancelTitle       = NSLocalizedString(@"Cancel", @"Cancel");
        NSString* saveTitle         = NSLocalizedString(@"Save", @"Save");
        id delegate                 = self;
        
        alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:delegate cancelButtonTitle:cancelTitle otherButtonTitles:saveTitle, nil];
        
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    }
    
    addPlaylistAlert = alert;
    
    [alert show];
}

#pragma mark Protected Methods - NavigationBar Setup

- (void) setUpNavigationBarAppearance
{
	UIImage* image = [UIImage imageNamed:NAV_BAR_BACKGROUND_IMAGE];
	
	if (image)
	{
		UINavigationBar* navBar = self.navigationController.navigationBar;
		
		[navBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
				
		[navBar setTitleTextAttributes:[OhmAppearance defaultNavBarTextAttributes]];
	}
}

- (void) setUpRightNavigationBarButton
{	
	id target						= self;
	const SEL action				= @selector(segueToMusicScreen:);
	NSString* const	IMAGE_NAME		= NAV_BAR_RIGHT_BUTTON_IMAGE;
	
	UIBarButtonItem* barButtonItem = [OhmBarButtonItems barButtonItemWithImageNamed:IMAGE_NAME target:target action:action];
	
	if (barButtonItem) 
	{
		[self.navigationItem setRightBarButtonItem:barButtonItem];
	}
}

- (UIBarButtonItem*) leftNavigationBarButton
{	
	id target						= self;
	const SEL action				= @selector(addPlaylist:);
	NSString* const	IMAGE_NAME		= NAV_BAR_LEFT_BUTTON_IMAGE;
	
	return [OhmBarButtonItems barButtonItemWithImageNamed:IMAGE_NAME target:target action:action];
}

- (void) setUpLeftNavigationBarButton
{		
	UIBarButtonItem* barButtonItem = [self leftNavigationBarButton];
	
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

#pragma mark Protected Methods - TableView Setup

- (void) setUpPlaylistsTableView
{
    UITableView* table = wire;
    
    NSParameterAssert(table);
    
    table.showsVerticalScrollIndicator = NO;
    
    table.pagingEnabled = NO;
    
    // Save the original tableview frame (as it's laid out in IB).
    const CGRect originalIBFrame = table.frame;
    
    // Rotate the table view on its side by rotating it Pi/2 radians (or 90 degrees clockwise).
    table.transform=CGAffineTransformMakeRotation(WIRE_TABLE_VIEW_ROTATION_IN_RADIANS);
    
    // The frame was rotated as well, so restore it to its original IB frame.
    table.frame = originalIBFrame;
        
    table.rowHeight = table.frame.size.width / 3.0F; // There should be room for up to 3 cells.
}

#pragma mark Protected Methods - UIScrollView Support

- (void) scrollToNearestPlaylist
{
    UITableView* table = wire;
    
    CGPoint frameCenter = table.center;
    CGPoint boundsCenter = [table convertPoint:frameCenter fromView:table.superview];
    
    NSIndexPath* indexPath = [table indexPathForRowAtPoint:boundsCenter];
    
    if (indexPath)
    {
        [table scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

#pragma mark Gesture Handling Methods - Protected

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
						
			if (tableView)
			{
				[longPressActionSheet showInView:tableView];
				longPressIndexPath = indexPath;
			}
		}
	}
	
}

- (void) handleSwipe:(UIGestureRecognizer *)gestureRecognizer
{
	NSParameterAssert(tableView);
	
	const CGPoint swipeCentroid = [gestureRecognizer locationInView:tableView];
	
	NSIndexPath* indexPath = [tableView indexPathForRowAtPoint:swipeCentroid];
	
	if (indexPath)
	{
		MusicLibrarySong* song = [self songForIndexPath:indexPath];
		
		if (song) [SongsTableViewSupport queueSong:song inTableView:tableView atIndexPath:indexPath];
		
		[self alertSongAddedToQueue:song];
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

#pragma mark UIScrollViewDelegate Methods

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	// This method is called whenever the scollviews stops.
	
	if (scrollView == wire)
	{
        [self scrollToNearestPlaylist];
    }
	else if (scrollView == tableView)
	{
		// By design, do nothing.
	}
	else
	{
		NSAssert1(NO, @"Unknown scroll view %@", scrollView);
	}
}

#pragma mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
    if (aTableView == wire)
    {
        return 1;
    }
    else if (aTableView == tableView)
    {
        return 1;
    }
    else
    {
        NSAssert1(NO, @"Unknown tableview %@", aTableView);
        return 0;
    }
    
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    if (aTableView == wire)
    {
        return [[self playlists] count];  //  Note: this is the total number of apple and ohm playlists combined.
    }
    else if (aTableView == tableView)
    {
        return [[self selectedPlaylist] count];
    }
    else
    {
        NSAssert1(NO, @"Unknown tableview %@", aTableView);
        return 0;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    NSParameterAssert(aTableView && indexPath);

    if (aTableView == wire)
    {
        UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:PLAYLIST_WIRE_CELL_REUSE_ID];
        
        if (!cell)
        {
            cell = [self wireViewCell];
        }
        
        // Configure the cell...
 
        const NSInteger row = [indexPath row];
        
        Playlist* playlist = (row >=0) ? [[self playlists] objectAtIndex:row] : nil;

        [self configurePlaylistCell:cell forPlaylist:playlist];
        
        return cell;
    }
    else if (aTableView == tableView)
    {
        UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:PLAYLIST_SONG_CELL_REUSE_ID];
        if (!cell)
        {
            cell = [self tableViewCell];
        }
        
        // Configure the cell...
        
        NSArray* songs = [self songs];
        
        const NSInteger row = [indexPath row];
        
        MusicLibrarySong* song = (row >=0) ? [songs objectAtIndex:row] : nil;
        
        if (song)
        {
            [self configureSongCell:cell forSong:song];
        }
        
        return cell;
    }
    else
    {
        NSAssert1(NO, @"Unknown tableview %@", aTableView);
        return nil;
    }

}

// Override to support editing the table view.
- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath);
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // Delete the row from the data source
        
        if (aTableView == tableView)
        {
            MutablePlaylist* playlist = [self selectedMutablePlaylist];
            
            if (playlist)
            {
                [playlist removeSongAtIndex:[indexPath row]];
                
                // Animate the deletion in the tableview.
                
                [aTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
        else if (aTableView == wire)
        {
            // Don't allow deleting playlists from the wire (?)
        }
        
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSParameterAssert(fromIndexPath && toIndexPath);
    
    MutablePlaylist* playlist = [self selectedMutablePlaylist];
    
    if (playlist)
    {
        // Note: there's currently only one section in each mutable playlist, so only the row indexes are pertient. This may change
        // in the future if playlists change to contain multiple index sections.
        
        [playlist moveSongAtIndex:[fromIndexPath row] toIndex:[toIndexPath row]];
    }
    
}

// Override to support editing the table view.
- (BOOL)tableView:(UITableView *)aTableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if (aTableView == tableView)
    {
        // Immutable iPod playlists should not allow swipe-to-right to show a delete control.

        return ([self selectedMutablePlaylist]) ? YES : NO;
    }
    else if (aTableView == wire)
    {
        // Playlists should not allow swipe-to-"right" to show a delete control. Note: this means swipe "up" for rotated tableviews such as the wire...
        
        return NO;
    }
    
    return NO;
}

#pragma mark UITableViewDelegate Methods

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (aTableView == wire)
    {
        // If the user selects a playlist in the wire while the [songs] table view is editing a playlist, stop editing.
        
        if (tableView.isEditing)
        {
            [self doneEditingPlaylist:nil];
        }
        
        const NSInteger row = [indexPath row];
        
        if (row >= 0) [self selectPlaylistAtIndex:row];
    }
    else if (aTableView == tableView)
    {
        [aTableView deselectRowAtIndexPath:[aTableView indexPathForSelectedRow] animated:YES];
        
        [self playSongInTableView:aTableView atIndexPath:indexPath];
        
#if OHM_TARGET_4
        // We have to manually segue to the Ohm/Now Playing screen. Otherwise, the segue is already setup in the storyboard.
        
        [self segueToNowPlayingScreen];
#endif
    }
    else
    {
        NSAssert1(NO, @"Unknown tableview %@", aTableView);
    }
	
}

- (void)tableView:(UITableView *)aTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (aTableView == wire)
    {
        UIColor* backgroundColor = nil;
        
        if (backgroundColor)
        {
            cell.backgroundColor = backgroundColor;
        }    
    }
    else if (aTableView == tableView)
    {
        UIColor* backgroundColor = [self tableViewBackgroundColor];
        
        if (backgroundColor)
        {
            cell.backgroundColor = backgroundColor;
        }    
    }
    else
    {
        NSAssert1(NO, @"Unknown tableview %@", aTableView);
    }
	
}

#pragma mark UIViewController Methods

- (void) didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
    
    if (!ipodPlaylistActionSheet.visible) ipodPlaylistActionSheet = nil;
    if (!ohmPlaylistActionSheet.visible) ohmPlaylistActionSheet = nil;
    
    if (!copyPlaylistAlert.visible) copyPlaylistAlert = nil;
    if (!renamePlaylistAlert.visible) renamePlaylistAlert = nil;
    if (!addPlaylistAlert.visible) addPlaylistAlert = nil;

	if (!longPressActionSheet.isVisible) longPressActionSheet = nil;
}

- (void) viewWillAppear:(BOOL)animated
{
    // When returning to this screen, blow the composite cache of playlists.
    
    compositePlaylists = nil;
    
	[self setUpNavBar];

	[super viewWillAppear:animated];
		
	[self selectPlaylistAtIndex:[self savedPlaylistIndex]];
	
	static BOOL firstLoadSinceLaunch = YES;
	
	if (firstLoadSinceLaunch)
	{
		firstLoadSinceLaunch = NO;
		
		// ISSUE: this is a bit of a hack.

		// The music / Now Playing screen is conceptually the first screen the user should see.
		// Normally, this would make it the root story board scene.
		
		// Unfortunately, instead of figuring out how to create a custom transition that simulates a right to left transition
		// (i.e. a reverse push) I instead decided to layput the story board like this: playlist -> music screen -> queue.
		// Doing so gives us the effect we want. But it also means the first time we visit the playlist screen, we should
		// instead transition to the music screen.
		
		// Don't laugh, it works. :-)
		
		UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
		UINavigationController *rootNavController =self.navigationController;
		UIViewController* musicScreen = [storyboard instantiateViewControllerWithIdentifier:@"MusicScreen"];
		
		[rootNavController pushViewController:musicScreen animated:NO];
	}

}

-(void) viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
    NSIndexPath* indexPath = [wire indexPathForSelectedRow];
    
    if (indexPath && [indexPath row] >= 0)
    {
        [self setSavedPlaylistIndex:[indexPath row]];
    }
}

- (void) viewDidLoad
{
    [super viewDidLoad];
	
	UIColor* color = [self tableViewBackgroundColor];
	
	if (color)
	{
		tableView.backgroundColor = color;
		playlistHeaderView.backgroundColor = color;
		ohmPlaylistHeaderView.backgroundColor = color;
	}
    
    // We want the background to show through underneath the wire....
    wire.backgroundColor = [UIColor clearColor];
	
    [self setUpPlaylistsTableView];
    
	NSParameterAssert(wire);
}

- (void) viewDidUnload
{
	[self setWire:nil];
	[self setTableView:nil];
	[self setPlaylistHeaderView:nil];
	[self setOhmPlaylistHeaderView:nil];
	
	compositePlaylists = nil;
	
	[super viewDidUnload];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark UIAlertView Delegate Methods - Protected

- (NSString*) newPlaylistName
{
    const NSUInteger numPlaylists = [[[OhmPlaylistManager sharedInstance] persistentMutablePlaylists] count] + 1;
    
    return [NSString stringWithFormat:NSLocalizedString(@"Playlist %ld", @"Playlist %ld"), (long)numPlaylists];
}

- (void) createPlaylistWithName:(NSString*)name
{
    NSParameterAssert(name);
    
    if (!name) name = [self newPlaylistName];
    
    // Create a playlist based on the selected playlist.
    
    Playlist* playlist = [self selectedPlaylist];
    
    if (![playlist isEmpty])
    {        
        if ([name length])
        {
            [[OhmPlaylistManager sharedInstance] copyPlaylist:playlist withName:name];
            [self updateDisplayedPlaylists];
        }
    }
    
}

- (void) createEmptyPlaylistNamed:(NSString*)name
{
    NSParameterAssert(name);
    
    if (!name) name = [self newPlaylistName];
    
    [[OhmPlaylistManager sharedInstance] createEmptyPlaylistWithName:name];
    
    [self updateDisplayedPlaylists]; // repopulates the playlist array, resets selection to 0
}

- (void) renamePlaylistWithName:(NSString*)name
{
    NSParameterAssert(name);
            
    MutablePlaylist* playlist = [self selectedMutablePlaylist];
    
    if ([name length])
    {
        playlist.name = name;
        
        playlistNameLabel.text = playlist.name;
    }
    
}

- (void) copyPlaylist
{
    UIAlertView* alert = copyPlaylistAlert;
    
    if (!alert)
    {
        // Copying a playlist is the same as creating a new one, because we have to ask for a new name.

        NSString* title             = NSLocalizedString(@"New Playlist", @"New Playlist");
        NSString* message           = nil;
        NSString* cancelTitle       = NSLocalizedString(@"Cancel", @"Cancel");
        NSString* saveTitle         = NSLocalizedString(@"Save", @"Save");
        id delegate                 = self;
        
        alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:delegate cancelButtonTitle:cancelTitle otherButtonTitles:saveTitle, nil];
        
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    }
    
    copyPlaylistAlert = alert;
    
    [alert show];
}

- (void) renamePlaylist
{
    UIAlertView* alert = renamePlaylistAlert;
    
    if (!alert)
    {
        NSString* title             = NSLocalizedString(@"Rename Playlist", @"Rename Playlist");
        NSString* message           = nil;
        NSString* cancelTitle       = NSLocalizedString(@"Cancel", @"Cancel");
        NSString* saveTitle         = NSLocalizedString(@"Save", @"Save");
        id delegate                 = self;
        
        alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:delegate cancelButtonTitle:cancelTitle otherButtonTitles:saveTitle, nil];
        
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    }
    
    renamePlaylistAlert = alert;
    
    [alert show];
}

#pragma mark UIAlertView Delegate Methods - Protected

- (void)copyAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [alertView cancelButtonIndex])
    {
        // do nothing
    }
    else
    {
        NSString* userEnteredText = [[alertView textFieldAtIndex:0] text];
        
        if ([userEnteredText length]) [self createPlaylistWithName:userEnteredText];
    }
    
}

- (void)renameAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [alertView cancelButtonIndex])
    {
        // do nothing
    }
    else
    {
        NSString* userEnteredText = [[alertView textFieldAtIndex:0] text];
        
        if ([userEnteredText length]) [self renamePlaylistWithName:userEnteredText];
    }
    
}

#pragma mark UIAlertView Delegate Method

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{    
    if (alertView == copyPlaylistAlert)
    {
        [self copyAlertView:alertView clickedButtonAtIndex:buttonIndex];
    }
    else if (alertView == renamePlaylistAlert)
    {
        [self renameAlertView:alertView clickedButtonAtIndex:buttonIndex];
    }
    else if (alertView == addPlaylistAlert)
    {
        if (buttonIndex == [alertView cancelButtonIndex])
        {
            // do nothing
        }
        else
        {
            NSString* userEnteredText = [[alertView textFieldAtIndex:0] text];
            
            if ([userEnteredText length]) [self createEmptyPlaylistNamed:userEnteredText];
            
            BOOL    tutorialWasSeen = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_PLAYLISTS_TUTORIAL_WAS_SEEN];
            
            if (!tutorialWasSeen)
            {
                self.tutorialController = [PlaylistsTutorialViewController playlistsTutorialViewController];
                
                if (self.tutorialController)
                {
                    [self.view addSubview:self.tutorialController.view];
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_DEFAULTS_PLAYLISTS_TUTORIAL_WAS_SEEN];
                }
            }
        }
    }
    else
    {
        NSAssert1(NO, @"ERROR: Unknown AlertView %@", alertView);
    }
    
}

#pragma mark Actions

- (IBAction) editPlaylist:(id)sender
{
    if ([self selectedMutablePlaylist])
    {
        // Set the editing button
        
        id target						= self;
        const SEL action				= @selector(doneEditingPlaylist:);

        UIBarButtonItem* barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:target action:action];
        
        if (barButtonItem) 
        {
            [self.navigationItem setRightBarButtonItem:barButtonItem];
        }

        [self.tableView setEditing:YES animated:YES];
    }
}

- (IBAction)doneEditingPlaylist:(id)sender
{
	[self.tableView setEditing:NO animated:YES];
    [self setUpRightNavigationBarButton];
}

- (IBAction) copyPlaylist:(id)sender
{    
	[self copyPlaylist];
}

- (IBAction) renamePlaylist:(id)sender
{
	[self renamePlaylist];
}

- (IBAction) deletePlaylist:(id)sender
{
    MutablePlaylist* mutablePlaylist = [self selectedMutablePlaylist];
    
	if (mutablePlaylist)
    {
        [[OhmPlaylistManager sharedInstance] deletePlaylist:mutablePlaylist];
        [self updateDisplayedPlaylists];
    }
    
}

- (IBAction) clearPlaylist:(id)sender
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (IBAction) shufflePlaylist:(id)sender
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (IBAction) changePhoto:(id)sender
{
    [self showChangePhotoActionSheet];
}

- (IBAction) takePhoto:(id)sender
{
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera] == NO)
    {
        NSLog(@"Camera not available.");
        return;
    }
    
    UIImagePickerController*    imagePickerController = [[UIImagePickerController alloc] init];
    
    // Provides access to all the photo albums on the device
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    // Takes still images only
    //imagePickerController.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeImage, nil];
    
    // Shows the controls for moving and scaling pictures.
    imagePickerController.allowsEditing = YES;
    
    imagePickerController.delegate = self;
    
    [self presentModalViewController:imagePickerController animated:YES];
}

- (IBAction) choosePhoto:(id)sender
{
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary] == NO)
    {
        NSLog(@"Photo library not available.");
        return;
    }
    
    UIImagePickerController*    imagePickerController = [[UIImagePickerController alloc] init];
    
    // Provides access to all the photo albums on the device
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    // Displays still images only
    //imagePickerController.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeImage, nil];
    
    // Shows the controls for moving and scaling pictures.
    imagePickerController.allowsEditing = YES;
    
    imagePickerController.delegate = self;
    
    [self presentModalViewController:imagePickerController animated:YES];
}

- (IBAction) removePhoto:(id)sender
{
    NSUInteger          selectedRow = [[self playlists] indexOfObject:selectedPlaylist];
    NSIndexPath*        selectedIndex = [NSIndexPath indexPathForRow:selectedRow inSection:0];
    UITableViewCell*    selectedCell = [wire cellForRowAtIndexPath:selectedIndex];
    UIImageView*        imageView = (UIImageView*)[selectedCell viewWithTag:imageViewTag];
    
    if (imageView)
    {
        imageView.image = nil;
        selectedPlaylist.imageData = nil;
        
        [wire reloadData];
        [wire selectRowAtIndexPath:selectedIndex 
                          animated:NO 
                    scrollPosition:UITableViewScrollPositionNone];
    }
}

- (IBAction) addPlaylistToQueue:(id)sender
{	
	MutablePlaylist* ohmQueue = [self ohmQueue];
	
	[ohmQueue addSongsForPlaylist:[self selectedPlaylist]];
	
	if ([self musicPlayer].isStopped)
	{
		[[self musicPlayer] playSongCollection:ohmQueue];
	}
	
	// Reload all cells to show they've been added to the queue.
	
	[tableView reloadData];
}

- (IBAction) action:(id)sender
{
    if ([self selectedMutablePlaylist])
    {
        [self showMutablePlaylistActionSheet];
    }
    else
    {
        [self showReadOnlyPlaylistActionSheet];
    }
}

- (IBAction)segueToMusicScreen:(id)sender
{
	[self performSegueWithIdentifier:SEGUE_FROM_PLAYLISTS_TO_MUSIC_SCREEN_ID sender:self];
}

- (IBAction)back:(id)sender
{
	[self segueToMusicScreen:sender];
}

- (IBAction)addPlaylist:(id)sender
{
    [self createPlaylist];
}

#pragma mark UIActionSheet Display - Protected

- (void) showMutablePlaylistActionSheet
{
    NSString* actionSheetTitle          = NSLocalizedString(@"Ohm Playlist Action", @"Ohm Playlist Action");
    NSString* cancelButtonTitle         = NSLocalizedString(@"Cancel", @"Cancel");
    NSString* destructiveButtonTitle    = NSLocalizedString(@"Delete", @"Delete");
    NSString* renameButtonTitle         = NSLocalizedString(@"Rename", @"Rename");
    NSString* editButtonTitle           = NSLocalizedString(@"Edit", @"Edit");
    NSString* copyButtonTitle           = NSLocalizedString(@"Duplicate", @"Duplicate");

    NSString* changePhotoTitle          = selectedPlaylist.imageData ? NSLocalizedString(@"Change Photo", @"Change Photo") : 
                                                                       NSLocalizedString(@"Add Photo", @"Add Photo");

    NSString* addToQueue				= NSLocalizedString(@"Add to Queue", @"Add to Queue");

    id<UIActionSheetDelegate> delegate  = self;

    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:actionSheetTitle
                                                             delegate:delegate
                                                    cancelButtonTitle:cancelButtonTitle
                                               destructiveButtonTitle:destructiveButtonTitle
                                                    otherButtonTitles:editButtonTitle, renameButtonTitle, copyButtonTitle, changePhotoTitle, addToQueue, nil
                                  ];
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    
    ohmPlaylistActionSheet = actionSheet;
    
    [actionSheet showInView:self.wire];
}

- (void) showReadOnlyPlaylistActionSheet
{
    NSString* actionSheetTitle          = NSLocalizedString(@"iPod Playlist Action", @"iPod Playlist Action");
    NSString* cancelButtonTitle         = NSLocalizedString(@"Cancel", @"Cancel");
    NSString* destructiveButtonTitle    = nil;
    NSString* copyButtonTitle           = NSLocalizedString(@"Duplicate to Ohm Playlist", @"Duplicate to Ohm Playlist");
    NSString* addToQueue				= NSLocalizedString(@"Add to Queue", @"Add to Queue");

    id<UIActionSheetDelegate> delegate  = self;
    
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:actionSheetTitle
                                                             delegate:delegate
                                                    cancelButtonTitle:cancelButtonTitle
                                               destructiveButtonTitle:destructiveButtonTitle
                                                    otherButtonTitles:copyButtonTitle, addToQueue, nil
                                  ];
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    
    ipodPlaylistActionSheet = actionSheet;
    
    [actionSheet showInView:self.wire];
    
}

- (void) showChangePhotoActionSheet
{
    NSString* actionSheetTitle          = selectedPlaylist.imageData ? NSLocalizedString(@"Change Photo", @"Change Photo") :
                                                                       NSLocalizedString(@"Add Photo", @"Add Photo");
    
    NSString* cancelButtonTitle         = NSLocalizedString(@"Cancel", @"Cancel");
    
    NSString* destructiveButtonTitle    = selectedPlaylist.imageData ? NSLocalizedString(@"Remove Photo", @"Remove Photo") : 
                                                                       nil;
    
    NSString* takePhotoButtonTitle      = NSLocalizedString(@"Take Photo", @"Take Photo");
    NSString* choosePhotoTitle          = NSLocalizedString(@"Choose Photo", @"Choose Photo");
    
    id<UIActionSheetDelegate> delegate  = self;
    
    UIActionSheet*  actionSheet = [[UIActionSheet alloc] initWithTitle:actionSheetTitle 
                                                              delegate:delegate 
                                                     cancelButtonTitle:cancelButtonTitle
                                                destructiveButtonTitle:destructiveButtonTitle
                                                     otherButtonTitles:takePhotoButtonTitle, choosePhotoTitle, nil
                                   ];
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    
    changePhotoActionSheet = actionSheet;
    
    [actionSheet showInView:self.wire];
    
}

#pragma mark UIActionSheetDelegate Methods - Protected

- (void) handleiPodListActionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.cancelButtonIndex == buttonIndex)
    {
        // By design, do nothing...
    }
    else if (actionSheet.firstOtherButtonIndex == buttonIndex)
    {
        [self copyPlaylist:nil];        
    }
    else if ((actionSheet.firstOtherButtonIndex + 1) == buttonIndex)
    {
        [self addPlaylistToQueue:nil];
    }
    else
    {
        NSAssert1(NO, @"ERROR: Action sheet received unknown button index %ld", (long)buttonIndex);
    }
    
}

- (void) handleOhmListActionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.cancelButtonIndex == buttonIndex)
    {
        // By design, do nothing...
    }
    else if (actionSheet.destructiveButtonIndex == buttonIndex)
    {
        [self deletePlaylist:nil];
    }
    else if (actionSheet.firstOtherButtonIndex == buttonIndex)
    {
        [self editPlaylist:nil];        
    }
    else if ((actionSheet.firstOtherButtonIndex + 1) == buttonIndex)
    {
        [self renamePlaylist:nil];
    }
    else if ((actionSheet.firstOtherButtonIndex + 2) == buttonIndex)
    {
        [self copyPlaylist:nil];
    }
    else if ((actionSheet.firstOtherButtonIndex + 3) == buttonIndex)
    {
        [self changePhoto:nil];
    }
    else if ((actionSheet.firstOtherButtonIndex + 4) == buttonIndex)
    {
        [self addPlaylistToQueue:nil];
    }
    else
    {
        NSAssert1(NO, @"ERROR: Action sheet received unknown button index %ld", (long)buttonIndex);
    }
    
}

- (void) handleLongPressActionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
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

- (void) handleChangePhotoActionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.cancelButtonIndex == buttonIndex)
    {
        // By design, do nothing...
    }
    else if (actionSheet.destructiveButtonIndex == buttonIndex)
    {
        [self removePhoto:nil];
    }
    else if (actionSheet.firstOtherButtonIndex == buttonIndex)
    {
        [self takePhoto:nil];        
    }
    else if ((actionSheet.firstOtherButtonIndex + 1) == buttonIndex)
    {
        [self choosePhoto:nil];
    }
    else
    {
        NSAssert1(NO, @"ERROR: Action sheet received unknown button index %ld", (long)buttonIndex);
    }
    
}

#pragma mark UIActionSheetDelegate Methods

- (void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{    
    if (actionSheet == ipodPlaylistActionSheet)
    {
        [self handleiPodListActionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
    }
    else if (actionSheet == ohmPlaylistActionSheet)
    {
        [self handleOhmListActionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
    }
    else if (actionSheet == longPressActionSheet)
    {
        [self handleLongPressActionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
    }
    else if (actionSheet == changePhotoActionSheet)
    {
        [self handleChangePhotoActionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
    }
    else
    {
        NSAssert1(NO, @"ERROR: Unknown Action sheet %@", actionSheet);
    }
    
}

#pragma mark UIImagePickerControllerDelegate Methods

- (void) imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{
    //NSString*   mediaType = [info objectForKey: UIImagePickerControllerMediaType];

    // Handle a still image picked from a photo album
    //if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo)
    {
        NSUInteger          selectedRow = [[self playlists] indexOfObject:selectedPlaylist];
        NSIndexPath*        selectedIndex = [NSIndexPath indexPathForRow:selectedRow inSection:0];
        UITableViewCell*    selectedCell = [wire cellForRowAtIndexPath:selectedIndex];
        UIImageView*        imageView = (UIImageView*)[selectedCell viewWithTag:imageViewTag];
        
        if (imageView)
        {
            UIImage*    originalImage = [info objectForKey: UIImagePickerControllerOriginalImage];
            UIImage*    editedImage = [info objectForKey: UIImagePickerControllerEditedImage];
            
            imageView.image = editedImage ? editedImage : originalImage;
            selectedPlaylist.imageData = UIImagePNGRepresentation(imageView.image);
            
            [wire reloadData];
            [wire selectRowAtIndexPath:selectedIndex animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
    
    [self dismissModalViewControllerAnimated:YES];
}

@end
