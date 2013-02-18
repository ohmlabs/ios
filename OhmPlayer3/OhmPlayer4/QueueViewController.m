//
//  QueueViewController.m
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import "QueueViewController.h"

#import "MusicLibrary.h"
#import "MusicPlayer.h"
#import "MutablePlaylist.h"
#import "OhmPlaylistManager.h"
#import "OhmAppearance.h"
#import "OhmBarButtonItems.h"
#import "AppState.h"
#import "QueueTutorialViewController.h"

static NSString* const QUEUE_SONG_CELL_REUSE_ID		= @"QueueCell";
static NSString* const NAV_BAR_BACKGROUND_IMAGE		= @"titlebar";
static NSString* const NAV_BAR_RIGHT_BUTTON_IMAGE	= @"music_btn_up";
static NSString* const NAV_BAR_LEFT_BUTTON_IMAGE	= @"back_btn_up";
static NSString* const TOOLBAR_ACTION_BUTTON_IMAGE	= @"action-btn-up";
static NSString* const PLACEHOLDER_ALBUM_IMAGE_NAME = @"default_album_artwork";
static NSString* const USER_DEFAULTS_QUEUE_TUTORIAL_WAS_SEEN = @"USER_DEFAULTS_QUEUE_TUTORIAL_WAS_SEEN";

@implementation QueueViewController

#pragma mark Synthesized Properties

@synthesize actionButton;
@synthesize editButton;
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

- (MutablePlaylist*) queue
{
    return [OhmPlaylistManager queue];
}

- (NSArray*) songs
{
	return [[self queue] songs];
}

- (UITableViewCell*) tableViewCell
{
	return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:QUEUE_SONG_CELL_REUSE_ID];
}

- (UIColor*) nowPlayingTextColor
{
    return [UIColor lightGrayColor];
}

- (UIColor*) notPlayingTextColor
{
    return [UIColor darkGrayColor];
}

- (BOOL) isPlayingSong:(Song*)song
{
    return (song) ? [[self musicPlayer] isPlayingSong:song] : NO;
}

- (UITableViewCellAccessoryType) nowPlayingAccessoryType
{
    return UITableViewCellAccessoryDisclosureIndicator;
}

- (UITableViewCellAccessoryType) notPlayingAccessoryType
{
    return UITableViewCellAccessoryNone;
}

