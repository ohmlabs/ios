//
//  NowPlayingViewController.h
//  OhmPlayer3
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NowPlayingTutorialViewController;

@interface NowPlayingViewController : UIViewController
{
	UIStatusBarStyle savedStatusBarStyle;
	UIColor* savedNavigationBarColor;

	NSTimer* playbackTimer;
}

@property (strong, nonatomic) IBOutlet UIView* volumeControlView;
@property (strong, nonatomic) IBOutlet UIView* airplayControllView;

@property (strong, nonatomic) IBOutlet UILabel* artistName;
@property (strong, nonatomic) IBOutlet UILabel* songTitle;
@property (strong, nonatomic) IBOutlet UILabel *timeRemaining;
@property (strong, nonatomic) IBOutlet UILabel *timeElapsed;
@property (strong, nonatomic) IBOutlet UILabel *songNumber;
@property (strong, nonatomic) IBOutlet UISlider *playbackTimeSlider;
@property (strong, nonatomic) IBOutlet UIButton *shuffleButton;

@property (strong, nonatomic) IBOutlet UIView* albumArtView;
@property (strong, nonatomic) IBOutlet UIView* addToQueueControl;
@property (strong, nonatomic) IBOutlet UIView* popUpPlayerControls;

@property (strong, nonatomic) IBOutlet UIGestureRecognizer* singleTapRecognizer;
@property (strong, nonatomic) IBOutlet UIGestureRecognizer* doubleTapRecognizer;

@property (strong, nonatomic) NowPlayingTutorialViewController* tutorialController;

- (IBAction)skipToPreviousItem;
- (IBAction)play;
- (IBAction)skipToNextItem;
- (IBAction)sliderDidChange:(UISlider*)sender;
- (IBAction)compose:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)togglePlayerControls:(id)sender;
- (IBAction)toggleMusicPlaying:(id)sender;
- (IBAction)addToQueue:(id)sender;
- (IBAction) shuffleAll;
- (IBAction)shuffleRoulette:(id)sender;

@end
