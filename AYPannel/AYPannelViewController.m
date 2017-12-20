//
//  XPannelViewController.m
//  XPannel
//
//  Created by anyuan on 11/12/2017.
//  Copyright © 2017 anyuan. All rights reserved.
//

#import "AYPannelViewController.h"
#import "AYPassthroughScrollView.h"

static CGFloat kAYDefaultCollapsedHeight = 68.0f; //默认收起大小
static CGFloat kAYDefaultPartialRevealHeight = 264.0f; //默认部分展开大小

static CGFloat kAYTopInset = 20.0f;
static CGFloat kAYBounceOverflowMargin = 20.0f;
static CGFloat kAYDefaultDimmingOpacity = 0.5f;

static CGFloat kAYDefaultShadowOpacity = 0.1f;
static CGFloat kAYDefaultShadowRadius = 3.0f;

static CGFloat kAYPannelSnapModeUnlessExceededThreshold = 20.0f;

typedef NS_ENUM(NSUInteger, AYPannelSnapMode) {
    AYPannelSnapModeNearestPosition,
    AYPannelSnapModeUnlessExceeded,
};


@interface AYPannelViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate, AYPassthroughScrollViewDelegate>
@property (nonatomic, assign) CGPoint lastDragTargetContentOffSet; //记录上次滑动位置
@property (nonatomic, assign) BOOL isAnimatingDrawerPosition;

@property (nonatomic, strong) UIPanGestureRecognizer *pan; //滑动手势
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer; //点击手势，用于蒙层点击

@property (nonatomic, strong) UIView *primaryContentContainer; //主要内容容器视图
@property (nonatomic, strong) UIView *drawerContentContainer; //抽屉内容容器视图
@property (nonatomic, strong) AYPassthroughScrollView *drawerScrollView; //抽屉滚动视图
@property (nonatomic, strong) UIView *drawerShadowView; //阴影

@property (nonatomic, strong) UIVisualEffectView *drawerBackgroundVisualEffectView; //毛玻璃效果

@property (nonatomic, strong) UIView *backgroundDimmingView; //黑色蒙层

@property (nonatomic, strong) id <AYPannelPrimaryDelegate>primaryContentViewController; //主视图VC
@property (nonatomic, strong) id <AYPannelDrawerDelegate>drawerContentViewController; //抽屉视图VC

@property (nonatomic, strong) NSSet <NSNumber *> *supportedPostions;
@end

@implementation AYPannelViewController

