//
//  PulleyPassthroughScrollView.m
//  XPannel
//
//  Created by anyuan on 12/12/2017.
//  Copyright © 2017 anyuan. All rights reserved.
//

#import "AYPassthroughScrollView.h"

@implementation AYPassthroughScrollView

#pragma mark - Override
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.touchDelegate) {
        if ([self.touchDelegate shouldTouchPassthroughScrollView:self point:point]) {
            UIView *view = [self.touchDelegate viewToReceiveTouch:self point:point];
            CGPoint p = [view convertPoint:point fromView:self];
            return [view hitTest:p withEvent:event];
        }
    }
    return [super hitTest:point withEvent:event];
}


//如果scroll view上有button，优先滚动
- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    if ( [view isKindOfClass:[UIButton class]] ) {
        return YES;
    }
    
    return [super touchesShouldCancelInContentView:view];
}
@end
