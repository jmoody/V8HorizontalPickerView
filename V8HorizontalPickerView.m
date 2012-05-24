#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#if !(__IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_4_3)
#warning This file contains features that are only available for iOS 4.3 or higher
#endif

//
//  V8HorizontalPickerView.m
//
//  Created by Shawn Veader on 9/17/10.
//  Copyright 2010 V8 Labs, LLC. All rights reserved.
//


#import "V8HorizontalPickerView.h"

// sub-class of UILabel that knows how to change it's state
@interface V8HorizontalPickerLabel : UILabel <V8HorizontalPickerElementState> { }

@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, strong) UIColor *selectedStateColor;
@property (nonatomic, strong) UIColor *normalStateColor;

@end

#pragma mark - Picker Label Implementation

@implementation V8HorizontalPickerLabel : UILabel

@synthesize isSelected, selectedStateColor, normalStateColor;


- (void) setSelectedState:(BOOL) aSelected {
	if (self.isSelected != aSelected) {
		if (aSelected == YES) {
			self.textColor = self.selectedStateColor;
		} else {
			self.textColor = self.normalStateColor;
		}
		self.isSelected = aSelected;
		[self setNeedsLayout];
	}
}

// whoa - possibly unnecessary
- (void) setNormalStateColor:(UIColor *) aColor {
	if (self.normalStateColor != aColor) {
		normalStateColor = aColor;
		self.textColor = aColor;
		[self setNeedsLayout];
	}
}

@end


#pragma mark - Internal Method Interface
@interface V8HorizontalPickerView ()

#pragma mark - iVars
@property (nonatomic, strong) UIScrollView *scrollView;

// collection of widths of each element.
@property (nonatomic, strong) NSArray *elementWidths;
@property (nonatomic, assign) CGFloat elementPadding;

// state keepers
@property (nonatomic, assign) BOOL dataHasBeenLoaded;
@property (nonatomic, assign) BOOL scrollSizeHasBeenSet;
@property (nonatomic, assign) BOOL scrollingBasedOnUserInteraction;

// keep track of which elements are visible for tiling
@property (nonatomic, assign) NSInteger firstVisibleElement;
@property (nonatomic, assign) NSInteger lastVisibleElement;

@property (nonatomic, assign) NSInteger currentSelectedIndex_Internal;


- (void) setTotalWidthOfScrollContent;
- (void) updateScrollContentInset;

- (void) configureScrollView;
- (void) drawPositionIndicator;
- (V8HorizontalPickerLabel *) labelForForElementAtIndex:(NSUInteger) aIndex withTitle:(NSString *) aTitle;
- (CGRect) frameForElementAtIndex:(NSUInteger) aIndex;

- (CGRect) frameForLeftScrollEdgeView;
- (CGRect) frameForRightScrollEdgeView;
- (CGFloat) leftScrollEdgeWidth;
- (CGFloat) rightScrollEdgeWidth;

- (CGPoint) currentCenter;
- (void) scrollToElementNearestToCenter;
- (NSUInteger) nearestElementToCenter;
- (NSUInteger) indexOfNearestElementToPoint:(CGPoint) point;
- (NSUInteger) elementContainingPoint:(CGPoint) point;

- (CGFloat) offsetForElementAtIndex:(NSUInteger) index;
- (CGFloat) centerOfElementAtIndex:(NSUInteger) index;

- (void) scrollViewTapped:(UITapGestureRecognizer *) recognizer;

- (NSUInteger) tagForElementAtIndex:(NSUInteger) index;
- (NSUInteger) indexForElement:(UIView *) element;
@end


#pragma mark - Implementation
@implementation V8HorizontalPickerView : UIView

@synthesize dataSource, delegate;
@synthesize numberOfElements;
@synthesize currentSelectedIndex;
@synthesize elementFont, textColor, selectedTextColor;
@synthesize selectionPoint, selectionIndicatorView, indicatorPosition;
@synthesize leftEdgeView, rightEdgeView;
@synthesize leftScrollEdgeView, rightScrollEdgeView, scrollEdgeViewPadding;

