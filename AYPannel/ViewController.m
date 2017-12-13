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
    
    self.xPannelViewController = [[AYPannelViewController alloc] initWithPrimaryContentViewController:[AYPrimaryContentViewController new] drawerContentViewController:[AYDrawerContentViewController new]];
    
    [self addChildViewController:self.xPannelViewController];
    self.xPannelViewController.view.frame = self.view.bounds;
    [self.view addSubview:self.xPannelViewController.view];
    
}

@end

