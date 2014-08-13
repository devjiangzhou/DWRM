//
//  BIViewController.m
//  memLeakCheck
//
//  Created by Seven on 14-3-10.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import "BIViewController.h"
#import "BIRemoteMethodPublic.h"
#import "mach/mach.h"

vm_size_t usedMemory(void) {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    return (kerr == KERN_SUCCESS) ? info.resident_size : 0; // size in bytes
}

vm_size_t freeMemory(void) {
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;
    
    host_page_size(host_port, &pagesize);
    (void) host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    return vm_stat.free_count * pagesize;
}

void logMemUsage(UInt32 threshold) {
    // compute memory usage and log if different by >= 100k
    static long prevMemUsage = 0;
    long curMemUsage = usedMemory();
    long memUsageDiff = curMemUsage - prevMemUsage;
    
    if (threshold == 0 || memUsageDiff > threshold || memUsageDiff < threshold) {
        prevMemUsage = curMemUsage;
        NSLog(@"Memory used %7.1f (%+5.0f), free %7.1f kb", curMemUsage/1000.0f, memUsageDiff/1000.0f, freeMemory()/1000.0f);
    }
}

#define CheckMemLeak
@interface XCTestCase : NSObject
@end
@implementation XCTestCase
- (void)setUp
{}
- (void)tearDown
{}
@end
#include "../BIRemoteMethodLayerTests/BIRemoteMethodLayerTests.m"



@interface BIViewController ()

@end

@implementation BIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self checkMemUse:0];
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timer:) userInfo:nil repeats:YES];
    });
}

- (void)checkMemUse:(UInt32)threshold
{
    logMemUsage(threshold);
}

- (void)timer:(NSTimer *)timer
{
    static int count = 0;
    
    static BIRemoteMethodLayerTests *test = nil;
    if (!test)
    {
        test = [[BIRemoteMethodLayerTests alloc] init];
        [test setUp];
    }
    
    //
    [test testArgInOut];
    [test testArgInOutC];
    
    [test testDataArg];
    
    [test testDataReturn];
    [test testDataReturnC];
    
    
    [self checkMemUse:0];
    if (count++ > 999)
    {
        [timer invalidate];
        [test tearDown];
        [test release];
        test = nil;
        [self checkMemUse:0];
    }
}

@end
