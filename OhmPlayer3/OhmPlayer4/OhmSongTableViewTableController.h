//
//  OhmSongTableViewTableController.h
//  OhmPlayer3
//
//  Copyright (c) 2012 Ohm Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

// Direct subclasses of UITableViewController can inherit this class.

@interface OhmSongTableViewTableController : UITableViewController

// Subclasses should override these methods to intercept horizontal swipes and long presses.

- (void) handleSwipe:(UISwipeGestureRecognizer*)gestureRecognizer;
- (void) handleLongPress:(UILongPressGestureRecognizer*)gestureRecognizer;

@property (nonatomic, strong) UITableView* tableView;

@end
