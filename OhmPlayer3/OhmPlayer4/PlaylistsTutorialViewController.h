//
//  PlaylistsTutorialViewController.h
//
//  Copyright (c) 2012 Ohm Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlaylistsTutorialViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIView*  backgroundView;

+ (id) playlistsTutorialViewController;

- (IBAction)tapAction:(id)sender;

@end
