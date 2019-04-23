//
//  ZLAlicloudPushManager.m
//  Pods-ZLAlicloudPushManager_Example
//
//  Created by 刘聪 on 2019/4/23.
//

#import "ZLAlicloudPushManager.h"
#import <CloudPushSDK/CloudPushSDK.h>

@interface ZLAlicloudPushManager ()<UNUserNotificationCenterDelegate>

@end

@implementation ZLAlicloudPushManager


+ (ZLAlicloudPushManager *)shareInstanted {
    static ZLAlicloudPushManager *instanted;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instanted = [[ZLAlicloudPushManager alloc] init];
    });
    return instanted;
}

#pragma mark APNs Register
/**
 *    向APNs注册，获取deviceToken用于推送
 *
 *    @param application description of param here removes warning
 */
-(void)zl_registerAPNS:(UIApplication * )application notificationCenter:(UNUserNotificationCenter *)nc
API_AVAILABLE(ios(10.0)){
    float systemVersionNum = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (systemVersionNum >= 10.0) {
        // iOS 10 notifications
        if (@available(iOS 10.0, *)) {
            nc = [UNUserNotificationCenter currentNotificationCenter];
        } else {
            // Fallback on earlier versions
        }
        // 创建category，并注册到通知中心
        [self createCustomNotificationCategoryWithNotificationCenter:nc];
        nc.delegate = self;
        // 请求推送权限
        if (@available(iOS 10.0, *)) {
            [nc requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if (granted) {
                    // granted
                    NSLog(@"zl_: User authored notification.");
                    // 向APNs注册，获取deviceToken
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [application registerForRemoteNotifications];
                    });
                } else {
                    // not granted
                    NSLog(@"zl_: User denied notification.");
                }
            }];
        } else {
            // Fallback on earlier versions
        }
    }
}

-(void)zl_RegistereISOLessThan10APNS:(UIApplication * ) application
{
    float systemVersionNum = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (systemVersionNum >= 8.0) {
        // iOS 8 Notifications
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        [application registerUserNotificationSettings:
         [UIUserNotificationSettings settingsForTypes:
          (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge)
                                           categories:nil]];
        [application registerForRemoteNotifications];
#pragma clang diagnostic pop
    } else {
        // iOS < 8 Notifications
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
#pragma clang diagnostic pop
    }
}
/*
 *  APNs注册成功回调，将返回的deviceToken上传到CloudPush服务器。 用在 UIApplicationDelegate: didRegisterForRemoteNotificationsWithDeviceToken里面
 */
-(void)zl_RegisterDevice:(NSData *)deviceToken
{
    [CloudPushSDK registerDevice:deviceToken withCallback:^(CloudPushCallbackResult *res) {
        if (res.success) {
            NSLog(@"zl_: Register deviceToken success, deviceToken: %@", [CloudPushSDK getApnsDeviceToken]);
        } else {
            NSLog(@"zl_: Register deviceToken failed, error: %@", res.error);
        }
    }];
}

#pragma mark SDK Init
-(NSString *)zl_InitCloudPushWithAppKey:(NSString *)appKey withAppSecret:(NSString *)appSecret
{
    static NSString * returnValue = @"";
    [CloudPushSDK asyncInit:appKey appSecret:appSecret callback:^(CloudPushCallbackResult *res) {
        if (res.success) {
            NSLog(@"zl_: Push SDK init success, deviceId: %@.", [CloudPushSDK getDeviceId]);
            returnValue = [CloudPushSDK getDeviceId];
        } else {
            NSLog(@"zl_: Push SDK init failed, error: %@", res.error);
            returnValue = @"";
        }
    }];
    return returnValue;
}
-(void)zl_ListenerOnChannelOpened
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onChannelOpened:)
                                                 name:@"CCPDidChannelConnectedSuccess"
                                               object:nil];
}
/**
 *    推送通道打开回调
 *
 *    @param notification description of param here removes warning
 */
