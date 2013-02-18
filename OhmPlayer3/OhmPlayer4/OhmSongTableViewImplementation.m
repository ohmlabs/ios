// WARNING: This implementation is shared.

// NOTE: Objective-C does not support multiple inheritance. In order to reuse this code, it's #included
// into implementing classes. This file is only compiled indirectly.


#pragma mark Default Methods

- (void) handleSwipe:(UISwipeGestureRecognizer*)gestureRecognizer
{
	// Subclasses MAY override
	NSLog(@"Subclass MAY override - %@", gestureRecognizer);
}

- (void) handleLongPress:(UILongPressGestureRecognizer*)gestureRecognizer
{
	// Subclasses MAY override
	NSLog(@"Subclass MAY override - %@", gestureRecognizer);
}

@dynamic tableView;

#pragma mark Protected Methods

- (void) installLongPressRecognizer
{
	UIGestureRecognizer* longPressRecongizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	
	if (longPressRecongizer) [[self tableView] addGestureRecognizer:longPressRecongizer];
}

- (void) installSwipeRecognizer
{	
	UISwipeGestureRecognizer* swipeRecongizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
	
	if (swipeRecongizer)
	{
		// By design, we allow swiping in either  horizontal direction.
		
		swipeRecongizer.direction = UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight;
		
		[[self tableView] addGestureRecognizer:swipeRecongizer];
	}
}

- (void) installGestureRecognizers
{
	[self installLongPressRecognizer];
	[self installSwipeRecognizer];
}

#pragma mark UITableViewController Methods

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self installGestureRecognizers];
}
