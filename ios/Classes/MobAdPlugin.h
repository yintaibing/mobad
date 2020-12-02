#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface MobAdPlugin : NSObject<FlutterPlugin>
+ (UIViewController *)findCurrentShowingViewController;
@end

NS_ASSUME_NONNULL_END
