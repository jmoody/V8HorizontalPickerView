//
//  V8HorizontalPickerView.h
//
//  Created by Shawn Veader on 9/17/10.
//  Copyright 2010 V8 Labs, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "V8HorizontalPickerViewProtocol.h"

// position of indicator view, if shown
typedef enum {
	V8HorizontalPickerIndicatorBottom = 0,
	V8HorizontalPickerIndicatorTop	
} V8HorizontalPickerIndicatorPosition;

typedef enum {
  V8HorizontalPickerSelectionStateSelected = 0,
  V8HorizontalPickerSelectionStateUnselected
} V8HorizontalPickerSelectionState;


@interface V8HorizontalPickerView : UIView <UIScrollViewDelegate> { }

// delegate and datasources to feed scroll view. this view only maintains a weak reference to these
@property (nonatomic, unsafe_unretained) id <V8HorizontalPickerViewDataSource> dataSource;
@property (nonatomic, unsafe_unretained) id <V8HorizontalPickerViewDelegate> delegate;

@property (nonatomic, readonly) NSUInteger numberOfElements;
@property (nonatomic, readonly) NSUInteger currentSelectedIndex;

// what font to use for the element labels?
@property (nonatomic) UIFont *elementFont;

//// color of labels used in picker
//@property (nonatomic, strong) UIColor *textColor;
//@property (nonatomic, strong) UIColor *selectedTextColor; // color of current selected element

// the point, defaults to center of view, where the selected element sits
@property (nonatomic, assign) CGFloat selectionX;
@property (nonatomic, strong) UIView *selectionIndicatorView;

@property (nonatomic, assign) V8HorizontalPickerIndicatorPosition indicatorPosition;

// views to display on edges of picker (eg: gradients, etc)
@property (nonatomic, strong) UIView *leftEdgeView;
@property (nonatomic, strong) UIView *rightEdgeView;

// views for left and right of scrolling area
@property (nonatomic, strong) UIView *leftScrollEdgeView;
@property (nonatomic, strong) UIView *rightScrollEdgeView;

// padding for left/right scroll edge views
@property (nonatomic, assign) CGFloat scrollEdgeViewPadding;


- (void) reloadData;
- (void) scrollToElement:(NSUInteger) aIndex animated:(BOOL) animate;
- (void) setTitleColor:(UIColor *) aColor forSelectionState:(V8HorizontalPickerSelectionState) aState;



@end


