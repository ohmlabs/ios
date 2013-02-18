//
//  QueueViewController.h
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OhmSongTableViewTableController.h"
#import "SelectPlaylistTableViewController.h"

@class Song;
@class QueueTutorialViewController;

@interface QueueViewController : OhmSongTableViewTableController<UIActionSheetDelegate, SelectPlaylistDelegate>
{
	Song*   longPressedSong;
}

@property (strong, nonatomic) UIBarButtonItem* actionButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* editButton;
@property (strong, nonatomic) QueueTutorialViewController* tutorialController;

- (IBAction) handleToolbarAction:(id)sender;

@end