@synthesize scrollView;
@synthesize elementWidths;
@synthesize elementPadding;
@synthesize dataHasBeenLoaded;
@synthesize scrollSizeHasBeenSet;
@synthesize scrollingBasedOnUserInteraction;
@synthesize firstVisibleElement;
@synthesize lastVisibleElement;
@synthesize currentSelectedIndex_Internal;

#pragma mark - Init/Dealloc
- (id) initWithFrame:(CGRect) frame {
	self = [super initWithFrame:frame];
  if (self) {
		self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    [self configureScrollView];
    [self addSubview:self.scrollView];
    
    //self.elementWidths = [NSMutableArray array];
		self.textColor   = [UIColor blackColor];
		self.elementFont = [UIFont systemFontOfSize:14.0];

    // nothing is selected yet
		self.currentSelectedIndex_Internal = -1; 
		
    self.elementPadding       = 0;
//		self.dataHasBeenLoaded    = NO;
		self.scrollSizeHasBeenSet = NO;
		self.scrollingBasedOnUserInteraction = NO;

		// default to the center
		self.selectionPoint = CGPointMake(frame.size.width / 2, 0.0);
		self.indicatorPosition = V8HorizontalPickerIndicatorBottom;
    
    // possible problem
		self.firstVisibleElement = -1;
		self.lastVisibleElement  = -1;

		self.scrollEdgeViewPadding = 0.0;

		self.autoresizesSubviews = YES;
    elementWidths = nil;
	}
	return self;
}

- (NSUInteger) numberOfElements {
  NSUInteger result = 0;
  SEL dataSourceCall = @selector(numberOfElementsInHorizontalPickerView:);
	if (self.dataSource && [self.dataSource respondsToSelector:dataSourceCall]) {
		result = [self.dataSource numberOfElementsInHorizontalPickerView:self];
	} 
//  NSLog(@"number of elements = %d", result);
  return result;
}

- (NSUInteger) currentSelectedIndex {
  return currentSelectedIndex == -1 ? NSNotFound : self.currentSelectedIndex_Internal;
}

- (NSArray *) elementWidths {
  if (elementWidths == nil) {
    NSUInteger numElements = self.numberOfElements;
    SEL delegateCall = @selector(horizontalPickerView:widthForElementAtIndex:);
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:numElements];
    for (NSUInteger index = 0; index < numElements; index++) {
      if (self.delegate && [self.delegate respondsToSelector:delegateCall]) {
        CGFloat width = [self.delegate horizontalPickerView:self widthForElementAtIndex:index];
        [array addObject:[NSNumber numberWithDouble:width]];
      }
    }
    elementWidths = [NSArray arrayWithArray:array];
  }
  return elementWidths;
}

#pragma mark - LayoutSubViews

