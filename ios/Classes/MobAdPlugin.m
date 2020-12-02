#import "MobAdPlugin.h"
#import <MobADSDK/MobADSDKApi.h>
#import "MobAdBannerPlatformView.h"

@interface MobAdPlugin()<MADRewardVideoAdCallbackDelegate, MADInterstitialAdCallbackDelegate, FlutterStreamHandler>

@property (nonatomic, strong) id<MADRewardVideoAdManagerProtocol> rewardVideoAd;
@property (nonatomic, strong) FlutterResult callback;
@property (nonatomic, weak) NSObject<FlutterPluginRegistrar> *registrar;
@end

@implementation MobAdPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"com.mob.adsdk/method" binaryMessenger:[registrar messenger]];
    MobAdPlugin *instance = [[MobAdPlugin alloc] init];
    instance.registrar = registrar;
    [registrar addMethodCallDelegate:instance channel:channel];

    MobAdBannerPlatformViewFactory *f = [[MobAdBannerPlatformViewFactory alloc] initWithRegistrar:registrar];
    [registrar registerViewFactory:f withId:@"com.mob.adsdk/banner"];
}

- (void)dealloc {
    NSLog(@"ad plugin -> dealloc");
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    
    NSLog(@"ad plugin -> handleMethodCall:%@, args:%@", call.method, call.arguments);
    
    // 建立监听
    NSString *channelId = call.arguments[@"_channelId"];
    if ([channelId isKindOfClass:[NSNumber class]]) {
        NSString *channel = [NSString stringWithFormat:@"com.mob.adsdk/event_%@", channelId];
        FlutterEventChannel *eventChannel = [FlutterEventChannel eventChannelWithName:channel binaryMessenger:[_registrar messenger]];
        [eventChannel setStreamHandler:self];
    }
    
    // 调用方法
    if ([call.method isEqualToString:@"setUserId"]) {
        NSString *uid = call.arguments[@"userId"];
        MobADConfigModel *config = [MobADSDKApi getConfig];
        if ([uid isKindOfClass:[NSString class]] && uid.length) {
            config.userId = uid;
        } else {
            config.userId = nil;
        }
        
    } else if ([call.method isEqualToString:@"showInterstitialAd"]) {
        NSString *groupId = call.arguments[@"unitId"];
        if (![groupId isKindOfClass:[NSString class]] || groupId.length == 0) {
            groupId = @"i1";
        }
        // 加载插屏广告
        [MobADSDKApi showInterstitialAdWithViewController:[[self class] findCurrentShowingViewController] delegate:self group:groupId];
        
    } else if (([call.method isEqualToString:@"showRewardVideoAd"])) {
        NSString *groupId = call.arguments[@"unitId"];
        if (![groupId isKindOfClass:[NSString class]] || groupId.length == 0) {
            groupId = @"rv1";
        }
        // 生成激励视频加载器
        if (!_rewardVideoAd) {
            _rewardVideoAd = [MobADSDKApi rewardVideoAdManager];
        }
        
        // 加载激励视频
        [_rewardVideoAd loadRewardVideoWithViewController:[[self class] findCurrentShowingViewController] delegate:self timeout:10 group:groupId];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (FlutterError* _Nullable)onListenWithArguments:(NSString *_Nullable)arguments
                                       eventSink:(FlutterEventSink)events {
    NSLog(@"ad plugin -> onListen:%@", arguments);
    if (events) {
        self.callback = events;
    }
    
//    if ([arguments isEqualToString:@"rewardVideo"]) {
//        if (events) {
//            self.rvCallback = events;
//        }
//    } else if ([arguments isEqualToString:@"interstitial"]) {
//        if (events) {
//            self.interCallback = events;
//        }
//    }
    
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
    NSLog(@"ad plugin -> onCancelListen:%@", arguments);
    return nil;
}

#pragma mark - ad delegate

- (void)ad_interstitialAdCallbackWithEvent:(MADInterstitialAdCallbackEvent)event error:(NSError *)error andInfo:(NSDictionary *)info {
    
    if (self.callback) {
        NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:info];
        [result setObject:[[self class] intersticial_eventStringWithEvent:event] forKey:@"event"];
        if (error) {
            NSString *msg = error.userInfo[NSLocalizedDescriptionKey]?: @"";
            [result setObject:@(error.code) forKey:@"code"];
            [result setObject:msg forKey:@"message"];
        }
        
        self.callback(result);
        
        if (event == MADInterstitialAdCallbackEventAdLoadError || event == MADInterstitialAdCallbackEventAdDidClose) {
            self.callback(FlutterEndOfEventStream);
            self.callback = nil;
        }
    }
}

- (void)ad_rewardVideoCallbackWithEvent:(MADRewardVideoCallbackEvent)event error:(NSError *)error andInfo:(NSDictionary *)info {
    
    if (self.callback) {
        NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:info];
        [result setObject:[[self class] rewardVideo_eventStringWithEvent:event] forKey:@"event"];
        if (error) {
            NSString *msg = error.userInfo[NSLocalizedDescriptionKey]?: @"";
            [result setObject:@(error.code) forKey:@"code"];
            [result setObject:msg forKey:@"message"];
        }
        
        self.callback(result);
        
        if (event == MADRewardVideoCallbackEventAdLoadError || event == MADRewardVideoCallbackEventAdDidClose) {
            self.callback(FlutterEndOfEventStream);
            self.callback = nil;
        }
    }
}

