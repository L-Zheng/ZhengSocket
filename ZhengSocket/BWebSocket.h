//
//  BWebSocket.h
//  GoldNetworkFramework
//
//  Created by 李保征 on 2017/4/20.
//  Copyright © 2017年 wallstreetcn. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BSocketState) {
    BSocketState_Connecting   = 0,
    BSocketState_Open         = 1,
    BSocketState_Closing      = 2,
    BSocketState_Closed       = 3,
};

@class BWebSocket;

@protocol BWebSocketDelegate <NSObject>

- (void)bSocket:(BWebSocket *)socket didReceiveMessage:(id)message;

@optional
- (void)bSocketDidOpen:(BWebSocket *)socket;
- (void)bSocket:(BWebSocket *)socket didFailWithError:(NSError *)error;
- (void)bSocket:(BWebSocket *)socket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
@end


@interface BWebSocket : NSObject

@property (nonatomic,weak) id <BWebSocketDelegate> delegate;

@property (nonatomic,assign,readonly) BSocketState socketState;

/** 进入后台是否关闭 默认NO */
@property (nonatomic,assign) BOOL isCloseWhenBackground;

/** 进入前台是否连接 默认NO */
@property (nonatomic,assign) BOOL isConnectWhenForeground;

/** 意外断开 是否自动重新连接 默认NO */
@property (nonatomic,assign) BOOL isAutoConnectWhenOff;

@property (nonatomic,strong) NSURLRequest *request;

- (instancetype)initWithURLRequest:(NSURLRequest *)request;

- (void)startConnect;

- (void)closeConnect;

//Send a String/Data/Array/Dic
- (void)sendMessage:(id)sendMessage;

@end
