//
//  BIRemoteMethodReturn.m
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-5.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import "BIRemoteMethodPublic.h"

struct BIRemoteMethodReturn
{
    //-------- 64bit ---------
    UInt8 version;
    UInt8 isMemoryFlat;
    //arg
    UInt8 shouldFreeMethodArg;///< when isMemoryFlat is set, this value should be ingored.
    BI_ALIGNMENT_8BIT;
    UInt32 dataLength;///< This length indicates the real memeory length of the data, and it may NOT equals to the one BIRemoteMethodReturnType indicates.
    //------------------------
    
    
    //-------- 64bit ---------
    UInt32 identity;
    UInt32 flatMemorySize;
    //------------------------
    
    
    //-------- n*64bit ---------
    BIRemoteMethodReturnType returnType;
    //------------------------
    
    
    //-------- 64bit ---------
    union
    {
        UInt64 dataOffset;
        void *data;
    };
    //------------------------
    
    
    //-------- 64bit ---------
    union
    {
        UInt64 pMethodArgOffset;
        BIRemoteMethodArgRef pMethodArgOutput;//Before flat, this pointer is always a weak reference from BIRemoteMethodCallRef
    };
    //------------------------
} BI_STRUCT_ALIGNMENT;

//============================= public ==============================
#pragma mark - public

BIRemoteMethodReturnRef BIRemoteMethodReturnCreate(BIRemoteMethodCallRef call)
{
    BIRemoteMethodReturnRef methodReturn = NULL;
    if (call)
    {
        BIRemoteMethodReturnType returnType = BIRemoteMethodCallGetReturnType(call);
        methodReturn = calloc(1, sizeof(struct BIRemoteMethodReturn));
        if (methodReturn)
        {
            methodReturn->version = BI_REMOTE_METHOD_LAYER_VERSION;
            methodReturn->identity = BIRemoteMethodCallGetIdentity(call);
            methodReturn->returnType = returnType;
            BIRemoteMethodArgRef methodArg = BIRemoteMethodCallGetMethodArg(call);
            methodReturn->pMethodArgOutput = BIRemoteMethodArgCreateOutput(methodArg);
            methodReturn->shouldFreeMethodArg = YES;
            UInt32 dataLength = BIRemoteMethodReturnTypeTryGetDataLength(returnType);
            if (dataLength > 0)
            {
                void *data = calloc(1, dataLength);
                if (data)
                {
                    methodReturn->dataLength = dataLength;
                    methodReturn->data = data;
                }
                else
                {
                    free(methodReturn);
                    methodReturn = NULL;
                }
            }
        }
    }
    return methodReturn;
}

UInt32 BIRemoteMethodReturnGetIdentity(BIRemoteMethodReturnRef methodReturn)
{
    if (methodReturn)
    {
        return methodReturn->identity;
    }
    return 0;
}

BIRemoteMethodArgRef BIRemoteMethodReturnGetMethodArg(BIRemoteMethodReturnRef methodReturn)
{
    if (methodReturn)
    {
        if (methodReturn->isMemoryFlat)
        {
            if (methodReturn->pMethodArgOffset == 0)
            {
                return NULL;
            }
            return (BIRemoteMethodArgRef)BI_INCREATMENT_POINTER(methodReturn, methodReturn->pMethodArgOffset);
        }
        else
        {
            return methodReturn->pMethodArgOutput;
        }
    }
    else
    {
        return NULL;
    }
}

void *BIRemoteMethodReturnGetReturnData(BIRemoteMethodReturnRef methodReturn)
{
    if (methodReturn)
    {
        if (methodReturn->dataLength == 0)
        {
            return NULL;
        }
        
        if (methodReturn->isMemoryFlat)
        {
            if (methodReturn->dataOffset == 0)
            {
                return NULL;
            }
            return BI_INCREATMENT_POINTER(methodReturn, methodReturn->dataOffset);
        }
        else
        {
            return methodReturn->data;
        }
    }
    return NULL;
}

