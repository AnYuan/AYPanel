//
//  ViewController.m
//  XPannel
//
//  Created by anyuan on 11/12/2017.
//  Copyright © 2017 anyuan. All rights reserved.
//

#import "ViewController.h"
#import "AYPannelViewController.h"

@interface ViewController ()
@property (nonatomic, strong) AYPannelViewController *xPannelViewController;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor greenColor];
    
    self.xPannelViewController = [[AYPannelViewController alloc] init];
    
    [self addChildViewController:self.xPannelViewController];
    self.xPannelViewController.view.frame = CGRectMake(0, 10, self.view.frame.size.width, self.view.frame.size.height - 10);
    [self.view addSubview:self.xPannelViewController.view];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

