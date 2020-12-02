#import "MobAdBannerPlatformView.h"
#import <MobADSDK/MobADSDK.h>
#import "MobAdPlugin.h"

#pragma mark - PlatformView

@interface MobAdBannerPlatformView()<FlutterStreamHandler, MADBannerAdCallbackDelegate>
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) id<MADBannerAdManagerProtocol> bannerAd;
@property (nonatomic, strong) FlutterResult bannerCallback;

@end

@implementation MobAdBannerPlatformView
- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
                    registrar:(NSObject<FlutterPluginRegistrar> *)registrar
{
    if (self = [super init]) {
        
        // 获取参数
        NSString *unitId;
        CGFloat bannerWidth = 0, bannerHeight = 0;
        if ([args isKindOfClass:[NSDictionary class]]) {
            unitId = args[@"unitId"];
            bannerWidth = [args[@"width"] floatValue];
            bannerHeight = [args[@"height"] floatValue];
        }
        
        if (bannerWidth <= 0.0) {
            bannerWidth = [UIScreen mainScreen].bounds.size.width;
            bannerHeight = bannerWidth /6.4;
        }
        
        if (![unitId isKindOfClass:[NSString class]] || unitId.length == 0) {
            unitId = @"b1";
        }
        
        // 加载banner
        _bannerAd = [MobADSDKApi bannerAdManager];
        [_bannerAd loadBannerAdWithFrame:CGRectMake(0, 0, bannerWidth, bannerHeight) viewController:[MobAdPlugin findCurrentShowingViewController] delegate:self interval:0 group:@"b1"];
        
        // 容器view
        _containerView = [[UIView alloc] initWithFrame:frame];
        _containerView.backgroundColor = [UIColor clearColor];
        
        // 事件通道
        NSString *channelName = [NSString stringWithFormat:@"com.mob.adsdk/banner_event_%lld", viewId];
        FlutterEventChannel *eventChannel = [FlutterEventChannel eventChannelWithName:channelName binaryMessenger:[registrar messenger]];
        [eventChannel setStreamHandler:self];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}

- (nonnull UIView *)view {
    return _containerView;
}

- (FlutterError* _Nullable)onListenWithArguments:(NSString *_Nullable)arguments
                                       eventSink:(FlutterEventSink)events {
    NSLog(@"banner event -> listen");
    if (events) {
        self.bannerCallback = events;
    }
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
    NSLog(@"banner event -> cancel listen");
    return nil;
}

#pragma mark - BannerAdDelegate

- (void)ad_bannerAdView:(UIView<MADBannerAdViewProtocol> *)adView callbackWithEvent:(MADBannerAdCallbackEvent)event error:(NSError *)error andInfo:(NSDictionary *)info {
    NSLog(@"banner ad event:%zd, info:%@, error:%@", event, info, error);
    if (event == MADBannerAdCallbackEventAdLoadSuccess) {
        [self.containerView addSubview:adView];
    } else if (event == MADBannerAdCallbackEventAdDidClose) {
        [_bannerAd removeBannerAd:adView];
        [self.containerView removeFromSuperview];
        self.containerView = nil;
    }
    
    if (self.bannerCallback) {
        NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:info];
        [result setObject:[[self class] eventStringForEvent:event] forKey:@"event"];
        if (error) {
            NSString *msg = error.userInfo[NSLocalizedDescriptionKey]?: @"";
            [result setObject:@(error.code) forKey:@"code"];
            [result setObject:msg forKey:@"message"];
        }
        
        self.bannerCallback(result);
        
        if (event == MADBannerAdCallbackEventAdLoadError || event == MADBannerAdCallbackEventAdDidClose) {
            self.bannerCallback = nil;
        }
    }
}

+ (NSString *)eventStringForEvent:(MADBannerAdCallbackEvent)event {
    switch (event) {
        case MADBannerAdCallbackEventAdLoadSuccess:
            return @"onAdLoad";
            break;
        case MADBannerAdCallbackEventAdLoadError:
            return @"onAdError";
            break;
        case MADBannerAdCallbackEventAdWillVisible:
            return @"onAdShow";
            break;
        case MADBannerAdCallbackEventAdDidClick:
            return @"onAdClick";
            break;
        default:
            return @"onAdClose";
            break;
    }
}

@end

#pragma mark - PlatformViewFactory

@interface MobAdBannerPlatformViewFactory()
@property (nonatomic, strong) NSObject<FlutterPluginRegistrar> *registrar;
@end

@implementation MobAdBannerPlatformViewFactory

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    self = [super init];
    if (self) {
        _registrar = registrar;
    }
    return self;
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args {
    return [[MobAdBannerPlatformView alloc] initWithFrame:frame viewIdentifier:viewId arguments:args registrar:_registrar];
}

@end
