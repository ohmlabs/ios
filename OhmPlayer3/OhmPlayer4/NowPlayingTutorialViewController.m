//
//  NowPlayingTutorialViewController.m
//
//  Copyright (c) 2012 Ohm Labs. All rights reserved.
//

#import "NowPlayingTutorialViewController.h"
#import "OhmAppearance.h"

static NSString* const NOW_PLAYING_TUTORIAL_VIEWCONTROLLER_ID	= @"NowPlayingTutorialViewControllerID";
static NSString* const NOW_PLAYING_TUTORIAL_VC_STORYBOARD		= @"MainStoryboard";

@implementation NowPlayingTutorialViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark Action Methods

- (IBAction)tapAction:(id)sender
{
    [self.view removeFromSuperview];
}

#pragma mark Public Methods

+ (id) nowPlayingTutorialViewController
{		
	UIStoryboard* storyBoard = [UIStoryboard storyboardWithName:NOW_PLAYING_TUTORIAL_VC_STORYBOARD bundle:nil];
    
	NowPlayingTutorialViewController*   tutorialViewController = [storyBoard instantiateViewControllerWithIdentifier:NOW_PLAYING_TUTORIAL_VIEWCONTROLLER_ID];
    
//    tutorialViewController.view.backgroundColor = [OhmAppearance defaultTableViewBackgroundColor];
    
	return tutorialViewController;
}

@end
