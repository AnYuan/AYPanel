//
//  AYDrawerContentViewController.h
//  AYPannel
//
//  Created by anyuan on 13/12/2017.
//  Copyright © 2017 anyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AYPannelViewController.h"

@protocol AYPannelDrawerDelegate;



@interface AYDrawerContentViewController : UIViewController <AYPannelDrawerDelegate>
@property (nonatomic, weak) id<AYDrawerScrollViewDelegate> drawerScrollDelegate;
@end