- (void)onChannelOpened:(NSNotification *)notification {
    NSLog(@"zl_: 温馨提示: 消息通道建立成功");
}

#pragma mark Receive Message
/**
 *    @brief    注册推送消息到来监听
 */
-(void)zl_RegisterMessageReceive
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMessageReceived:)
                                                 name:@"CCPDidReceiveMessageNotification"
                                               object:nil];
}

/**
 *    处理到来推送消息
 *
 *    @param notification description of param here removes warning
 */
- (void)onMessageReceived:(NSNotification *)notification {
    NSLog(@"zl_: Receive one message!");
    CCPSysMessage *message = [notification object];
    NSString *title = [[NSString alloc] initWithData:message.title encoding:NSUTF8StringEncoding];
    NSString *body = [[NSString alloc] initWithData:message.body encoding:NSUTF8StringEncoding];
    //NSLog(@"TEST: Receive message title: %@, content: %@.", title, body);
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    if(title)
        [dic setObject:title forKey:@"title"];
    if(body)
        [dic setObject:body forKey:@"body"];
}
// 点击通知将App从关闭状态启动时，将通知打开回执上报
- (void)zl_SendNotificationAck:(NSDictionary *)launchOptions {
    [CloudPushSDK sendNotificationAck:launchOptions];
}
/**
 *  创建并注册通知category(iOS 10+)
 */
- (void)createCustomNotificationCategoryWithNotificationCenter:(UNUserNotificationCenter *) nc API_AVAILABLE(ios(10.0)){
    if(@available(iOS 10.0, *)){
        // 自定义`action1`和`action2`
        UNNotificationAction *action1 = [UNNotificationAction actionWithIdentifier:@"action1" title:@"test1" options: UNNotificationActionOptionNone];
        UNNotificationAction *action2 = [UNNotificationAction actionWithIdentifier:@"action2" title:@"test2" options: UNNotificationActionOptionNone];
        // 创建id为`test_category`的category，并注册两个action到category
        // UNNotificationCategoryOptionCustomDismissAction表明可以触发通知的dismiss回调
        UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:@"test_category" actions:@[action1, action2] intentIdentifiers:@[] options:
                                            UNNotificationCategoryOptionCustomDismissAction];
        // 注册category到通知中心
        [nc setNotificationCategories:[NSSet setWithObjects:category, nil]];
    }
}

/**
 *  处理iOS 10通知(iOS 10+)
 */
- (void)handleiOS10Notification:(UNNotification *)notification  API_AVAILABLE(ios(10.0)){
    UNNotificationRequest *request = notification.request;
    UNNotificationContent *content = request.content;
    NSDictionary *userInfo = content.userInfo;
    // 通知时间
    NSDate * noticeDate = notification.date;
    // 标题
    NSString * title = content.title == nil ? @"" : content.title;
    // 副标题
    NSString *subtitle = content.subtitle == nil ? @"" : content.subtitle;
    // 内容
    NSString *body = content.body == nil ? @"" : content.body;
    // 角标
    int badge = [content.badge intValue];
    // 取得通知自定义字段内容，例：获取key为"Extras"的内容
    NSString *extras = [userInfo valueForKey:@"Extras"] == nil ? @"" : [userInfo valueForKey:@"Extras"];
    // 通知角标数清0
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    // 同步角标数到服务端
    // [self syncBadgeNum:0];
    // 通知打开回执上报
    [CloudPushSDK sendNotificationAck:userInfo];
    [self delegateNotificationDataCallBack:noticeDate strOfTitle:title strOfSubtitle:subtitle strOfBody:body intOfBadge:badge strOfExtras:extras strOfSound:nil strOfContent:nil];
    //    NSLog(@"TEST: Notification, date: %@, title: %@, subtitle: %@, body: %@, badge: %d, extras: %@.", noticeDate, title, subtitle, body, badge, extras);
}
/**
 *  App处于前台时收到通知(iOS 10+)
 */
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler  API_AVAILABLE(ios(10.0)){
    NSLog(@"zl_: Receive a notification in foregound.");
    // 处理iOS 10通知，并上报通知打开回执
    [self handleiOS10Notification:notification];
    // 通知不弹出
    completionHandler(UNNotificationPresentationOptionNone);
    // 通知弹出，且带有声音、内容和角标
    //completionHandler(UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
}
/**
 *  触发通知动作时回调，比如点击、删除通知和点击自定义action(iOS 10+)
 */

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler  API_AVAILABLE(ios(10.0)){
    NSString *userAction = response.actionIdentifier;
    // 点击通知打开
    //NSLog(@"TEST: --------%@",userAction);
    if ([userAction isEqualToString:UNNotificationDefaultActionIdentifier]) {
        NSLog(@"zl_: User opened the notification.");
        // 处理iOS 10通知，并上报通知打开回执
        [self handleiOS10Notification:response.notification];
    }
    // 通知dismiss，category创建时传入UNNotificationCategoryOptionCustomDismissAction才可以触发
    if ([userAction isEqualToString:UNNotificationDismissActionIdentifier]) {
        NSLog(@"zl_: User dismissed the notification.");
    }
    NSString *customAction1 = @"action1";
    NSString *customAction2 = @"action2";
    // 点击用户自定义Action1
    if ([userAction isEqualToString:customAction1]) {
        NSLog(@"User custom action1.");
    }
    
    // 点击用户自定义Action2
    if ([userAction isEqualToString:customAction2]) {
        NSLog(@"User custom action2.");
    }
    completionHandler();
}

