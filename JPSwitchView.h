//
//  JPSwitchView.h
//  SwitchTest

#import <UIKit/UIKit.h>

typedef void (^JPSwitchViewDidChangeValueBlock) (BOOL isOn);

@interface JPSwitchView : UIView

@property (nonatomic, readonly) BOOL on;

@property (nonatomic, copy) JPSwitchViewDidChangeValueBlock didChangeValueBlock;

- (id)initWithFrame:(CGRect)frame withBackgroundImage:(UIImage *)backgroundImage withThumbImage:(UIImage *)thumbImage withThumbHighlightImage:(UIImage *)thumbHighlightImage;

- (id)initWithFrame:(CGRect)frame withBackgroundImage:(UIImage *)backgroundImage withThumbImage:(UIImage *)thumbImage withThumbHighlightImage:(UIImage *)thumbHighlightImage withCornerRadius:(CGFloat)cornerRadius;

- (void)setOn:(BOOL)on animated:(BOOL)animated;

@end
