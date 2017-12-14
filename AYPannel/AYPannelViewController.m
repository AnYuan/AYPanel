//
//  XPannelViewController.m
//  XPannel
//
//  Created by anyuan on 11/12/2017.
//  Copyright © 2017 anyuan. All rights reserved.
//

#import "AYPannelViewController.h"
#import "AYPassthroughScrollView.h"
#import "AYDrawerContentViewController.h"

static CGFloat kAYDefaultCollapsedHeight = 68.0f;
static CGFloat kAYDefaultPartialRevealHeight = 264.0f;
static CGFloat kAYTopInset = 20.0f;
static CGFloat kAYBounceOverflowMargin = 20.0f;
static CGFloat kAYDefaultDimmingOpacity = 0.5f;


@interface AYPannelViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate, AYPassthroughScrollViewDelegate>
@property (nonatomic, assign) CGPoint lastDragTargetContentOffSet;
@property (nonatomic, assign) BOOL isAnimatingDrawerPosition;

@property (nonatomic, strong) UIPanGestureRecognizer *pan;

@property (nonatomic, strong) UIView *primaryContentContainer;
@property (nonatomic, strong) UIView *drawerContentContainer;
@property (nonatomic, strong) AYPassthroughScrollView *drawerScrollView;

@property (nonatomic, strong) UIView *backgroundDimmingView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic, strong) UIViewController *primaryContentViewController;
@property (nonatomic, strong) UIViewController <AYPannelViewControllerDelegate> *drawerContentViewController;
@end

@implementation AYPannelViewController

- (instancetype)initWithPrimaryContentViewController:(UIViewController *)primaryContentViewController drawerContentViewController:(UIViewController <AYPannelViewControllerDelegate> *)drawerContentViewController {
    self = [super init];
    if (self) {
        self.primaryContentViewController = primaryContentViewController;
        self.drawerContentViewController = drawerContentViewController;
    }
    return self;
}

#pragma mark - Life Cycle
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.lastDragTargetContentOffSet = CGPointZero;
    
    [self.drawerScrollView addSubview:self.drawerContentContainer];

    self.drawerScrollView.showsVerticalScrollIndicator = NO;
    self.drawerScrollView.showsHorizontalScrollIndicator = NO;
    self.drawerScrollView.bounces = NO;
    self.drawerScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.drawerScrollView.touchDelegate = self;
    
    
    self.pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerAction:)];
    self.pan.delegate = self;
    [self.drawerScrollView addGestureRecognizer:self.pan];
    
    [self.view addSubview:self.primaryContentContainer];
    [self.view addSubview:self.backgroundDimmingView];
    [self.view addSubview:self.drawerScrollView];

}

