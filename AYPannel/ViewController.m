//
//  ViewController.m
//  XPannel
//
//  Created by anyuan on 11/12/2017.
//  Copyright © 2017 anyuan. All rights reserved.
//

#import "ViewController.h"
#import "AYPannelViewController.h"
#import "AYPrimaryContentViewController.h"
#import "AYDrawerContentViewController.h"

@interface ViewController ()
@property (nonatomic, strong) AYPannelViewController *xPannelViewController;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor greenColor];
    
    
    AYPrimaryContentViewController *p = [AYPrimaryContentViewController new];
    AYDrawerContentViewController *d = [AYDrawerContentViewController new];
    self.xPannelViewController = [[AYPannelViewController alloc] initWithPrimaryContentViewController:p drawerContentViewController:d];
    
    d.drawerScrollDelegate = self.xPannelViewController;
    
    [self addChildViewController:self.xPannelViewController];
    self.xPannelViewController.view.frame = self.view.bounds;
    [self.view addSubview:self.xPannelViewController.view];
    
}

@end

