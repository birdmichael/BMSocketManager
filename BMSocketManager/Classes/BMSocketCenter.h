//
//  BMSocketCenter.h
//  BMSocketManager
//
//  Created by BirdMichael on 2019/1/24.
//

#import <Foundation/Foundation.h>
/**
 *  Socket状态
 */
typedef NS_ENUM(NSInteger,BMSocketStatus){
    BMSocketStatusConnected,        // 连接成功
    BMSocketStatusFailed,           // 连接失败
    BMSocketStatusClosedByServer,   // 系统强制关闭
    BMSocketStatusClosedByUser,     // 用户手动关闭
    BMSocketStatusReceived          // 接受到消息
};

/**
 *  消息类型
 */
typedef NS_ENUM(NSInteger,BMSocketReceiveType){
    BMSocketReceiveTypeForMessage,
    BMSocketReceiveTypeForPong
};
/**
 *  连接成功回调
 */
typedef void(^BMSocketDidConnectBlock)(void);
/**
 *  失败回调
 */
typedef void(^BMSocketDidFailBlock)(NSError *error);
/**
 *  关闭回调
 */
typedef void(^BMSocketDidCloseBlock)(NSInteger code,NSString *reason,BOOL wasClean);
/**
 *  消息接收回调
 */
typedef void(^BMSocketDidReceiveBlock)(id message ,BMSocketReceiveType type);

NS_ASSUME_NONNULL_BEGIN

@interface BMSocketCenter : NSObject

/**
 *  @author 孔凡列
 *
 *  当前的socket状态
 */
@property (nonatomic, assign, readonly) BMSocketStatus socketStatus;
/**
 *  超时重连时间，默认1秒
 */
@property (nonatomic, assign) NSTimeInterval overtime;
/**
 *  重连次数,默认5次
 */
@property (nonatomic, assign) NSUInteger reconnectCount;

+ (instancetype)sharedCenter;

- (void)connectUrlStr:(NSString *)urlStr connect:(BMSocketDidConnectBlock)connect receive:(BMSocketDidReceiveBlock)receive failure:(BMSocketDidFailBlock)failure;

- (void)close:(BMSocketDidCloseBlock)close;
- (void)sendStr:(NSString *)str;
- (void)sendJson:(id)json;
- (void)sendData:(id)data;
@end

NS_ASSUME_NONNULL_END