- (void) layoutSubviews {
	[super layoutSubviews];
  BOOL adjustWhenFinished = NO;

  if (self.scrollSizeHasBeenSet == NO) {
		adjustWhenFinished = YES;
		[self updateScrollContentInset];
		[self setTotalWidthOfScrollContent];
  }

	SEL titleForElementSelector = @selector(horizontalPickerView:titleForElementAtIndex:);
	SEL viewForElementSelector  = @selector(horizontalPickerView:viewForElementAtIndex:);
	SEL setSelectedSelector     = @selector(setSelectedElement:);

	CGRect visibleBounds   = [self bounds];
	CGRect scaledViewFrame = CGRectZero;

	// remove any subviews that are no longer visible
	for (UIView *view in [self.scrollView subviews]) {
		scaledViewFrame = [self.scrollView convertRect:[view frame] toView:self];

		// if the view doesn't intersect, it's not visible, so we can recycle it
		if (!CGRectIntersectsRect(scaledViewFrame, visibleBounds)) {
			[view removeFromSuperview];
		} else { // if it is still visible, update it's selected state
			if ([view respondsToSelector:setSelectedSelector]) {
				// view's tag is it's index
				BOOL isSelected = (self.currentSelectedIndex_Internal == [self indexForElement:view]);
				if (isSelected == YES) {
					// if this view is set to be selected, make sure it is over the selection point
					NSUInteger currentIndex = [self nearestElementToCenter];
					isSelected = (currentIndex == self.currentSelectedIndex_Internal);
				}
				// casting to V8HorizontalPickerLabel so we can call this without all the NSInvocation jazz
				[(V8HorizontalPickerLabel *)view setSelectedState:isSelected];
			}
		}
	}

	// find needed elements by looking at left and right edges of frame
	CGPoint offset = self.scrollView.contentOffset;
	NSUInteger firstNeededElement = [self indexOfNearestElementToPoint:CGPointMake(offset.x, 0.0f)];
	NSUInteger lastNeededElement  = [self indexOfNearestElementToPoint:CGPointMake(offset.x + visibleBounds.size.width, 0.0f)];

	// add any views that have become visible
	UIView *view = nil;
	for (NSUInteger index = firstNeededElement; index <= lastNeededElement; index++) {
		view = nil; // paranoia
		view = [self.scrollView viewWithTag:[self tagForElementAtIndex:index]];
		if (!view) {
			if (index < self.numberOfElements) { 
        // make sure we are not requesting data out of range
				if (self.delegate && [self.delegate respondsToSelector:titleForElementSelector]) {
					NSString *title = [self.delegate horizontalPickerView:self titleForElementAtIndex:index];
					view = [self labelForForElementAtIndex:index withTitle:title];
				} else if (self.delegate && [self.delegate respondsToSelector:viewForElementSelector]) {
					view = [self.delegate horizontalPickerView:self viewForElementAtIndex:index];
				}

				if (view != nil) {
					// use the index as the tag so we can find it later
					view.tag = [self tagForElementAtIndex:index];
					[self.scrollView addSubview:view];
				}
			}
		}
	}

	// add the left or right edge views if visible
	CGRect viewFrame = CGRectZero;
	if (leftScrollEdgeView) {
		viewFrame = [self frameForLeftScrollEdgeView];
		scaledViewFrame = [self.scrollView convertRect:viewFrame toView:self];
		if (CGRectIntersectsRect(scaledViewFrame, visibleBounds) && 
        ![leftScrollEdgeView isDescendantOfView:self.scrollView]) {
			leftScrollEdgeView.frame = viewFrame;
			[self.scrollView addSubview:leftScrollEdgeView];
		}
	}
	if (rightScrollEdgeView) {
		viewFrame = [self frameForRightScrollEdgeView];
		scaledViewFrame = [self.scrollView convertRect:viewFrame toView:self];
		if (CGRectIntersectsRect(scaledViewFrame, visibleBounds) && 
        ![rightScrollEdgeView isDescendantOfView:self.scrollView]) {
			rightScrollEdgeView.frame = viewFrame;
			[self.scrollView addSubview:rightScrollEdgeView];
		}
	}

	// save off what's visible now
	firstVisibleElement = firstNeededElement;
	lastVisibleElement  = lastNeededElement;

	// determine if scroll view needs to shift in response to resizing?
  // possible problem
	if (self.currentSelectedIndex_Internal > -1 && 
      [self centerOfElementAtIndex:self.currentSelectedIndex_Internal] != [self currentCenter].x) {
		if (adjustWhenFinished) {
      [self scrollToElement:self.currentSelectedIndex_Internal animated:NO];
		} else if (self.numberOfElements <= self.currentSelectedIndex_Internal) {
			// if currentSelectedIndex no longer exists, select what is currently centered
			self.currentSelectedIndex_Internal = [self nearestElementToCenter];
			[self scrollToElement:self.currentSelectedIndex_Internal animated:NO];
		}
	}
}


#pragma mark - Getters and Setters

- (void) setSelectionPoint:(CGPoint) aPoint {
	if (!CGPointEqualToPoint(aPoint, self.selectionPoint)) {
		selectionPoint = aPoint;
		[self updateScrollContentInset];
	}
}

// possible problem
//// allow the setting of this views background color to change the scroll view
//- (void) setBackgroundColor:(UIColor *)newColor {
//  
//  [super setBackgroundColor:newColor];
//	self.scrollView.backgroundColor = newColor;
//	// TODO: set all subviews as well?
//}

- (void) setIndicatorPosition:(V8HorizontalPickerIndicatorPosition) aPosition {
	if (indicatorPosition != aPosition) {
		indicatorPosition = aPosition;
		[self drawPositionIndicator];
	}
}

