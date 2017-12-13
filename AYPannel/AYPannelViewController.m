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

static CGFloat kAYDefaultCollapsedHeight = 68.0;
static CGFloat kAYDefaultPartialRevealHeight = 264.0;

@interface AYPannelViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate, AYPassthroughScrollViewDelegate>
@property (nonatomic, strong) UIView *drawerContentContainer;
@property (nonatomic, strong) AYPassthroughScrollView *drawerScrollView;
@property (nonatomic, assign) CGPoint lastDragTargetContentOffSet;
@property (nonatomic, assign) BOOL isAnimatingDrawerPosition;

@property (nonatomic, strong) UIPanGestureRecognizer *pan;

@property (nonatomic, strong) UIView *primaryContentContainer;

@property (nonatomic, strong) UIViewController *primaryContentViewController;
@property (nonatomic, strong) UIViewController *drawerContentViewController;
@end

@implementation AYPannelViewController

- (instancetype)initWithPrimaryContentViewController:(UIViewController *)primaryContentViewController drawerContentViewController:(UIViewController *)drawerContentViewController {
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
    // Do any additional setup after loading the view.
    
    self.lastDragTargetContentOffSet = CGPointZero;
    
    [self.drawerScrollView addSubview:self.drawerContentContainer];
//    self.drawerScrollView.delaysContentTouches = YES;
//    self.drawerScrollView.canCancelContentTouches = YES;
    self.drawerScrollView.showsVerticalScrollIndicator = NO;
    self.drawerScrollView.showsHorizontalScrollIndicator = NO;
    self.drawerScrollView.bounces = NO;
    self.drawerScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.drawerScrollView.touchDelegate = self;
    
    
    self.pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerAction:)];
    self.pan.delegate = self;
    [self.drawerScrollView addGestureRecognizer:self.pan];
    
    [self.view addSubview:self.primaryContentContainer];
    [self.view addSubview:self.drawerScrollView];

}

- (void)viewDidLayoutSubviews {
    
    [super viewDidLayoutSubviews];
    
    [self.primaryContentContainer addSubview:self.primaryContentViewController.view];
    [self.primaryContentContainer sendSubviewToBack:self.primaryContentViewController.view];
    
    [self.drawerContentContainer addSubview:self.drawerContentViewController.view];
    [self.drawerContentContainer sendSubviewToBack:self.drawerContentViewController.view];

    
    self.drawerScrollView.frame = CGRectMake(0, 20, self.view.bounds.size.width, self.view.bounds.size.height);

    
    self.primaryContentContainer.frame = self.view.bounds;
    
    self.drawerContentContainer.frame = CGRectMake(0, self.drawerScrollView.bounds.size.height - 80, self.view.bounds.size.width, self.view.bounds.size.height);

    
    self.drawerScrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 2 * self.drawerScrollView.frame.size.height - kAYDefaultCollapsedHeight - self.view.safeAreaInsets.bottom);
    self.drawerScrollView.transform = CGAffineTransformIdentity;
    self.drawerContentContainer.transform = self.drawerScrollView.transform;
    
    [self setDrawerPosition:AYPannelPositionCollapsed animated:NO];
}

#pragma mark - Getter and Setter
- (void)setPrimaryContentViewController:(UIViewController *)primaryContentViewController {
    
    if (!primaryContentViewController) { return; }
    _primaryContentViewController = primaryContentViewController;
    [self addChildViewController:_primaryContentViewController];
}

- (void)setDrawerContentViewController:(UIViewController *)drawerContentViewController {
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
//    NSLog(@"scroll view is %@", scrollView);
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
            [self setDrawerPosition:AYPannelPositionOpen animated:YES];
        } else if (fabs(currentClosestStop - kAYDefaultCollapsedHeight) <= FLT_EPSILON) {
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
    CGFloat lowestStop = kAYDefaultCollapsedHeight;
    if (position == AYPannelPositionCollapsed) {
        stopToMoveTo = kAYDefaultCollapsedHeight;
    } else if (position == AYPannelPositionPartiallyRevealed) {
        stopToMoveTo = kAYDefaultPartialRevealHeight;
    } else if (position == AYPannelPositionOpen) {
        stopToMoveTo = self.drawerScrollView.frame.size.height;
    } else {
        stopToMoveTo = 0.0f;
    }
    
    self.isAnimatingDrawerPosition = YES;
    self.currentPosition = position;
    if ([self.drawerContentViewController respondsToSelector:@selector(drawerPositionDidChange:)]) {
        id<AYPannelViewControllerDelegate> delegate = (id<AYPannelViewControllerDelegate>)self.drawerContentViewController;
        [delegate drawerPositionDidChange:self];
    }
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
    
    if (self.shouldScrollDrawerScrollView && getsutre.state == UIGestureRecognizerStateChanged) {
        CGPoint old = [getsutre translationInView:self.drawerScrollView];
        CGPoint p = CGPointMake(0, self.drawerScrollView.frame.size.height - fabs(old.y) - 80);
        [self.drawerScrollView setContentOffset:p];
    } else if (self.shouldScrollDrawerScrollView && getsutre.state == UIGestureRecognizerStateEnded) {
        self.shouldScrollDrawerScrollView = NO;
        CGFloat lowestStop = kAYDefaultCollapsedHeight;
        CGFloat distanceFromBottomOfView = self.drawerScrollView.frame.size.height - lowestStop - [getsutre translationInView:self.drawerScrollView].y;
        
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
            [self setDrawerPosition:AYPannelPositionOpen animated:YES];
        } else if (fabs(currentClosestStop - kAYDefaultCollapsedHeight) <= FLT_EPSILON) {
            //collapsed
            [self setDrawerPosition:AYPannelPositionCollapsed animated:YES];
        } else {
            //partially revealed
            [self setDrawerPosition:AYPannelPositionPartiallyRevealed animated:YES];
        }

    }
}

#pragma mark - AYDrawerScrollViewDelegate

- (void)drawerScrollViewDidScroll:(UIScrollView *)scrollView {
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

@end
