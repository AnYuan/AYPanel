//
//  AYPrimaryContentViewController.m
//  AYPannel
//
//  Created by anyuan on 13/12/2017.
//  Copyright © 2017 anyuan. All rights reserved.
//

#import "AYPrimaryContentViewController.h"

@interface AYPrimaryContentViewController ()
@property (nonatomic, strong) UISwitch *primarySwitch;
@end

@implementation AYPrimaryContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.primarySwitch];
    
    self.view.backgroundColor = [UIColor yellowColor];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.primarySwitch.frame = CGRectMake(10, 100, 50, 50);
}

- (UISwitch *)primarySwitch {
    if (!_primarySwitch) {
        _primarySwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    }
    return _primarySwitch;
}

@end