- (void) setSelectionIndicatorView:(UIView *) aIndicatorView {
	if (selectionIndicatorView != aIndicatorView) {
		if (selectionIndicatorView) {
			[selectionIndicatorView removeFromSuperview];
		}
		selectionIndicatorView = aIndicatorView;
		[self drawPositionIndicator];
	}
}

- (void) setLeftEdgeView:(UIView *) aLeftView {
	if (leftEdgeView != aLeftView) {
		if (leftEdgeView) {
			[leftEdgeView removeFromSuperview];
		}
		leftEdgeView = aLeftView;

		CGRect tmpFrame = leftEdgeView.frame;
		tmpFrame.origin.x = 0.0f;
		tmpFrame.origin.y = 0.0f;
		leftEdgeView.frame = tmpFrame;
		[self addSubview:leftEdgeView];
	}
}

- (void) setRightEdgeView:(UIView *) aRightView {
	if (rightEdgeView != aRightView) {
		if (rightEdgeView) {
			[rightEdgeView removeFromSuperview];
		}
		rightEdgeView = aRightView;

		CGRect tmpFrame = rightEdgeView.frame;
		tmpFrame.origin.x = self.frame.size.width - tmpFrame.size.width;
		tmpFrame.origin.y = 0.0f;
		rightEdgeView.frame = tmpFrame;
		[self addSubview:rightEdgeView];
	}
}

- (void) setLeftScrollEdgeView:(UIView *) aLeftView {
	if (leftScrollEdgeView != aLeftView) {
		if (leftScrollEdgeView) {
			[leftScrollEdgeView removeFromSuperview];
		}
		leftScrollEdgeView = aLeftView;

		scrollSizeHasBeenSet = NO;
		[self setNeedsLayout];
	}
}

- (void) setRightScrollEdgeView:(UIView *) aRightView {
	if (rightScrollEdgeView != aRightView) {
		if (rightScrollEdgeView) {
			[rightScrollEdgeView removeFromSuperview];
		}
		rightScrollEdgeView = aRightView;

		scrollSizeHasBeenSet = NO;
		[self setNeedsLayout];
	}
}

- (void)setFrame:(CGRect)newFrame {
	if (!CGRectEqualToRect(self.frame, newFrame)) {
		// causes recalulation of offsets, etc based on new size
		scrollSizeHasBeenSet = NO;
	}
	[super setFrame:newFrame];
}

#pragma mark - Data Fetching Methods

- (void) reloadData {
  // nil out the array of widths
  elementWidths = nil;
	// remove all scrollview subviews and "recycle" them
	for (UIView *view in [self.scrollView subviews]) {
		[view removeFromSuperview];
	}

	self.firstVisibleElement = NSIntegerMax;
	self.lastVisibleElement  = NSIntegerMin;
  
  self.scrollSizeHasBeenSet = NO;
  [self setTotalWidthOfScrollContent];
	[self updateScrollContentInset];
  [self setNeedsLayout];
}


#pragma mark - Scroll To Element Method
- (void) scrollToElement:(NSUInteger) aIndex animated:(BOOL) animate {
	self.currentSelectedIndex_Internal = aIndex;
	CGFloat x = [self centerOfElementAtIndex:aIndex] - selectionPoint.x;
	[self.scrollView setContentOffset:CGPointMake(x, 0) animated:animate];

	// notify delegate of the selected index
	SEL delegateCall = @selector(horizontalPickerView:didSelectElementAtIndex:);
	if (self.delegate && [self.delegate respondsToSelector:delegateCall]) {
		[self.delegate horizontalPickerView:self didSelectElementAtIndex:aIndex];
	}
  [self setNeedsLayout];
}


#pragma mark - UIScrollViewDelegate Methods
- (void) scrollViewDidScroll:(UIScrollView *) aScrollView {
	if (self.scrollingBasedOnUserInteraction == YES) {
		// NOTE: sizing and/or changing orientation of control might cause scrolling
		//		 not initiated by user. do not update current selection in these
		//		 cases so that the view state is properly preserved.

		// set the current item under the center to "highlighted" or current
		self.currentSelectedIndex_Internal = [self nearestElementToCenter];
	}
	[self setNeedsLayout];
}

