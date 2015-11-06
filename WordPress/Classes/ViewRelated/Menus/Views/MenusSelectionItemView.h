#import <UIKit/UIKit.h>

@class Menu;
@class MenuLocation;

@interface MenusSelectionViewItem : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *details;
@property (nonatomic, copy) NSString *iconSourceFileName;
@property (nonatomic, strong) id itemObject;
@property (nonatomic, assign) BOOL selectedItem;

+ (MenusSelectionViewItem *)itemWithMenu:(Menu *)menu;
+ (MenusSelectionViewItem *)itemWithLocation:(MenuLocation *)location;

@end

@interface MenusSelectionItemView : UIView

@property (nonatomic, strong) MenusSelectionViewItem *item;
@property (nonatomic, assign) BOOL drawsDesignStrokeBottom;

@end
