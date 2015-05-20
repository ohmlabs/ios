//
//  GalleryListViewController.m
//  OhmPlayer3
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import "GalleryListViewController.h"

#import <MediaPlayer/MediaPlayer.h>

#import "GalleryViewController.h"
#import "AlbumsTableViewDataSource.h"
#import "ArtistsTableViewDataSource.h"
#import "SongsTableViewDataSource.h"
#import "SearchResultsTableViewDataSource.h"
#import "SongsTableViewSupport.h"
#import "MusicLibrary.h"
#import "MusicPlayer.h"
#import "MutablePlaylist.h"
#import "Song.h"
#import "OhmPlaylistManager.h"
#import "OhmBarButtonItems.h"
#import "OhmAppearance.h"
#import "NotificationListener.h"
#import "AppState.h"

#import "OhmTargetConditionals.h"

#undef NSParameterAssert
#define NSParameterAssert(condition)    ({\
do {\
_Pragma("clang diagnostic push")\
_Pragma("clang diagnostic ignored \"-Wcstring-format-directive\"")\
NSAssert((condition), @"Invalid parameter not satisfying: %s", #condition);\
_Pragma("clang diagnostic pop")\
} while(0);\
})

// IMPORTANT: These indexes must match those in the corresponding storyboard.

enum {ARTISTS_TAB_INDEX = 0, ALBUMS_TAB_INDEX = 1 , SONGS_TAB_INDEX = 2};

static NSString* const CELL_SEGUE_TO_GALLERY						= @"CellSegueToGallery";
static NSString* const GALLERY_LISTVIEW_STATE_SELECTED_TAB_INDEX	= @"GALLERY_LIST_VIEW_STATE_SELECTED_TAB_INDEX";
static NSString* const CELL_SEGUE_IDENTIFIER_ARTIST                = @"CellSegueToGallery_artistCell";
static NSString* const CELL_SEGUE_IDENTIFIER_ALBUMS                 = @"CellSegueToGallery_albumsCell";

static NSString* const NAV_BAR_LEFT_BUTTON_IMAGE					= @"back_btn_up";
static NSString* const SHUFFLE_BUTTOM_IMAGE							= @"shuffleAll_btn_up";
static NSString* const NAV_BAR_BACKGROUND_IMAGE						= @"titlebar";

//static const CGFloat SHUFFLE_ALL_FONT_SIZE			= 36.0F;

//static const CGFloat DEFAULT_TABLEVIEWCELL_HEIGHT	= 44.0F;

@interface GalleryListViewController (ForwardDeclarations)

- (BOOL) albumDataSourceIsSelected;
- (IBAction) shuffleAll;

@end

@implementation GalleryListViewController

#pragma mark Properties

@synthesize tabBar;
@synthesize tableView;

#pragma mark Accessors

- (NSObject<UITableViewDataSource, UITableViewDelegate>*) albumsTableViewDataSource
{
	if (!albumsTableViewDataSource)
	{
		albumsTableViewDataSource = [[AlbumsTableViewDataSource alloc] init];
	}
	
	return albumsTableViewDataSource;
}

- (NSObject<UITableViewDataSource, UITableViewDelegate>*) artistsTableViewDataSource
{
	if (!artistsTableViewDataSource)
	{
		artistsTableViewDataSource = [[ArtistsTableViewDataSource alloc] init];
	}
	
	return artistsTableViewDataSource;
}

- (NSObject<UITableViewDataSource, UITableViewDelegate>*) songsTableViewDataSource
{
	if (!songsTableViewDataSource)
	{
		songsTableViewDataSource = [[SongsTableViewDataSource alloc] init];
	}
	
	return songsTableViewDataSource;
}

- (NSObject<UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate>*) searchResultsTableViewDataSource
{
	if (!searchResultsTableViewDataSource)
	{
		searchResultsTableViewDataSource = [[SearchResultsTableViewDataSource alloc] init];
	}
	
	return searchResultsTableViewDataSource;
}

- (SongsTableViewSupport*) songsTableViewSupport
{
	if (!songsTableViewSupport)
	{
		songsTableViewSupport = [[SongsTableViewSupport alloc] init];
	}
	
	return songsTableViewSupport;
}

#pragma mark Protected Methods - Notififcation Handling

- (void) nowPlayingSongDidChangeNotificationHandler:(NSNotification*)note
{
	[self.tableView reloadData];
}

