//
//  BIRemoteMethodCall.m
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-5.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import "BIRemoteMethodCall.h"
#import "BIRemoteMethodPublic.h"

struct BIRemoteMethodCall
{
    //-------- 64bit ---------
    UInt8 version;
    UInt8 isMemoryFlat;
    BI_ALIGNMENT_16BIT;
    BI_ALIGNMENT_32BIT;
    //------------------------
    
    
    //-------- 64bit ---------
    UInt32 identity;
    UInt32 flatMemorySize;
    //------------------------
    
    
    //-------- 64bit ---------
    union {
        UInt64 pMethodOffset;
        BIRemoteMethodRef pMethod;
    };
    //------------------------

    
    //-------- 64bit ---------
    union
    {
        UInt64 pMethodArgOffset;
        BIRemoteMethodArgRef pMethodArg;
    };
    //------------------------
    
    
    BIRemoteMethodReturnType returnType;
} BI_STRUCT_ALIGNMENT;


//============================= private ==============================
#pragma mark - private

BIRemoteMethodCallRef _BIRemoteMethodCallCreate(BIRemoteMethodRef method)
{
    BIRemoteMethodCallRef methodCall = calloc(1, sizeof(struct BIRemoteMethodCall));
    if (methodCall)
    {
        methodCall->version = BI_REMOTE_METHOD_LAYER_VERSION;
        methodCall->pMethod = method;
        return methodCall;
    }
    free(methodCall);
    return NULL;
}

//@todo output-only arguments should not be sent.
SInt32 _BIRemoteMethodCallAddArgument(BIRemoteMethodCallRef call, void *pData, UInt32 len, BOOL isData, BOOL isOutPut)
{
    //if isData == YES, then the NULL pointer with zero length shall be valid.
    if (!call || (!isData && (!pData || len == 0)))
    {
        return BIRemoteMethodErrorNoOperation;
    }
    
    if (call->isMemoryFlat)
    {
        return BIRemoteMethodErrorFlatMemory;
    }
    
    if (!call->pMethodArg)
    {
        BIRemoteMethodArgRef methodArg = BIRemoteMethodArgCreate();
        if (!methodArg)
        {
            return -1;
        }
        call->pMethodArg = methodArg;
    }
    
    //
    BOOL isNULLPointer = isData && pData == NULL;
    if (isNULLPointer)
    {
        len = 0;
    }
    return BIRemoteMethodArgAddArg(call->pMethodArg, pData, len, isData, isOutPut);
}



//============================= public ==============================
#pragma mark - public

