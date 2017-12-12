//
//  XPannelViewController.m
//  XPannel
//
//  Created by anyuan on 11/12/2017.
//  Copyright © 2017 anyuan. All rights reserved.
//

#import "AYPannelViewController.h"
#import "AYPassthroughScrollView.h"

static CGFloat kAYDefaultCollapsedHeight = 68.0;
static CGFloat kAYDefaultPartialRevealHeight = 264.0;

@interface AYPannelViewController () <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UIView *drawerContentContainer;
@property (nonatomic, strong) AYPassthroughScrollView *drawerScrollView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) CGPoint lastDragTargetContentOffSet;
@property (nonatomic, assign) BOOL isAnimatingDrawerPosition;
@end

@implementation AYPannelViewController

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.lastDragTargetContentOffSet = CGPointZero;
    
    [self.view addSubview:self.drawerScrollView];
    
    [self.drawerContentContainer addSubview:self.headerView];
    [self.drawerContentContainer addSubview:self.tableView];
    
    [self.drawerScrollView addSubview:self.drawerContentContainer];
//    self.drawerScrollView.delaysContentTouches = YES;
//    self.drawerScrollView.canCancelContentTouches = YES;
    self.drawerScrollView.showsVerticalScrollIndicator = NO;
    self.drawerScrollView.showsHorizontalScrollIndicator = NO;
    self.drawerScrollView.bounces = NO;
    self.drawerScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"table view cell"];
}

- (void)viewDidLayoutSubviews {
    self.headerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 60);
    self.tableView.frame = CGRectMake(0, 60, self.view.bounds.size.width, 300);
    self.tableView.backgroundColor = [UIColor yellowColor];
    
    self.drawerContentContainer.frame = CGRectMake(0, self.view.bounds.size.height - 68, self.view.bounds.size.width, self.view.bounds.size.height);

    self.drawerScrollView.frame = CGRectMake(0, 20, self.view.bounds.size.width, self.view.bounds.size.height);
    
    self.drawerScrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 2 * self.drawerScrollView.frame.size.height - kAYDefaultCollapsedHeight - self.view.safeAreaInsets.bottom);
    self.drawerScrollView.transform = CGAffineTransformIdentity;
    self.drawerContentContainer.transform = self.drawerScrollView.transform;
}

#pragma mark - Getter and Setter
- (UIView *)drawerContentContainer {
    if (!_drawerContentContainer) {
        _drawerContentContainer = [[UIView alloc] initWithFrame:self.view.bounds];
        _drawerContentContainer.backgroundColor = [UIColor blueColor];
    }
    return _drawerContentContainer;
}

- (AYPassthroughScrollView *)drawerScrollView {
    if (!_drawerScrollView) {
        _drawerScrollView = [[AYPassthroughScrollView alloc] initWithFrame:self.drawerContentContainer.bounds];
        _drawerScrollView.delegate = self;
    }
    return _drawerScrollView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}

- (UIView *)headerView {
    if (!_headerView) {
        _headerView = [[UIView alloc] init];
        _headerView.backgroundColor = [UIColor redColor];
    }
    return _headerView;
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView dequeueReusableCellWithIdentifier:@"table view cell"];
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

#pragma mark - UIScrollViewDelegate


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.drawerScrollView) {
//        NSLog(@"scrollView did scroll");
        
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView == self.drawerScrollView) {
        
        CGFloat lowestStop = kAYDefaultCollapsedHeight;
        CGFloat distanceFromBottomOfView = lowestStop + self.lastDragTargetContentOffSet.y;
        
        CGFloat currentClosestStop = lowestStop;
        
        //collapsed, partial reveal, open
        NSArray *drawerStops = @[@(kAYDefaultCollapsedHeight), @(kAYDefaultPartialRevealHeight), @(self.drawerScrollView.frame.size.height)];
        
        for (NSNumber *currentStop in drawerStops) {
            if (fabs(currentStop.floatValue - distanceFromBottomOfView) < fabs(currentClosestStop - distanceFromBottomOfView)) {
                currentClosestStop = currentStop.integerValue;
            }
        }
        
        if (fabs(currentClosestStop - (self.drawerScrollView.frame.size.height)) <= FLT_EPSILON) {
            //open
            [self setDrawerPosition:XPannelPositionOpen animated:YES];
        } else if (fabs(currentClosestStop - kAYDefaultCollapsedHeight) <= FLT_EPSILON) {
            //collapsed
            [self setDrawerPosition:XPannelPositionCollapsed animated:YES];
        } else {
            //partially revealed
            [self setDrawerPosition:XPannelPositionPartiallyRevealed animated:YES];
        }
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView == self.drawerScrollView) {
        self.lastDragTargetContentOffSet = CGPointMake(targetContentOffset->x, targetContentOffset->y);
        *targetContentOffset = scrollView.contentOffset;
    }
}

- (void)setDrawerPosition:(XPannelPosition)position
                 animated:(BOOL)animated {
    
    CGFloat stopToMoveTo;
    CGFloat lowestStop = kAYDefaultCollapsedHeight;
    if (position == XPannelPositionCollapsed) {
        stopToMoveTo = kAYDefaultCollapsedHeight;
    } else if (position == XPannelPositionPartiallyRevealed) {
        stopToMoveTo = kAYDefaultPartialRevealHeight;
    } else if (position == XPannelPositionOpen) {
        stopToMoveTo = self.drawerScrollView.frame.size.height;
    } else {
        stopToMoveTo = 0.0f;
    }
    
    self.isAnimatingDrawerPosition = YES;
    __weak typeof (self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.75 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [weakSelf.drawerScrollView setContentOffset:CGPointMake(0, stopToMoveTo - lowestStop) animated:NO];
    } completion:^(BOOL finished) {
        weakSelf.isAnimatingDrawerPosition = NO;
    }];
}
@end
