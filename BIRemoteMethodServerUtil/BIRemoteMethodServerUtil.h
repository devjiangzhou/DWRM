//
//  BIRemoteMethodServerUtil.h
//  BIRemoteMethodServerUtil
//
//  Created by Seven on 14-4-15.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#ifndef BIIPTCoreServer_h
#define BIIPTCoreServer_h

#import "BIRemoteMethodPublic.h"

typedef struct BIRemoteMethodSimpleServer* BIRemoteMethodSimpleServerRef;

BIRemoteMethodSimpleServerRef BIRemoteMethodSimpleServerCreate(const char* destAddr, UInt32 port, UInt32 maxClient);
BIRemoteMethodSimpleServerRef BIRemoteMethodSimpleServerCreateDefault();

int BIRemoteMethodSimpleServerStartSync(BIRemoteMethodSimpleServerRef server);
///stop should have a callback, but currently we do not need it.
BOOL BIRemoteMethodSimpleServerStop(BIRemoteMethodSimpleServerRef server);

UInt64 BIRemoteMethodSimpleServerGetLastCommunicatePeerId(BIRemoteMethodSimpleServerRef server);

void BIRemoteMethodSimpleServerRelease(BIRemoteMethodSimpleServerRef server);

#endif
