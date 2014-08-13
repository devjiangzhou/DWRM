//
//  BIRemoteMethodClientUtil.m
//  BIRemoteMethodClientUtil
//
//  Created by Seven on 14-4-15.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import "BIRemoteMethodClientUtil.h"

static BIRemoteMethodLayerRef gClientSocketLayer = NULL;

BIRemoteMethodReturnRef BIRemoteMethodDefaultClientCopyReturnInvoker(BIRemoteMethodCallRef call)
{
    if (!gClientSocketLayer)
    {
        gClientSocketLayer = BIRemoteMethodSocketLayerCreateClient(BIRemoteMethodSocketLayerLocalhostAddr, BIRemoteMethodSocketLayerDefaultPort);
    }
    return BIRemoteMethodLayerCallMethodAndCopyReturn(gClientSocketLayer, call);
}

BI_EXTERN void BIRemoteMethodDefaultClientCopyReturnInvokerSetPeerId(UInt64 peerId)
{
    if (gClientSocketLayer)
    {
        BIRemoteMethodLayerSetPeerIdentity(gClientSocketLayer, peerId);
    }
}