void *BIRemoteMethodReturnCopyReturnData(BIRemoteMethodReturnRef ret)
{
    size_t dataLength = BIRemoteMethodReturnTypeTryGetDataLength(ret->returnType);
    if (dataLength > 0)
    {
        void *data = BIRemoteMethodReturnGetReturnData(ret);
        if (data)
        {
            void *buffer = malloc(dataLength);
            if (buffer)
            {
                memcpy(buffer, data, dataLength);
                return buffer;
            }
        }
    }
    return NULL;
}

UInt32 BIRemoteMethodReturnGetReturnDataLength(BIRemoteMethodReturnRef ret)
{
    UInt32 length = 0;
    if (ret)
    {
        length = BIRemoteMethodReturnTypeTryGetDataLength(ret->returnType);
    }
    return length;
}

void BIRemoteMethodReturnGetReturnValue(BIRemoteMethodReturnRef ret, void *buffer)
{
    if (ret && buffer)
    {
        void *data = BIRemoteMethodReturnGetReturnData(ret);
        if (data)
        {
            if (BIRemoteMethodReturnTypeStructureIsValue(ret->returnType))
            {
                //basice type, we treate the buffer pointer as the address of a variable
                memcpy(buffer, data, ret->returnType.option2);
            }
            else
            {
                //data type, we treate the buffer pointer as the address of a pointer.
                *((void **)buffer) = data;
            }
        }
    }
}

BIRemoteMethodReturnRef BIRemoteMethodReturnCreateFlatMemory(BIRemoteMethodReturnRef methodReturn)
{
    if (methodReturn && !methodReturn->isMemoryFlat)
    {
        UInt32 mothodReturnSize = sizeof(struct BIRemoteMethodReturn);
        UInt32 methodArgSize = 0;
        BIRemoteMethodArgRef methodArg = BIRemoteMethodReturnGetMethodArg(methodReturn);
        if (methodArg)
        {
            methodArgSize = BIRemoteMethodArgGetTotalMemorySize(methodArg);
        }
        
        //此句有问题，如果data已经生成，则此判断有误
        UInt32 dataLength = BIRemoteMethodReturnTypeTryGetDataLength(methodReturn->returnType);
        UInt32 alignedDataLength = BINextAlignment8(dataLength);
        UInt32 totalSize = mothodReturnSize + alignedDataLength + methodArgSize;
        
        BIRemoteMethodReturnRef buffer = calloc(1, totalSize);
        //1.
        memcpy(buffer, methodReturn, mothodReturnSize);
        //2.
        UInt32 returnDataOffset = mothodReturnSize;
        if (dataLength > 0)
        {
            memcpy(BI_INCREATMENT_POINTER(buffer, returnDataOffset), methodReturn->data, dataLength);
            buffer->dataOffset = returnDataOffset;
        }
        
        //3.
        if (methodArgSize > 0)
        {
            UInt32 methodArgOffset = returnDataOffset + alignedDataLength;
            BIRemoteMethodArgFlatMemoryToBuffer(methodArg, BI_INCREATMENT_POINTER(buffer, methodArgOffset));
            buffer->pMethodArgOffset = methodArgOffset;
        }

        //4. fix value
        buffer->isMemoryFlat = YES;
        buffer->flatMemorySize = totalSize;
        buffer->dataLength = dataLength;
        
        return buffer;
    }
    else
    {
        return NULL;
    }
}

BOOL BIRemoteMethodReturnIsMemoeryFlat(BIRemoteMethodReturnRef methodReturn)
{
    if (methodReturn)
    {
        return methodReturn->isMemoryFlat;
    }
    return NO;
}

UInt32 BIRemoteMethodReturnGetFlatMemorySize(BIRemoteMethodReturnRef methodReturn)
{
    if (methodReturn)
    {
        if (methodReturn->isMemoryFlat)
        {
            return methodReturn->flatMemorySize;
        }
    }
    return 0;
}

void *BIRemoteMethodReturnSetValue(BIRemoteMethodReturnRef methodReturn, const void *ptr)
{
    if (methodReturn)
    {
        if (methodReturn->isMemoryFlat)
        {
            return NULL;
        }
        if (BIRemoteMethodReturnTypeStructureIsValue(methodReturn->returnType))
        {
            if (ptr)
            {
                memcpy(methodReturn->data, ptr, methodReturn->returnType.option2);
            }
            else
            {
                memset(methodReturn->data, 0, methodReturn->returnType.option2);
            }
            return methodReturn->data;
        }
    }
    return NULL;
}

