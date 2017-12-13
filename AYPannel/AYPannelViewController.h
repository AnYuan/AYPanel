//
//  XPannelViewController.h
//  XPannel
//
//  Created by anyuan on 11/12/2017.
//  Copyright © 2017 anyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, XPannelPosition) {
    XPannelPositionCollapsed,//收起
    XPannelPositionPartiallyRevealed, //部分展开
    XPannelPositionOpen,//全部展开
    XPannelPositionClosed, //不在可视范围
};

static CGFloat const kXPannelDefaultCollapsedHeight = 68.0f;
static CGFloat const kXPannelDefaultPartialRevealHeight = 264.0f;


@interface AYPannelViewController : UIViewController
@end