- (void)viewDidLayoutSubviews {
    
    [super viewDidLayoutSubviews];
    
    
    [self.primaryContentContainer addSubview:self.primaryContentViewController.view];
    [self.primaryContentContainer sendSubviewToBack:self.primaryContentViewController.view];
    
    [self.drawerContentContainer addSubview:self.drawerContentViewController.view];
    [self.drawerContentContainer sendSubviewToBack:self.drawerContentViewController.view];
    
    self.primaryContentContainer.frame = self.view.bounds;
    
    CGFloat safeAreaTopInset;
    CGFloat safeAreaBottomInset;
    
    if (@available(iOS 11.0, *)) {
        safeAreaTopInset = self.view.safeAreaInsets.top;
        safeAreaBottomInset = self.view.safeAreaInsets.bottom;
    } else {
        safeAreaTopInset = self.topLayoutGuide.length;
        safeAreaBottomInset = self.bottomLayoutGuide.length;
    }
    
    if (@available(iOS 11.0, *)) {
        self.drawerScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.drawerScrollView.contentInset = UIEdgeInsetsMake(0, 0, self.bottomLayoutGuide.length, 0);
    }
    
    CGFloat lowestStop = [self collapsedHeight];
    self.drawerScrollView.frame = CGRectMake(0, kAYTopInset + safeAreaTopInset, self.view.bounds.size.width, self.view.bounds.size.height - kAYTopInset - safeAreaTopInset);
    
    self.drawerContentContainer.frame = CGRectMake(0, self.drawerScrollView.bounds.size.height - lowestStop, self.drawerScrollView.bounds.size.width, self.drawerScrollView.bounds.size.height + kAYBounceOverflowMargin);
    
    self.drawerScrollView.contentSize = CGSizeMake(self.drawerScrollView.bounds.size.width, (self.drawerScrollView.bounds.size.height - lowestStop) + self.drawerScrollView.bounds.size.height - safeAreaBottomInset);
    
    
    self.backgroundDimmingView.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height + self.drawerScrollView.contentSize.height);
    
    self.drawerScrollView.transform = CGAffineTransformIdentity;
    self.drawerContentContainer.transform = self.drawerScrollView.transform;
    
    [self.backgroundDimmingView setHidden:NO];
    
    [self setDrawerPosition:AYPannelPositionCollapsed animated:NO];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    
    if (scrollView != self.drawerScrollView) { return; }
    

    CGFloat lowestStop = [self collapsedHeight];
    if ((scrollView.contentOffset.y - [self bottomSafeArea]) > ([self partialRevealDrawerHeight] - lowestStop)) {
        CGFloat fullRevealHeight = self.drawerScrollView.bounds.size.height;
        CGFloat progress;
        if (fullRevealHeight == [self partialRevealDrawerHeight]) {
            progress = 1.0;
        } else {
            progress = (scrollView.contentOffset.y - ([self partialRevealDrawerHeight] - lowestStop)) / (fullRevealHeight - [self partialRevealDrawerHeight]);
        }
        
        self.backgroundDimmingView.alpha = progress * kAYDefaultDimmingOpacity;
        [self.backgroundDimmingView setUserInteractionEnabled:YES];
    } else {
        if (self.backgroundDimmingView.alpha >= 0.01) {
            self.backgroundDimmingView.alpha = 0.0;
            [self.backgroundDimmingView setUserInteractionEnabled:NO];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView == self.drawerScrollView) {
        
        CGFloat lowestStop = [self collapsedHeight];
        CGFloat distanceFromBottomOfView = lowestStop + self.lastDragTargetContentOffSet.y;
        
        CGFloat currentClosestStop = lowestStop;
        
        //collapsed, partial reveal, open
        NSArray *drawerStops = @[@([self collapsedHeight]), @([self partialRevealDrawerHeight]), @(self.drawerScrollView.frame.size.height)];
        
        for (NSNumber *currentStop in drawerStops) {
            if (fabs(currentStop.floatValue - distanceFromBottomOfView) < fabs(currentClosestStop - distanceFromBottomOfView)) {
                currentClosestStop = currentStop.integerValue;
            }
        }
        
        if (fabs(currentClosestStop - (self.drawerScrollView.frame.size.height)) <= FLT_EPSILON) {
            //open
            [self setDrawerPosition:AYPannelPositionOpen animated:YES];
        } else if (fabs(currentClosestStop - [self collapsedHeight]) <= FLT_EPSILON) {
            //collapsed
            [self setDrawerPosition:AYPannelPositionCollapsed animated:YES];
        } else {
            //partially revealed
            [self setDrawerPosition:AYPannelPositionPartiallyRevealed animated:YES];
        }
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView == self.drawerScrollView) {
        self.lastDragTargetContentOffSet = CGPointMake(targetContentOffset->x, targetContentOffset->y);
        *targetContentOffset = scrollView.contentOffset;
    }
}

- (void)setDrawerPosition:(AYPannelPosition)position
                 animated:(BOOL)animated {
    
    CGFloat stopToMoveTo;
    CGFloat lowestStop = [self collapsedHeight];
    if (position == AYPannelPositionCollapsed) {
        stopToMoveTo = lowestStop;
    } else if (position == AYPannelPositionPartiallyRevealed) {
        stopToMoveTo = [self partialRevealDrawerHeight];
    } else if (position == AYPannelPositionOpen) {
        stopToMoveTo = self.drawerScrollView.frame.size.height;
    } else { //close
        stopToMoveTo = 0.0f;
    }
    
    self.isAnimatingDrawerPosition = YES;
    self.currentPosition = position;
    
    __weak typeof (self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.75 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [weakSelf.drawerScrollView setContentOffset:CGPointMake(0, stopToMoveTo - lowestStop) animated:NO];
    } completion:^(BOOL finished) {
        weakSelf.isAnimatingDrawerPosition = NO;
    }];
}

#pragma mark - UIPanGestureRecognizer
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)panGestureRecognizerAction:(UIPanGestureRecognizer *)getsutre {
    
    if (!self.shouldScrollDrawerScrollView) { return; }
    
    if (getsutre.state == UIGestureRecognizerStateChanged) {
        CGPoint old = [getsutre translationInView:self.drawerScrollView];
        CGPoint p = CGPointMake(0, self.drawerScrollView.frame.size.height - fabs(old.y) - 80);
        [self.drawerScrollView setContentOffset:p];
    } else if (getsutre.state == UIGestureRecognizerStateEnded) {
        self.shouldScrollDrawerScrollView = NO;
        CGFloat lowestStop = [self collapsedHeight];
        CGFloat distanceFromBottomOfView = self.drawerScrollView.frame.size.height - lowestStop - [getsutre translationInView:self.drawerScrollView].y;
        
        CGFloat currentClosestStop = lowestStop;
        
        //collapsed, partial reveal, open
        NSArray *drawerStops = @[@([self collapsedHeight]), @([self partialRevealDrawerHeight]), @(self.drawerScrollView.frame.size.height)];
        
        for (NSNumber *currentStop in drawerStops) {
            if (fabs(currentStop.floatValue - distanceFromBottomOfView) < fabs(currentClosestStop - distanceFromBottomOfView)) {
                currentClosestStop = currentStop.integerValue;
            }
        }
        
        if (fabs(currentClosestStop - (self.drawerScrollView.frame.size.height)) <= FLT_EPSILON) {
            //open
            [self setDrawerPosition:AYPannelPositionOpen animated:YES];
        } else if (fabs(currentClosestStop - [self collapsedHeight]) <= FLT_EPSILON) {
            //collapsed
            [self setDrawerPosition:AYPannelPositionCollapsed animated:YES];
        } else {
            //partially revealed
            [self setDrawerPosition:AYPannelPositionPartiallyRevealed animated:YES];
        }
    }
}