- (instancetype)initWithPrimaryContentViewController:(id<AYPannelPrimaryDelegate>)primaryContentViewController drawerContentViewController:(id<AYPannelDrawerDelegate>)drawerContentViewController {
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
    
    [self.drawerScrollView addSubview:self.drawerShadowView];
    
    if (self.drawerBackgroundVisualEffectView) {
        [self.drawerScrollView insertSubview:self.drawerBackgroundVisualEffectView aboveSubview:self.drawerShadowView];
        self.drawerBackgroundVisualEffectView.layer.cornerRadius = [self p_cornerRadius];
    }
    
    [self.drawerScrollView addSubview:self.drawerContentContainer];
    
    self.drawerScrollView.showsVerticalScrollIndicator = NO;
    self.drawerScrollView.showsHorizontalScrollIndicator = NO;
    self.drawerScrollView.bounces = NO;
    self.drawerScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.drawerScrollView.touchDelegate = self;
    
    self.drawerShadowView.layer.shadowOpacity = kAYDefaultShadowOpacity;
    self.drawerShadowView.layer.shadowRadius = kAYDefaultShadowRadius;
    self.drawerShadowView.backgroundColor = [UIColor clearColor];
    
    
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
    NSMutableArray <NSNumber *> *drawerStops = [[NSMutableArray alloc] init];
    
    if ([self.supportedPostions containsObject:@(AYPannelPositionCollapsed)]) {
        [drawerStops addObject:@([self collapsedHeight])];
    }
    
    if ([self.supportedPostions containsObject:@(AYPannelPositionPartiallyRevealed)]) {
        [drawerStops addObject:@([self partialRevealDrawerHeight])];
    }
    
    if ([self.supportedPostions containsObject:@(AYPannelPositionOpen)]) {
        [drawerStops addObject:@(self.drawerScrollView.bounds.size.height)];
    }
    
    CGFloat lowestStop = [[drawerStops valueForKeyPath:@"@min.floatValue"] floatValue];
    
    if ([self.supportedPostions containsObject:@(AYPannelPositionOpen)]) {
        self.drawerScrollView.frame = CGRectMake(0, kAYTopInset + safeAreaTopInset, self.view.bounds.size.width, self.view.bounds.size.height - kAYTopInset - safeAreaTopInset);
    } else {
        CGFloat adjustedTopInset = [self.supportedPostions containsObject:@(AYPannelPositionPartiallyRevealed)] ? [self partialRevealDrawerHeight] : [self collapsedHeight];
        self.drawerScrollView.frame = CGRectMake(0, self.view.bounds.size.height - adjustedTopInset, self.view.bounds.size.width, adjustedTopInset);
    }
    
    
    self.drawerContentContainer.frame = CGRectMake(0, self.drawerScrollView.bounds.size.height - lowestStop, self.drawerScrollView.bounds.size.width, self.drawerScrollView.bounds.size.height + kAYBounceOverflowMargin);
    
    if (self.drawerBackgroundVisualEffectView) {
        self.drawerBackgroundVisualEffectView.frame = self.drawerContentContainer.frame;
    }
    
    self.drawerShadowView.frame = self.drawerContentContainer.frame;
    
    self.drawerScrollView.contentSize = CGSizeMake(self.drawerScrollView.bounds.size.width, (self.drawerScrollView.bounds.size.height - lowestStop) + self.drawerScrollView.bounds.size.height - safeAreaBottomInset);
    
    
    self.backgroundDimmingView.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height + self.drawerScrollView.contentSize.height);
    
    if ([self p_needsCornerRadius]) {
        CGFloat cornerRadius = [self p_cornerRadius];
        CGPathRef path = [UIBezierPath bezierPathWithRoundedRect:self.drawerContentContainer.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(cornerRadius, cornerRadius)].CGPath;
        
        CAShapeLayer *layer = [[CAShapeLayer alloc] init];
        layer.path = path;
        layer.frame = self.drawerContentContainer.bounds;
        layer.fillColor = [UIColor whiteColor].CGColor;
        layer.backgroundColor = [UIColor clearColor].CGColor;
        self.drawerContentContainer.layer.mask = layer;
        self.drawerShadowView.layer.shadowPath = path;
        
        self.drawerScrollView.transform = CGAffineTransformIdentity;
        self.drawerContentContainer.transform = self.drawerScrollView.transform;
        self.drawerShadowView.transform = self.drawerScrollView.transform;
        
        [self p_maskBackgroundDimmingView];
    }
    
    
    [self.backgroundDimmingView setHidden:NO];
    
    
    [self p_setDrawerPosition:AYPannelPositionCollapsed animated:NO];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    
    if (scrollView != self.drawerScrollView) { return; }
    
    NSMutableArray <NSNumber *> *drawerStops = [[NSMutableArray alloc] init];
    
    if ([self.supportedPostions containsObject:@(AYPannelPositionCollapsed)]) {
        [drawerStops addObject:@([self collapsedHeight])];
    }
    
    if ([self.supportedPostions containsObject:@(AYPannelPositionPartiallyRevealed)]) {
        [drawerStops addObject:@([self partialRevealDrawerHeight])];
    }
    
    if ([self.supportedPostions containsObject:@(AYPannelPositionOpen)]) {
        [drawerStops addObject:@(self.drawerScrollView.bounds.size.height)];
    }
    
    CGFloat lowestStop = [[drawerStops valueForKeyPath:@"@min.floatValue"] floatValue];
    
    
    if ([self.drawerContentViewController respondsToSelector:@selector(drawerDraggingProgress:)]) {
        
        CGFloat safeAreaTopInset;
        
        if (@available(iOS 11.0, *)) {
            safeAreaTopInset = self.view.safeAreaInsets.top;
        } else {
            safeAreaTopInset = self.topLayoutGuide.length;
        }
        
        CGFloat spaceToDrag = self.drawerScrollView.bounds.size.height - safeAreaTopInset - lowestStop;
        
        CGFloat dragProgress = fabs(scrollView.contentOffset.y) / spaceToDrag;
        if (dragProgress - 1 > FLT_EPSILON) { //in case greater than 1
            dragProgress = 1.0f;
        }
        NSString *p = [NSString stringWithFormat:@"%.2f", dragProgress];
        [self.drawerContentViewController drawerDraggingProgress:p.floatValue];
    }
    
    //蒙层颜色变化
    if ((scrollView.contentOffset.y - [self p_bottomSafeArea]) > ([self partialRevealDrawerHeight] - lowestStop)) {
        CGFloat progress;
        CGFloat fullRevealHeight = self.drawerScrollView.bounds.size.height;
        
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
    
    self.backgroundDimmingView.frame = [self p_backgroundDimmingViewFrameForDrawerPosition:scrollView.contentOffset.y + lowestStop];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView == self.drawerScrollView) {
        
        [self p_setDrawerPosition:[self p_postionToMoveFromPostion:self.currentPosition lastDragTargetContentOffSet:self.lastDragTargetContentOffSet scrollView:self.drawerScrollView supportedPosition:self.supportedPostions] animated:YES];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView == self.drawerScrollView) {
        self.lastDragTargetContentOffSet = CGPointMake(targetContentOffset->x, targetContentOffset->y);
        *targetContentOffset = scrollView.contentOffset;
    }
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
        
        [self p_setDrawerPosition:[self p_postionToMoveFromPostion:self.currentPosition lastDragTargetContentOffSet:self.lastDragTargetContentOffSet scrollView:self.drawerScrollView supportedPosition:self.supportedPostions] animated:YES];
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
    if (self.currentPosition == AYPannelPositionOpen && self.backgroundDimmingView) {
        return self.backgroundDimmingView;
    }
    return self.primaryContentContainer;
}


