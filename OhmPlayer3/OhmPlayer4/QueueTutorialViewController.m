//
//  QueueTutorialViewController.m
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import "QueueTutorialViewController.h"
#import "OhmAppearance.h"

static NSString* const QUEUE_TUTORIAL_VIEWCONTROLLER_ID	= @"QueueTutorialViewControllerID";
static NSString* const QUEUE_TUTORIAL_VC_STORYBOARD		= @"MainStoryboard";

@implementation QueueTutorialViewController

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

+ (id) queueTutorialViewController
{		
	UIStoryboard* storyBoard = [UIStoryboard storyboardWithName:QUEUE_TUTORIAL_VC_STORYBOARD bundle:nil];
    
	QueueTutorialViewController*   tutorialViewController = [storyBoard instantiateViewControllerWithIdentifier:QUEUE_TUTORIAL_VIEWCONTROLLER_ID];
    
    tutorialViewController.view.backgroundColor = [OhmAppearance defaultTableViewBackgroundColor];
    
	return tutorialViewController;
}

@end
