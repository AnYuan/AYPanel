//
//  PulleyPassthroughScrollView.h
//  XPannel
//
//  Created by anyuan on 12/12/2017.
//  Copyright © 2017 anyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AYPassthroughScrollView;

@protocol PulleyPassthroughScrollViewDelegate

- (BOOL)shouldTouchPassthroughScrollView:(AYPassthroughScrollView *)scrollView
                                   point:(CGPoint)point;

- (UIView *)viewToReceiveTouch:(AYPassthroughScrollView *)scrollView
                         point:(CGPoint)point;
@end

@interface AYPassthroughScrollView : UIScrollView
@property (nonatomic, weak) id<PulleyPassthroughScrollViewDelegate> touchDelegate;
@end
