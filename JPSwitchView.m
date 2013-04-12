//
//  JPSwitchView.m
//  SwitchTest

#import "JPSwitchView.h"

#import <QuartzCore/QuartzCore.h>

#define JPSwitchViewMaxDuration 0.2f

@implementation JPSwitchView
{
    UIView *_container;
    UIButton *_transparentButton;
    UIImageView *_thumbImageView;
    UIImageView *_backgroundImageView;
    CGFloat _offX;
    CGFloat _onX;
    CGFloat _maxDistance;
    CGFloat _maxDistanceDuration;
    UIPanGestureRecognizer *_panGestureRecognizer;
    BOOL _isPanning;
}

#pragma mark - initialize

- (id)initWithFrame:(CGRect)frame withBackgroundImage:(UIImage *)backgroundImage withThumbImage:(UIImage *)thumbImage withThumbHighlightImage:(UIImage *)thumbHighlightImage
{
    return [self initWithFrame:frame withBackgroundImage:backgroundImage withThumbImage:thumbImage withThumbHighlightImage:thumbHighlightImage withCornerRadius:0.f];
}

- (id)initWithFrame:(CGRect)frame withBackgroundImage:(UIImage *)backgroundImage withThumbImage:(UIImage *)thumbImage withThumbHighlightImage:(UIImage *)thumbHighlightImage withCornerRadius:(CGFloat)cornerRadius
{
    self = [super initWithFrame:frame];
    
    if (self) {
        
        [self _setupWithBackgroundImage:backgroundImage withThumbImage:thumbImage withThumbHighlightImage:thumbHighlightImage withCornerRadius:cornerRadius];
        
    }
    
    return self;
}

#pragma mark - public

- (void)setOn:(BOOL)on animated:(BOOL)animated
{
    if (_on != on) {
        _on = on;
        if (_didChangeValueBlock) {
            _didChangeValueBlock(_on);
        }
        
        [self _moveWithAnimated:animated];
    }
}

#pragma mark - private

- (void)_setOn:(BOOL)on animated:(BOOL)animated
{
    if (_on != on) {
        _on = on;
        if (_didChangeValueBlock) {
            _didChangeValueBlock(_on);
        }
    }
    
    [self _moveWithAnimated:animated];
}

- (void)_setupWithBackgroundImage:(UIImage *)backgroundImage withThumbImage:(UIImage *)thumbImage withThumbHighlightImage:(UIImage *)thumbHighlightImage withCornerRadius:(CGFloat)cornerRadius
{
    CALayer *layer = self.layer;
    layer.masksToBounds = YES;
    layer.cornerRadius = cornerRadius;
    
    _backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
    _thumbImageView = [[UIImageView alloc] initWithImage:thumbImage highlightedImage:thumbHighlightImage];
    _thumbImageView.center = CGPointMake(CGRectGetMidX(_backgroundImageView.bounds), CGRectGetMidY(_backgroundImageView.bounds));

    _transparentButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_transparentButton addTarget:self action:@selector(_toggle:) forControlEvents:UIControlEventTouchUpInside];
    [_transparentButton addTarget:self action:@selector(_thumbHighlight) forControlEvents:UIControlEventTouchDown];
    [_transparentButton addTarget:self action:@selector(_thumbDehighlight) forControlEvents:UIControlEventTouchUpInside];
    [_transparentButton addTarget:self action:@selector(_thumbDehighlight) forControlEvents:UIControlEventTouchUpOutside];
    [_transparentButton addTarget:self action:@selector(_thumbDehighlight) forControlEvents:UIControlEventTouchCancel];
    [_transparentButton addTarget:self action:@selector(_thumbDehighlight) forControlEvents:UIControlEventTouchDragExit];
    
    _transparentButton.frame = _backgroundImageView.frame;
    _container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(_backgroundImageView.bounds), CGRectGetHeight(_backgroundImageView.bounds))];
    
    _offX = CGRectGetMinX(self.bounds);
    _onX = CGRectGetMaxX(self.bounds);
    
    _maxDistance = CGRectGetWidth(self.bounds) - CGRectGetWidth(_thumbImageView.bounds);
    _maxDistanceDuration = JPSwitchViewMaxDuration;
    
    [_container addSubview:_backgroundImageView];
    [_container addSubview:_thumbImageView];
    [_container addSubview:_transparentButton];
    
    [self addSubview:_container];
    
    [self _moveToOff:self.on];
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_paned:)];
    [self addGestureRecognizer:_panGestureRecognizer];
}

