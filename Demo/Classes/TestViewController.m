//
//  TestViewController.m
//  fStats
//
//  Created by Shawn Veader on 9/18/10.
//  Copyright 2010 V8 Labs, LLC. All rights reserved.
//

#import "TestViewController.h"


@implementation TestViewController

@synthesize pickerView;
@synthesize nextButton, reloadButton;
@synthesize infoLabel;

#pragma mark - iVars
NSMutableArray *titleArray;
int indexCount;

#pragma mark - Init/Dealloc
- (id)init {
	self = [super init];
	if (self) {
		titleArray = [NSMutableArray arrayWithObjects:@"All", @"Today", @"Thursday", @"Wednesday", @"Tuesday", @"Monday", nil];
		indexCount = 0;
	}
	return self;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark - View Management Methods
- (void)viewDidLoad {
	[super viewDidLoad];

	self.view.backgroundColor = [UIColor blackColor];
	CGFloat margin = 40.0f;
	CGFloat width = (self.view.bounds.size.width - (margin * 2.0f));
	CGFloat pickerHeight = 40.0f;
	CGFloat x = margin;
	CGFloat y = 150.0f;
	CGFloat spacing = 25.0f;
	CGRect tmpFrame = CGRectMake(x, y, width, pickerHeight);

//	CGFloat width = 200.0f;
//	CGFloat x = (self.view.frame.size.width - width) / 2.0f;
//	CGRect tmpFrame = CGRectMake(x, 150.0f, width, 40.0f);

	pickerView = [[V8HorizontalPickerView alloc] initWithFrame:tmpFrame];
  [pickerView setTitleColor:[UIColor blueColor] forSelectionState:V8HorizontalPickerSelectionStateSelected];
  [pickerView setTitleColor:[UIColor greenColor] forSelectionState:V8HorizontalPickerSelectionStateUnselected];

	pickerView.backgroundColor   = [UIColor darkGrayColor];
  
   
	pickerView.delegate    = self;
	pickerView.dataSource  = self;
	pickerView.elementFont = [UIFont boldSystemFontOfSize:14.0f];
	pickerView.selectionX = 120;

	// add carat or other view to indicate selected element
	UIImageView *indicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"indicator"]];
	pickerView.selectionIndicatorView = indicator;
  pickerView.leftEdgeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"left_fade"]];
  pickerView.rightEdgeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"right_fade"]];

  
  
  tmpFrame = CGRectMake(0, 0, 320, 50);
  V8HorizontalPickerView *pv = [[V8HorizontalPickerView alloc] initWithFrame:tmpFrame];
  pv.backgroundColor   = [UIColor darkGrayColor];
	pv.delegate    = self;
	pv.dataSource  = self;
	pv.elementFont = [UIFont boldSystemFontOfSize:16.0f];
//  pv.selectionPoint = CGPointMake(60, 0);
  [self.view addSubview:pv];
  
  indicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"indicator"]];
	pv.selectionIndicatorView = indicator;
  pv.indicatorPosition = V8HorizontalPickerIndicatorBottom;
  pv.selectionX = 180;