- (void)zl_DidReceiveRemoteNotificationForOldIOSVersion:(NSDictionary*)userInfo application:(UIApplication*)application {
    NSLog(@"zl_: Receive one notification.");
    // 取得APNS通知内容
    NSDictionary *aps = [userInfo valueForKey:@"aps"];
    // 内容
    NSString *content = [aps valueForKey:@"alert"];
    // badge数量
    int badge = [[aps valueForKey:@"badge"] intValue];
    // 播放声音
    NSString *sound = [aps valueForKey:@"sound"];
    // 取得通知自定义字段内容，例：获取key为"Extras"的内容
    NSString *extras = [userInfo valueForKey:@"Extras"]; //服务端中Extras字段，key是自己定义的
    //NSLog(@"content = [%@], badge = [%ld], sound = [%@], Extras = [%@]", content, (long)badge, sound, Extras);
    // iOS badge 清0
    application.applicationIconBadgeNumber = 0;
    // 同步通知角标数到服务端
    // [self syncBadgeNum:0];
    // 通知打开回执上报
    [CloudPushSDK sendNotificationAck:userInfo];
    [self delegateNotificationDataCallBack:nil strOfTitle:nil strOfSubtitle:nil strOfBody:nil intOfBadge:badge strOfExtras:extras strOfSound:sound strOfContent:content];
}

/* 同步通知角标数到服务端 */
- (void)syncBadgeNum:(NSUInteger)badgeNum {
    [CloudPushSDK syncBadgeNum:badgeNum withCallback:^(CloudPushCallbackResult *res) {
        if (res.success) {
            NSLog(@"Sync badge num: [%lu] success.", (unsigned long)badgeNum);
        } else {
            NSLog(@"Sync badge num: [%lu] failed, error: %@", (unsigned long)badgeNum, res.error);
        }
    }];
}

