//
//  ViewController.m
//  NSOperationQueue
//
//  Created by 蒲悦蓉 on 2020/8/22.
//  Copyright © 2020 蒲悦蓉. All rights reserved.
//

#import "ViewController.h"
#import "PYROperation.h"

@interface ViewController ()
@property int ticketSurplusCount;
@property NSLock *lock;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    [self aboutCreatNSOperation];
//    [self aboutAddOperationIntoOperationQueue];
//    [self initTicketSale];
    [self aboutSiSuo];
}

- (void)aboutCreatNSOperation {
    //方式一：利用NSOperation的子类：NSInvocationOperation
    NSLog(@"----------------------方式1----------------------");
    NSInvocationOperation *op1 = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performTaskOne) object:nil];
    [op1 start];
    
    //方式2: 使用子类 NSBlockOperation 添加会开启新线程 所以可能会和代码添加顺序不同
    NSLog(@"----------------------方式2----------------------");
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"%@", [NSThread currentThread]);
        NSLog(@"用NSBlockOperation创建");
    }];
    [op2 addExecutionBlock:^{
        NSLog(@"%@", [NSThread currentThread]);
        NSLog(@"通过addExecutionBlock添加——1");
    }];
    [op2 addExecutionBlock:^{
        NSLog(@"%@", [NSThread currentThread]);
        NSLog(@"通过addExecutionBlock添加——2");
    }];
    [op2 addExecutionBlock:^{
        NSLog(@"%@", [NSThread currentThread]);
        NSLog(@"通过addExecutionBlock添加——3");
    }];[op2 addExecutionBlock:^{
        NSLog(@"%@", [NSThread currentThread]);
        NSLog(@"通过addExecutionBlock添加——4");
    }];
    [op2 start];
       
    //方式3——自定义的NSOperation
    NSLog(@"----------------------方式3----------------------");
    PYROperation *op3 = [[PYROperation alloc] init];
    [op3 start];
}

- (void)performTaskOne {
    NSLog(@"%@", [NSThread currentThread]);
    NSLog(@"用NSInvocationOperation创建");
}

- (void)aboutCreatNSOperationQueue {
    //创建主队列
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    //创建自定义队列
    NSOperationQueue *pyrQueue = [[NSOperationQueue alloc] init];
}

- (void)addOperationWithBlockToQueue {
    // 1.创建队列
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];

    // 2.使用 addOperationWithBlock: 添加操作到队列中
    [queue addOperationWithBlock:^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
            NSLog(@"1---%@", [NSThread currentThread]); // 打印当前线程
        }
    }];
    [queue addOperationWithBlock:^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
            NSLog(@"2---%@", [NSThread currentThread]); // 打印当前线程
        }
    }];
    [queue addOperationWithBlock:^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
            NSLog(@"3---%@", [NSThread currentThread]); // 打印当前线程
        }
    }];
}

- (void)addOperation {
    NSOperationQueue *pyrQueue = [[NSOperationQueue alloc] init];
    //设置为1时，串型执行 大于1时：并发执行 -1时：不进行限制 并发
//    pyrQueue.maxConcurrentOperationCount = 1;
    
    NSInvocationOperation *op1 = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performTaskOne) object:nil];
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"用NSBlockOperation创建");
    }];
    PYROperation *op3 = [[PYROperation alloc] init];
    
    [pyrQueue addOperation:op1];
    [pyrQueue addOperation:op2];
    [pyrQueue addOperation:op3];
}
- (void)aboutAddOperationIntoOperationQueue {
    
    //方法一：addOperation 开启新线程 并发执行 顺序错乱
    [self addOperation];
    
    //方法2: addOperationWithBlock 开启新线程 并发执行 顺序错乱
//    [self addOperationWithBlockToQueue];
}

/**
 * 非线程安全：不使用 NSLock
 * 初始化火车票数量、卖票窗口(非线程安全)、并开始卖票
 */
- (void)initTicketSale {
    NSLog(@"currentThread---%@",[NSThread currentThread]); // 打印当前线程

    self.ticketSurplusCount = 50;

    // 1.创建 queue1,queue1 代表北京火车票售卖窗口
    NSOperationQueue *queue1 = [[NSOperationQueue alloc] init];
    queue1.maxConcurrentOperationCount = 1;

    // 2.创建 queue2,queue2 代表上海火车票售卖窗口
    NSOperationQueue *queue2 = [[NSOperationQueue alloc] init];
    queue2.maxConcurrentOperationCount = 1;

    // 3.创建卖票操作 op1
    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        [self saleTicketSafe];
    }];

    // 4.创建卖票操作 op2
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        [self saleTicketSafe];
    }];

    // 5.添加操作，开始卖票
    [queue1 addOperation:op1];
    [queue2 addOperation:op2];
}

/**
 * 售卖火车票(非线程安全)
 */
- (void)saleTicketSafe {
    while (1) {
        // 加锁
        [self.lock lock];

        if (self.ticketSurplusCount > 0) {
            //如果还有票，继续售卖
            self.ticketSurplusCount--;
            NSLog(@"%@", [NSString stringWithFormat:@"剩余票数:%d 窗口:%@", self.ticketSurplusCount, [NSThread currentThread]]);
            [NSThread sleepForTimeInterval:0.2];
        }

        // 解锁
        [self.lock unlock];

        if (self.ticketSurplusCount <= 0) {
            NSLog(@"所有火车票均已售完");
            break;
        }
    }
}

- (void)aboutSiSuo {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"%@", [NSThread currentThread]);
        NSLog(@"操作1");
    }];
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"%@", [NSThread currentThread]);
        NSLog(@"操作2");
    }];
    [op1 addDependency:op2];
    [op2 addDependency:op1];
    [queue addOperation:op1];
    [queue addOperation:op2];
}

@end
