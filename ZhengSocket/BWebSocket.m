//
//  BWebSocket.m
//  GoldNetworkFramework
//
//  Created by 李保征 on 2017/4/20.
//  Copyright © 2017年 wallstreetcn. All rights reserved.
//

#import "BWebSocket.h"
#import "SRWebSocket.h"
#import <UIKit/UIKit.h>

@interface BWebSocket()<SRWebSocketDelegate>

@property (nonatomic,strong) SRWebSocket *webSocket;

/** 更换请求地址 */
@property (nonatomic,assign) BOOL isRequestChange;

@property (nonatomic,retain) NSMutableArray <NSNumber *> *fibseArray;

@end

@implementation BWebSocket

#pragma mark - init

- (instancetype)init{
    return [self initWithURLRequest:nil];
}

- (instancetype)initWithURLRequest:(NSURLRequest *)request{
    self = [super init];
    if (self) {
        [self addNotification];
        
        [self configSwitch];
        
        self.request = request;
        
        [self createSocket];
    }
    return self;
}

- (void)createSocket{
    self.isRequestChange = NO;
    
    if (self.request) {
        [self resetConnect];
        self.webSocket = [[SRWebSocket alloc] initWithURLRequest:self.request];
        self.webSocket.delegate = self;
    }
}

- (void)addNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)configSwitch{
    self.isCloseWhenBackground = NO;
    self.isConnectWhenForeground = NO;
    self.isAutoConnectWhenOff = NO;
}

#pragma mark - getter

- (BSocketState)socketState{
    BSocketState state;
    
    switch (self.webSocket.readyState) {
        case SR_CONNECTING:
            state = BSocketState_Connecting;
            break;
        case SR_OPEN:
            state = BSocketState_Open;
            break;
        case SR_CLOSING:
            state = BSocketState_Closing;
            break;
        case SR_CLOSED:
            state = BSocketState_Closed;
            break;
        default:
            break;
    }
    return state;
}

- (NSMutableArray <NSNumber *> *)fibseArray{
    if (!_fibseArray) {
        _fibseArray = [NSMutableArray arrayWithArray:@[@(1),@(1)]];
    }
    return _fibseArray;
}

#pragma mark - setter

- (void)setRequest:(NSURLRequest *)request{
    
    //检查是否更换了地址
    NSString *originUrlStr = _request.URL.absoluteString;
    NSString *newUrlStr = request.URL.absoluteString;
    if (originUrlStr && newUrlStr) {
        self.isRequestChange = ![originUrlStr isEqualToString:newUrlStr];
    }
    
    _request = request;
}

#pragma mark - public func

- (void)startConnect{
    if (!self.webSocket) {  //不存在连接
        [self createSocket];
    }else{
        //连接地址是否已经更改
        if (self.isRequestChange) {
            [self createSocket];
        }
    }
    
    //开始连接
    if (self.webSocket) {
        if (self.socketState == BSocketState_Connecting) {
            [self.webSocket open];
        }
    }
}

- (void)closeConnect{
    [self.webSocket close];
}

- (void)sendMessage:(id)sendMessage{
    
    if ((self.socketState == BSocketState_Open) && sendMessage) {
        
        NSData *sendMessageData = nil;
        
        if (![sendMessage isKindOfClass:[NSData class]]){
            //不是二进制数据
            NSError *error = nil;
            sendMessageData = [NSJSONSerialization dataWithJSONObject:sendMessage options:NSJSONWritingPrettyPrinted error:&error];
            if (error) {
                sendMessageData = nil;
            }
        }else{
            sendMessageData = sendMessage;
        }
        
        if (sendMessageData) {
            NSString *jsonString = [[NSString alloc] initWithData:sendMessageData encoding:NSUTF8StringEncoding];
            [self.webSocket send:jsonString];
        }
    }
    // 发送方式一 Send a UTF8 String or Data.
    //            [webSocket send:jsonString];
    
    // 发送方式二 Send Data (can be nil) in a ping message.
    //    - (void)sendPing:(NSData *)data;
}

#pragma mark - private func

- (void)resetConnect{
    self.webSocket.delegate = nil;
    [self.webSocket close];
    //关闭连接后 或者意外断开连接  一定要清空
    self.webSocket = nil;
}

- (void)restartConnection{
    if (self.isAutoConnectWhenOff) {
        NSTimeInterval delaytime = 0;
        for (NSNumber *number in self.fibseArray) {
            delaytime += number.doubleValue;
        }
        
        [self performSelector:@selector(startConnect) withObject:nil afterDelay:delaytime];
        
        [self.fibseArray removeObjectAtIndex:0];
        [self.fibseArray addObject:[NSNumber numberWithDouble:delaytime]];
    }
}

- (void)cancelDelay{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startConnect) object:nil];
}

- (void)resetFibseArray{
    self.fibseArray = nil;
}

#pragma mark - Notification

- (void)applicationEnterBackground{
    if (self.isCloseWhenBackground) {
        [self closeConnect];
    }
}

- (void)applicationEnterForeground{
    if (self.isConnectWhenForeground) {
        [self startConnect];
    }
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket{
    [self resetFibseArray];
    [self cancelDelay];
    
    if ([_delegate respondsToSelector:@selector(bSocketDidOpen:)]) {
        [_delegate bSocketDidOpen:self];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    [self resetConnect];
    
    if ([_delegate respondsToSelector:@selector(bSocket:didFailWithError:)]) {
        [_delegate bSocket:self didFailWithError:error];
    }
    
    //重新连接
    [self restartConnection];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    
    [self resetConnect];
    [self resetFibseArray];
    [self cancelDelay];
    
    if ([_delegate respondsToSelector:@selector(bSocket:didCloseWithCode:reason:wasClean:)]) {
        [_delegate bSocket:self didCloseWithCode:code reason:reason wasClean:wasClean];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    
    id parseMessage = nil;

    if ([message isKindOfClass:[NSData class]]){
        
        NSError *error = nil;
        parseMessage = [NSJSONSerialization JSONObjectWithData:message options:NSJSONReadingAllowFragments error:&error];
        if (error) {
            parseMessage = nil;
        }
        
    } else if ([message isKindOfClass:[NSString class]]) {
        NSString *messageStr = (NSString *)message;
        NSData *messageData = [messageStr dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error = nil;
        parseMessage = [NSJSONSerialization JSONObjectWithData:messageData options:NSJSONReadingAllowFragments error:&error];
        if (error) {
            parseMessage = nil;
        }
    }else{
        parseMessage = message;
    }
    
    if ([_delegate respondsToSelector:@selector(bSocket:didReceiveMessage:)]) {
        [_delegate bSocket:self didReceiveMessage:parseMessage];
    }
}

#pragma mark - dealloc

- (void)dealloc{
    [self resetConnect];
    [self cancelDelay];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
