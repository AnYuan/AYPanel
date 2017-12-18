//
//  XPannelViewController.h
//  XPannel
//
//  Created by anyuan on 11/12/2017.
//  Copyright © 2017 anyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, AYPannelPosition) {
    AYPannelPositionClosed, //不在可视范围
    AYPannelPositionCollapsed,//收起
    AYPannelPositionPartiallyRevealed, //部分展开
    AYPannelPositionOpen,//全部展开
};

@class AYPannelViewController;

//通知外界drawerPosition发生变化
@protocol AYPannelDrawerDelegate <NSObject>
@property (nonatomic, strong) UIView *view;

- (void)drawerPositionDidChange:(AYPannelViewController *)drawer;
@optional
- (CGFloat)collapsedDrawerHeight;
- (CGFloat)partialRevealDrawerHeight;
- (NSSet <NSNumber *> *)supportPannelPosition; // 返回支持位置的AYPannelPosition枚举的NSNumber对象, 如果不实现或者返回空，就默认是所有位置都支持

- (UIVisualEffectView *)drawerBackgroundVisualEffectView; // 如果要展示毛玻璃效果，上层view需要设置为透明; 不需要返回nil即可
- (CGFloat)drawerCornerRadius; //是否需要圆角， 如果返回0.0则不需要圆角, 此处设置圆角，其他使用圆角位置自动设置，如黑色蒙层
- (UIView *)backgroundDimmingView; //蒙层View， 只需要初始化UIView，设置蒙层颜色即可, 不需要蒙层，返回nil即可
@end

@protocol AYPannelPrimaryDelegate <NSObject>
@property (nonatomic, strong) UIView *view;
@end

//Drawer 滚动回调
@protocol AYDrawerScrollViewDelegate
- (void)drawerScrollViewDidScroll:(UIScrollView *)scrollView;
@end

@interface AYPannelViewController : UIViewController <AYDrawerScrollViewDelegate>

@property (nonatomic, assign) AYPannelPosition currentPosition;
@property (nonatomic, assign) BOOL shouldScrollDrawerScrollView;

- (instancetype)initWithPrimaryContentViewController:(id<AYPannelPrimaryDelegate>)primaryContentViewController
                         drawerContentViewController:(id<AYPannelDrawerDelegate>)drawerContentViewController;
@end
