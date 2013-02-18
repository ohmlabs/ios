//
//  PlaylistsTutorialViewController.m
//
//  Copyright (c) 2012 Ohm Labs. All rights reserved.
//

#import "PlaylistsTutorialViewController.h"
#import "OhmAppearance.h"

static NSString* const PLAYLISTS_TUTORIAL_VIEWCONTROLLER_ID	= @"PlaylistsTutorialViewControllerID";
static NSString* const PLAYLISTS_TUTORIAL_VC_STORYBOARD		= @"MainStoryboard";

@implementation PlaylistsTutorialViewController

@synthesize backgroundView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark View Life Cycle

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.backgroundView.backgroundColor = [OhmAppearance defaultTableViewBackgroundColor];
}

#pragma mark Action Methods

- (IBAction)tapAction:(id)sender
{
    [self.view removeFromSuperview];
}

#pragma mark Public Methods

+ (id) playlistsTutorialViewController
{		
	UIStoryboard* storyBoard = [UIStoryboard storyboardWithName:PLAYLISTS_TUTORIAL_VC_STORYBOARD bundle:nil];
    
	PlaylistsTutorialViewController*   tutorialViewController = [storyBoard instantiateViewControllerWithIdentifier:PLAYLISTS_TUTORIAL_VIEWCONTROLLER_ID];
    
	return tutorialViewController;
}

@end