//  [pv setTitleColor:[UIColor blueColor] forSelectionState:V8HorizontalPickerSelectionStateSelected];
//  [pv setTitleColor:[UIColor greenColor] forSelectionState:V8HorizontalPickerSelectionStateUnselected];

  
//	pickerView.indicatorPosition = V8HorizontalPickerIndicatorTop; // specify indicator's location

	// add gradient images to left and right of view if desired

	// add image to left of scroll area
  
  pv.leftScrollEdgeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"loopback"]];
  pv.rightScrollEdgeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"airplane"]];
  

	[self.view addSubview:pickerView];

	self.nextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	y = y + tmpFrame.size.height + spacing;
	tmpFrame = CGRectMake(x, y, width, 50.0f);
	nextButton.frame = tmpFrame;
	[nextButton addTarget:self action:@selector(nextButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	[nextButton	setTitle:@"Center Element 0" forState:UIControlStateNormal];
	nextButton.titleLabel.textColor = [UIColor blackColor];
	[self.view addSubview:nextButton];

	self.reloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	y = y + tmpFrame.size.height + spacing;
	tmpFrame = CGRectMake(x, y, width, 50.0f);
	reloadButton.frame = tmpFrame;
	[reloadButton addTarget:self action:@selector(reloadButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	[reloadButton setTitle:@"Reload Data" forState:UIControlStateNormal];
	[self.view addSubview:reloadButton];

	y = y + tmpFrame.size.height + spacing;
	tmpFrame = CGRectMake(x, y, width, 50.0f);
	infoLabel = [[UILabel alloc] initWithFrame:tmpFrame];
	infoLabel.backgroundColor = [UIColor blackColor];
	infoLabel.textColor = [UIColor whiteColor];
	infoLabel.textAlignment = UITextAlignmentCenter;
	[self.view addSubview:infoLabel];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	self.pickerView = nil;
	self.nextButton = nil;
	self.infoLabel  = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[pickerView scrollToElement:0 animated:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}



- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	CGFloat margin = 40.0f;
	CGFloat width = (self.view.bounds.size.width - (margin * 2.0f));
	CGFloat x = margin;
	CGFloat y = 0.0f;
	CGFloat height = 40.0f;
	CGFloat spacing = 25.0f;
	CGRect tmpFrame;
	if (fromInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
		fromInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
		y = 150.0f;
		spacing = 25.0f;
		tmpFrame = CGRectMake(x, y, width, height);
	} else {
		y = 50.0f;
		spacing = 10.0f;
		tmpFrame = CGRectMake(x, y, width, height);
	}
	pickerView.frame = tmpFrame;
	
	y = y + tmpFrame.size.height + spacing;
	tmpFrame = nextButton.frame;
	tmpFrame.origin.y = y;
	nextButton.frame = tmpFrame;
	
	y = y + tmpFrame.size.height + spacing;
	tmpFrame = reloadButton.frame;
	tmpFrame.origin.y = y;
	reloadButton.frame = tmpFrame;
	
	y = y + tmpFrame.size.height + spacing;
	tmpFrame = infoLabel.frame;
	tmpFrame.origin.y = y;
	infoLabel.frame = tmpFrame;

}

#pragma mark - Button Tap Handlers
- (void)nextButtonTapped:(id)sender {
	[pickerView scrollToElement:indexCount animated:NO];
	indexCount += 1;
	if ([titleArray count] <= indexCount) {
		indexCount = 0;
	}
	[nextButton	setTitle:[NSString stringWithFormat:@"Center Element %d", indexCount]
				forState:UIControlStateNormal];
}

- (void)reloadButtonTapped:(id)sender {
	// change our title array so we can see a change
	if ([titleArray count] > 1) {
		[titleArray removeLastObject];
	}

	[pickerView reloadData];
}

#pragma mark - HorizontalPickerView DataSource Methods
- (NSInteger)numberOfElementsInPickerView:(V8HorizontalPickerView *)picker {
	return [titleArray count];
}

#pragma mark - HorizontalPickerView Delegate Methods
- (NSString *) pickerView:(V8HorizontalPickerView *)aPicker titleForIndex:(NSUInteger)aIndex {
	return [titleArray objectAtIndex:aIndex];
}

- (CGFloat) pickerView:(V8HorizontalPickerView *)picker widthForIndex:(NSUInteger) aIndex {
	CGSize constrainedSize = CGSizeMake(MAXFLOAT, MAXFLOAT);
	NSString *text = [titleArray objectAtIndex:aIndex];
	CGSize textSize = [text sizeWithFont:[UIFont boldSystemFontOfSize:16.0f]
					   constrainedToSize:constrainedSize
						   lineBreakMode:UILineBreakModeWordWrap];
	return textSize.width + 40.0f; // 20px padding on each side
}

- (void) pickerView:(V8HorizontalPickerView *)aPicker didSelectIndex:(NSUInteger)aIndex {
  self.infoLabel.text = [NSString stringWithFormat:@"Selected index %d", aIndex];
}

@end