#pragma mark - Getter and Setter
- (void)setPrimaryContentViewController:(id<AYPannelPrimaryDelegate>)primaryContentViewController {
    
    if (!primaryContentViewController) { return; }
    _primaryContentViewController = primaryContentViewController;
}

- (void)setDrawerContentViewController:(id<AYPannelDrawerDelegate>)drawerContentViewController {
    if (!drawerContentViewController) { return; }
    _drawerContentViewController = drawerContentViewController;
}

- (UIView *)drawerContentContainer {
    if (!_drawerContentContainer) {
        _drawerContentContainer = [[UIView alloc] initWithFrame:self.view.bounds];
        _drawerContentContainer.backgroundColor = [UIColor clearColor];
    }
    return _drawerContentContainer;
}

- (UIView *)drawerShadowView {
    if (!_drawerShadowView) {
        _drawerShadowView = [[UIView alloc] init];
    }
    return _drawerShadowView;
}

- (UIView *)primaryContentContainer {
    if (!_primaryContentContainer) {
        _primaryContentContainer = [[UIView alloc] initWithFrame:self.view.bounds];
        _primaryContentContainer.backgroundColor = [UIColor clearColor];
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
        if ([self.drawerContentViewController respondsToSelector:@selector(backgroundDimmingView)]) {
            _backgroundDimmingView = [self.drawerContentViewController backgroundDimmingView];
        }
        [_backgroundDimmingView setUserInteractionEnabled:NO];
        _backgroundDimmingView.alpha = 0.0;
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_dimmingTapGestureRecognizer:)];
        [_backgroundDimmingView addGestureRecognizer:_tapGestureRecognizer];
    }
    return _backgroundDimmingView;
}

