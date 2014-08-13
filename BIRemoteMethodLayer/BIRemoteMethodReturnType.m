//
//  BIRemoteMethodReturnType.m
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-6.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import "BIRemoteMethodReturnType.h"
#import "BIRemoteMethodConst.h"

const BIRemoteMethodReturnType BIRemoteMethodReturnTypeVoid = (BIRemoteMethodReturnType){0,0,0};
const BIRemoteMethodReturnType BIRemoteMethodReturnTypeDynamic = (BIRemoteMethodReturnType){BIRemoteMethodReturnTypeStructureDynamicData, 0, 0};

UInt32 BIRemoteMethodReturnTypeGetNulTerminatedDataLength(void *data, UInt32 unitSize)
{
    UInt32 length = 0;
    char *tmpPointer = data;
    BOOL isZeroUnit;
    while (1)
    {
        //protection
        if (length >= INT32_MAX)
        {
            length  = UINT32_MAX;
            break;
        }
        //scan
        isZeroUnit = YES;
        //@TODO: optimize for UInt16 UInt32 UInt64
        for (int i = 0; i < unitSize; i++)
        {
            if (*(tmpPointer+i) != 0)
            {
                isZeroUnit = NO;
                break;
            }
        }
        if (isZeroUnit)
        {
            break;
        }
        else
        {
            length+=unitSize;
            tmpPointer+=unitSize;
        }
    }
    return length;
}

UInt32 BIRemoteMethodReturnTypeGetArgumentLengthDataLength(void *arg, UInt32 argLen, UInt32 unitSize)
{
    UInt64 ret = 0;
    switch (argLen) {
        case 1:
            ret = *(UInt8 *)arg;
            break;
        case 2:
            ret = *(UInt16 *)arg;
            break;
        case 4:
            ret = *(UInt32 *)arg;
            break;
        case 8:
            ret = *(UInt64 *)arg;
            break;
        default:
            break;
    }
    return (UInt32)ret * unitSize;
}

UInt32 BIRemoteMethodReturnTypeTryGetDataLength(BIRemoteMethodReturnType returnType)
{
    UInt32 dataLength = 0;
    if (returnType.structure == BIRemoteMethodReturnTypeStructureValue ||
        returnType.structure == BIRemoteMethodReturnTypeStructureCalculatedData ||
        returnType.structure == BIRemoteMethodReturnTypeStructureFixedLengthData
        )
    {
        dataLength = returnType.option2;
    }
    else
    {
        //can't determine
    }
    return dataLength;
}

UInt32 BIRemoteMethodReturnTypeMakeSignature(BIRemoteMethodReturnType type)
{
    UInt32 sig = type.structure;
    switch (type.structure)
    {
        case BIRemoteMethodReturnTypeStructureArgumentLengthData:
        case BIRemoteMethodReturnTypeStructureCalculatedData:
            sig += type.option1 + type.option2;
            break;
        case BIRemoteMethodReturnTypeStructureValue:
        case BIRemoteMethodReturnTypeStructureNulTerminatedData:
        case BIRemoteMethodReturnTypeStructureFixedLengthData:
            sig += type.option2;
            break;
            
        case BIRemoteMethodReturnTypeStructureDynamicData:
        case BIRemoteMethodReturnTypeStructureVoid:
        default:
            break;
    }
    return sig;
}

char* BIRemoteMethodReturnTypeDebugInfo(BIRemoteMethodReturnType type)
{
    char* dbgInfo = calloc(1, BIRMC_DEBUG_INFO_BUFFER_UNIT);
    if (dbgInfo)
    {
        sprintf(dbgInfo, "{structure:%d, option1:%d, option2:%d, estimated data length:%d}", type.structure, type.option1, (unsigned int)type.option2, (unsigned int)BIRemoteMethodReturnTypeTryGetDataLength(type));
    }
    return dbgInfo;
}