- (void) imageCachedDidChangeNotificationHandler:(NSNotification*)note
{
	// Only the albums table view shows artwork, so if we get a stray notification
	// that the image cache has changed, we ignore it for non-ablum table views.
	
	if ([self albumDataSourceIsSelected])
	{
		[self.tableView reloadData];
	}
}

#pragma mark Protected Methods - Notififcation Registration

- (void) registerForNotifications
{
	if (!nowPlayingItemDidChangeNotificationListener)
	{
		nowPlayingItemDidChangeNotificationListener = [[NotificationListener alloc] initWithTarget:self notificationHandler:@selector(nowPlayingSongDidChangeNotificationHandler:) notificationName:MPMusicPlayerControllerNowPlayingItemDidChangeNotification];
	}
	
	if (!imageCacheDidChangeNotificationListener)
	{
		imageCacheDidChangeNotificationListener = [[NotificationListener alloc] initWithTarget:self notificationHandler:@selector(imageCachedDidChangeNotificationHandler:) notificationName:MusicLibraryImageCacheDidChangeNotification];
	}

}

- (void) unregisterForNotifications
{
	nowPlayingItemDidChangeNotificationListener = nil;
	imageCacheDidChangeNotificationListener = nil;
}

#pragma mark Protected Methods

- (MusicPlayer*) musicPlayer
{
	return musicPlayer();
}

- (MusicLibrary*) musicLibrary
{
	return musicLibrary();
}

- (NSUInteger) selectedTabBarIndex
{
	return [[tabBar items] indexOfObject:[tabBar selectedItem]];
}

- (void) selectTabBarButtonAtIndex:(NSUInteger)i
{
	if (i < [[tabBar items] count])
	{	
		tabBar.selectedItem = [[tabBar items] objectAtIndex:i];
	}
}

- (NSObject<UITableViewDataSource, UITableViewDelegate>*) currentTableViewDataSource
{
	NSObject<UITableViewDataSource, UITableViewDelegate>* dataSource = nil;
	
	const NSUInteger i = [self selectedTabBarIndex];
	
	switch (i) {
		case ALBUMS_TAB_INDEX:
			dataSource = [self albumsTableViewDataSource];
			break;
						
		case SONGS_TAB_INDEX:
			dataSource = [self songsTableViewDataSource];
			break;
			
		case ARTISTS_TAB_INDEX:
		default:
			dataSource = [self artistsTableViewDataSource];
			break;
	}
	
	return dataSource;
}

- (void) setSelectedTableViewDataSource
{
	selectedTableViewDataSource = [self currentTableViewDataSource];
}

- (NSObject<UITableViewDataSource, UITableViewDelegate>*) selectedTableViewDataSource
{	
	return (selectedTableViewDataSource) ? selectedTableViewDataSource : [self currentTableViewDataSource];
}

- (NSUInteger) savedSelectedTabIndex
{
	return [[appState() valueForKey:GALLERY_LISTVIEW_STATE_SELECTED_TAB_INDEX] unsignedIntegerValue];
}

- (void) setSavedSelectedTabIndex:(NSUInteger)index
{
	[appState() setValue:[NSNumber numberWithUnsignedInteger:index] forKey:GALLERY_LISTVIEW_STATE_SELECTED_TAB_INDEX];
}

- (MusicLibrarySong*) songForIndexPath:(NSIndexPath*)indexPath
{
	return (indexPath) ? [[self musicLibrary] songAtIndexPath:indexPath] : nil;
}

- (void) playSongInTableView:(UITableView*)aTableView atIndexPath:(NSIndexPath*)indexPath
{	
	MusicLibrarySong* song = [self songForIndexPath:indexPath];
		
	if (song)
	{
		[[self musicPlayer] playSong:song inCollection:[self musicLibrary]];
		
		// Reload/redraw just the selected cell.
		
		NSArray* paths = [[NSArray alloc] initWithObjects:indexPath, nil];
		[aTableView reloadRowsAtIndexPaths:paths withRowAnimation:NO];
	}
}

- (BOOL) artistDataSourceIsSelected
{
	return [self selectedTableViewDataSource] == artistsTableViewDataSource;
}

- (BOOL) albumDataSourceIsSelected
{
	return [self selectedTableViewDataSource] == albumsTableViewDataSource;
}

- (BOOL) songDataSourceIsSelected
{
	return [self selectedTableViewDataSource] == songsTableViewDataSource;
}

- (NSString*) albumName
{
	UITableViewCell* cell = [albumsTableViewDataSource tableView:tableView cellForRowAtIndexPath:[tableView indexPathForSelectedRow]];
	
	return cell.textLabel.text;
}

