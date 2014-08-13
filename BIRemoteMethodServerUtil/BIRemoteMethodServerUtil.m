//
//  BIRemoteMethodServerUtil.m
//  BIRemoteMethodServerUtil
//
//  Created by Seven on 14-4-15.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BIRemoteMethodServerUtil.h"

struct BIRemoteMethodSimpleServer
{
    BIRemoteMethodLayerRef serverLayer;
    BOOL shouldStopServer;
    BOOL serverStarted;
};

BIRemoteMethodSimpleServerRef BIRemoteMethodSimpleServerCreate(const char* destAddr, UInt32 port, UInt32 maxClient)
{
    BIRemoteMethodLayerRef serverLayer = BIRemoteMethodSocketLayerCreateServer(destAddr, port, maxClient);
    if (serverLayer)
    {
        BIRemoteMethodSimpleServerRef server = calloc(1, sizeof(struct BIRemoteMethodSimpleServer));
        if (server)
        {
            server->serverLayer = serverLayer;
            return server;
        }
        else
        {
            BIRemoteMethodLayerRelease(serverLayer);
        }
    }
    return NULL;
}

BIRemoteMethodSimpleServerRef BIRemoteMethodSimpleServerCreateDefault()
{
    return BIRemoteMethodSimpleServerCreate(BIRemoteMethodSocketLayerLocalhostAddr, BIRemoteMethodSocketLayerDefaultPort, BIRemoteMethodSocketLayerDefaultMaxClient);
}

int BIRemoteMethodSimpleServerStartSync(BIRemoteMethodSimpleServerRef server)
{
    if (!server || server->serverStarted)
    {
        return 0;
    }
    
    BIRMCDPRINT(@"BIRemoteMethodSimpleServer Start");

    server->serverStarted = YES;
    BIRemoteMethodCallRef call = NULL;
    BIRemoteMethodReturnRef methodReturn = NULL;
    
    while (1)
    {
        if (server->shouldStopServer)
        {
            break;
        }
        
        call = BIRemoteMethodLayerReadCopyMethodCall(server->serverLayer);
        BIRMCDPRINT(@"got %s", BIRemoteMethodGetName(BIRemoteMethodCallGetMethod(call)));
        
        methodReturn = BIRemoteMethodCallSendCAndCreateMethodReturn(call, BIRemoteMethodCFuncHandlerCallWrapper, NULL);
        
        BIRemoteMethodCallRelease(call);
        call = NULL;
        
        if (methodReturn)
        {
            BIRemoteMethodLayerSendMethodReturn(server->serverLayer, methodReturn);
            
            BIRemoteMethodReturnRelease(methodReturn);
            methodReturn = NULL;
        }
        else
        {
            BIRMCDPRINT(@"NULL method return, this is unexpected. server stop.");
            BIRemoteMethodSimpleServerStop(server);
        }
    }
    
    server->serverStarted = NO;
    BIRMCDPRINT(@"BIRemoteMethodSimpleServer Ended");
    
    return 1;
}

BOOL BIRemoteMethodSimpleServerStop(BIRemoteMethodSimpleServerRef server)
{
    if (server)
    {
        server->shouldStopServer = YES;
        return YES;
    }
    return NO;
}

UInt64 BIRemoteMethodSimpleServerGetLastCommunicatePeerId(BIRemoteMethodSimpleServerRef server)
{
    if (server)
    {
        return BIRemoteMethodLayerGetLastCommunicatePeerIdentity(server->serverLayer);
    }
    return 0;
}

void BIRemoteMethodSimpleServerRelease(BIRemoteMethodSimpleServerRef server)
{
    if (server)
    {
        BIRemoteMethodSimpleServerStop(server);
        BIRemoteMethodLayerRelease(server->serverLayer);
    }
    free(server);
}