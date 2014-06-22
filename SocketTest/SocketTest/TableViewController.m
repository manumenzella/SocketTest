//
//  ViewController.m
//  SocketTest
//
//  Created by Manuel Menzella on 12/22/13.
//  Copyright (c) 2013 Manuel Menzella. All rights reserved.
//

#import "TableViewController.h"
#import "TableViewCell.h"
#import "SocketIO.h"
#import "SocketIOPacket.h"

#import <AudioToolbox/AudioToolbox.h>

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface TableViewController () <SocketIODelegate>
@property (nonatomic, strong) NSMutableArray *messagesArray;
@property (nonatomic, strong) SocketIO *socketIO;
@end

@implementation TableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColorFromRGB(0x3582CA);
    self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0x3582CA);
    
    self.messagesArray = [[NSMutableArray alloc] init];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.socketIO = [[SocketIO alloc] initWithDelegate:self];
    [self connectToSocket];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [NSTimer scheduledTimerWithTimeInterval:2.00f target:self selector:@selector(tick) userInfo:nil repeats:YES];
}

- (void)tick
{
    if (self.socketIO.isConnected) {
        [self.socketIO sendEvent:@"send" withData:@{@"username": @"Time", @"message": [NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]]}];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self tryConnectionAfterDelay];
}

- (void)tryConnectionAfterDelay
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (!self.socketIO.isConnected && !self.socketIO.isConnecting) {
            NSLog(@"%d %d", self.socketIO.isConnected, self.socketIO.isConnecting);
            [self connectToSocket];
        }
    });
}

- (void)connectToSocket
{
    self.title = @"Connecting...";
    [self.socketIO connectToHost:@"50.112.249.164" onPort:3700];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self.socketIO disconnect];
        
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"backgroundTimeRemaining: %.2fs", [[UIApplication sharedApplication] backgroundTimeRemaining]);
        [self.socketIO sendEvent:@"send" withData:@{@"username": @"Device", @"message": @"Going down!"}];
        [self.socketIO disconnect];
        
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    });
}

#pragma mark - TableView Deletage and DataSource

- (TableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[TableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.label.attributedText = [self.messagesArray objectAtIndex:indexPath.row];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.messagesArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [TableViewCell height];
}

#pragma mark - SocketIO

- (void)socketIODidConnect:(SocketIO *)socket
{
    self.title = @"Connected";
}

- (void)socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet
{
    NSLog(@"%@", packet);
    
    NSString *usernameString = [[packet.args objectAtIndex:0] objectForKey:@"username"] ? [[packet.args objectAtIndex:0] objectForKey:@"username"] : nil;
    NSString *messageString = [[packet.args objectAtIndex:0] objectForKey:@"message"];
    
    if ([usernameString isEqualToString:@"Time"]) {
        AudioServicesPlaySystemSound(1057);
    } else {
        AudioServicesPlaySystemSound(1111);
    }
    
    unsigned long usernameLength = 0;
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];
    if (usernameString) {
        [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:usernameString]];
        [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:@":"]];
        [attrString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]] range:NSMakeRange(0, attrString.length)];
        [attrString addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0xAAFFFF) range:NSMakeRange(0, attrString.length)];
        //[attrString addAttribute:NSForegroundColorAttributeName value:[self randomColor] range:NSMakeRange(0, attrString.length)];
        usernameLength = attrString.length;
        
        [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    }
    [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:messageString]];
    [attrString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:[UIFont systemFontSize]] range:NSMakeRange(usernameLength, attrString.length - usernameLength)];
    [attrString addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0xDDDDDD) range:NSMakeRange(usernameLength, attrString.length - usernameLength)];
    
    [self.messagesArray addObject:attrString];
    [self.tableView reloadData];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([self.tableView numberOfRowsInSection:0] - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)socketIO:(SocketIO *)socket onError:(NSError *)error
{
    self.title = @"Connection Error";
    [self tryConnectionAfterDelay];
    
    NSLog(@"onError() %@", error);
}


- (void)socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error
{
    self.title = @"Connection Lost";
    [self tryConnectionAfterDelay];
    
    NSLog(@"Socket.IO Disconnected. Error: %@", error);
}

#pragma mark Utils

- (UIColor *)randomColor
{
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    //CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    //CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;
    CGFloat brightness = ( arc4random() % 64 / 256.0 ) + 0.75;
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    
    return color;
}

@end
