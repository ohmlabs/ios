//
//  SelectPlaylistTableViewController.h
//  OhmPlayer3
//
//  Copyright (c) 2012 Ohm Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Playlist;

@protocol SelectPlaylistDelegate <NSObject>

// Note: this method MUST dismiss the currently presented view controller.

- (void)didSelectPlaylist:(Playlist*)playlist;

@end

@interface SelectPlaylistTableViewController : UITableViewController

@property (nonatomic, weak) id<SelectPlaylistDelegate> selectPlaylistDelegate;

- (IBAction)cancel:(id)sender;

+ (id) selectPlaylistTableViewControllerWithDelegate:(id<SelectPlaylistDelegate>)delegate;

@end
