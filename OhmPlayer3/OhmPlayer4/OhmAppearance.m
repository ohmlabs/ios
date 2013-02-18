//
//  OhmAppearance.m
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import "OhmAppearance.h"

#import "AppleSampleCode.h"

@implementation OhmAppearance

+ (NSString*) defaultFontName
{
	return @"Helvetica Neue";
}

#pragma mark Metrics

+ (CGFloat) characterIndexFontSize
{
	return 12.0F;
}

+ (CGFloat) artistCellFontSize
{
	return 32.0F;
}

#pragma mark Colors

+ (UIColor*) defaultViewControllerBackgroundColor
{
	// Gray.
	const CGFloat ComponentValue = 200.0F/255.0F;
	
	return [UIColor colorWithRed:ComponentValue green:ComponentValue blue:ComponentValue alpha:1.0F];
}

+ (UIColor*) defaultTableViewBackgroundColor
{
	return [OhmAppearance defaultViewControllerBackgroundColor];
}

+ (UIColor*) playlistTableViewBackgroundColor
{
	return [OhmAppearance defaultTableViewBackgroundColor];
}

+ (UIColor*) nowPlayingViewControllerBackgroundColor
{
	// Light gray.
	const CGFloat ComponentValue = 228.0F/255.0F;
	
	return [UIColor colorWithRed:ComponentValue green:ComponentValue blue:ComponentValue alpha:1.0F];
}

+ (UIColor*) windowBackgroundColor
{
	return [UIColor whiteColor];
}

+ (UIColor*) navigationBarTintColor
{
	return [UIColor clearColor];
}

+ (UIColor*) characterIndexTextColor
{
	return [UIColor lightTextColor];
}

+ (UIColor*) characterIndexBackgroundColor
{
	return [UIColor clearColor];
}

+ (UIColor*) queuedSongTableViewTextColor
{
	return [UIColor darkGrayColor];
}

+ (UIColor*) songTableViewTextColor
{
	return [UIColor darkTextColor];
}

+ (UIColor*) songTableViewBackgroundColor
{
	return nil;
}

+ (UIColor*) songTableViewCellBackgroundColor
{
	return [OhmAppearance defaultTableViewBackgroundColor];
}

+ (UIColor*) artistCellTextColor
{
	return [UIColor whiteColor];
}

+ (UIColor*) artistCellBackgroundColor
{
	return [UIColor clearColor];
}

#pragma mark Fonts

+ (UIFont*) defaultFontOfSize:(const CGFloat)size
{
	return [UIFont fontWithName:[OhmAppearance defaultFontName] size:size];
}

+ (UIFont*) characterIndexFont
{
	return [UIFont systemFontOfSize:[OhmAppearance characterIndexFontSize]];
}

+ (UIFont*) artistCellFont
{
	return [UIFont fontWithName:[OhmAppearance defaultFontName] size:[OhmAppearance artistCellFontSize]];
}

#pragma mark Text Attributes

+ (NSDictionary*) defaultNavBarTextAttributes
{
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	
	UIFont* navBarFont = [OhmAppearance defaultFontOfSize:23.0F];
	
	UIColor* navBarTextColor = [UIColor whiteColor];
	
	[dict setValue:navBarFont forKey:UITextAttributeFont];
	[dict setValue:navBarTextColor forKey:UITextAttributeTextColor];
	
	return dict;
}

#pragma mark Styles

+ (UIStatusBarStyle) defaultStatusBarStyle
{

	return UIStatusBarStyleBlackOpaque;

}

+ (UIStatusBarStyle) nowPlayingStatusBarStyle
{

	return UIStatusBarStyleBlackOpaque;

}

#pragma mark Text Values

+ (NSString*) defaultSongTitle
{
    return NSLocalizedString(@"Untitled", @"Untitled");
}

+ (NSString*) defaultAlbumTitle
{
    return NSLocalizedString(@"Unknown album", @"Unknown album");
}

+ (NSString*) defaultArtistName
{
    return NSLocalizedString(@"Unknown artist", @"Unknown artist");
}

#pragma mark Reflection Support

+ (UIImage*) reflectedImageFromUIImageView:(UIImageView*)imageView withHeight:(NSUInteger)height
{
    return [AppleSampleCode reflectedImage:imageView withHeight:height];
}

@end
