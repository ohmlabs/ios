//
//  SongTableViewSupport.h
//  OhmPlayer3
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Song;

@interface SongsTableViewSupport : NSObject
{
	UIImage* songCellAccessoryImage;
}

// When the accessory button returned is tapped, the target
// is sent an addSongButtonTapped: message with the button
// as the sender.

- (UIView*) accessoryButtonViewWithTarget:(id)target;

+ (UIActionSheet*) songActionSheetForDelegate:(id)delegate;

+ (void) queueSong:(Song*)song inTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath;

@end
