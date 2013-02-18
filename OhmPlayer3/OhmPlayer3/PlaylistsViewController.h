//
//  PlaylistsViewController.h
//  OhmPlayer3
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GalleryView.h"
#import "OhmSongTableViewController.h"
#import "SelectPlaylistTableViewController.h"

@class Playlist;
@class Song;
@class PlaylistsTutorialViewController;

@interface PlaylistsViewController : OhmSongTableViewController<UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SelectPlaylistDelegate>
{
	Playlist* selectedPlaylist;
	NSArray* compositePlaylists; // An array of playlist objects.
    UIActionSheet* ipodPlaylistActionSheet;
    UIActionSheet* ohmPlaylistActionSheet;
    UIAlertView* copyPlaylistAlert;
	UIActionSheet* changePhotoActionSheet;
    UIAlertView* renamePlaylistAlert;
	UIActionSheet* longPressActionSheet; 
	NSIndexPath* longPressIndexPath;
    UIAlertView* addPlaylistAlert;
	
	Song* longPressedSong;
}

@property (strong, nonatomic) IBOutlet UITableView* wire;
@property (strong, nonatomic) IBOutlet UITableView* tableView;
@property (strong, nonatomic) IBOutlet UIView* playlistHeaderView;
@property (strong, nonatomic) IBOutlet UIView* ohmPlaylistHeaderView;

@property (strong, nonatomic) IBOutlet UILabel* playlistNameLabel;
@property (strong, nonatomic) IBOutlet UILabel* playlistSongCountLabel;

@property (strong, nonatomic) PlaylistsTutorialViewController* tutorialController;

- (IBAction) editPlaylist:(id)sender;
- (IBAction) copyPlaylist:(id)sender;
- (IBAction) deletePlaylist:(id)sender;
- (IBAction) clearPlaylist:(id)sender;
- (IBAction) shufflePlaylist:(id)sender;
- (IBAction) action:(id)sender;
- (IBAction) addPlaylist:(id)sender;

@end