- (NSString*) artistName
{
	if ([self albumDataSourceIsSelected])
	{
		UITableViewCell* cell = [albumsTableViewDataSource tableView:tableView cellForRowAtIndexPath:[tableView indexPathForSelectedRow]];
		
		return cell.detailTextLabel.text;
	}
	else if ([self artistDataSourceIsSelected])
	{
		UITableViewCell* cell = [artistsTableViewDataSource tableView:tableView cellForRowAtIndexPath:[tableView indexPathForSelectedRow]];
		
		return cell.textLabel.text;
	}
	
	return nil;
}

- (void) segueToNowPlayingScreen
{
#if OHM_TARGET_4
	[[self navigationController] popViewControllerAnimated:YES];
#else
	[self performSegueWithIdentifier:SEGUE_FROM_GALLERY_LIST_TO_NOW_PLAYING_ID sender:self];
#endif
}

- (void)handleTapToShuffle:(UITapGestureRecognizer*)sender
{
	if (sender.state == UIGestureRecognizerStateEnded)
	{ 
		[self shuffleAll];
	}
}

- (void) setUpNavigationBarAppearance
{
	UIImage* barBackgroundImage = [UIImage imageNamed:NAV_BAR_BACKGROUND_IMAGE];
	
	if (barBackgroundImage)
	{
		UINavigationBar* navBar = self.navigationController.navigationBar;
		
		[navBar setBackgroundImage:barBackgroundImage forBarMetrics:UIBarMetricsDefault];
        
		[navBar setTitleTextAttributes:[OhmAppearance defaultNavBarTextAttributes]];
	}
	
	UIImage* shuffleImage = [UIImage imageNamed:SHUFFLE_BUTTOM_IMAGE];
	
	if (shuffleImage)
	{
		UIImageView* imageView = [[UIImageView alloc] initWithImage:shuffleImage];;
		
		imageView.userInteractionEnabled = YES; // Allow gestures to be recognized for this image view.
		
		UIGestureRecognizer* singleTapRecongizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapToShuffle:)];
		
		if (imageView && singleTapRecongizer)
		{
			[imageView addGestureRecognizer:singleTapRecongizer];
			
			[self.navigationItem setTitleView:imageView];
		}
	}
	
}