- (void) scrollViewWillBeginDragging:(UIScrollView *) aScrollView {
	self.scrollingBasedOnUserInteraction = YES;
}

- (void) scrollViewDidEndDragging:(UIScrollView *) aScrollView willDecelerate:(BOOL) aDecelerate {
	// only do this if we aren't decelerating
	if (aDecelerate == YES) {
		[self scrollToElementNearestToCenter];
	}
}

//- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView { }

- (void) scrollViewDidEndDecelerating:(UIScrollView *) aScrollView {
	[self scrollToElementNearestToCenter];
}

- (void) scrollViewDidEndScrollingAnimation:(UIScrollView *) aScrollView {
	self.scrollingBasedOnUserInteraction = NO;
}


#pragma mark - View Creation Methods (Internal Methods)
- (void) configureScrollView {
  self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
  self.scrollView.delegate = self;
  self.scrollView.scrollEnabled = YES;
  self.scrollView.scrollsToTop  = NO;
  self.scrollView.showsVerticalScrollIndicator   = NO;
  self.scrollView.showsHorizontalScrollIndicator = NO;
  self.scrollView.bouncesZoom  = NO;
  self.scrollView.alwaysBounceHorizontal = YES;
  self.scrollView.alwaysBounceVertical   = NO;
  // setting min/max the same disables zooming
  self.scrollView.minimumZoomScale = 1.0; 
  self.scrollView.maximumZoomScale = 1.0;
  self.scrollView.contentInset = UIEdgeInsetsZero;
  self.scrollView.decelerationRate = 0.1; //UIScrollViewDecelerationRateNormal;
  self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  self.scrollView.autoresizesSubviews = YES;
  
  UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] 
                                           initWithTarget:self 
                                           action:@selector(scrollViewTapped:)];
  [self.scrollView addGestureRecognizer:tapRecognizer];
}

- (void)drawPositionIndicator {
	CGRect indicatorFrame = self.selectionIndicatorView.frame;
	CGFloat x = self.selectionPoint.x - (indicatorFrame.size.width / 2);
	CGFloat y;

	switch (self.indicatorPosition) {
		case V8HorizontalPickerIndicatorTop: {
			y = 0.0f;
			break;
		}
		case V8HorizontalPickerIndicatorBottom: {
			y = self.frame.size.height - indicatorFrame.size.height;
			break;
		}
		default:
			break;
	}

	// properly place indicator image in view relative to selection point
	CGRect tmpFrame = CGRectMake(x, y, indicatorFrame.size.width, indicatorFrame.size.height);
	self.selectionIndicatorView.frame = tmpFrame;
	[self addSubview:self.selectionIndicatorView];
}

// create a UILabel for this element.
- (V8HorizontalPickerLabel *) labelForForElementAtIndex:(NSUInteger) aIndex withTitle:(NSString *) aTitle {
	CGRect labelFrame = [self frameForElementAtIndex:aIndex];
	V8HorizontalPickerLabel *elementLabel = [[V8HorizontalPickerLabel alloc] initWithFrame:labelFrame];

	elementLabel.textAlignment   = UITextAlignmentCenter;
	elementLabel.backgroundColor = self.backgroundColor;
	elementLabel.text            = aTitle;
	elementLabel.font            = self.elementFont;

	elementLabel.normalStateColor   = self.textColor;
	elementLabel.selectedStateColor = self.selectedTextColor;

	// show selected status if this element is the selected one and is currently over selectionPoint

	NSUInteger currentIndex = [self nearestElementToCenter];
  // ok this is weird ass shit
	elementLabel.isSelected = (self.currentSelectedIndex_Internal == aIndex) && (currentIndex == self.currentSelectedIndex_Internal);

	return elementLabel;
}


#pragma mark - Delegate Calling Method (Internal Method)
//- (NSArray *) askDelegateForElementWidths {
//  NSUInteger numElements = self.numberOfElements;
//	SEL delegateCall = @selector(horizontalPickerView:widthForElementAtIndex:);
//	NSMutableArray *array = [NSMutableArray arrayWithCapacity:numElements];
//  for (NSUInteger index = 0; index < numElements; index++) {
//		if (self.delegate && [self.delegate respondsToSelector:delegateCall]) {
//			CGFloat width = [self.delegate horizontalPickerView:self widthForElementAtIndex:index];
//			[array addObject:[NSNumber numberWithDouble:width]];
//    }
//	}
//  return [NSArray arrayWithArray:array];
//}