- (UIVisualEffectView *)drawerBackgroundVisualEffectView {
    if (!_drawerBackgroundVisualEffectView) {
        if ([self.drawerContentViewController respondsToSelector:@selector(drawerBackgroundVisualEffectView)]) {
            _drawerBackgroundVisualEffectView = [self.drawerContentViewController drawerBackgroundVisualEffectView];
        }
    }
    return _drawerBackgroundVisualEffectView;
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

- (void)setCurrentPosition:(AYPannelPosition)currentPosition {
    _currentPosition = currentPosition;
    //通知外部位置变化
    [_drawerContentViewController drawerPositionDidChange:self];
}

- (NSSet<NSNumber *> *)supportedPostions {
    if (!_supportedPostions) {
        if ([_drawerContentViewController respondsToSelector:@selector(supportPannelPosition)]) {
            _supportedPostions = [_drawerContentViewController supportPannelPosition];
        }
        if (!_supportedPostions) { //外层未返回，使用默认
            NSArray *array = @[@(AYPannelPositionOpen), @(AYPannelPositionClosed), @(AYPannelPositionCollapsed), @(AYPannelPositionPartiallyRevealed)];
            _supportedPostions = [NSSet setWithArray:array];
        }
    }
    return _supportedPostions;
}

#pragma mark - Private Mehtods

- (void)p_maskBackgroundDimmingView {
    
    if (!self.backgroundDimmingView) { return; }
    
    CGFloat cornerRadius = [self p_cornerRadius];
    CGFloat cutoutHeight = 2 * cornerRadius;
    CGFloat maskHeight = self.backgroundDimmingView.bounds.size.height - cutoutHeight - self.drawerScrollView.contentSize.height;
    CGFloat maskWidth = self.backgroundDimmingView.bounds.size.width;
    CGRect drawerRect = CGRectMake(0, maskHeight, maskWidth, self.drawerContentContainer.bounds.size.height);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:drawerRect byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    
    [path appendPath:[UIBezierPath bezierPathWithRect:self.backgroundDimmingView.bounds]];
    [layer setFillRule:kCAFillRuleEvenOdd];
    
    layer.path = path.CGPath;
    self.backgroundDimmingView.layer.mask = layer;
}

- (CGFloat)p_bottomSafeArea {
    CGFloat safeAreaBottomInset;
    if (@available(iOS 11.0, *)) {
        safeAreaBottomInset = self.view.safeAreaInsets.bottom;
    } else {
        safeAreaBottomInset = self.bottomLayoutGuide.length;
    }
    return safeAreaBottomInset;
}

- (void)p_dimmingTapGestureRecognizer:(UITapGestureRecognizer *)tapGesture {
    if (tapGesture == self.tapGestureRecognizer) {
        if (self.tapGestureRecognizer.state == UIGestureRecognizerStateEnded) {
            [self p_setDrawerPosition:AYPannelPositionCollapsed animated:YES];
        }
    }
}

- (CGRect)p_backgroundDimmingViewFrameForDrawerPosition:(CGFloat)position {
    
    CGFloat cutoutHeight = 2 * [self p_cornerRadius];
    CGRect backgroundDimmingViewFrame = self.backgroundDimmingView.frame;
    backgroundDimmingViewFrame.origin.y = 0 - position + cutoutHeight;
    return backgroundDimmingViewFrame;
}

- (AYPannelPosition)p_postionToMoveFromPostion:(AYPannelPosition)currentPosition
                   lastDragTargetContentOffSet:(CGPoint)lastDragTargetContentOffSet
                                    scrollView:(UIScrollView *)scrollView
                             supportedPosition:(NSSet <NSNumber *> *)supportedPosition {
    
    AYPannelPosition positionToMove;
    
    NSMutableArray <NSNumber *> *drawerStops = [[NSMutableArray alloc] init];
    CGFloat currentDrawerPositionStop = 0.0f;
    
    if ([supportedPosition containsObject:@(AYPannelPositionCollapsed)]) {
        CGFloat collapsedHeight = [self collapsedHeight];
        [drawerStops addObject:@(collapsedHeight)];
        if (currentPosition == AYPannelPositionCollapsed) {
            currentDrawerPositionStop = collapsedHeight;
        }
    }
    
    if ([supportedPosition containsObject:@(AYPannelPositionPartiallyRevealed)]) {
        CGFloat partialHeight = [self partialRevealDrawerHeight];
        [drawerStops addObject:@(partialHeight)];
        if (currentPosition == AYPannelPositionPartiallyRevealed) {
            currentDrawerPositionStop = partialHeight;
        }
    }
    
    if ([supportedPosition containsObject:@(AYPannelPositionOpen)]) {
        CGFloat openHeight = scrollView.bounds.size.height;
        [drawerStops addObject:@(openHeight)];
        if (currentPosition == AYPannelPositionOpen) {
            currentDrawerPositionStop = openHeight;
        }
    }
    
    //取最小值
    CGFloat lowestStop = [[drawerStops valueForKeyPath:@"@min.floatValue"] floatValue];
    CGFloat distanceFromBottomOfView = lowestStop + lastDragTargetContentOffSet.y;
    CGFloat currentClosestStop = lowestStop;
    
    AYPannelPosition cloestValidDrawerPosition = currentPosition;
    
    for (NSNumber *currentStop in drawerStops) {
        if (fabs(currentStop.floatValue - distanceFromBottomOfView) < fabs(currentClosestStop - distanceFromBottomOfView)) {
            currentClosestStop = currentStop.integerValue;
        }
    }
    
    if (fabs(currentClosestStop - (scrollView.frame.size.height)) <= FLT_EPSILON &&
        [supportedPosition containsObject:@(AYPannelPositionOpen)]) {
        
        cloestValidDrawerPosition = AYPannelPositionOpen;
        
    } else if (fabs(currentClosestStop - [self collapsedHeight]) <= FLT_EPSILON &&
               [supportedPosition containsObject:@(AYPannelPositionCollapsed)]) {
        
        cloestValidDrawerPosition = AYPannelPositionCollapsed;
        
    } else if ([supportedPosition containsObject:@(AYPannelPositionPartiallyRevealed)]){
        
        cloestValidDrawerPosition = AYPannelPositionPartiallyRevealed;
        
    }
    
    AYPannelSnapMode snapToUse = cloestValidDrawerPosition == currentPosition ? AYPannelSnapModeUnlessExceeded : AYPannelSnapModeNearestPosition;
    
    switch (snapToUse) {
        case AYPannelSnapModeNearestPosition: {
            positionToMove = cloestValidDrawerPosition;
        }
            break;
        case AYPannelSnapModeUnlessExceeded: {
            CGFloat distance = currentDrawerPositionStop - distanceFromBottomOfView;
            AYPannelPosition positionToSnapTo = currentPosition;
            if (fabs(distance) > kAYPannelSnapModeUnlessExceededThreshold) {
                if (distance < 0) {
                    NSArray <NSNumber *> *sorted = [[supportedPosition allObjects] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                        return [obj1 integerValue] < [obj2 integerValue];
                    }];
                    
                    for (NSNumber *n in sorted) {
                        if (n.integerValue != AYPannelPositionClosed && n.integerValue > self.currentPosition) {
                            positionToSnapTo = (AYPannelPosition)n.integerValue;
                            break;
                        }
                    }
                } else {
                    NSArray <NSNumber *> *sorted = [[supportedPosition allObjects] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                        return [obj1 integerValue] > [obj2 integerValue];
                    }];
                    
                    for (NSNumber *n in sorted) {
                        if (n.integerValue != AYPannelPositionClosed && n.integerValue < self.currentPosition) {
                            positionToSnapTo = (AYPannelPosition)n.integerValue;
                            break;
                        }
                    }
                }
            }
            positionToMove = positionToSnapTo;
        }
            break;
    }
    
    return positionToMove;
}

