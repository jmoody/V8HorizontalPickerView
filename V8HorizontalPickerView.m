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
@interface V8HorizontalPickerLabel : UILabel <V8HorizontalPickerElementView> { }

@end

#pragma mark - Picker Label Implementation

@implementation V8HorizontalPickerLabel : UILabel

- (void) setSelectedState:(BOOL) aSelected {
   self.highlighted = aSelected;
}

@end


@interface V8HorizontalPickerView ()

@property (nonatomic, strong) UIScrollView *scrollView;

// collection of widths of each element.
@property (nonatomic, strong) NSArray *elementWidths;

// state keepers
@property (nonatomic, assign) BOOL scrollSizeHasBeenSet;
@property (nonatomic, assign) BOOL scrollingBasedOnUserInteraction;

// keep track of which elements are visible for tiling
@property (nonatomic, assign) NSInteger firstVisibleElement;
@property (nonatomic, assign) NSInteger lastVisibleElement;

// distinct from the public read-only currentSelectedIndex
@property (nonatomic, assign) NSInteger currentSelectedIndex_Internal;

// color of labels used in picker
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *selectedTextColor;

- (void) updateWidthOfScrollContent;
- (void) updateScrollContentInset;

- (void) configureScrollView;
- (void) drawPositionIndicator;
- (V8HorizontalPickerLabel *) labelForForElementAtIndex:(NSUInteger) aIndex 
                                              withTitle:(NSString *) aTitle;
- (CGRect) frameForElementAtIndex:(NSUInteger) aIndex;

- (CGRect) frameForLeftScrollEdgeView;
- (CGRect) frameForRightScrollEdgeView;
- (CGFloat) leftScrollEdgeWidth;
- (CGFloat) rightScrollEdgeWidth;

- (CGPoint) currentCenter;
- (void) scrollToElementNearestToCenter;
- (NSUInteger) indexOfElementNearestToCenter;
- (NSUInteger) indexOfNearestElementToPoint:(CGPoint) point;
- (NSUInteger) indexOfElementContainingPoint:(CGPoint) point;

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
@synthesize selectedIndex;
@synthesize elementFont;
@synthesize textColor = _textColor;
@synthesize selectedTextColor = _selectedTextColor;
@synthesize selectionX = _selectionX;
@synthesize selectionIndicatorView = _selectionIndicatorView;
@synthesize indicatorPosition = _indicatorPosition;
@synthesize leftEdgeView, rightEdgeView;
@synthesize leftScrollEdgeView = _leftScrollEdgeView;
@synthesize rightScrollEdgeView = _rightScrollEdgeView;
@synthesize scrollEdgeViewPadding = _scrollEdgeViewPadding;

@synthesize scrollView;
@synthesize elementWidths = _elementWidths;
@synthesize scrollSizeHasBeenSet;
@synthesize scrollingBasedOnUserInteraction;
@synthesize firstVisibleElement;
@synthesize lastVisibleElement;
@synthesize currentSelectedIndex_Internal;

- (void) dealloc {
  self.delegate = nil;
  self.dataSource = nil;
}

#pragma mark - Init/Dealloc
- (id) initWithFrame:(CGRect) frame {
	self = [super initWithFrame:frame];
  if (self) {
    _elementWidths = nil;
		self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    [self configureScrollView];
    [self addSubview:self.scrollView];
    
		// nothing is selected yet
		self.currentSelectedIndex_Internal = -1; 
		
		self.scrollSizeHasBeenSet = NO;
		self.scrollingBasedOnUserInteraction = NO;

		// default to the center
		_selectionX = frame.size.width/2;
		self.indicatorPosition = V8HorizontalPickerIndicatorBottom;
    
//    self.firstVisibleElement = -1;
//		self.lastVisibleElement  = -1;

    self.firstVisibleElement = NSIntegerMax;
    self.lastVisibleElement  = NSIntegerMin;

		_scrollEdgeViewPadding = 0.0;
		self.autoresizesSubviews = YES;
    
    self.textColor = [UIColor blackColor];
    self.selectedTextColor = [UIColor whiteColor];

    
	}
	return self;
}

- (NSUInteger) numberOfElements {
  NSUInteger result = 0;
  SEL dataSourceCall = @selector(numberOfElementsInPickerView:);
	if (self.dataSource && [self.dataSource respondsToSelector:dataSourceCall]) {
		result = [self.dataSource numberOfElementsInPickerView:self];
	} 
  return result;
}

