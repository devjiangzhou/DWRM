//
//  BIRemoteMethodSocketLayer.h
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-5.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BIRemoteMethodLayer.h"

/**
 *  Currently BIRemoteMethodSocketLayer will open a new socket each time it read/receive, and when done, that socket will be closed.
 */

BI_EXTERN const UInt32 BIRemoteMethodSocketLayerDefaultPort;
BI_EXTERN const char* BIRemoteMethodSocketLayerLocalhostAddr;
BI_EXTERN const UInt32 BIRemoteMethodSocketLayerDefaultMaxClient;

BIRemoteMethodLayerRef BIRemoteMethodSocketLayerCreateClient(const char* destAddr, UInt32 port);

BIRemoteMethodLayerRef BIRemoteMethodSocketLayerCreateServer(const char* destAddr, UInt32 port, UInt32 maxClient);
