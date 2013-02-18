//
//  GalleryListViewController.h
//  OhmPlayer3
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OhmSongTableViewController.h"
#import "SelectPlaylistTableViewController.h"

@class SongsTableViewSupport;
@class NotificationListener;
@class AlbumsTableViewDataSource;
@class ArtistsTableViewDataSource;
@class SongsTableViewDataSource;
@class SearchResultsTableViewDataSource;
@class Song;

@interface GalleryListViewController : OhmSongTableViewController<UITabBarDelegate, UITableViewDataSource, UISearchDisplayDelegate, UISearchBarDelegate, SelectPlaylistDelegate>
{
	NSObject<UITableViewDataSource, UITableViewDelegate>* selectedTableViewDataSource;
	
	AlbumsTableViewDataSource* albumsTableViewDataSource;
	ArtistsTableViewDataSource* artistsTableViewDataSource;
	SongsTableViewDataSource* songsTableViewDataSource;
	
	SearchResultsTableViewDataSource* searchResultsTableViewDataSource;
	
	SongsTableViewSupport* songsTableViewSupport;
	NotificationListener* nowPlayingItemDidChangeNotificationListener;
	NotificationListener* imageCacheDidChangeNotificationListener;
	
	Song* longPressedSong;

	UIActionSheet* longPressActionSheet; 
	NSIndexPath* longPressIndexPath;
}

@property (strong, nonatomic) IBOutlet UITabBar *tabBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)segueToNowPlayingScreen:(id)sender;
- (IBAction)back:(id)sender;

@end
