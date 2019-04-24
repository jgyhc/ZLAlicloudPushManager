//
//  ZLAlicloudPushManager.h
//  Pods-ZLAlicloudPushManager_Example
//
//  Created by 刘聪 on 2019/4/23.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>// iOS 10 notification

NS_ASSUME_NONNULL_BEGIN

@interface ZLAlicloudPushManager : NSObject

+ (ZLAlicloudPushManager *)shareInstanted;


- (void)zl_registerAPNS:(UIApplication * ) application notificationCenter:(UNUserNotificationCenter *) nc API_AVAILABLE(ios(10.0));

- (void)zl_registereISOLessThan10APNS:(UIApplication * ) application;

- (NSString *)zl_InitCloudPushWithAppKey:(NSString *)appKey withAppSecret:(NSString *)appSecret; //返回值: Ali Device ID

- (void)zl_listenerOnChannelOpened;

- (void)zl_registerMessageReceive;

- (void)zl_sendNotificationAck:(NSDictionary *)launchOptions;// 点击通知将App从关闭状态启动时，将通知打开回执上报
//APNs注册成功回调，将返回的deviceToken上传到CloudPush服务器。 用在 UIApplicationDelegate: didRegisterForRemoteNotificationsWithDeviceToken里面
- (void)zl_registerDevice:(NSData *)deviceToken;

- (void)zl_didReceiveRemoteNotificationForOldIOSVersion:(NSDictionary*)userInfo application:(UIApplication*)application;

- (int)zl_bindAccount:(NSString *)account; //返回值：flag(int)，flag = 0：账号为空，flag= 1：账号绑定成功，flag=2：账号绑定失败

- (int)zl_unbindAccount; //返回值：flag(int)，账号解除绑定 flag= 1：账号绑定成功，flag=2：账号绑定失败

- (int)zl_bindTagForDevice:(NSString *)tagStr; //返回值：flag(int)，flag= 1：tag绑定成功，flag=2：tag绑定失败

- (int)zl_unbindTagForDevice:(NSString *)tagStr; //返回值：flag(int)，flag= 1：tag解绑成功，flag=2：tag解绑失败

- (int)zl_addAlias:(NSString *)alias; //返回值：flag(int)，flag= 1：别名绑定成功，flag=2：别名绑定失败

- (int)zl_removeAlias:(NSString *)alias; //返回值：flag(int)，flag= 1：别名解绑成功，flag=2：别名解绑失败

- (NSString *)zl_getSDKVersion;

- (NSString *)zl_getAliDeviceId;//推送SDK初始化结束后调用有效，否则为空

- (void)zl_registerToHsSystem: (NSDictionary *)dic;//上报Ali DeviceId，绑定的海信账号等信息给系统端，供后续推送使用
@end

NS_ASSUME_NONNULL_END
