//
//  AYDrawerContentViewController.m
//  AYPannel
//
//  Created by anyuan on 13/12/2017.
//  Copyright © 2017 anyuan. All rights reserved.
//

#import "AYDrawerContentViewController.h"
#import "AYPannelViewController.h"

@interface AYDrawerContentViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation AYDrawerContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.headerView];
    [self.view addSubview:self.tableView];
    self.view.backgroundColor = [UIColor yellowColor];
    
    [self.tableView setScrollEnabled:NO];
    self.tableView.bounces = NO;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"table view cell"];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.headerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 60);
    self.tableView.frame = CGRectMake(0, 60, self.view.bounds.size.width, self.view.bounds.size.height - 60);
}
#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"table view cell"];
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.text = [NSString stringWithFormat:@"This is indexPath %ld", (long)indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

#pragma mark - AYPannelViewControllerDelegate
- (void)drawerPositionDidChange:(AYPannelViewController *)drawer {
    if (drawer.currentPosition == AYPannelPositionOpen) {
        [self.tableView setScrollEnabled:YES];
    } else {
        [self.tableView setScrollEnabled:NO];
    }
}

- (void)drawerDraggingProgress:(CGFloat)progress {
    NSLog(@"###### dragging progress is %f", progress);
}

- (CGFloat)collapsedDrawerHeight {
    return 68.0f;
}

- (CGFloat)partialRevealDrawerHeight {
    return 264.0f;
}

- (NSSet<NSNumber *> *)supportPannelPosition {
    NSArray *array = @[@(AYPannelPositionCollapsed), @(AYPannelPositionPartiallyRevealed), @(AYPannelPositionOpen), @(AYPannelPositionClosed)];
    return [NSSet setWithArray:array];
}

- (UIVisualEffectView *)drawerBackgroundVisualEffectView {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    UIVisualEffectView *drawerBackgroundVisualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    drawerBackgroundVisualEffectView.clipsToBounds = YES;
    return drawerBackgroundVisualEffectView;
}

- (CGFloat)drawerCornerRadius {
    return 13.0f;
}

- (UIView *)backgroundDimmingView {
    UIView *backgroundDimmingView = [[UIView alloc] init];
    backgroundDimmingView.backgroundColor = [UIColor blackColor];
    return backgroundDimmingView;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.drawerScrollDelegate drawerScrollViewDidScroll:scrollView];
}


#pragma mark - Getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = [UIColor clearColor];
    }
    return _tableView;
}

- (UIView *)headerView {
    if (!_headerView) {
        _headerView = [[UIView alloc] init];
        _headerView.backgroundColor = [UIColor clearColor];
    }
    return _headerView;
}
@end
