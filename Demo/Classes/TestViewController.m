//
//  TestViewController.m
//  fStats
//
//  Created by Shawn Veader on 9/18/10.
//  Copyright 2010 V8 Labs, LLC. All rights reserved.
//

#import "TestViewController.h"
#import <QuartzCore/QuartzCore.h>
#include <stdlib.h>
#include "math.h"

@interface TestElementView : UIView <V8HorizontalPickerElementView>

@property (nonatomic, strong) UILabel *label;

- (id) initWithFrame:(CGRect) aFrame 
               title:(NSString *) aTitle 
        needsLeftBar:(BOOL) aNeedsLeftBar;
     
- (CGFloat) width;

@end

@implementation TestElementView

@synthesize label;

- (id) initWithFrame:(CGRect) aFrame 
               title:(NSString *) aTitle 
        needsLeftBar:(BOOL) aNeedsLeftBar {
  self = [super initWithFrame:aFrame];
  if (self) {  

    CGSize size = [aTitle sizeWithFont:[UIFont systemFontOfSize:18]];
    self.frame = CGRectMake(aFrame.origin.x, aFrame.origin.y, size.width + 20, aFrame.size.height);
    CGFloat x = (size.width + 20)/2 - (size.width/2);
    CGFloat y = (aFrame.size.height/2) - (size.height/2);
    CGRect frame = CGRectMake(x, y, size.width, size.height);
    self.label = [[UILabel alloc] initWithFrame:frame];
    self.label.text = aTitle;
    self.label.textAlignment = UITextAlignmentCenter;
    self.label.textColor = [UIColor blueColor];
    self.label.highlightedTextColor = [UIColor orangeColor];
    self.label.font = [UIFont systemFontOfSize:18];
    self.label.highlighted = NO;
    self.label.backgroundColor = [UIColor clearColor];
    [self addSubview:self.label];
    
    if (aNeedsLeftBar == YES) {
      UIView *left = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 4, aFrame.size.height)];
      left.backgroundColor = [UIColor blueColor];
      [self addSubview:left];
    }
    
    UIView *right = [[UIView alloc] initWithFrame:CGRectMake(size.width + 16, 0, 4, aFrame.size.height)];
    right.backgroundColor = [UIColor blueColor];
    [self addSubview:right];
    
  }
  return self;
}

- (void) setSelectedState:(BOOL)aSelected {
  self.label.highlighted = aSelected;
}

- (CGFloat) width {
  return self.frame.size.width;
}

@end

@interface TestElementPickerDelegate : NSObject 
<V8HorizontalPickerViewDataSource, V8HorizontalPickerViewDelegate>

@property (nonatomic, strong) NSArray *titleArray;
@property (nonatomic, strong) NSArray *views;

@end

@implementation TestElementPickerDelegate

@synthesize titleArray;
@synthesize views;

- (id) init {
  self = [super init];
  if (self) {
    self.titleArray = [NSArray arrayWithObjects:@"All", @"Today", @"Thursday", @"Wednesday", @"Tuesday", @"Monday", nil];
    __block NSUInteger count = [self.titleArray count];
    __block NSMutableArray *marray = [NSMutableArray arrayWithCapacity:count];
    [self.titleArray enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
      CGRect frame = CGRectMake(2, 2, -1, 50);
      BOOL needsLeft = idx == 0;
      TestElementView *view = [[TestElementView alloc] initWithFrame:frame
                                                               title:title
                                                        needsLeftBar:needsLeft];
                                                       
      
      [marray addObject:view];
    }];
    self.views = [NSArray arrayWithArray:marray];
  }
  return self;
}

- (NSUInteger) numberOfElementsInPickerView:(V8HorizontalPickerView *)aPicker {
  return [self.titleArray count];
}



- (CGFloat) pickerView:(V8HorizontalPickerView *)picker widthForIndex:(NSUInteger) aIndex {
  TestElementView *view = (TestElementView *)[self.views objectAtIndex:aIndex];
  return [view width];
}

- (UIView <V8HorizontalPickerElementView> *) pickerView:(V8HorizontalPickerView *)aPicker 
                                          viewForIndex:(NSUInteger)aIndex {
  return [self.views objectAtIndex:aIndex];
}

