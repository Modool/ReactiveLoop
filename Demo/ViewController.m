//
//  ViewController.m
//  Demo
//
//  Created by xulinfeng on 2017/11/19.
//  Copyright © 2017年 Modool. All rights reserved.
//

#import <ReactiveLoop/ReactiveLoop.h>
#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, assign) NSUInteger value;

@end

@implementation ViewController

- (instancetype)init{
    if (self = [super init]) {
        self.rl_name = @"hhhh";
        
//        [[self rl_viewDidLoadNode] feedbackValue:@"lllll" observe:^(id  _Nullable value, id  _Nullable source) {
//            NSLog(@"value: %@ source: %@", value, source);
//        }];
        
        [[self rl_nodeWithStream:RLObserve(self, value)] feedbackObserve:^(id  _Nullable value, id  _Nullable source) {
            NSLog(@"value: %@ source: %@", value, source);
        }];
    }
    return self;
}

- (void)loadView{
    [super loadView];
    
    self.view.backgroundColor = [UIColor redColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.value = 1;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
