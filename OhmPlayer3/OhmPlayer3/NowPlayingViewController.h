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

@property (weak, nonatomic) IBOutlet UIView* volumeControlView;
@property (weak, nonatomic) IBOutlet UIView* airplayControllView;

@property (weak, nonatomic) IBOutlet UILabel* artistName;
@property (weak, nonatomic) IBOutlet UILabel* songTitle;
@property (weak, nonatomic) IBOutlet UILabel *timeRemaining;
@property (weak, nonatomic) IBOutlet UILabel *timeElapsed;
@property (weak, nonatomic) IBOutlet UILabel *songNumber;
@property (weak, nonatomic) IBOutlet UISlider *playbackTimeSlider;
@property (weak, nonatomic) IBOutlet UIButton *shuffleButton;

@property (weak, nonatomic) IBOutlet UIView* albumArtView;
@property (weak, nonatomic) IBOutlet UIView* addToQueueControl;
@property (weak, nonatomic) IBOutlet UIView* popUpPlayerControls;

@property (weak, nonatomic) IBOutlet UIGestureRecognizer* singleTapRecognizer;
@property (weak, nonatomic) IBOutlet UIGestureRecognizer* doubleTapRecognizer;

@property (strong, nonatomic) NowPlayingTutorialViewController* tutorialController;

- (IBAction)skipToPreviousItem;
- (IBAction)play;
- (IBAction)skipToNextItem;
- (IBAction)sliderDidChange:(id)sender;
- (IBAction)compose:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)togglePlayerControls:(id)sender;
- (IBAction)toggleMusicPlaying:(id)sender;
- (IBAction)addToQueue:(id)sender;
- (IBAction) shuffleAll;
- (IBAction)shuffleRoulette:(id)sender;

@end