#pragma mark - View Calculation and Manipulation Methods (Internal Methods)
// what is the total width of the content area?
- (void) setTotalWidthOfScrollContent {
	NSUInteger totalWidth = 0;

	totalWidth += [self leftScrollEdgeWidth];
	totalWidth += [self rightScrollEdgeWidth];

	// sum the width of all elements
	for (NSNumber *width in self.elementWidths) {
		totalWidth += [width intValue];
		totalWidth += self.elementPadding;
	}
	// TODO: is this necessary?
	totalWidth -= self.elementPadding; // we add "one too many" in for loop

	if (self.scrollView) {
		// create our scroll view as wide as all the elements to be included
		self.scrollView.contentSize = CGSizeMake(totalWidth, self.bounds.size.height);
		self.scrollSizeHasBeenSet = YES;
	}
}

// reset the content inset of the scroll view based on centering first and last elements.
- (void) updateScrollContentInset {
	// update content inset if we have element widths
	if ([self.elementWidths count] != 0) {
		CGFloat scrollerWidth = self.scrollView.frame.size.width;

		CGFloat halfFirstWidth = 0.0f;
		CGFloat halfLastWidth  = 0.0f;
		if ( [self.elementWidths count] > 0 ) {
			halfFirstWidth = [[self.elementWidths objectAtIndex:0] doubleValue] / 2.0; 
			halfLastWidth  = [[self.elementWidths lastObject] doubleValue]      / 2.0;
		}

		// calculating the inset so that the bouncing on the ends happens more smooothly
		// - first inset is the distance from the left edge to the left edge of the
		//     first element when that element is centered under the selection point.
		//     - represented below as the # area
		// - last inset is the distance from the right edge to the right edge of
		//     the last element when that element is centered under the selection point.
		//     - represented below as the * area
		//
		//        Selection
		//  +---------|---------------+
		//  |####| Element |**********| << UIScrollView
		//  +-------------------------+
		CGFloat firstInset = self.selectionPoint.x - halfFirstWidth;
		firstInset -= [self leftScrollEdgeWidth];
		CGFloat lastInset  = (scrollerWidth - self.selectionPoint.x) - halfLastWidth;
		lastInset -= [self rightScrollEdgeWidth];

		self.scrollView.contentInset = UIEdgeInsetsMake(0, firstInset, 0, lastInset);
	}
}

// what is the left-most edge of the element at the given index?
- (CGFloat) offsetForElementAtIndex:(NSUInteger) aIndex {
	NSUInteger offset = 0;
	if (aIndex >= [self.elementWidths count]) {
		return 0;
	}

	offset += [self leftScrollEdgeWidth];

	for (int i = 0; i < aIndex && i < [self.elementWidths count]; i++) {
		offset += [[self.elementWidths objectAtIndex:i] intValue];
		offset += self.elementPadding;
	}
	return offset;
}

// return the tag for an element at a given index
- (NSUInteger) tagForElementAtIndex:(NSUInteger) aIndex {
	return (aIndex + 1) * 10;
}

// return the index given an element's tag
- (NSUInteger) indexForElement:(UIView *) aElement {
	return (aElement.tag / 10) - 1;
}

// what is the center of the element at the given index? 
- (CGFloat) centerOfElementAtIndex:(NSUInteger) aIndex {
	if (aIndex >= [self.elementWidths count]) {
		return 0;
	}

	CGFloat elementOffset = [self offsetForElementAtIndex:aIndex];
	CGFloat elementWidth  = [[self.elementWidths objectAtIndex:aIndex] doubleValue] / 2;
	return elementOffset + elementWidth;
}

// what is the frame for the element at the given index?
- (CGRect) frameForElementAtIndex:(NSUInteger) aIndex {
	CGFloat width = 0.0;
	if ([self.elementWidths count] > aIndex) {
		width = [[self.elementWidths objectAtIndex:aIndex] doubleValue];
	}
	return CGRectMake([self offsetForElementAtIndex:aIndex], 0.0, width, self.frame.size.height);
}

