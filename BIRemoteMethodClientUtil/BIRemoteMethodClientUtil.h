//
//  BIRemoteMethodClientUtil.h
//  BIRemoteMethodClientUtil
//
//  Created by Seven on 14-4-15.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BIRemoteMethodPublic.h"

BI_EXTERN BIRemoteMethodReturnRef BIRemoteMethodDefaultClientCopyReturnInvoker(BIRemoteMethodCallRef call);
BI_EXTERN void BIRemoteMethodDefaultClientCopyReturnInvokerSetPeerId(UInt64 peerId);
