Fork Notes
======================

Shawn did a great job on this picker view - he really nailed the look-and-feel. 
The scrolling and snap-to effects are brilliant!  The indicator view and the 
selection point are great.  The option of adding a left/right edge _and_ 
left/right scroll view is fantastic.

I discovered a few limitations and a couple of bugs so I thought I would have 
a crack at fixing them.

1. delegates can now be shared across multiple picker views
2. converted the project and sources to ARC
3. the frames of custom views were not being set correctly
4. the y and height of custom view frames were not being respected
5. the selected state of custom views was not being set correct on the first
   call to scrollToIndex:animate:
6. it was possible to produce a bad UI state (element not centered over selection
   point or scroll view scrolling past all the elements) if scrollToIndex:selected
   was called before layoutSubviews

In the course of my bug fixes, I also did some refactoring.

1. the delegate and data source protocols to be more terse
2. converted NSInteger to NSUInteger where appropriate
3. converted NSInteger to CGFloat where appropriate
4. removed several state variables that were no longer necessary
5. dramatically simplified the V8HorizontalPickerLabel class
6. replaced textColor and  selectedTextColor properties with:
   - (void) setTitleColor:(UIColor *) aColor 
        forSelectionState:(V8HorizontalPickerSelectionState) aState;
7. added a little (not enough!) clarifying documentation

-jjm

V8HorizontalPickerView
======================
by Shawn Veader (@veader) of [V8 Logic](http://v8logic.com) / [V8 Labs, LLC](http://v8labs.com)

Original design by [Buck Sharp](http://bucksharp.tumblr.com/), the designer on f/stats.


How to use V8HorizontalPickerView
---------------------------------
Add the `V8HorizontalPickerView` header and implementation files (.h and .m)
along with the protocol header file to your app source and include them in
your project. (I like to keep them in their own group to keep things tidy.)

Implement the necessary delegate and data source protocol methods.
Instantiate and add the picker view to your view and wire up the delegate
and data source. That's it!

I modeled this after a lot of the standard Apple controls such as `UITableView`.

Delegate Protocol
----------------
    - (NSInteger)numberOfElementsInHorizontalPickerView:(V8HorizontalPickerView *)picker;

Data Source Protocol
-------------------
    - (void)horizontalPickerView:(V8HorizontalPickerView *)picker didSelectElementAtIndex:(NSInteger)index;
    - (NSString *)horizontalPickerView:(V8HorizontalPickerView *)picker titleForElementAtIndex:(NSInteger)index;
    - (UIView *)  horizontalPickerView:(V8HorizontalPickerView *)picker  viewForElementAtIndex:(NSInteger)index;
    - (NSInteger) horizontalPickerView:(V8HorizontalPickerView *)picker widthForElementAtIndex:(NSInteger)index;

The protocol requires the width method to be implemented and for either the
title or view *ForElementAtIndex: method to be implemented. (ie: you don't
need both)

Using Views for Elements
------------------------
If you are going to implement the

    -horizontalPickerView:viewForElementAtIndex:

data source method, make sure your view conforms to the 
`V8HorizontalPickerElementState` protocol.

License
-------
See LICENSE file.
TL;DR: I am publishing this under the zlib/libpng license.

Thanks
------
Thanks for taking the time to check out the project. Let me know via the
GitHub issues feature if you find any bugs or have feature requests. Please
drop me a note and let me know if you use this in a project that hits the
AppStore.

Apps Using this Control
-----------------------
[f/stats](http://fstatsapp.com) - Flickr stats for iPhone

[Spentory](http://spentory-landingpage.herokuapp.com/) - Expense Transactions inventory for iPhone


- Submit yours to be included in this list.