- (void) configureCell:(UITableViewCell*)cell forSong:(Song*)song
{	
	NSParameterAssert(cell && song);
    
    if ([self isPlayingSong:song])
	{
		cell.textLabel.textColor = [self nowPlayingTextColor];
		cell.accessoryType = [self nowPlayingAccessoryType];
	}
	else
	{
		cell.textLabel.textColor = [self notPlayingTextColor];
		cell.accessoryType = [self notPlayingAccessoryType];
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

- (UIColor*) tableViewBackgroundColor
{
	return [OhmAppearance defaultTableViewBackgroundColor];
}

- (Song*) songForIndexPath:(NSIndexPath*)indexPath
{	
    NSParameterAssert(indexPath);
    
	const NSInteger row = [indexPath row];
	
	NSArray* songs = [self songs];
	
	return (row >=0 && [songs count]) ? [songs objectAtIndex:row] : nil;
}

- (void) playSongInTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath
{	
    NSParameterAssert(tableView && indexPath);

	MusicLibrarySong* song = [self songForIndexPath:indexPath];
	
	if (song)
	{
        // This is the queue view controller, so here we're always playing a song in the user's queue.
        
		[[self musicPlayer] playSong:song inCollection:[OhmPlaylistManager queue]];
		
		// Note: we must show the now playing indicator at the new index path and remove
		// it from the previously playing index path (if it's onscreen).
		
		// Ideally, we'd only reload cells at the current and previous index path's.
        // Note: however that reloading the entire table doesn't appear to result in
        // noticeable performance penalties so we take the easy route.
		
		[tableView reloadData];
	}
}

- (NSString*) newPlaylistName
{
    const NSUInteger numPlaylists = [[[OhmPlaylistManager sharedInstance] persistentMutablePlaylists] count] + 1;
        
    return [NSString stringWithFormat:NSLocalizedString(@"Playlist %ld", @"Playlist %ld"), (long)numPlaylists];
}

- (void) clearQueue
{
    // Remove all songs from the queue.
    
    [[self queue] removeAllSongs];
    
    actionButton.enabled = NO;
    
    [self.tableView reloadData];
}

- (void) createPlaylistWithName:(NSString*)name
{
    NSParameterAssert(name);
    
    if (!name) name = [self newPlaylistName];
    
    // Create a playlist based on the user's queue.
    
    Playlist* playlist = [self queue];
    
    if (![playlist isEmpty])
    {        
        if ([name length])
        {
            [[OhmPlaylistManager sharedInstance] copyPlaylist:playlist withName:name]; 
        }
    }
    
}

- (void) createPlaylist
{
    NSString* title             = NSLocalizedString(@"New Playlist", @"New Playlist");
    NSString* message           = nil;
    NSString* cancelTitle       = NSLocalizedString(@"Cancel", @"Cancel");
    NSString* saveTitle         = NSLocalizedString(@"Save", @"Save");
    id delegate                 = self;
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:delegate cancelButtonTitle:cancelTitle otherButtonTitles:saveTitle, nil];
    
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;

    [alert show];
}

#pragma mark Protected Methods - Segue Support

- (void) segueToNowPlayingScreen
{
#if OHM_TARGET_4
	[[self navigationController] popViewControllerAnimated:YES];
#else
	[self performSegueWithIdentifier:SEGUE_FROM_GALLERY_TO_NOW_PLAYING_ID sender:self];
#endif
}

- (NSArray*) songsForTableViewSection:(NSInteger)section
{
    NSParameterAssert(section == 0); // There's currently only one section at index 0.
    
    return [self songs];
}

#pragma mark Protected Methods - NavigationBar Setup

- (void) setUpNavigationBarAppearance
{
	UIImage* image = [UIImage imageNamed:NAV_BAR_BACKGROUND_IMAGE];
	    
	if (!image)
    {
        NSLog(@"WARNING: Could not load image: %@", NAV_BAR_BACKGROUND_IMAGE);
    }

    UINavigationBar* navBar = self.navigationController.navigationBar;
    
    [navBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    
    [navBar setTitleTextAttributes:[OhmAppearance defaultNavBarTextAttributes]];
}

- (UIBarButtonItem*) leftNavigationBarButton
{	
	id target						= self;
	const SEL action				= @selector(back:);
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

- (UIBarButtonItem*) actionToolBarButton
{	
	id target						= self;
	const SEL action				= @selector(handleToolbarAction:);
	NSString* const	IMAGE_NAME		= TOOLBAR_ACTION_BUTTON_IMAGE;
    
	return [OhmBarButtonItems barButtonItemWithImageNamed:IMAGE_NAME target:target action:action];
}

- (void) setUpActionToolBarButton
{		
	self.actionButton = [self actionToolBarButton];
	
	if (self.actionButton)
	{
        UIBarButtonItem*    flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                                                                      target:self 
                                                                                      action:nil];
        NSArray* items = [NSArray arrayWithObjects:flexSpace, self.actionButton, nil];
        self.toolbarItems = items;
	}
}

- (void) setUpNavBar
{
	[self setUpNavigationBarAppearance];
	[self setUpLeftNavigationBarButton];
}

- (void) hideToolbar:(BOOL)hide
{
    [self.navigationController setToolbarHidden:hide];
}

- (void) setUpToolbar
{
    self.navigationController.toolbar.barStyle  = UIBarStyleBlackOpaque;
    [self hideToolbar:NO];
    [self setUpActionToolBarButton];
    actionButton.enabled = [self songs].count ? YES : NO;
}

#pragma mark Protected Methods - Gesture Handling

- (void) alertSong:(Song*)song addedToPlaylist:(Playlist*)playlist
{
	NSLog(@"Song %@ added to playlist.name %@", song, playlist.name);
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
	// WARNING: this handler can be called multiple times.
	// We have to avoid creating and displaying more than one sheet at a time.

    UITableView* aTableView = self.tableView;
    NSIndexPath* indexPath = [self indexPathForGestureRecognizer:gestureRecognizer
                                                         inTable:aTableView];
    
    longPressedSong = [self songForIndexPath:indexPath];
    
    [self showPlaylistSelector];
}

#pragma mark UIAlert Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
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

#pragma mark UIViewController Methods

- (void) viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
    // Set the background color for this view controller.
	self.tableView.backgroundColor = [self tableViewBackgroundColor];
	
	[self setUpNavBar];
    
    BOOL    tutorialWasSeen = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_QUEUE_TUTORIAL_WAS_SEEN];
    
    if (!tutorialWasSeen && ![self songs].count)
    {
        self.tutorialController = [QueueTutorialViewController queueTutorialViewController];
        
        if (self.tutorialController)
        {
            [self.view addSubview:self.tutorialController.view];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_DEFAULTS_QUEUE_TUTORIAL_WAS_SEEN];
        }
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [self setUpToolbar];
    
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [self hideToolbar:YES];
    
    [super viewWillDisappear:animated];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{    
    [super setEditing:editing animated:animated];

    if (editing)
    {
        self.navigationItem.hidesBackButton = YES;
        [self.navigationItem setLeftBarButtonItem:nil animated:animated];
    }
    else
    {
        self.navigationItem.hidesBackButton = NO;
        [self.navigationItem setLeftBarButtonItem:[self leftNavigationBarButton] animated:animated];
    }
    
}

#pragma mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1; // There's only one. ISSUE: If the queue is large, should it have index sections?
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return (NSInteger)[[self songsForTableViewSection:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    NSParameterAssert(aTableView && indexPath);
    
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:QUEUE_SONG_CELL_REUSE_ID];
    
	if (!cell)
	{
		cell = [self tableViewCell];
	}
	
	// Configure the cell...
		
	MusicLibrarySong* song = [self songForIndexPath:indexPath];

	if (song)
	{
		[self configureCell:cell forSong:song];
	}
	
	return cell;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath);
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // Delete the row from the data source

        MutablePlaylist* queue = [self queue];
        
        if (queue)
        {
            [queue removeSongAtIndex:[indexPath row]];
            
            // Animate the deletion in the tableview.
            
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
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

    MutablePlaylist* queue = [self queue];
    
    if (queue)
    {
        // Note: there's currently only one section in each mutable playlist, so only the row indexes are pertient. This may change
        // in the future if playlists change to contain multiple index sections.
        
        [queue moveSongAtIndex:[fromIndexPath row] toIndex:[toIndexPath row]];
    }
    
}

#pragma mark UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert(tableView && indexPath);
    
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
	
	[self playSongInTableView:tableView atIndexPath:indexPath];

#if OHM_TARGET_4
    
	// We have to manually override the Ohm3 segue in the storyboard and segue to the Ohm/Now Playing screen instead in Ohm4.
	
    [self segueToNowPlayingScreen];
#endif
}

