//
//  V8HorizontalPickerViewProtocol.h
//
//  Created by Shawn Veader on 9/17/10.
//  Copyright 2010 V8 Labs, LLC. All rights reserved.
//

@class V8HorizontalPickerView;

// ------------------------------------------------------------------
// V8HorizontalPickerElementState Protocol
@protocol V8HorizontalPickerElementView <NSObject>

@required
// element views should know how display themselves based on selected status
- (void) setSelectedState:(BOOL) aSelected;
@end

// ------------------------------------------------------------------
// V8HorizontalPickerView DataSource Protocol
@protocol V8HorizontalPickerViewDataSource <NSObject>

@required
// data source is responsible for reporting how many elements there are
- (NSUInteger) numberOfElementsInPickerView:(V8HorizontalPickerView *) aPicker;
@end


// ------------------------------------------------------------------
// V8HorizontalPickerView Delegate Protocol
@protocol V8HorizontalPickerViewDelegate <NSObject>


@required
// delegate is responsible for reporting the size of each element
- (CGFloat) pickerView:(V8HorizontalPickerView *) aPicker 
         widthForIndex:(NSUInteger) aIndex;

@optional
// delegate callback to notify delegate selected element has changed
- (void) pickerView:(V8HorizontalPickerView *) aPicker 
     didSelectIndex:(NSUInteger) aIndex;

// one of these two methods must be defined
- (NSString *) pickerView:(V8HorizontalPickerView *) aPicker 
            titleForIndex:(NSUInteger) aIndex;

- (UIView <V8HorizontalPickerElementView> *) pickerView:(V8HorizontalPickerView *) aPicker 
                                           viewForIndex:(NSUInteger) aIndex;



@end