@end

@interface TestViewController ()
// required because we need to retain this delegate (in ARC there is explicit retaining)
@property (nonatomic, strong) TestElementPickerDelegate *tepd;
@property (nonatomic, strong) V8HorizontalPickerView *pv2;

- (void) buttonTouchedScrollPv2:(id) sender;
@end


@implementation TestViewController

@synthesize pickerView;
@synthesize nextButton, reloadButton;
@synthesize infoLabel;
@synthesize tepd;
@synthesize pv2;

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
	pickerView.elementFont = [UIFont boldSystemFontOfSize:16.0f];
	pickerView.selectionX = 120;
	// add carat or other view to indicate selected element
	UIImageView *indicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"indicator"]];
	pickerView.selectionIndicatorView = indicator;
  pickerView.leftEdgeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"left_fade"]];
  pickerView.rightEdgeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"right_fade"]];
	[self.view addSubview:pickerView];
  [pickerView scrollToIndex:3 animated:NO];
  
  
  tmpFrame = CGRectMake(0, 0, 320, 50);
  V8HorizontalPickerView *pv = [[V8HorizontalPickerView alloc] initWithFrame:tmpFrame];
  pv.backgroundColor   = [UIColor darkGrayColor];
	pv.delegate    = self;
	pv.dataSource  = self;
	pv.elementFont = [UIFont boldSystemFontOfSize:16.0f];

  indicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"indicator"]];
	pv.selectionIndicatorView = indicator;
  pv.indicatorPosition = V8HorizontalPickerIndicatorBottom;
  pv.selectionX = 180;
  pv.leftScrollEdgeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"loopback"]];
  pv.rightScrollEdgeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"airplane"]];
  [self.view addSubview:pv];
  [pv scrollToIndex:4 animated:NO];
  
  tmpFrame = CGRectMake(0, 60, 320, 54);
  self.pv2 = [[V8HorizontalPickerView alloc] initWithFrame:tmpFrame];
  pv2.backgroundColor   = [UIColor lightGrayColor];
  self.tepd = [[TestElementPickerDelegate alloc] init];
	pv2.delegate    = tepd;
	pv2.dataSource  = tepd;
	pv2.selectionIndicatorView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"indicator"]];
  pv2.indicatorPosition = V8HorizontalPickerIndicatorBottom;
  pv2.selectionX = 160;
  pv2.scrollEdgeViewPadding = 80;
  pv2.leftScrollEdgeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"loopback"]];
  pv2.rightScrollEdgeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"airplane"]];
  NSLog(@"selected index: %d", pv2.selectedIndex);
  [self.view addSubview:pv2];

  UIButton *scrollButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 400, 80, 50)];
  [scrollButton setTitle:@"scroll pv2" forState:UIControlStateNormal];
  scrollButton.titleLabel.font = [UIFont systemFontOfSize:12];
  scrollButton.backgroundColor = [UIColor whiteColor];
  [scrollButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [scrollButton addTarget:self action:@selector(buttonTouchedScrollPv2:) 
         forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:scrollButton];
  
  
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
//	[pickerView scrollToIndex:0 animated:NO];
//[self.pv2 scrollToIndex:4 animated:YES];
  [self.pv2 scrollToIndex:4 animated:NO];
  [self.pv2 scrollToIndex:4 animated:NO];
  
  NSLog(@"selected index: %d", pv2.selectedIndex);
}

- (void) buttonTouchedScrollPv2:(id)sender {
  static const float ARC4RANDOM_MAX = 0x100000000;
  NSUInteger min = 0;
  NSUInteger max = [self.tepd numberOfElementsInPickerView:self.pv2] - 1;
  NSUInteger index = ((max - min + 1) * (arc4random() / ARC4RANDOM_MAX)) + min;
  NSLog(@"index = %d", index);
  [self.pv2 scrollToIndex:index animated:YES];
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
	[pickerView scrollToIndex:indexCount animated:NO];
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
- (NSUInteger) numberOfElementsInPickerView:(V8HorizontalPickerView *)picker {
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