- (void)p_setDrawerPosition:(AYPannelPosition)position
                   animated:(BOOL)animated {
    
    if (![self.supportedPostions containsObject:@(position)]) {
        return;
    }
    
    CGFloat stopToMoveTo;
    CGFloat lowestStop = [self collapsedHeight];
    if (position == AYPannelPositionCollapsed) {
        stopToMoveTo = lowestStop;
    } else if (position == AYPannelPositionPartiallyRevealed) {
        stopToMoveTo = [self partialRevealDrawerHeight];
    } else if (position == AYPannelPositionOpen) {
        if (self.backgroundDimmingView) {
            stopToMoveTo = self.drawerScrollView.frame.size.height;
        } else {
            stopToMoveTo = self.drawerScrollView.frame.size.height - kAYDefaultShadowRadius;
        }
    } else { //close
        stopToMoveTo = 0.0f;
    }
    
    self.isAnimatingDrawerPosition = YES;
    self.currentPosition = position;
    
    __weak typeof (self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.75 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [weakSelf.drawerScrollView setContentOffset:CGPointMake(0, stopToMoveTo - lowestStop) animated:NO];
        
        if (weakSelf.backgroundDimmingView) {
            weakSelf.backgroundDimmingView.frame = [weakSelf p_backgroundDimmingViewFrameForDrawerPosition:stopToMoveTo];
        }
        
    } completion:^(BOOL finished) {
        weakSelf.isAnimatingDrawerPosition = NO;
    }];
}

- (BOOL)p_needsCornerRadius {
    return [self p_cornerRadius] > FLT_EPSILON;
}

- (CGFloat)p_cornerRadius {
    if ([self.drawerContentViewController respondsToSelector:@selector(drawerCornerRadius)]) {
        return [self.drawerContentViewController drawerCornerRadius];
    }
    return 0.0f;
}



@end