void *BIRemoteMethodReturnSetData(BIRemoteMethodReturnRef methodReturn, const void *ptr, UInt32 length)
{
    if (methodReturn)
    {
        if (methodReturn->isMemoryFlat)
        {
            return NULL;
        }
        
        if (BIRemoteMethodReturnTypeStructureIsData(methodReturn->returnType))
        {
            if (ptr && length > 0)
            {
                //if the old buffer can't be reused, we realloc one.
                if (length > methodReturn->dataLength)
                {
                    if (methodReturn->data)
                    {
                        free(methodReturn->data);
                    }
                    methodReturn->data = calloc(1, length);
                    methodReturn->dataLength = methodReturn->data ? length : 0;
                }
                
                if (methodReturn->data)
                {
                    //everthing's OK, we copy memory.
                    memcpy(methodReturn->data, ptr, length);
                    methodReturn->returnType = BIRemoteMethodReturnTypeMakeStructureCalculatedData(methodReturn->returnType, length);
                    
                    return methodReturn->data;
                }
            }
            
            //If:
            //1. Buffer can't be build
            //2. Original function returns NULL pointer
            //We set return type length to 0
            methodReturn->returnType = BIRemoteMethodReturnTypeMakeStructureCalculatedData(methodReturn->returnType, 0);
        }
    }
    return NULL;
}

void BIRemoteMethodReturnRelease(BIRemoteMethodReturnRef methodReturn)
{
    if (methodReturn)
    {
        if (!methodReturn->isMemoryFlat)
        {
            free(methodReturn->data);
            if (methodReturn->shouldFreeMethodArg)
            {
                BIRemoteMethodArgRelease(methodReturn->pMethodArgOutput);
            }
        }
        free(methodReturn);
    }
}

char* BIRemoteMethodReturnDebugInfo(BIRemoteMethodReturnRef methodReturn)
{
    if (methodReturn)
    {
        BIRemoteMethodArgRef methodArg = BIRemoteMethodReturnGetMethodArg(methodReturn);
        
        char *methodArgDebugInfo = BIRemoteMethodArgDebugInfo(methodArg);
        char *returnTypeDebugInfo = BIRemoteMethodReturnTypeDebugInfo(methodReturn->returnType);
        
        const char *dataDesc = NULL;
        void *data = BIRemoteMethodReturnGetReturnData(methodReturn);
        UInt32 dataLen = BIRemoteMethodReturnGetReturnDataLength(methodReturn);
        if (data && dataLen > 0)
        {
            dataDesc = [[[NSData dataWithBytes:data length:dataLen] debugDescription] UTF8String];
        }

        size_t bufferLen = BIRMC_DEBUG_INFO_BUFFER_UNIT*2 + (methodArgDebugInfo?strlen(methodArgDebugInfo):0 + returnTypeDebugInfo?strlen(returnTypeDebugInfo):0 + dataDesc?strlen(dataDesc):0);
        char *debugInfo = calloc(1, bufferLen);
        if (debugInfo)
        {
            sprintf(debugInfo, "{this:%p, version:%i, identity:%i, isMemoryFlat:%i, flatMemorySize:%i, returnType:%s, dataOffset:%i, data:%s, shouldFreeMethodArg:%i, pMethodArgOffset:%i, pMethodArgOutput:%s}", methodReturn, methodReturn->version, (unsigned int)methodReturn->identity, methodReturn->isMemoryFlat, (unsigned int)methodReturn->flatMemorySize, returnTypeDebugInfo?returnTypeDebugInfo:"", (unsigned int)methodReturn->dataOffset, dataDesc?dataDesc:"", methodReturn->shouldFreeMethodArg, (unsigned int)methodReturn->pMethodArgOffset, methodArgDebugInfo?methodArgDebugInfo:"");
        }
        
        free(returnTypeDebugInfo);
        free(methodArgDebugInfo);
        
        return debugInfo;
    }
    return NULL;
}
