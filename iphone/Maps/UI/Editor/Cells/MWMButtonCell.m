#import "MWMButtonCell.h"
#import "SwiftBridge.h"

@interface MWMButtonCell ()

@property(nonatomic) IBOutlet UIButton *button;
@property(weak, nonatomic) id<MWMButtonCellDelegate> delegate;
@property(nonatomic, nullable) MWMVoidBlock action;

@end

@implementation MWMButtonCell

- (void)configureWithDelegate:(id<MWMButtonCellDelegate>)delegate title:(NSString *)title enabled:(BOOL)enabled {
  [self.button setTitle:title forState:UIControlStateNormal];
  self.button.enabled = enabled;
  self.delegate = delegate;
}

- (void)configureWithTitle:(NSString *)title styleName:(NSString *)styleName action:(MWMVoidBlock)action
{
  [self.button setTitle:title forState:UIControlStateNormal];
  self.action = action;
  [self.button addTarget:self action:@selector(buttonTap) forControlEvents:UIControlEventTouchUpInside];
  [self.button setStyleName:styleName];
}

- (IBAction)buttonTap {
  [self.delegate cellDidPressButton:self];
  if (self.action)
    self.action();
}

@end
