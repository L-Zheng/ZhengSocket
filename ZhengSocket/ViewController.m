//
//  ViewController.m
//  BWebSocket
//
//  Created by 李保征 on 2017/5/9.
//  Copyright © 2017年 李保征. All rights reserved.
//

#import "ViewController.h"
#import "BWebSocket.h"

@interface ViewController ()<BWebSocketDelegate>

@property (nonatomic,strong) BWebSocket *webSocket;

@end

@implementation ViewController

- (BWebSocket *)webSocket{
    if (!_webSocket) {
        _webSocket.delegate = nil;
        [_webSocket closeConnect];
        //socket链接地址
        _webSocket = [[BWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@""]]];
        _webSocket.delegate = self;
    }
    return _webSocket;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)bSocketDidOpen:(BWebSocket *)socket{
    
}
- (void)bSocket:(BWebSocket *)socket didFailWithError:(NSError *)error{
    
}
- (void)bSocket:(BWebSocket *)socket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    
}

- (void)bSocket:(BWebSocket *)socket didReceiveMessage:(id)message{
    
}

@end
