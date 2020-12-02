#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

#import <MobADSDK/MobADSDK.h>
#import "SplashLogoView.h"
#import "LaunchPlaceHolder.h"

#import "MobAdPlugin.h"

@interface AppDelegate ()<MADSplashAdCallbackDelegate>
@property (nonatomic, strong) UIView *splashView;
@end

@implementation AppDelegate

- (NSObject<FlutterPluginRegistrar>*)registrarForPlugin:(NSString*)pluginKey {
    UIViewController* rootViewController = self.window.rootViewController;
  if ([rootViewController isKindOfClass:[FlutterViewController class]]) {
    return [[(FlutterViewController*)rootViewController pluginRegistry] registrarForPlugin:pluginKey];
  } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
     FlutterViewController *flutterVC = [rootViewController.childViewControllers firstObject];
      if ([flutterVC isKindOfClass:[FlutterViewController class]]) {
        return [[flutterVC pluginRegistry] registrarForPlugin:pluginKey];
      }
  }
  return nil;
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    FlutterViewController *vc = [[FlutterViewController alloc] init];
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:vc];
    navi.navigationBarHidden = YES;
    UIWindow *window = [[UIWindow alloc] init];
    window.rootViewController = navi;
    self.window = window;

    
    // 初始化广告SDK
    [self setupMobADSDK];
    // 显示开屏
    [self showSplashAd:YES];

    // 注册 flutter 插件
    [GeneratedPluginRegistrant registerWithRegistry:self];

    [self.window makeKeyAndVisible];

    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

// 从后台进入App可重新展示开屏
- (void)applicationWillEnterForeground:(UIApplication *)application {
    double last = [[NSUserDefaults standardUserDefaults] doubleForKey:@"AppLastSplashShownTimestamp"];
    double ts = [[NSDate date] timeIntervalSince1970];
    double delt = ts - last;
    
    NSLog(@"splash -> interval:%lf", delt);

    NSInteger interval = 3 * 60;// 3分钟间隔展示开屏
    if (interval <= 0) {
        return;
    }
    
    if (delt >= interval) {
        NSLog(@"splash -> should show");
        [self showSplashAd:NO];
    }
}

#pragma mark - 广告SDK

// 初始化广告SDK
- (void)setupMobADSDK {
    
    // 创建初始化配置实例
    MobADConfigModel *config = [[MobADConfigModel alloc] init];
    
    // 渠道id，必填(由我司分配），下面的是测试用
    config.appId = @"ba0063bfbc1a5ad878";
    // SDK接入方的用户id（如果已登录）
    //config.userId = @"userId";
    
    // 初始化SDK
    BOOL result = [MobADSDKApi setupWithConfig:config];
    
    NSLog(@"MobADSDK setup success:%d", result);
    NSLog(@"MobADSDK version:%@", [MobADSDKApi sdkVersion]);
}

// 调用开屏广告
- (void)showSplashAd:(BOOL)isLaunch {
    
    // 开屏占位视图(加载开屏广告时的占位视图)
    LaunchPlaceHolder *placeHolder = [LaunchPlaceHolder loadViewFromXib];
    placeHolder.frame = self.window.bounds;
    
    // 开屏自定义logo视图(显示在开屏广告底部)
    SplashLogoView *logoView = [SplashLogoView loadViewFromXib];
    logoView.frame = CGRectMake(0, 0, self.window.bounds.size.width, floor(self.window.bounds.size.height/4.0));
    
    // 加载开屏
    self.splashView = [MobADSDKApi splashAdViewFromWindow:self.window delegate:self placeHolder:placeHolder customView:logoView timeout:3 isLaunch:YES group:@"s1"];
}

// 开屏广告回调
- (void)ad_splashAdCallbackWithEvent:(MADSplashAdCallbackEvent)event error:(NSError *)error andInfo:(NSDictionary *)info {
    NSLog(@"splash event:%zd, error:%@, info:%@", event, error, info);
    
    if (event == MADSplashAdCallbackEventAdLoadSuccess) {
        // 保存上次开屏时间
        double ts = [[NSDate date] timeIntervalSince1970];
        NSLog(@"splash -> save ts:%lf", ts);
        [[NSUserDefaults standardUserDefaults] setDouble:ts forKey:@"AppLastSplashShownTimestamp"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // 移除开屏
    if (event == MADSplashAdCallbackEventAdDidClose) {
        [self.splashView removeFromSuperview];
        self.splashView = nil;
    }
}

@end
