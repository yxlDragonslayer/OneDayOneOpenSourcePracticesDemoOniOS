/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 6.x Edition
 BSD License, Use at your own risk
 */


#import <UIKit/UIKit.h>

@interface CustomSlider : UISlider
{
    float previousValue;
}
+ (id) slider;
- (void) updateThumb;
@end