- (void)_moveWithAnimated:(BOOL)animated
{
    if (self.on)
    {
        [self _moveToOn:animated];
    }else
    {
        [self _moveToOff:animated];
    }
}

- (void)_moveToOn:(BOOL)animated
{
    CGRect frame = CGRectMake(_onX - CGRectGetMaxX(_thumbImageView.frame), CGRectGetMinY(_container.frame), CGRectGetWidth(_container.bounds), CGRectGetHeight(_container.bounds));
    [self _moveToFrame:frame animated:animated];
}

- (void)_moveToOff:(BOOL)animated
{
    CGRect frame = CGRectMake(_offX - CGRectGetMinX(_thumbImageView.frame), CGRectGetMinY(_container.frame), CGRectGetWidth(_container.bounds), CGRectGetHeight(_container.bounds));
    [self _moveToFrame:frame animated:animated];
}

- (void)_moveToFrame:(CGRect)frame animated:(BOOL)animated
{
    self.userInteractionEnabled = NO;
    
    if (animated)
    {
        __weak typeof(self) weakSelf = self;
        __weak typeof(_container) weakContainer = _container;
        
        CGFloat currentMinX = CGRectGetMinX(_container.frame);
        CGFloat targetMinX = CGRectGetMinX(frame);
        CGFloat moveDistance = (currentMinX > targetMinX) ? currentMinX - targetMinX : targetMinX - currentMinX;
        CGFloat timeRatio = moveDistance / _maxDistance;
        CGFloat duration = _maxDistanceDuration * timeRatio;
        
        [UIView animateWithDuration:duration delay:0 options:0
                         animations:^{
                             weakContainer.frame = frame;
                         }
                         completion:^(BOOL finished) {
                             weakSelf.userInteractionEnabled = YES;
                         }];
    }else
    {
        _container.frame = frame;
        self.userInteractionEnabled = YES;
    }
}

- (void)_paned:(UIPanGestureRecognizer *)aRecognizer
{
    switch (aRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            [self _thumbHighlight];
            _isPanning = YES;
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint point = [aRecognizer translationInView:self];
            CGRect nextThumbFrame = CGRectOffset(_thumbImageView.frame, point.x, 0.f);
            CGRect convertedThumbFrame = [self convertRect:nextThumbFrame fromView:_container];
            CGFloat nextThumbMinX = CGRectGetMinX(convertedThumbFrame);
            CGFloat nextThumbMaxX = CGRectGetMaxX(convertedThumbFrame);
            if (nextThumbMinX >= _offX && nextThumbMaxX <= _onX)
            {
                _container.frame = CGRectOffset(_container.frame, point.x, 0.f);
            }
            [aRecognizer setTranslation:CGPointZero inView:self];
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            _isPanning = NO;
            [self _didEndPan];
            [self _thumbDehighlight];
        }
            break;
        default:
            break;
    }
}

- (void)_didEndPan
{
    CGRect convertedThumbFrame = [self convertRect:_thumbImageView.frame fromView:_container];
    CGFloat thumbMinX = CGRectGetMinX(convertedThumbFrame);
    CGFloat thumbMaxX = CGRectGetMaxX(convertedThumbFrame);
    CGFloat diffToOff = thumbMinX;
    CGFloat diffToOn = CGRectGetMaxX(self.bounds) - thumbMaxX;
    if (diffToOff > diffToOn)
    {
        [self _setOn:YES animated:YES];
    }else
    {
        [self _setOn:NO animated:YES];
    }
}

#pragma mark - UIActions

- (void)_toggle:(id)sender
{
    [self setOn:!self.on animated:YES];
}

- (void)_thumbHighlight
{
    if (!_isPanning) {
        _thumbImageView.highlighted = YES;
    }
}

- (void)_thumbDehighlight
{
    if (!_isPanning) {
        _thumbImageView.highlighted = NO;
    }
}

@end
