#import "MWMTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MWMButtonCellDelegate <NSObject>

- (void)cellDidPressButton:(UITableViewCell *)cell;

@end

@interface MWMButtonCell : MWMTableViewCell

- (void)configureWithDelegate:(id<MWMButtonCellDelegate>)delegate title:(NSString *)title enabled:(BOOL)enabled;
- (void)configureWithTitle:(NSString *)title styleName:(NSString *)styleName action:(MWMVoidBlock _Nullable)action;

@end

NS_ASSUME_NONNULL_END