#pragma mark UIActionSheetDelegate Methods

- (void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{    
    if (actionSheet.cancelButtonIndex == buttonIndex)
    {
        // By design, do nothing...
    }
    else if (actionSheet.destructiveButtonIndex == buttonIndex)
    {
        [self clearQueue];
    }
    else if (actionSheet.firstOtherButtonIndex == buttonIndex)
    {
        [self createPlaylist];        
    }
    else
    {
        NSAssert1(NO, @"Action sheet received unknown button index %ld", (long)buttonIndex);
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

#pragma mark Actions

- (IBAction)back:(id)sender
{
    // This action is called by the left navigation bar item (i.e. a custom back button).
    
	[[self navigationController] popViewControllerAnimated:YES];
}

- (IBAction) handleToolbarAction:(id)sender
{
    if (self.isEditing)
    {
        [self setEditing:NO];
    }
    
    NSString* actionSheetTitle          =  NSLocalizedString(@"Queue Action", @"Queue Action");
    NSString* cancelButtonTitle         = NSLocalizedString(@"Cancel", @"Cancel");
    NSString* destructiveButtonTitle    = NSLocalizedString(@"Clear", @"Clear");
    NSString* saveButtonTitle           = NSLocalizedString(@"Create Playlist", @"Create Playlist");
    id<UIActionSheetDelegate> delegate  = self;

    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:actionSheetTitle
                                                             delegate:delegate
                                                    cancelButtonTitle:cancelButtonTitle
                                               destructiveButtonTitle:destructiveButtonTitle
                                                    otherButtonTitles:saveButtonTitle, nil
                                  ];
    
    UIToolbar* toolbar = self.navigationController.toolbar;
    
    NSParameterAssert(toolbar);
    
    if (toolbar) [actionSheet showFromToolbar:toolbar];
    
}

@end