- (void)dimmingTapGestureRecognizer:(UITapGestureRecognizer *)tapGesture {
    if (tapGesture == self.tapGestureRecognizer) {
        if (self.tapGestureRecognizer.state == UIGestureRecognizerStateEnded) {
            [self setDrawerPosition:AYPannelPositionCollapsed animated:YES];
        }
    }
}

#pragma mark - AYDrawerScrollViewDelegate

- (void)drawerScrollViewDidScroll:(UIScrollView *)scrollView {
    //当drawer中的scroll view 的contentOffset.y 为 0时，触发drawerScrollView滚动
    if (CGPointEqualToPoint(scrollView.contentOffset, CGPointZero)) {
        self.shouldScrollDrawerScrollView = YES;
        [scrollView setScrollEnabled:NO];
        
    } else {
        self.shouldScrollDrawerScrollView = NO;
        [scrollView setScrollEnabled:YES];
    }
}


#pragma mark - AYPassthroughScrollViewDelegate
- (BOOL)shouldTouchPassthroughScrollView:(AYPassthroughScrollView *)scrollView
                                   point:(CGPoint)point {

    CGPoint p = [self.drawerContentContainer convertPoint:point fromView:scrollView];
    return !CGRectContainsPoint(self.drawerContentContainer.bounds, p);
}

- (UIView *)viewToReceiveTouch:(AYPassthroughScrollView *)scrollView
                         point:(CGPoint)point {
    return self.primaryContentContainer;
}


#pragma mark - Getter and Setter
- (void)setPrimaryContentViewController:(UIViewController *)primaryContentViewController {
    
    if (!primaryContentViewController) { return; }
    _primaryContentViewController = primaryContentViewController;
    [self addChildViewController:_primaryContentViewController];
}

- (void)setDrawerContentViewController:(UIViewController <AYPannelViewControllerDelegate>*)drawerContentViewController {
    if (!drawerContentViewController) { return; }
    _drawerContentViewController = drawerContentViewController;
    [self addChildViewController:_drawerContentViewController];
}

- (UIView *)drawerContentContainer {
    if (!_drawerContentContainer) {
        _drawerContentContainer = [[UIView alloc] initWithFrame:self.view.bounds];
        _drawerContentContainer.backgroundColor = [UIColor blueColor];
    }
    return _drawerContentContainer;
}

- (UIView *)primaryContentContainer {
    if (!_primaryContentContainer) {
        _primaryContentContainer = [[UIView alloc] initWithFrame:self.view.bounds];
        _primaryContentContainer.backgroundColor = [UIColor whiteColor];
    }
    return _primaryContentContainer;
}

- (AYPassthroughScrollView *)drawerScrollView {
    if (!_drawerScrollView) {
        _drawerScrollView = [[AYPassthroughScrollView alloc] initWithFrame:self.drawerContentContainer.bounds];
        _drawerScrollView.delegate = self;
    }
    return _drawerScrollView;
}

- (UIView *)backgroundDimmingView {
    if (!_backgroundDimmingView) {
        _backgroundDimmingView = [[UIView alloc] init];
        [_backgroundDimmingView setUserInteractionEnabled:NO];
        _backgroundDimmingView.alpha = 0.0;
        _backgroundDimmingView.backgroundColor = [UIColor blackColor];
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dimmingTapGestureRecognizer:)];
        [_backgroundDimmingView addGestureRecognizer:_tapGestureRecognizer];
    }
    return _backgroundDimmingView;
}

- (CGFloat)collapsedHeight {
    CGFloat collapsedHeight = kAYDefaultCollapsedHeight;
    
    if ([self.drawerContentViewController respondsToSelector:@selector(collapsedDrawerHeight)]) {
        collapsedHeight = [self.drawerContentViewController collapsedDrawerHeight];
    }
    
    return collapsedHeight;
}

- (CGFloat)partialRevealDrawerHeight {
    CGFloat partialRevealDrawerHeight = kAYDefaultPartialRevealHeight;
    if ([self.drawerContentViewController respondsToSelector:@selector(partialRevealDrawerHeight)]) {
        partialRevealDrawerHeight = [self.drawerContentViewController partialRevealDrawerHeight];
    }
    return partialRevealDrawerHeight;
}

- (CGFloat)bottomSafeArea {
    CGFloat safeAreaBottomInset;
    if (@available(iOS 11.0, *)) {
        safeAreaBottomInset = self.view.safeAreaInsets.bottom;
    } else {
        safeAreaBottomInset = self.bottomLayoutGuide.length;
    }
    return safeAreaBottomInset;
}

- (void)setCurrentPosition:(AYPannelPosition)currentPosition {
    _currentPosition = currentPosition;
    //通知外部位置变化
    [_drawerContentViewController drawerPositionDidChange:self];
}

@end
