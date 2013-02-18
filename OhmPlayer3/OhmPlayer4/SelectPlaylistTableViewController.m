//
//  SelectPlaylistTableViewController.m
//  OhmPlayer3
//
//  Copyright (c) 2012 Ohm Labs. All rights reserved.
//

#import "SelectPlaylistTableViewController.h"

#import "OhmAppearance.h"
#import "OhmPlaylistManager.h"
#import "Playlist.h"
#import <QuartzCore/QuartzCore.h> // For CALayer access...

static NSString* const SELECT_PLAYLIST_VIEWCONTROLLER_ID	= @"SelectPlaylistTableViewControllerID";
static NSString* const SELECT_PLAYLIST_VC_STORYBOARD		= @"MainStoryboard";

@implementation SelectPlaylistTableViewController

#pragma mark Properties

@synthesize selectPlaylistDelegate;

#pragma mark Protected Methods

- (void) setUpNavigationBarAppearance
{
#if 0
	// ISSUE: For some reason this does not have the desired effect - the text
	// is truncated!
	
	UINavigationBar* navBar = self.navigationController.navigationBar;
	
	[navBar setTitleTextAttributes:[OhmAppearance defaultNavBarTextAttributes]];
#endif
}

#pragma mark UITableViewController Methods

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
	// The select playlist delegate MUST be set before displaying this view controller.
	
	NSParameterAssert(selectPlaylistDelegate);
	
    [super viewWillAppear:animated];
	
	[self setUpNavigationBarAppearance];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

#pragma mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1; // There's only one section of playlists.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// Note: this correctly does not display iTunes playlists, which are immutable.
	
	return [[[OhmPlaylistManager sharedInstance] persistentMutablePlaylists] count];
}

- (UIColor*) colorForIdentifier:(NSString*)identifier
{
//    PlaylistColors* sharedInstance = [PlaylistColors sharedInstance];
//    NSUInteger      index = identifier.hash % sharedInstance.colors.count;
//    
//    return [sharedInstance.colors objectAtIndex:index];
	return [UIColor blueColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"selectPlaylistCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    
	Playlist* playlist = [[[OhmPlaylistManager sharedInstance] persistentMutablePlaylists] objectAtIndex:[indexPath row]];
	
	NSData* imageData = playlist.imageData;
	
	UIImage* image = imageData ? [UIImage imageWithData:imageData] : nil;
	
	if (image)
	{
		cell.imageView.image = image;
		cell.imageView.opaque = YES;
	}
	else
	{
		cell.imageView.layer.backgroundColor = [self colorForIdentifier:playlist.identifier].CGColor;
	}
	
	cell.textLabel.text = playlist.name;
	
    return cell;
}

#pragma mark UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	id delegate = selectPlaylistDelegate;
	
	if ([delegate conformsToProtocol:@protocol(SelectPlaylistDelegate)])
	{
		Playlist* playlist = [[[OhmPlaylistManager sharedInstance] persistentMutablePlaylists] objectAtIndex:[indexPath row]];

		[(id<SelectPlaylistDelegate>)delegate didSelectPlaylist:playlist];
	}
	else
	{
		NSLog(@"Delegate %@ does not conform to protocol SelectPlaylistDelegate", delegate);
	}
}

#pragma mark Actions Methods

- (IBAction)cancel:(id)sender
{
	id delegate = selectPlaylistDelegate;

	if ([delegate conformsToProtocol:@protocol(SelectPlaylistDelegate)])
	{
		[(id<SelectPlaylistDelegate>)delegate didSelectPlaylist:nil];
	}
	else
	{
		NSLog(@"Delegate %@ does not conform to protocol SelectPlaylistDelegate", delegate);
		
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}

#pragma mark Public Methods

+ (id) selectPlaylistTableViewControllerWithDelegate:(id<SelectPlaylistDelegate>)delegate
{		
	NSParameterAssert(delegate);
	
	if (!delegate) return nil;
	
	UIStoryboard* storyBoard = [UIStoryboard storyboardWithName:SELECT_PLAYLIST_VC_STORYBOARD bundle:nil];
	
	// Note: the select playlist delegate is embedded in a navigation controller...
	
	UINavigationController* navController = [storyBoard instantiateViewControllerWithIdentifier:SELECT_PLAYLIST_VIEWCONTROLLER_ID];
	
	SelectPlaylistTableViewController* selectPlaylistViewController = [[navController viewControllers] count] ? [[navController viewControllers] objectAtIndex:0] : nil;
	
	selectPlaylistViewController.selectPlaylistDelegate = delegate;

	return navController;
}

@end