// what is the frame for the left scroll edge view?
- (CGRect) frameForLeftScrollEdgeView {
	if (leftScrollEdgeView != nil) {
		CGFloat scrollHeight = self.scrollView.contentSize.height;
		CGFloat viewHeight   = self.leftScrollEdgeView.frame.size.height;
		return CGRectMake(0.0f, 
                      ((scrollHeight / 2.0) - (viewHeight / 2.0)),
                      self.leftScrollEdgeView.frame.size.width,
                      viewHeight);
	} else {
		return CGRectZero;
	}
}

// what is the width of the left edge of the scroll area?
- (CGFloat) leftScrollEdgeWidth {
	if (self.leftScrollEdgeView != nil) {
		CGFloat width = self.leftScrollEdgeView.frame.size.width;
		width += self.scrollEdgeViewPadding;
		return width;
	}
	return 0.0f;
}

// what is the frame for the right scroll edge view?
- (CGRect) frameForRightScrollEdgeView {
	if (self.rightScrollEdgeView != nil) {
		CGFloat scrollWidth  = self.scrollView.contentSize.width;
		CGFloat scrollHeight = self.scrollView.contentSize.height;
		CGFloat viewWidth  = self.rightScrollEdgeView.frame.size.width;
		CGFloat viewHeight = self.rightScrollEdgeView.frame.size.height;
		return CGRectMake(scrollWidth - viewWidth, 
                      ((scrollHeight / 2.0) - (viewHeight / 2.0)),
                      viewWidth, 
                      viewHeight);
	} else {
		return CGRectZero;
	}
}

// what is the width of the right edge of the scroll area?
- (CGFloat) rightScrollEdgeWidth {
	if (self.rightScrollEdgeView != nil) {
		CGFloat width = self.rightScrollEdgeView.frame.size.width;
		width += self.scrollEdgeViewPadding;
		return width;
	}
	return 0.0;
}

// what is the "center", relative to the content offset and adjusted to selection point?
- (CGPoint) currentCenter {
	CGFloat x = self.scrollView.contentOffset.x + self.selectionPoint.x;
	return CGPointMake(x, 0.0);
}

// what is the element nearest to the center of the view?
- (NSUInteger) nearestElementToCenter {
	return [self indexOfNearestElementToPoint:[self currentCenter]];
}

// what is the element nearest to the given point?
- (NSUInteger) indexOfNearestElementToPoint:(CGPoint) aPoint {
	for (NSUInteger index = 0; index < self.numberOfElements; index++) {
		CGRect frame = [self frameForElementAtIndex:index];
		if (CGRectContainsPoint(frame, aPoint)) {
			return index;
		} else if (aPoint.x < frame.origin.x) {
			// if the center is before this element, go back to last one,
			//     unless we're at the beginning
			if (index > 0) {
				return index - 1;
			} else {
				return 0;
			}
			break;
		} else if (aPoint.x > frame.origin.y) {
			// if the center is past the last element, scroll to it
			if (index == self.numberOfElements - 1) {
				return index;
			}
		}
	}
	return 0;
}

// similar to nearestElementToPoint: however, this method does not look past beginning/end
- (NSUInteger) elementContainingPoint:(CGPoint) aPoint {
	for (NSUInteger index = 0; index < self.numberOfElements; index++) {
		CGRect frame = [self frameForElementAtIndex:index];
		if (CGRectContainsPoint(frame, aPoint)) {
			return index;
		}
	}
	return NSNotFound;
}

// move scroll view to position nearest element under the center
- (void) scrollToElementNearestToCenter {
	[self scrollToElement:[self nearestElementToCenter] animated:YES];
}


#pragma mark - Tap Gesture Recognizer Handler Method
// use the gesture recognizer to slide to element under tap
- (void) scrollViewTapped:(UITapGestureRecognizer *) aRecognizer {
	if (aRecognizer.state == UIGestureRecognizerStateRecognized) {
		CGPoint tapLocation    = [aRecognizer locationInView:self.scrollView];
		NSUInteger elementIndex = [self elementContainingPoint:tapLocation];
		if (elementIndex != NSNotFound) { // point not in element
			[self scrollToElement:elementIndex animated:YES];
		}
	}
}

@end