BIRemoteMethodCallRef BIRemoteMethodCallCreateC(const char *methodName)
{
    BIRemoteMethodRef method = BIRemoteMethodCreateC(methodName);
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

SInt32 BIRemoteMethodCallAddArgument(BIRemoteMethodCallRef call, void *pArg, UInt32 len)
{
    return _BIRemoteMethodCallAddArgument(call, pArg, len, NO, NO);
}

SInt32 BIRemoteMethodCallAddArgumentCopyData(BIRemoteMethodCallRef call, void *pData, UInt32 len, BOOL isOutPut)
{
    return _BIRemoteMethodCallAddArgument(call, pData, len, YES, isOutPut);
}

BIRemoteMethodCallRef BIRemoteMethodCallCreateFlatMemory(BIRemoteMethodCallRef call)
{
    if (!call || call->isMemoryFlat)
    {
        return NULL;
    }
    
    UInt32 methodCallSize = sizeof(struct BIRemoteMethodCall);
    UInt32 methodSize = BIRemoteMethodGetTotalMemorySize(call->pMethod);
    UInt32 methodArgSize = BIRemoteMethodArgGetTotalMemorySize(call->pMethodArg);
    UInt32 totalMemorySize = methodCallSize + methodSize + methodArgSize;
    
    BIRemoteMethodCallRef buffer = calloc(1, totalMemorySize);
    if (!buffer)
    {
        return NULL;
    }
    
    //1.copy BIRemoteMethodCall
    memcpy(buffer, call, methodCallSize);
    //2.copy BIRemoteMethod
    UInt32 pMethodOffset = methodCallSize;
    BIRemoteMethodFlatMemoryToBuffer(call->pMethod, BI_INCREATMENT_POINTER(buffer, pMethodOffset));
    //3.copy BIRemoteMethodArg
    if (methodArgSize)
    {
        UInt32 pMethodArgOffset = pMethodOffset + methodSize;
        BIRemoteMethodArgFlatMemoryToBuffer(call->pMethodArg, BI_INCREATMENT_POINTER(buffer, pMethodArgOffset));
        buffer->pMethodArgOffset = pMethodArgOffset;
    }
    //4.fix value
    buffer->isMemoryFlat = YES;
    buffer->pMethodOffset = pMethodOffset;
    buffer->flatMemorySize = totalMemorySize;
    
    return buffer;
}

BOOL BIRemoteMethodCallIsMemoeryFlat(BIRemoteMethodCallRef call)
{
    if (call)
    {
        return call->isMemoryFlat;
    }
    return NO;
}

UInt32 BIRemoteMethodCallGetFlatMemorySize(BIRemoteMethodCallRef call)
{
    if (call)
    {
        if (call->isMemoryFlat)
        {
            return call->flatMemorySize;
        }
    }
    return 0;
}

UInt32 BIRemoteMethodCallGetIdentity(BIRemoteMethodCallRef call)
{
    UInt32 identity = 0;
    if (call)
    {
        if (call->identity == 0)
        {
            //calculate identity
            BIRemoteMethodRef method = BIRemoteMethodCallGetMethod(call);
            BIRemoteMethodArgRef methodArg = BIRemoteMethodCallGetMethodArg(call);
            identity = call->version + call->flatMemorySize + BIRemoteMethodGetSignature(method) + BIRemoteMethodArgGetSignature(methodArg) + BIRemoteMethodReturnTypeMakeSignature(call->returnType);
            if (call->isMemoryFlat)
            {
                call->identity = identity;
            }
        }
        else
        {
            identity = call->identity;
        }
    }
    return identity;
}

BIRemoteMethodRef BIRemoteMethodCallGetMethod(BIRemoteMethodCallRef call)
{
    if (call)
    {
        if (call->isMemoryFlat)
        {
            if (call->pMethodOffset == 0)
            {
                return NULL;
            }
            return (BIRemoteMethodRef)BI_INCREATMENT_POINTER(call, call->pMethodOffset);
        }
        else
        {
            return call->pMethod;
        }
    }
    else
    {
        return NULL;
    }
}

BIRemoteMethodArgRef BIRemoteMethodCallGetMethodArg(BIRemoteMethodCallRef call)
{
    if (call)
    {
        if (call->isMemoryFlat)
        {
            if (call->pMethodArgOffset == 0)
            {
                return NULL;
            }
            return (BIRemoteMethodArgRef)BI_INCREATMENT_POINTER(call, call->pMethodArgOffset);
        }
        else
        {
            return call->pMethodArg;
        }
    }
    else
    {
        return NULL;
    }
}

void BIRemoteMethodCallSetReturnType(BIRemoteMethodCallRef call, BIRemoteMethodReturnType type)
{
    if (call)
    {
        call->returnType = type;
    }
}

BIRemoteMethodReturnType BIRemoteMethodCallGetReturnType(BIRemoteMethodCallRef call)
{
    if (call)
    {
        return call->returnType;
    }
    return BIRemoteMethodReturnTypeVoid;
}

void BIRemoteMethodCallRelease(BIRemoteMethodCallRef call)
{
    if (call)
    {
        if (!call->isMemoryFlat)
        {
            BIRemoteMethodRelease(call->pMethod);
            BIRemoteMethodArgRelease(call->pMethodArg);
        }
        free(call);
    }
}

char* BIRemoteMethodCallDebugInfo(BIRemoteMethodCallRef call)
{
    if (call)
    {
        char* methodDbgInfo = BIRemoteMethodDebugInfo(BIRemoteMethodCallGetMethod(call));
        char* argDbgInfo = BIRemoteMethodArgDebugInfo(BIRemoteMethodCallGetMethodArg(call));
        char* returnTypeDbgInfo = BIRemoteMethodReturnTypeDebugInfo(call->returnType);
        
        size_t bufferLen = BIRMC_DEBUG_INFO_BUFFER_UNIT*2 + (methodDbgInfo ? strlen(methodDbgInfo) : 0) + (argDbgInfo ? strlen(argDbgInfo) : 0) + (returnTypeDbgInfo ? strlen(returnTypeDbgInfo) : 0);
        char* dbgInfo = calloc(1, bufferLen);
        
        if (dbgInfo)
        {
            sprintf(dbgInfo, "{this:%p version:%d, identity:%d, isMemoryFlat:%d, flatMemorySize:%d, BIRemoteMethod:%s, BIRemoteMethodArg:%s, BIRemoteMethodReturnType:%s}", call, call->version, (unsigned int)call->identity, call->isMemoryFlat, (unsigned int)call->flatMemorySize, methodDbgInfo?methodDbgInfo:"", argDbgInfo?argDbgInfo:"", returnTypeDbgInfo?returnTypeDbgInfo:"");
        }
        
        free(returnTypeDbgInfo);
        free(argDbgInfo);
        free(methodDbgInfo);
        
        return dbgInfo;
    }
    return NULL;
}