+ (NSString *)rewardVideo_eventStringWithEvent:(NSInteger)event {
    switch (event) {
        case MADRewardVideoCallbackEventAdLoadSuccess:
            return @"onAdLoad";
            break;
        case MADRewardVideoCallbackEventAdDidLoadVideo:
            return @"onVideoCached";
            break;
        case MADRewardVideoCallbackEventAdWillVisible:
            return @"onAdShow";
            break;
        case MADRewardVideoCallbackEventAdDidClick:
            return @"onAdClick";
            break;
        case MADRewardVideoCallbackEventAdRewardSuccess:
            return @"onReward";
            break;
        case MADRewardVideoCallbackEventAdPlayFinish:
            return @"onVideoComplete";
            break;
        case MADRewardVideoCallbackEventAdDidClose:
            return @"onAdClose";
            break;
        default:
            return @"onError";
            break;
    }
}

+ (NSString *)intersticial_eventStringWithEvent:(NSInteger)event {
    switch (event) {
        case MADInterstitialAdCallbackEventAdLoadSuccess:
            return @"onAdLoad";
            break;
        case MADInterstitialAdCallbackEventAdWillVisible:
            return @"onAdShow";
            break;
        case MADInterstitialAdCallbackEventAdDidClick:
            return @"onAdClick";
            break;
        case MADInterstitialAdCallbackEventAdDidClose:
            return @"onAdClose";
            break;
        default:
            return @"onError";
            break;
    }
}

// 获取当前显示的 UIViewController
+ (UIViewController *)findCurrentShowingViewController {
    //获得当前活动窗口的根视图
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *currentShowingVC = [self findCurrentShowingViewControllerFrom:vc];
    return currentShowingVC;
}

+ (UIViewController *)findCurrentShowingViewControllerFrom:(UIViewController *)vc
{
    // 递归方法 Recursive method
    UIViewController *currentShowingVC;
    if ([vc presentedViewController]) {
        // 当前视图是被presented出来的
        UIViewController *nextRootVC = [vc presentedViewController];
        currentShowingVC = [self findCurrentShowingViewControllerFrom:nextRootVC];

    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        // 根视图为UITabBarController
        UIViewController *nextRootVC = [(UITabBarController *)vc selectedViewController];
        currentShowingVC = [self findCurrentShowingViewControllerFrom:nextRootVC];

    } else if ([vc isKindOfClass:[UINavigationController class]]){
        // 根视图为UINavigationController
        UIViewController *nextRootVC = [(UINavigationController *)vc visibleViewController];
        currentShowingVC = [self findCurrentShowingViewControllerFrom:nextRootVC];

    } else {
        // 根视图为非导航类
        currentShowingVC = vc;
    }

    return currentShowingVC;
}

@end
