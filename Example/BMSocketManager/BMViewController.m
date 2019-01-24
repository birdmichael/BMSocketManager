//
//  BMViewController.m
//  BMSocketManager
//
//  Created by birdmichael on 01/24/2019.
//  Copyright (c) 2019 birdmichael. All rights reserved.
//

#import "BMViewController.h"
#import <BMSocketCenter.h>

@interface BMViewController ()

@end

@implementation BMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *url = @"ws://121.40.165.18:8800";
    [[BMSocketCenter sharedCenter] connectUrlStr:url connect:^{
        [[BMSocketCenter sharedCenter] sendStr:@"1"];
    } receive:^(id message, BMSocketReceiveType type) {
        if (type == BMSocketReceiveTypeForMessage) {
            NSLog(@"接收 类型1--%@",message);
        }
        else if (type == BMSocketReceiveTypeForPong){
            NSLog(@"接收 类型2--%@",message);
        }
    } failure:^(NSError *error) {
        NSLog(@"连接失败");
    }];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
