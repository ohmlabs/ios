//
//  SongTableViewSupport.m
//  OhmPlayer3
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import "SongsTableViewSupport.h"

#import "OhmPlaylistManager.h"
#import "MutablePlaylist.h"
#import "MusicPlayer.h"

static NSString* const ADD_BUTTON_IMAGE_NAME = @"add_button";

@implementation SongsTableViewSupport

#pragma mark Protected Methods

- (UIImage*) songAccessoryImage
{	
	if (!songCellAccessoryImage)
	{
		songCellAccessoryImage = [UIImage imageNamed:ADD_BUTTON_IMAGE_NAME];
	}
	
	return songCellAccessoryImage;
}

- (UIView*) addButtonAccessoryViewWithTarget:(id)target
{
	UIImage* image = [self songAccessoryImage];
	
	NSParameterAssert(image);
	
	if (image)
	{
		UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
        
  		button.frame = CGRectMake(0, 0, 40, 40); // ISSUE: hard code constants. No easy way to calculate...(?)
        
        // Scale the buttons content area so that its image scales to fill.
        
        const CGFloat dx = button.frame.size.width	/ image.size.width;
        const CGFloat dy = button.frame.size.height	/ image.size.height;
        
        button.transform = CGAffineTransformMakeScale(dx, dy);

		//button.backgroundColor = [UIColor greenColor];

		[button setImage:image forState:UIControlStateNormal];
		
		[button addTarget:target action:@selector(addSongButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
		
		return button;
	}
	
	return nil;
}

#pragma mark Public Methods

- (UIView*) accessoryButtonViewWithTarget:(id)target
{	
	return (target) ? [self addButtonAccessoryViewWithTarget:target] : nil;
}

+ (UIActionSheet*) songActionSheetForDelegate:(id)delegate
{
	NSString* actionSheetTitle          = nil;
	NSString* cancelButtonTitle         = NSLocalizedString(@"Cancel", @"Cancel");
	NSString* destructiveButtonTitle    = nil;
	NSString* addToQueueButtonTitle     = NSLocalizedString(@"Add To Queue", @"Add To Queue");
	NSString* addToPlaylistButtonTitle  = NSLocalizedString(@"Add To Playlist", @"Add To Playlist");
	
	UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:actionSheetTitle
															 delegate:delegate
													cancelButtonTitle:cancelButtonTitle
											   destructiveButtonTitle:destructiveButtonTitle
													otherButtonTitles:addToQueueButtonTitle,
								  addToPlaylistButtonTitle,
								  nil
								  ];
		
	//actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
	
	return actionSheet;
}

+ (void) queueSong:(Song*)song inTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath
{		
	if (song)
	{
		MutablePlaylist* ohmQueue = [OhmPlaylistManager queue];
		
		[ohmQueue addSong:song];
		
		MusicPlayer* player = musicPlayer();
		
		if (player.isStopped)
		{
			[player playSongCollection:ohmQueue];
		}
		
		// Reload/redraw just the selected cell to reveal it's in the queue.
		
		if (indexPath)
		{
			NSArray* paths = [[NSArray alloc] initWithObjects:indexPath, nil];
			[tableView reloadRowsAtIndexPaths:paths withRowAnimation:NO];
		}
	}
}

@end
