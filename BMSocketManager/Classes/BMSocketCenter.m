//
//  BMSocketCenter.m
//  BMSocketManager
//
//  Created by BirdMichael on 2019/1/24.
//

#import "BMSocketCenter.h"
#import "SRWebSocket.h"

@interface BMSocketCenter() <SRWebSocketDelegate>
@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, assign, readwrite) BMSocketStatus socketStatus;
@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, assign) NSUInteger reconnectCounter;

@property (nonatomic, copy)BMSocketDidConnectBlock connectBlock;
@property (nonatomic, copy)BMSocketDidReceiveBlock receiveBlock;
@property (nonatomic, copy)BMSocketDidFailBlock failureBlock;
@property (nonatomic, copy)BMSocketDidCloseBlock closeBlock;
@end

@implementation BMSocketCenter

+ (instancetype)sharedCenter{
    static BMSocketCenter *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.overtime = 1;
        instance.reconnectCount = 5;
    });
    return instance;
}

#pragma mark ——— 外部方法
- (void)connectUrlStr:(NSString *)urlStr connect:(BMSocketDidConnectBlock)connect receive:(BMSocketDidReceiveBlock)receive failure:(BMSocketDidFailBlock)failure {
    [BMSocketCenter sharedCenter].connectBlock = connect;
    [BMSocketCenter sharedCenter].receiveBlock = receive;
    [BMSocketCenter sharedCenter].failureBlock = failure;
    [self open:urlStr];
}

- (void)close:(BMSocketDidCloseBlock)close {
    [BMSocketCenter sharedCenter].closeBlock = close;
    [self close];
}
- (void)sendStr:(NSString *)str {
    [[BMSocketCenter sharedCenter] send:str];
}
- (void)sendJson:(id)json {
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&parseError];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [[BMSocketCenter sharedCenter] sendStr:jsonString];
}
- (void)sendData:(id)data {
    [[BMSocketCenter sharedCenter] send:data];
}
- (void)send:(id)data{
    switch ([BMSocketCenter sharedCenter].socketStatus) {
        case BMSocketStatusConnected:
        case BMSocketStatusReceived:{
            NSLog(@"BMSocketCenter 发送中。。。");
            [self.webSocket send:data];
            break;
        }
        case BMSocketStatusFailed:
            NSLog(@"BMSocketCenter 发送失败");
            break;
        case BMSocketStatusClosedByServer:
            NSLog(@"BMSocketCenter 已经关闭");
            break;
        case BMSocketStatusClosedByUser:
            NSLog(@"BMSocketCenter 已经关闭");
            break;
    }
    
}

#pragma mark ——— 私有函数
- (void)open:(id)params{
    //    NSLog(@"params = %@",params);
    NSString *urlStr = nil;
    if ([params isKindOfClass:[NSString class]]) {
        urlStr = (NSString *)params;
    }
    else if([params isKindOfClass:[NSTimer class]]){
        NSTimer *timer = (NSTimer *)params;
        urlStr = [timer userInfo];
    }
    [BMSocketCenter sharedCenter].urlString = urlStr;
    [self.webSocket close];
    self.webSocket.delegate = nil;
    
    self.webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]]];
    self.webSocket.delegate = self;
    
    [self.webSocket open];
}

- (void)close{
    
    [self.webSocket close];
    self.webSocket = nil;
    [self.timer invalidate];
    self.timer = nil;
}

- (void)reconnect{
    // 计数+1
    if (_reconnectCounter < self.reconnectCount - 1) {
        _reconnectCounter ++;
        // 开启定时器
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:self.overtime target:self selector:@selector(open:) userInfo:self.urlString repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        self.timer = timer;
    }
    else{
        NSLog(@"Websocket Reconnected Outnumber ReconnectCount");
        if (self.timer) {
            [self.timer invalidate];
            self.timer = nil;
        }
        return;
    }
    
}
#pragma mark -- SRWebSocketDelegate
- (void)webSocketDidOpen:(SRWebSocket *)webSocket{
    
    [BMSocketCenter sharedCenter].connectBlock ? [BMSocketCenter sharedCenter].connectBlock() : nil;
    [BMSocketCenter sharedCenter].socketStatus = BMSocketStatusConnected;
    // 开启成功后重置重连计数器
    _reconnectCounter = 0;
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    [BMSocketCenter sharedCenter].socketStatus = BMSocketStatusFailed;
    [BMSocketCenter sharedCenter].failureBlock ? [BMSocketCenter sharedCenter].failureBlock(error) : nil;
    // 重连
    [self reconnect];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    [BMSocketCenter sharedCenter].socketStatus = BMSocketStatusReceived;
    [BMSocketCenter sharedCenter].receiveBlock ? [BMSocketCenter sharedCenter].receiveBlock(message,BMSocketReceiveTypeForMessage) : nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    if (reason) {
        [BMSocketCenter sharedCenter].socketStatus = BMSocketStatusClosedByServer;
        // 重连
        [self reconnect];
    }
    else{
        [BMSocketCenter sharedCenter].socketStatus = BMSocketStatusClosedByUser;
    }
    [BMSocketCenter sharedCenter].closeBlock ? [BMSocketCenter sharedCenter].closeBlock(code,reason,wasClean) : nil;
    self.webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload{
    [BMSocketCenter sharedCenter].receiveBlock ? [BMSocketCenter sharedCenter].receiveBlock(pongPayload,BMSocketReceiveTypeForPong) : nil;
}

@end
