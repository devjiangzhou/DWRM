//
//  BIRemoteMethodSocketLayerTests.m
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-28.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BIRemoteMethodPublic.h"

@interface BIRemoteMethodSocketLayerTests : XCTestCase
{
    BIRemoteMethodLayerRef _clientLayer;
    BIRemoteMethodLayerRef _serverLayer;
}
@end

@implementation BIRemoteMethodSocketLayerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    _clientLayer = BIRemoteMethodSocketLayerCreateClient(BIRemoteMethodSocketLayerLocalhostAddr, BIRemoteMethodSocketLayerDefaultPort);
    
    _serverLayer = BIRemoteMethodSocketLayerCreateServer(BIRemoteMethodSocketLayerLocalhostAddr, BIRemoteMethodSocketLayerDefaultPort, BIRemoteMethodSocketLayerDefaultMaxClient);
    while (1)
    {
        BIRemoteMethodCallRef call = BIRemoteMethodLayerReadCopyMethodCall(_serverLayer);
        BIRemoteMethodReturnRef methodReturn = BIRemoteMethodCallSendCAndCreateMethodReturn(call, BIRemoteMethodCFuncHandlerCallWrapper, NULL);
        BIRemoteMethodLayerSendMethodReturn(_serverLayer, methodReturn);
    }
}

- (void)tearDown
{
    BIRemoteMethodLayerRelease(_clientLayer);
    BIRemoteMethodLayerRelease(_serverLayer);
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
