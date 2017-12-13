//
//  AYDrawerContentViewController.h
//  AYPannel
//
//  Created by anyuan on 13/12/2017.
//  Copyright © 2017 anyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AYPannelViewController.h"

@protocol AYPannelViewControllerDelegate;

@protocol AYDrawerScrollViewDelegate
- (void)drawerScrollViewDidScroll:(UIScrollView *)scrollView;
@end


@interface AYDrawerContentViewController : UIViewController <AYPannelViewControllerDelegate>
@property (nonatomic, weak) id<AYDrawerScrollViewDelegate> drawerScrollDelegate;
@end
