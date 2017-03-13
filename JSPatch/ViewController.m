//
//  ViewController.m
//  JSPatch
//
//  Created by 黄维筱 on 17/3/13.
//  Copyright © 2017年 黄维筱. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor =[UIColor redColor];
    
    UIView *view =[[UIView alloc]initWithFrame:CGRectMake(50, 50, 100, 100)];
    view.backgroundColor = [UIColor grayColor];
    [self.view addSubview:view];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
