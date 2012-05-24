//
//  V8HorizontalPickerViewProtocol.h
//
//  Created by Shawn Veader on 9/17/10.
//  Copyright 2010 V8 Labs, LLC. All rights reserved.
//

@class V8HorizontalPickerView;

// ------------------------------------------------------------------
// V8HorizontalPickerElementState Protocol
@protocol V8HorizontalPickerElementState <NSObject>

@required
// element views should know how display themselves based on selected status
- (void) setSelectedElement:(BOOL)selected;
@end

// ------------------------------------------------------------------
// V8HorizontalPickerView DataSource Protocol
@protocol V8HorizontalPickerViewDataSource <NSObject>

@required
// data source is responsible for reporting how many elements there are
- (NSInteger) numberOfElementsInHorizontalPickerView:(V8HorizontalPickerView *) aPicker;
@end


// ------------------------------------------------------------------
// V8HorizontalPickerView Delegate Protocol
@protocol V8HorizontalPickerViewDelegate <NSObject>


@required
// delegate is responsible for reporting the size of each element
- (CGFloat) horizontalPickerView:(V8HorizontalPickerView *)picker
          widthForElementAtIndex:(NSInteger) aIndex;

@optional
// delegate callback to notify delegate selected element has changed
- (void) horizontalPickerView:(V8HorizontalPickerView *) aPicker 
      didSelectElementAtIndex:(NSInteger) aIndex;

// one of these two methods must be defined
- (NSString *) horizontalPickerView:(V8HorizontalPickerView *) aPicker 
             titleForElementAtIndex:(NSInteger) aIndex;

- (UIView <V8HorizontalPickerElementState> *)  horizontalPickerView:(V8HorizontalPickerView *) aPicker 
                                             viewForElementAtIndex:(NSInteger) aIndex;



@end

