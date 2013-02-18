//
//  GalleryViewController.h
//  OhmPlayer3
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OhmSongTableViewController.h"
#import "SelectPlaylistTableViewController.h"

@class CharacterIndex;
@class SongsTableViewSupport;
@class Album;
@class Song;

@interface GalleryViewController : OhmSongTableViewController<UIScrollViewDelegate, UITableViewDelegate, SelectPlaylistDelegate>
{
	NSArray* artistNames;
	NSArray* albumNames;
	NSArray* artistSections;
	
	NSArray* cachedSongs; // PERFORMANCE: The music library object doesn't cache its results, so clients should.
    UILocalizedIndexedCollation* currentCollation; // Cache for performance.
    NSArray* currentCollationSectionTitles; // Cache for performance.

	UIImage* songCellAccessoryImage;

	UIActionSheet* longPressActionSheet; 

	NSIndexPath* longPressIndexPath;
	
	SongsTableViewSupport* songsTableViewSupport;
	
	Song* longPressedSong;
	
	UINib* nib;
}

@property (strong, nonatomic) IBOutlet UITableView *artistGallery;
@property (strong, nonatomic) IBOutlet UITableView *albumGallery;
@property (strong, nonatomic) IBOutlet UITableView *songsTableView;
@property (strong, nonatomic) IBOutlet UILabel *albumTitleLabel;
@property (strong, nonatomic) IBOutlet UIView *prototypeAlbumCell;
@property (strong, nonatomic) IBOutlet CharacterIndex *characterIndex;
@property (strong, nonatomic) IBOutlet UILabel *buildLabel;

- (IBAction)addAlbumSongs:(id)sender;
- (IBAction)addAndShuffleAlbumSongs:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)back:(id)sender;

- (void) selectArtistWithName:(NSString*)artistName;
- (void) selectAlbum:(Album*)album;

@end