//通知参数delegate回调
- (void)delegateNotificationDataCallBack:(NSDate * _Nullable)noticeDate strOfTitle:(NSString * _Nullable)title strOfSubtitle:(NSString * _Nullable)subtitle strOfBody:(NSString * _Nullable)body intOfBadge:(int)badge strOfExtras:(NSString *)extras strOfSound:(NSString * _Nullable) sound strOfContent:(NSString * _Nullable) content {
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    if(noticeDate)
        [dic setObject:noticeDate forKey:@"noticeDate"];//NSDate型
    if(sound)
        [dic setObject:sound forKey:@"sound"];
    if(content)
        [dic setObject:content forKey:@"content"];
    if(title)
        [dic setObject:title forKey:@"title"];
    if(subtitle)
        [dic setObject:subtitle forKey:@"subtitle"];
    if(body)
        [dic setObject:body forKey:@"body"];
    [dic setObject:[NSString stringWithFormat:@"%d",badge] forKey:@"badge"];
    [dic setObject:extras forKey:@"extras"];
}
//绑定账号
- (int)zl_BindAccount:(NSString *)account {
    static int flag = 0;
    if (account == nil || account.length == 0) {
        return flag;
    }
    [CloudPushSDK bindAccount:account withCallback:^(CloudPushCallbackResult *res) {
        if (res.success) {
            flag = 1;
            NSLog(@"zl_: 账号绑定成功");
        } else {
            flag = 2;
            NSLog(@"zl_: 账号绑定失败，错误: %@",res.error);
        }
    }];
    return flag;
}

//解除账号绑定
- (int)zl_UnbindAccount {
    static int flag = 0;
    [CloudPushSDK unbindAccount:^(CloudPushCallbackResult *res) {
        if (res.success) {
            flag = 1;
            NSLog(@"zl_: 账号解绑成功");
        } else {
            flag = 2;
            NSLog(@"zl_: 账号解绑失败，错误: %@",res.error);
        }
    }];
    return flag;
}

//绑定Tag
- (int)zl_BindTagForDevice:(NSString *)tagStr {
    static int flag = 0;
    NSArray *tagArray = [tagStr componentsSeparatedByString:@" "];
    [CloudPushSDK bindTag:1 withTags:tagArray withAlias:nil withCallback:^(CloudPushCallbackResult *res) {
        if (res.success) {
            flag = 1;
            NSLog(@"zl_: 设备标签绑定成功");
        } else {
            flag = 2;
            NSLog(@"zl_: 设备标签绑定失败，错误: %@",res.error);
        }
    }];
    return flag;
}
//解除绑定Tag
- (int)zl_UnbindTagForDevice:(NSString *)tagStr {
    static int flag = 0;
    NSArray *tagArray = [tagStr componentsSeparatedByString:@" "];
    [CloudPushSDK unbindTag:1 withTags:tagArray withAlias:nil withCallback:^(CloudPushCallbackResult *res) {
        if (res.success) {
            flag = 1;
            NSLog(@"zl_: 设备标签解绑成功");
        } else {
            flag = 2;
            NSLog(@"zl_: 设备标签解绑失败，错误: %@",res.error);
        }
    }];
    return flag;
}
//绑定别名
- (int)zl_AddAlias:(NSString *)alias {
    static int flag = 0;
    [CloudPushSDK addAlias:alias withCallback:^(CloudPushCallbackResult *res) {
        if (res.success) {
            flag = 1;
            NSLog(@"zl_: 别名添加成功");
        } else {
            flag = 2;
            NSLog(@"zl_: 别名添加失败，错误: %@",res.error);
        }
    }];
    return flag;
}
//解除绑定别名
- (int)zl_RemoveAlias:(NSString *)alias {
    static int flag = 0;
    [CloudPushSDK removeAlias:alias withCallback:^(CloudPushCallbackResult *res) {
        if (res.success) {
            flag = 1;
            NSLog(@"zl_: 别名移除成功");
        } else {
            flag = 2;
            NSLog(@"zl_: 别名移除失败，错误: %@",res.error);
        }
    }];
    return flag;
}

- (NSString *)zl_GetSDKVersion
{
    NSString * sdkVersion = @"";
    sdkVersion = [CloudPushSDK getVersion];
    return (sdkVersion) ? sdkVersion : @"";
}

- (NSString *)zl_GetAliDeviceId
{
    NSString * deviceId = @"";
    deviceId = [CloudPushSDK getDeviceId];
    return (deviceId) ? deviceId : @"";
}

//TODO: Pass device id to Hisense system for registration
- (void)zl_RegisterToHsSystem: (NSDictionary *)dic
{
    
}

@end