- (NSUInteger) selectedIndex {
  return self.currentSelectedIndex_Internal == -1 ? NSNotFound : self.currentSelectedIndex_Internal;
}

- (NSArray *) elementWidths {
  if (_elementWidths == nil) {
    NSUInteger numElements = self.numberOfElements;
    SEL delegateCall = @selector(pickerView:widthForIndex:);
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:numElements];
    for (NSUInteger index = 0; index < numElements; index++) {
      if (self.delegate && [self.delegate respondsToSelector:delegateCall]) {
        CGFloat width = [self.delegate pickerView:self widthForIndex:index];
        [array addObject:[NSNumber numberWithDouble:width]];
      }
    }
    _elementWidths = [NSArray arrayWithArray:array];
  }
  return _elementWidths;
}

- (void) setTitleColor:(UIColor *) aColor forSelectionState:(V8HorizontalPickerSelectionState) aState {
  BOOL requiresLayout = NO;
  switch (aState) {
    case V8HorizontalPickerSelectionStateSelected: {
      if (self.selectedTextColor != aColor) {
        self.selectedTextColor = aColor;
        requiresLayout = YES;
      }
      break;
    }
    case V8HorizontalPickerSelectionStateUnselected: {
      if (self.textColor != aColor) {
        self.textColor = aColor;
        requiresLayout = YES;
      }
      break;
    }

    default:
      NSLog(@"unknown state  %d - nothing to do", aState);
      break;
  }
  if (requiresLayout == YES) {
    [self setNeedsLayout];
  }
}

#pragma mark - LayoutSubViews

- (void) layoutSubviews {
	[super layoutSubviews];
  BOOL adjustWhenFinished = NO;

  if (self.scrollSizeHasBeenSet == NO) {
		adjustWhenFinished = YES;
		[self updateScrollContentInset];
		[self updateWidthOfScrollContent];
  }

	SEL titleForElementSelector = @selector(pickerView:titleForIndex:);
	SEL viewForElementSelector  = @selector(pickerView:viewForIndex:);

	CGRect visibleBounds   = [self bounds];
	CGRect scaledViewFrame = CGRectZero;

	// remove any subviews that are no longer visible
	for (UIView *view in [self.scrollView subviews]) {
		scaledViewFrame = [self.scrollView convertRect:[view frame] toView:self];

		// if the view doesn't intersect, it's not visible, so we can recycle it
		if (!CGRectIntersectsRect(scaledViewFrame, visibleBounds)) {
			[view removeFromSuperview];
		} else { 
      if ([view conformsToProtocol:@protocol(V8HorizontalPickerElementView)]) {
        UIView<V8HorizontalPickerElementView> *elmView;
        elmView =  (UIView<V8HorizontalPickerElementView> *) view;
        BOOL isSelected = (self.currentSelectedIndex_Internal == [self indexForElement:view]);
        BOOL isOverSelectionPoint = ([self indexOfElementNearestToCenter] == self.currentSelectedIndex_Internal);
        [elmView setSelectedState:(isSelected && isOverSelectionPoint)];
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
					NSString *title = [self.delegate pickerView:self titleForIndex:index];
					view = [self labelForForElementAtIndex:index withTitle:title];
				} else if (self.delegate && [self.delegate respondsToSelector:viewForElementSelector]) {
          view = [self.delegate pickerView:self viewForIndex:index];
          [view setFrame:[self frameForElementAtIndex:index]];
				}
        
				if (view != nil) {
					// use the index as the tag so we can find it later
					view.tag = [self tagForElementAtIndex:index];
					[self.scrollView addSubview:view];
          if ([view conformsToProtocol:@protocol(V8HorizontalPickerElementView)]) {
            UIView<V8HorizontalPickerElementView> *elmView;
            elmView =  (UIView<V8HorizontalPickerElementView> *) view;
            BOOL isSelected = (self.currentSelectedIndex_Internal == [self indexForElement:view]);
            BOOL isOverSelectionPoint = ([self indexOfElementNearestToCenter] == self.currentSelectedIndex_Internal);
            [elmView setSelectedState:(isSelected && isOverSelectionPoint)];
          }
				}
			}
		}
	}

	// add the left or right edge views if visible
	CGRect viewFrame = CGRectZero;
	if (self.leftScrollEdgeView) {
		viewFrame = [self frameForLeftScrollEdgeView];
		scaledViewFrame = [self.scrollView convertRect:viewFrame toView:self];
		if (CGRectIntersectsRect(scaledViewFrame, visibleBounds) && 
        ![self.leftScrollEdgeView isDescendantOfView:self.scrollView]) {
			self.leftScrollEdgeView.frame = viewFrame;
			[self.scrollView addSubview:self.leftScrollEdgeView];
		}
	}
	if (self.rightScrollEdgeView) {
		viewFrame = [self frameForRightScrollEdgeView];
		scaledViewFrame = [self.scrollView convertRect:viewFrame toView:self];
		if (CGRectIntersectsRect(scaledViewFrame, visibleBounds) && 
        ![self.rightScrollEdgeView isDescendantOfView:self.scrollView]) {
			self.rightScrollEdgeView.frame = viewFrame;
			[self.scrollView addSubview:self.rightScrollEdgeView];
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
     [self scrollToIndex:self.currentSelectedIndex_Internal animated:NO];
		} else if (self.numberOfElements <= self.currentSelectedIndex_Internal) {
			// if currentSelectedIndex no longer exists, select what is currently centered
			self.currentSelectedIndex_Internal = [self indexOfElementNearestToCenter];
			[self scrollToIndex:self.currentSelectedIndex_Internal animated:NO];
		}
	}
}


