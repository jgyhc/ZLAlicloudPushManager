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


- (void)zl_RegisterAPNS:(UIApplication * ) application notificationCenter:(UNUserNotificationCenter *) nc API_AVAILABLE(ios(10.0));
- (void)zl_RegistereISOLessThan10APNS:(UIApplication * ) application;
- (NSString *)zl_InitCloudPushWithAppKey:(NSString *)appKey withAppSecret:(NSString *)appSecret; //返回值: Ali Device ID
- (void)zl_ListenerOnChannelOpened;
- (void)zl_RegisterMessageReceive;
- (void)zl_SendNotificationAck:(NSDictionary *)launchOptions;// 点击通知将App从关闭状态启动时，将通知打开回执上报
//APNs注册成功回调，将返回的deviceToken上传到CloudPush服务器。 用在 UIApplicationDelegate: didRegisterForRemoteNotificationsWithDeviceToken里面
- (void)zl_RegisterDevice:(NSData *)deviceToken;
- (void)zl_DidReceiveRemoteNotificationForOldIOSVersion:(NSDictionary*)userInfo application:(UIApplication*)application;
- (int)zl_BindAccount:(NSString *)account; //返回值：flag(int)，flag = 0：账号为空，flag= 1：账号绑定成功，flag=2：账号绑定失败
- (int)zl_UnbindAccount; //返回值：flag(int)，账号解除绑定 flag= 1：账号绑定成功，flag=2：账号绑定失败
- (int)zl_BindTagForDevice:(NSString *)tagStr; //返回值：flag(int)，flag= 1：tag绑定成功，flag=2：tag绑定失败
- (int)zl_UnbindTagForDevice:(NSString *)tagStr; //返回值：flag(int)，flag= 1：tag解绑成功，flag=2：tag解绑失败
- (int)zl_AddAlias:(NSString *)alias; //返回值：flag(int)，flag= 1：别名绑定成功，flag=2：别名绑定失败
- (int)zl_RemoveAlias:(NSString *)alias; //返回值：flag(int)，flag= 1：别名解绑成功，flag=2：别名解绑失败
- (NSString *)zl_GetSDKVersion;
- (NSString *)zl_GetAliDeviceId;//推送SDK初始化结束后调用有效，否则为空
- (void)zl_RegisterToHsSystem: (NSDictionary *)dic;//上报Ali DeviceId，绑定的海信账号等信息给系统端，供后续推送使用
@end

NS_ASSUME_NONNULL_END
