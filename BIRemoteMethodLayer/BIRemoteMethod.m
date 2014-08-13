//
//  BIRemoteMethod.m
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-5.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import "BIRemoteMethodPublic.h"
#import "BIRemoteMethodConst.h"

NS_ENUM(UInt8, BIRemoteMethodType)
{
    BIRemoteMethodTypeUnknown,
    BIRemoteMethodTypeC,
    BIRemoteMethodTypeObjC,
};

struct BIRemoteMethod
{
    //-------- 64bit ---------
    UInt8 type;//0:unknown 1:c 2:objc
    UInt8 nameStrlen;//length does not include '\0'
    UInt8 isMemoryFlat;
    BI_ALIGNMENT_8BIT;
    BI_ALIGNMENT_32BIT;
    //------------------------
    
    //-------- 64bit ---------
    union
    {
        UInt64 nameOffset;
        char *name;//'\0' terminated c string.
    };
    //------------------------
    
} BI_STRUCT_ALIGNMENT;

//============================= private ==============================
#pragma mark - private

BIRemoteMethodRef _BIRemoteMethodCreate(const char *methodName, UInt8 type)
{
    BIRemoteMethodRef method = calloc(1, sizeof(struct BIRemoteMethod));
    if (method)
    {
        method->type = type;
        method->nameStrlen = strlen(methodName);
        method->name = malloc(sizeof(char)*(method->nameStrlen+1));
        if (method->name)
        {
            memcpy(method->name, methodName, method->nameStrlen+1);
            return method;
        }
        else
        {
            free(method);
            return NULL;
        }
    }
    return NULL;
}


//============================= public ==============================
#pragma mark - public

BIRemoteMethodRef BIRemoteMethodCreateObjC(SEL selector)
{
    NSString *methodName = NSStringFromSelector(selector);
    const char *nameCStr = [methodName UTF8String];
    return _BIRemoteMethodCreate(nameCStr, BIRemoteMethodTypeObjC);
}

BIRemoteMethodRef BIRemoteMethodCreateC(const char *methodName)
{
    return _BIRemoteMethodCreate(methodName, BIRemoteMethodTypeC);
}

UInt32 BIRemoteMethodGetSignature(BIRemoteMethodRef method)
{
    UInt32 sig = 0;
    if (method)
    {
        sig = method->type + method->nameStrlen;
        const char *name = BIRemoteMethodGetName(method);
        for (int i = 0; i < method->nameStrlen; i++)
        {
            sig += name[i];
        }
    }
    return sig;
}

const char *BIRemoteMethodGetName(BIRemoteMethodRef method)
{
    if (method)
    {
        if (method->isMemoryFlat)
        {
            if (method->nameOffset == 0)
            {
                return NULL;
            }
            return (const char *)BI_INCREATMENT_POINTER(method, method->nameOffset);
        }
        else
        {
            return method->name;
        }
    }
    return NULL;
}

SInt32 BIRemoteMethodGetTotalMemorySize(BIRemoteMethodRef method)
{
    if (method)
    {
        UInt32 sizeOfStruct = sizeof(struct BIRemoteMethod);
        UInt32 nameStrSize = method->nameStrlen + 1;
        return sizeOfStruct + BINextAlignment8(nameStrSize);
    }
    else
    {
        return BIRemoteMethodErrorNoOperation;
    }
}

void *BIRemoteMethodFlatMemoryToBuffer(BIRemoteMethodRef method, void *buffer)
{
    if (method && buffer)
    {
        size_t sizeOfStruct = sizeof(struct BIRemoteMethod);
        UInt64 nameOffset = sizeOfStruct;
        
        //copy memory
        memcpy(buffer, method, sizeOfStruct);
        memcpy(BI_INCREATMENT_POINTER(buffer, nameOffset), method->name, method->nameStrlen+1);
        //fix member value
        ((BIRemoteMethodRef )buffer)->isMemoryFlat = YES;
        ((BIRemoteMethodRef )buffer)->nameOffset = nameOffset;
    }
    return buffer;
}

void BIRemoteMethodRelease(BIRemoteMethodRef method)
{
    if (method)
    {
        if (!method->isMemoryFlat)
        {
            free(method->name);
        }
        free(method);
    }
}

char* BIRemoteMethodDebugInfo(BIRemoteMethodRef method)
{
    if (method)
    {
        char* dbgInfo = calloc(1, BIRMC_DEBUG_INFO_BUFFER_UNIT);
        sprintf(dbgInfo, "{this:%p, type:%d, nameStrlen:%d, isMemoryFlat:%d, nameOffset:%llu name:%s}", method, method->type, method->nameStrlen, method->isMemoryFlat, method->nameOffset, BIRemoteMethodGetName(method));
        return dbgInfo;
    }
    return NULL;
}
