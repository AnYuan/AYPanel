//
//  XPannelViewController.h
//  XPannel
//
//  Created by anyuan on 11/12/2017.
//  Copyright © 2017 anyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, AYPannelPosition) {
    AYPannelPositionCollapsed,//收起
    AYPannelPositionPartiallyRevealed, //部分展开
    AYPannelPositionOpen,//全部展开
    AYPannelPositionClosed, //不在可视范围
};

static CGFloat const kXPannelDefaultCollapsedHeight = 68.0f;
static CGFloat const kXPannelDefaultPartialRevealHeight = 264.0f;

@class AYPannelViewController;

//通知外界drawerPosition发生变化
@protocol AYPannelViewControllerDelegate
- (void)drawerPositionDidChange:(AYPannelViewController *)drawer;
@end

//Drawer 滚动回调
@protocol AYDrawerScrollViewDelegate
- (void)drawerScrollViewDidScroll:(UIScrollView *)scrollView;
@end

@interface AYPannelViewController : UIViewController <AYDrawerScrollViewDelegate>

@property (nonatomic, assign) AYPannelPosition currentPosition;
@property (nonatomic, assign) BOOL shouldScrollDrawerScrollView;
- (instancetype)initWithPrimaryContentViewController:(UIViewController *)primaryContentViewController
                         drawerContentViewController:(UIViewController *)drawerContentViewController;
@end
