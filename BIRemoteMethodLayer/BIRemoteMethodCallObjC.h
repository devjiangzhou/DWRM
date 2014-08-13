//
//  BIRemoteMethodCallObjC.h
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-10.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BIRemoteMethodCall.h"

BIRemoteMethodCallRef BIRemoteMethodCallCreateObjC(SEL selector);

/**
 *  Serialize a 'property list compatible object'.
 */
void *BIRemoteMethodCallObjCSerializeStandardObject(id standardObj, UInt32 *len);

id BIRemoteMethodCallObjCDeserializeStandardObject(void *data, UInt32 len);