#pragma mark - Getters and Setters


/*
 joshua > not sure this is necessary

//// allow the setting of this views background color to change the scroll view
//- (void) setBackgroundColor:(UIColor *)newColor {
//  
//  [super setBackgroundColor:newColor];
//	self.scrollView.backgroundColor = newColor;
//	// TODO: set all subviews as well?
//}
*/

- (void) setSelectionX:(CGFloat) aSelectionX {
  if (_selectionX != aSelectionX) {
		_selectionX = aSelectionX;
    [self drawPositionIndicator];
		[self updateScrollContentInset];
	}
}

- (void) setIndicatorPosition:(V8HorizontalPickerIndicatorPosition) aPosition {
	if (_indicatorPosition != aPosition) {
		_indicatorPosition = aPosition;
		[self drawPositionIndicator];
	}
}

- (void) setSelectionIndicatorView:(UIView *) aIndicatorView {
	if (_selectionIndicatorView != aIndicatorView) {
		if (_selectionIndicatorView != nil) {
			[_selectionIndicatorView removeFromSuperview];
		}
		_selectionIndicatorView = aIndicatorView;
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
  if (_leftScrollEdgeView != aLeftView) {
		if (_leftScrollEdgeView != nil) {
			[_leftScrollEdgeView removeFromSuperview];
		}
		_leftScrollEdgeView = aLeftView;
		scrollSizeHasBeenSet = NO;
		[self setNeedsLayout];
	}
}

- (void) setRightScrollEdgeView:(UIView *) aRightView {
	if (_rightScrollEdgeView != aRightView) {
		if (_rightScrollEdgeView != nil) {
			[_rightScrollEdgeView removeFromSuperview];
		}
		_rightScrollEdgeView = aRightView;
		scrollSizeHasBeenSet = NO;
		[self setNeedsLayout];
	}
}

- (void) setScrollEdgeViewPadding:(CGFloat) aScrollEdgeViewPadding {
  if (_scrollEdgeViewPadding != aScrollEdgeViewPadding) {
    _scrollEdgeViewPadding = aScrollEdgeViewPadding;
    scrollSizeHasBeenSet = NO;
		[self setNeedsLayout];
	}
}
- (void) setFrame:(CGRect) aNewFrame {
	if (!CGRectEqualToRect(self.frame, aNewFrame)) {
		// causes recalulation of offsets, etc based on new size
		scrollSizeHasBeenSet = NO;
	}
	[super setFrame:aNewFrame];
}

#pragma mark - Data Fetching Methods

- (void) reloadData {
  // nil out the array of widths
  _elementWidths = nil;
	// remove all scrollview subviews and "recycle" them
	for (UIView *view in [self.scrollView subviews]) {
		[view removeFromSuperview];
	}

	self.firstVisibleElement = NSIntegerMax;
	self.lastVisibleElement  = NSIntegerMin;
  
  self.scrollSizeHasBeenSet = NO;
  [self updateWidthOfScrollContent];
	[self updateScrollContentInset];
  [self setNeedsLayout];
}


#pragma mark - Scroll To Element Method


- (void) scrollToIndex:(NSUInteger) aIndex animated:(BOOL) aAnimate {
  if (self.scrollSizeHasBeenSet == NO) {
    self.scrollSizeHasBeenSet = NO;
    [self updateWidthOfScrollContent];
    [self updateScrollContentInset];
    [self setNeedsLayout];
  }
  
	self.currentSelectedIndex_Internal = aIndex;
	CGFloat x = [self centerOfElementAtIndex:aIndex] - self.selectionX;
	[self.scrollView setContentOffset:CGPointMake(x, 0) animated:aAnimate];

	// notify delegate of the selected index
	SEL delegateCall = @selector(pickerView:didSelectIndex:);

	if (self.delegate && [self.delegate respondsToSelector:delegateCall]) {
		[self.delegate pickerView:self didSelectIndex:aIndex];
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
		self.currentSelectedIndex_Internal = [self indexOfElementNearestToCenter];
	}
	[self setNeedsLayout];
}

- (void) scrollViewWillBeginDragging:(UIScrollView *) aScrollView {
	self.scrollingBasedOnUserInteraction = YES;
}

- (void) scrollViewDidEndDragging:(UIScrollView *) aScrollView willDecelerate:(BOOL) aDecelerate {
	// only do this if we aren't decelerating
	if (aDecelerate == NO) {
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
  // setting min/max the scale to 1.0 disables zooming
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

- (void) drawPositionIndicator {
	CGRect indicatorFrame = self.selectionIndicatorView.frame;
	CGFloat x = self.selectionX - (indicatorFrame.size.width / 2);
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

  elementLabel.textColor = self.textColor;
  elementLabel.highlightedTextColor = self.selectedTextColor;
	return elementLabel;
}


#pragma mark - View Calculation and Manipulation Methods (Internal Methods)
// what is the total width of the content area?
- (void) updateWidthOfScrollContent {
	NSUInteger totalWidth = 0;

	totalWidth += [self leftScrollEdgeWidth];
	totalWidth += [self rightScrollEdgeWidth];

	// sum the width of all elements
	for (NSNumber *width in self.elementWidths) {
		totalWidth += [width intValue];
	}
	
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
		CGFloat firstInset = self.selectionX - halfFirstWidth;
		firstInset -= [self leftScrollEdgeWidth];
		CGFloat lastInset  = (scrollerWidth - self.selectionX) - halfLastWidth;
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
	}
	return offset;
}

// return the tag for an element at a given index
- (NSUInteger) tagForElementAtIndex:(NSUInteger) aIndex {
	return (aIndex + 1) * 51;
}

// return the index given an element's tag
- (NSUInteger) indexForElement:(UIView *) aElement {
	return (aElement.tag / 51) - 1;
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
  
  CGFloat height = self.frame.size.height;
  CGFloat y = 0;
  if (self.delegate && [self.delegate respondsToSelector:@selector(pickerView:viewForIndex:)]) {
    UIView *view = [self.delegate pickerView:self viewForIndex:aIndex];
    height = view.frame.size.height;
    y = view.frame.origin.y;
  }
  
	return CGRectMake([self offsetForElementAtIndex:aIndex], y, width, height);
}

// what is the frame for the left scroll edge view?
- (CGRect) frameForLeftScrollEdgeView {
	if (self.leftScrollEdgeView != nil) {
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
	CGFloat x = self.scrollView.contentOffset.x + self.selectionX;
	return CGPointMake(x, 0.0);
}

// what is the element nearest to the center of the view?
- (NSUInteger) indexOfElementNearestToCenter {
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
- (NSUInteger) indexOfElementContainingPoint:(CGPoint) aPoint {
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
	[self scrollToIndex:[self indexOfElementNearestToCenter] animated:YES];
}


#pragma mark - Tap Gesture Recognizer Handler Method
// use the gesture recognizer to slide to element under tap
- (void) scrollViewTapped:(UITapGestureRecognizer *) aRecognizer {
	if (aRecognizer.state == UIGestureRecognizerStateRecognized) {
		CGPoint tapLocation    = [aRecognizer locationInView:self.scrollView];
		NSUInteger elementIndex = [self indexOfElementContainingPoint:tapLocation];
		if (elementIndex != NSNotFound) { // point not in element
			[self scrollToIndex:elementIndex animated:YES];
		}
	}
}

@end
