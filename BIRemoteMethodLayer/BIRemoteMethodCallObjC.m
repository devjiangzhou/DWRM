//
//  BIRemoteMethodCallObjC.m
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-10.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import "BIRemoteMethodCallObjC.h"

BI_EXTERN BIRemoteMethodCallRef _BIRemoteMethodCallCreate(BIRemoteMethodRef method);

BIRemoteMethodCallRef BIRemoteMethodCallCreateObjC(SEL selector)
{
    BIRemoteMethodRef method = BIRemoteMethodCreateObjC(selector);
    if (method)
    {
        BIRemoteMethodCallRef call = _BIRemoteMethodCallCreate(method);
        if (call)
        {
            return call;
        }
        BIRemoteMethodRelease(method);
    }
    return NULL;
}

void *BIRemoteMethodCallObjCSerializeStandardObject(id standardObj, UInt32 *len)
{
    NSError *err;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:standardObj format:NSPropertyListBinaryFormat_v1_0 options:NSPropertyListMutableContainersAndLeaves error:&err];
    //handle error
    if (err)
    {
        
    }
    
    if (len)
    {
        *len = (UInt32)[data length];
    }
    return data;
}

id BIRemoteMethodCallObjCDeserializeStandardObject(void *data, UInt32 len)
{
    NSData *aData = [NSData dataWithBytes:data length:len];
    NSError *err;
    id standardObj = [NSPropertyListSerialization propertyListWithData:aData options:NSPropertyListMutableContainersAndLeaves format:NULL error:&err];
    //handle error
    if (err)
    {
        
    }
    
    return standardObj;
}