- (void) setUpRightNavigationBarButton
{	
	// ISSUE: Do nothing until we get an asset (?)
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

#pragma mark UIActionSheetDelegate Methods

- (void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{    
	// actionSheet is long press action sheet...
		
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
	
	if (actionSheet == longPressActionSheet)
	{
		longPressActionSheet = nil;
		longPressIndexPath = nil;
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
#pragma GCC diagnostic ignored "-Wgnu"

- (void) handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{
	// WARNING: this handler can be called multiple times, but the alert sheet should be displayed modally.
	// We have to avoid creating and displaying more than one alert sheet at a time.
	
	if (![self songDataSourceIsSelected])
	{
		// ISSUE: April 15, 2012. What should happen when the user long presses
		// an album or artist on the music gallery lists screen has not been defined.
		// It is also not represented in the reference Android APK.
		
		return;
	}
	
	if (!longPressActionSheet)
	{
		UITableView* aTableView = self.tableView;
		
		NSIndexPath* indexPath = [self indexPathForGestureRecognizer:gestureRecognizer
															 inTable:aTableView];
		
		if (indexPath)
		{
			longPressActionSheet = [SongsTableViewSupport songActionSheetForDelegate:self];
		
			NSParameterAssert(tabBar);
			
			if (tabBar)
			{
				[longPressActionSheet showFromTabBar:tabBar];
				longPressIndexPath = indexPath;
			}
		}
	}
		
}

- (void) handleSwipe:(UIGestureRecognizer *)gestureRecognizer
{
	if ([self songDataSourceIsSelected])
	{
		UITableView* aTableView = self.tableView;
						
		NSIndexPath* indexPath = [self indexPathForGestureRecognizer:gestureRecognizer
															 inTable:aTableView];
		
		if (indexPath)
		{
			MusicLibrarySong* song = [self songForIndexPath:indexPath];

			if (song)
			{
				[self queueSong:song inTableView:aTableView atIndexPath:indexPath];
			}
		}
	}
	
}

#pragma mark UIViewController Methods

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
	
	if (!longPressActionSheet.isVisible) longPressActionSheet = nil;

}

- (void) viewWillAppear:(BOOL)animated
{
	// Restore the saved tab index.
	
	[self registerForNotifications];

	NSUInteger i = [self savedSelectedTabIndex];
	
	[self selectTabBarButtonAtIndex:i];
	
	[tableView reloadData];
	
	[self setUpNavBar];

	[super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[self unregisterForNotifications];

	[super viewWillDisappear:animated];
}

- (void) viewDidDisappear:(BOOL)animated
{
	// Save the current tab index so we can return to the same tab later.
	
	[self setSavedSelectedTabIndex:[self selectedTabBarIndex]];
	
	[super viewDidDisappear:animated];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{	
	// Note: there are multiple identical segues from cells to the gallery view in the storyboard.
	// Since seques must have unique IDs, we must check for a common ID prefix so
	// they can be treated identically.
	
    if (sender && (sender == self.searchDisplayController.searchResultsTableView))
    {
		GalleryViewController*  vc = [segue destinationViewController];
        
        NSIndexPath*    indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
        NSString*       selectedSection = [searchResultsTableViewDataSource sectionNameForIndexPath:indexPath];
        
		if ([selectedSection isEqualToString:SEARCH_RESULTS_KEY_ARTISTS])
		{
			[vc selectArtistWithName:[searchResultsTableViewDataSource artistResultForIndexPath:indexPath].name];
		}
		else if ([selectedSection isEqualToString:SEARCH_RESULTS_KEY_ALBUMS])
		{
            [vc selectAlbum:[searchResultsTableViewDataSource albumResultForIndexPath:indexPath]];
		}
    }
	else if ([[segue identifier] hasPrefix:CELL_SEGUE_TO_GALLERY])
	{
		GalleryViewController* vc = [segue destinationViewController];

		if ([self artistDataSourceIsSelected])
		{
			[vc selectArtistWithName:[self artistName]];
		}
		else if ([self albumDataSourceIsSelected])
		{
            NSParameterAssert([sender isKindOfClass:[UITableViewCell class]]);
                               
            UITableViewCell* cell = sender;
            
            NSIndexPath* indexPath = [tableView indexPathForCell:cell];
            
            Album* anAlbum = (indexPath) ? [albumsTableViewDataSource objectAtIndexPath:indexPath] : nil;
            
            if (anAlbum) [vc selectAlbum:anAlbum];
		}
		
	}
	
}

#pragma mark UITabBarDelegate Methods

- (void)tabBar:(UITabBar *)aTabBar didSelectItem:(UITabBarItem *)item
{
	[self setSelectedTableViewDataSource];
		
	[tableView reloadData];
}

#pragma mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
	if (aTableView == self.searchDisplayController.searchResultsTableView)
    {
        return [[self searchResultsTableViewDataSource] numberOfSectionsInTableView:aTableView];
    }
    else 
    {
        return [[self selectedTableViewDataSource] numberOfSectionsInTableView:aTableView];
    }
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
	if (aTableView == self.searchDisplayController.searchResultsTableView)
    {
        return [[self searchResultsTableViewDataSource] tableView:aTableView numberOfRowsInSection:section];
    }
    else 
    {
        return [[self selectedTableViewDataSource] tableView:aTableView numberOfRowsInSection:section];
    }
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (aTableView == self.searchDisplayController.searchResultsTableView)
    {
        return [[self searchResultsTableViewDataSource] tableView:aTableView cellForRowAtIndexPath:indexPath];
    }
    else 
    {
        UITableViewCell* cell = [[self selectedTableViewDataSource] tableView:aTableView cellForRowAtIndexPath:indexPath];
        
        if ([self songDataSourceIsSelected])
        {
            MusicLibrarySong* song = [self songForIndexPath:indexPath];
            
            UIColor* textColor = ([[OhmPlaylistManager queue] containsSong:song]) ? [OhmAppearance queuedSongTableViewTextColor] : [OhmAppearance songTableViewTextColor];
            
            cell.textLabel.textColor = textColor;

            if ([[self musicPlayer] isPlayingSong:song])
            {
                cell.accessoryView = nil;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            else
            {
                cell.accessoryView = nil; //[[self songsTableViewSupport] accessoryButtonViewWithTarget:self];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            //cell.accessoryView.tag = [indexPath row]; // IMPORTANT: Tag the *accessory view* so we can quickly determine its row later...
        }
        
        return cell;
	}
}

#pragma mark UITableViewDelegate Methods

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (aTableView == self.searchDisplayController.searchResultsTableView)
    {
        UITableViewCell* cell = [aTableView cellForRowAtIndexPath:indexPath];
        
        NSString* reuseID = [cell reuseIdentifier];
        
        if (reuseID)
        {
            if ([reuseID isEqualToString:SEARCH_RESULTS_CELL_REUSE_ID_ARTISTS])
            {
                [self performSegueWithIdentifier:CELL_SEGUE_IDENTIFIER_ARTIST sender:aTableView];
            }
            else if ([reuseID isEqualToString:SEARCH_RESULTS_CELL_REUSE_ID_ALBUMS])
            {
                [self performSegueWithIdentifier:CELL_SEGUE_IDENTIFIER_ALBUMS sender:aTableView];
            }
            else if ([reuseID isEqualToString:SEARCH_RESULTS_CELL_REUSE_ID_SONGS])
            {
                MusicLibrarySong* song = [searchResultsTableViewDataSource songResultForIndexPath:indexPath];
                
                if (song)
                {
                    [[self musicPlayer] playSong:song inCollection:[self musicLibrary]];
                }
                
#if OHM_TARGET_4
                // We have to manually segue to the Ohm/Now Playing screen. Otherwise, the segue is already setup in the storyboard.
                
                [self segueToNowPlayingScreen];
#endif
            }
        }
    }
    else 
    {
        [aTableView deselectRowAtIndexPath:[aTableView indexPathForSelectedRow] animated:YES];
        
        // UX DESIGN: If the user wants to merely add a song to the queue without preempting the currently
        // playing song (if any) they need to tap the + button. Note: tapping the + button
        // will call this controller's addSongButtonTapped: method.
        // If the user taps a song cell, the queue should be cleared and be replaced with the current
        // song list. Furthermore, the queue should jump to and start playing the just tapped song.
        
        if ([self songDataSourceIsSelected])
        {
            [self playSongInTableView:aTableView atIndexPath:indexPath];		
        
    #if OHM_TARGET_4
            // We have to manually segue to the Ohm/Now Playing screen. Otherwise, the segue is already setup in the storyboard.
            
            [self segueToNowPlayingScreen];
    #endif
        }
    }
}

#pragma mark UITableViewDelegate Methods - Table Index Methods

- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)aTableView
{
    if (aTableView == self.searchDisplayController.searchResultsTableView)
    {
        return nil;
    }
    else
    {
        return [[self selectedTableViewDataSource] sectionIndexTitlesForTableView:aTableView];
    }
}

- (NSString *) tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section
{
    if (aTableView == self.searchDisplayController.searchResultsTableView)
    {
        return [[self searchResultsTableViewDataSource] tableView:aTableView titleForHeaderInSection:section];
    }
    else
    {
        return [[self selectedTableViewDataSource] tableView:aTableView titleForHeaderInSection:section];
    }
}

- (NSInteger) tableView:(UITableView *)aTableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (aTableView == self.searchDisplayController.searchResultsTableView)
    {
        return [[self searchResultsTableViewDataSource] tableView:aTableView sectionForSectionIndexTitle:title atIndex:index];
    }
    else
    {
        return [[self selectedTableViewDataSource] tableView:aTableView sectionForSectionIndexTitle:title atIndex:index];
    }
}

#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    return [[self searchResultsTableViewDataSource] searchDisplayController:controller shouldReloadTableForSearchString:searchString];
}

#pragma mark Actions

- (IBAction) addSongButtonTapped:(UIView*)sender
{
	if ([self songDataSourceIsSelected])
	{
		NSAssert(NO, @"Change this to use the current selection, not the sender's tag (which no longer exists)", nil);
		
		//[self queueSongInTableView:self.tableView atIndexPath:[NSIndexPath indexPathForRow:sender.tag inSection:0]];
	}
}

- (IBAction) shuffleAll
{
	// For now, we're going to unconditionally shuffle songs, by design.
	// NSParameterAssert([self songDataSourceIsSelected]);
	
	// Note: I don't think this is a good design. Basically, the shuffle button completely ignores the fact that you're on
	// the album or artists screens - it just shuffles all songs...
	
	//if ([self songDataSourceIsSelected])
	{
		// Shuffle all songs.
				
		[[self musicPlayer] playSongCollection:[self musicLibrary]];
		
		[[self musicPlayer] shuffle:MPMusicShuffleModeSongs];
		
		//			[tableView reloadData]; // Reload the table view cells so the currently playing song is rendered correctly...
		
		[self segueToNowPlayingScreen];
	}

}

- (IBAction) segueToNowPlayingScreen:(id)sender
{
	[self segueToNowPlayingScreen];
}

- (IBAction)back:(id)sender
{
	[[self navigationController] popViewControllerAnimated:YES];
}

@end
