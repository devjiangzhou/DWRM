//
//  BIRemoteMethodArgument.m
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-5.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import "BIRemoteMethodPublic.h"
#import "BIRemoteMethodConst.h"

#define BI_REMOTE_METHOD_ARG_DATA_UNIT 1024
#define BI_REMOTE_METHOD_ARG_BUFFER_COUNT 5

const UInt32 BIRemoteMethodArgOptionData = 0x80000000;
const UInt32 BIRemoteMethodArgOptionOutput = 0x40000000;
const UInt32 BIRemoteMethodArgOptionInput = 0x20000000;
//const UInt32 BIRemoteMethodArgOptionObjC = 0x10000000;

BI_INLINE BOOL BIRemoteMethodArgOptionIsData(UInt32 argType)
{
    return ((argType&BIRemoteMethodArgOptionData) == BIRemoteMethodArgOptionData);
}

BI_INLINE UInt32 BIRemoteMethodArgOptionSetIsData(UInt32 argType)
{
    return argType|BIRemoteMethodArgOptionData;
}

BI_INLINE BOOL BIRemoteMethodArgOptionIsOutput(UInt32 argType)
{
    return ((argType&BIRemoteMethodArgOptionOutput) == BIRemoteMethodArgOptionOutput);
}

BI_INLINE UInt32 BIRemoteMethodArgOptionSetIsOutput(UInt32 argType)
{
    return argType|BIRemoteMethodArgOptionOutput;
}

//BI_INLINE BOOL BIRemoteMethodArgOptionIsInput(UInt32 option)
//{
//    return ((option&BIRemoteMethodArgOptionInput) == BIRemoteMethodArgOptionInput);
//}

//BI_INLINE BOOL BIRemoteMethodArgOptionIsObjC(UInt32 option)
//{
//    return ((option&BIRemoteMethodArgOptionObjC) == BIRemoteMethodArgOptionObjC);
//}

#define BI_REMOTE_METHOD_ARG_TYPE_LEN_MASK 0x0FFFFFFF //This means max data length is 256MB, it's still far more than enough
BI_INLINE UInt32 BIRemoteMethodArgOptionGetLength(UInt32 argType)
{
    return (argType&BI_REMOTE_METHOD_ARG_TYPE_LEN_MASK);
}


struct BIRemoteMethodArg
{
    //-------- 64bit ---------
    UInt8 isMemoryFlat;
    UInt8 argc;
    UInt8 argTypeBufferCount;
    BI_ALIGNMENT_8BIT;
    BI_ALIGNMENT_32BIT;
    //------------------------
    
    
    //-------- 64bit ---------
    union
    {
        UInt64 argTypeListOffset;
        /**
         *  Type is actully the length of each argument, for example, char('c') is 1 and int('i') is 4.
         *  Type is always binary ORed with masks(Type = length | BIRemoteMethodArgOption).
         */
        UInt32 *argTypeList;
    };
    //------------------------
    
    
    //-------- 64bit ---------
    UInt32 argDataLength;
    UInt32 argDataBufferLength;
    //------------------------
    
    
    //-------- 64bit ---------
    union
    {
        UInt64 argDataOffset;
        void *argData;
    };
    //------------------------
} BI_STRUCT_ALIGNMENT;

//============================= private ==============================
#pragma mark - private

char* _BIRemoteMethodArgTypeListDebugInfo(const UInt32 *argTypeList, UInt8 argc)
{
    if (argTypeList && argc > 0)
    {
        char typeInfo[BIRMC_DEBUG_INFO_BUFFER_UNIT];

        char* dbgInfo = calloc(1, sizeof(typeInfo) * argc);
        strcat(dbgInfo, "{");
        
        for (int index = 0; index < argc; index++)
        {
            UInt32 type = argTypeList[index];
            memset(typeInfo, 0, sizeof(typeInfo));
            sprintf(typeInfo, "%d:{type:0X%08X, isData:%d, isOutput:%d, length:%d},", index, (unsigned int)type, BIRemoteMethodArgOptionIsData(type), BIRemoteMethodArgOptionIsOutput(type), (unsigned int)BIRemoteMethodArgOptionGetLength(type));
            strcat(dbgInfo, typeInfo);
        }
        
        strcat(dbgInfo, "}");
        return dbgInfo;
    }
    return NULL;
}

BI_INLINE UInt32 _BIRemoteMethodArgTypeListBufferSizeForCount(UInt8 bufferCount)
{
    //Use UInt32 because argTypeList is of type UInt32*.
    return bufferCount * sizeof(UInt32);
}

SInt32 _BIRemoteMethodArgGrowTypeList(BIRemoteMethodArgRef methodArg)
{
    if (methodArg)
    {
        if (methodArg->isMemoryFlat)
        {
            return BIRemoteMethodErrorFlatMemory;
        }
        
        int argTypeBufferCountAfterGrown = methodArg->argTypeBufferCount + BI_REMOTE_METHOD_ARG_BUFFER_COUNT;
        //realloc won't free old memeory if no enough memory
        UInt32 *argTypeList = realloc(methodArg->argTypeList, _BIRemoteMethodArgTypeListBufferSizeForCount(argTypeBufferCountAfterGrown));
        if (argTypeList)
        {
            methodArg->argTypeList = argTypeList;
            methodArg->argTypeBufferCount = argTypeBufferCountAfterGrown;
            return argTypeBufferCountAfterGrown;
        }
        else
        {
            return BIRemoteMethodErrorCantAlloc;
        }
    }
    return BIRemoteMethodErrorNoOperation;
}

SInt32 _BIRemoteMethodArgGrowArgData(BIRemoteMethodArgRef methodArg, size_t reserveLen)
{
    if (methodArg)
    {
        if (methodArg->isMemoryFlat)
        {
            return BIRemoteMethodErrorFlatMemory;
        }
        
        UInt32 argDataLengthAfterGrown = methodArg->argDataBufferLength;
        while (methodArg->argDataLength + reserveLen > argDataLengthAfterGrown)
        {
            argDataLengthAfterGrown *= 2;
        }
        //此处逻辑略有拖泥带水，应改之
        if (argDataLengthAfterGrown == methodArg->argDataBufferLength)
        {
            return argDataLengthAfterGrown;
        }
        void *argData = realloc(methodArg->argData, argDataLengthAfterGrown);
        if (argData)
        {
            methodArg->argData = argData;
            methodArg->argDataBufferLength = argDataLengthAfterGrown;
            //返回值溢出情况暂不考虑
            return argDataLengthAfterGrown;
        }
        else
        {
            return BIRemoteMethodErrorCantAlloc;
        }
    }
    return BIRemoteMethodErrorNoOperation;
}

/**
 *  Always add argument type first, then add argument data.
 *
 *  @param len len is allowed to be 0, which means it is a placeholder(for creating output arguments) or a NULL pointer.
 *
 *  @return On success, return the arg count after add(positive value).
 */
SInt32 _BIRemoteMethodArgAddArgType(BIRemoteMethodArgRef methodArg, UInt32 len, BOOL isData, BOOL isOutput)
{
    if (methodArg)
    {
        if (methodArg->isMemoryFlat)
        {
            return BIRemoteMethodErrorFlatMemory;
        }
        
        if (methodArg->argc == methodArg->argTypeBufferCount)
        {
            SInt32 argBufferCount = _BIRemoteMethodArgGrowTypeList(methodArg);
            if (argBufferCount <= 0)
            {
                return argBufferCount;
            }
        }
        //add arg type
        if (isData)
        {
            len = BIRemoteMethodArgOptionSetIsData(len);
        }
        if (isOutput)
        {
            len = BIRemoteMethodArgOptionSetIsOutput(len);
        }
        methodArg->argTypeList[methodArg->argc++] = len;
        return methodArg->argc;
    }
    else
    {
        return BIRemoteMethodErrorNoOperation;
    }
}

void _BIRemoteMethodArgUndoLastArgTypeAdd(BIRemoteMethodArgRef methodArg)
{
    if (methodArg)
    {
        methodArg->argc--;
    }
}

/**
 *  Always add argument type first, then add argument data.
 */
SInt32 _BIRemoteMethodArgAddArgData(BIRemoteMethodArgRef methodArg, void *data, size_t len)
{
    if (methodArg && data && len > 0)
    {
        if (methodArg->isMemoryFlat)
        {
            return BIRemoteMethodErrorFlatMemory;
        }
        
        size_t alignLength = BINextAlignment8((UInt32)len);
        if (methodArg->argDataLength + alignLength > methodArg->argDataBufferLength)
        {
            SInt32 argDataBufferLen = _BIRemoteMethodArgGrowArgData(methodArg, alignLength);
            if (argDataBufferLen <= 0)
            {
                return argDataBufferLen;
            }
        }
        //add arg data
        memcpy(BI_INCREATMENT_POINTER(methodArg->argData, methodArg->argDataLength), data, len);
        methodArg->argDataLength += alignLength;
        return methodArg->argDataLength;
    }
    else
    {
        return BIRemoteMethodErrorNoOperation;
    }
}

//============================= public ==============================
#pragma mark - public
BIRemoteMethodArgRef BIRemoteMethodArgCreate()
{
    BIRemoteMethodArgRef methodArg = calloc(1, sizeof(struct BIRemoteMethodArg));
    void *argDataBuffer = calloc(1, BI_REMOTE_METHOD_ARG_DATA_UNIT);
    UInt32 *argTypeList = calloc(BI_REMOTE_METHOD_ARG_BUFFER_COUNT, sizeof(UInt32));
    if (!methodArg || !argDataBuffer || !argTypeList)
    {
        free(methodArg);
        free(argDataBuffer);
        free(argTypeList);
        return NULL;
    }
    methodArg->argTypeList = argTypeList;
    methodArg->argTypeBufferCount = BI_REMOTE_METHOD_ARG_BUFFER_COUNT;
    methodArg->argData = argDataBuffer;
    methodArg->argDataBufferLength = BI_REMOTE_METHOD_ARG_DATA_UNIT;
    return methodArg;
}

UInt32 *BIRemoteMethodArgGetArgTypeList(BIRemoteMethodArgRef methodArg)
{
    if (methodArg)
    {
        if (methodArg->isMemoryFlat)
        {
            if (methodArg->argTypeListOffset == 0)
            {
                return NULL;
            }
            else
            {
                return (UInt32 *)BI_INCREATMENT_POINTER(methodArg, methodArg->argTypeListOffset);
            }
        }
        else
        {
            return methodArg->argTypeList;
        }
    }
    else
    {
        return NULL;
    }
}

void *BIRemoteMethodArgGetArgData(BIRemoteMethodArgRef methodArg)
{
    if (methodArg)
    {
        if (methodArg->isMemoryFlat)
        {
            if (methodArg->argDataOffset == 0)
            {
                return NULL;
            }
            else
            {
                return (void *)BI_INCREATMENT_POINTER(methodArg, methodArg->argDataOffset);
            }
        }
        else
        {
            return methodArg->argData;
        }
    }
    else
    {
        return NULL;
    }
}

UInt8 BIRemoteMethodArgGetArgc(BIRemoteMethodArgRef methodArg)
{
    if (methodArg)
    {
        return methodArg->argc;
    }
    else
    {
        return 0;
    }
}

void *BIRemoteMethodArgGetArgAtIndex(BIRemoteMethodArgRef methodArg, int index)
{
    if (methodArg)
    {
        if (index >= methodArg->argc)
        {
            return NULL;
        }
        
        void *argData = BIRemoteMethodArgGetArgData(methodArg);
        if (argData)
        {
            int offSet = 0;
            int tmpOffSet = 0;
            for (int i = 0; i < index; i++)
            {
                tmpOffSet = BIRemoteMethodArgGetArgTypeAtIndex(methodArg, i, NULL, NULL);
                offSet += BINextAlignment8(tmpOffSet);
            }
            
            UInt32 length = BIRemoteMethodArgGetArgTypeAtIndex(methodArg, index, NULL, NULL);
            if (length == 0 || offSet + BINextAlignment8(length) > methodArg->argDataLength)
            {
                return NULL;
            }
            return BI_INCREATMENT_POINTER(argData, offSet);
        }
    }
    return NULL;
}

UInt32 BIRemoteMethodArgGetArgTypeAtIndex(BIRemoteMethodArgRef methodArg, int index, BOOL *isData, BOOL *isOutPut)
{
    if (methodArg)
    {
        if (index >= methodArg->argc)
        {
            return BIRemoteMethodErrorArrayOverflow;
        }
        UInt32 *typeList = BIRemoteMethodArgGetArgTypeList(methodArg);
        UInt32 type = typeList[index];
        if (isData)
        {
            *isData = BIRemoteMethodArgOptionIsData(type);
        }
        if (isOutPut)
        {
            *isOutPut = BIRemoteMethodArgOptionIsOutput(type);
        }
        return BIRemoteMethodArgOptionGetLength(type);
    }
    else
    {
        return BIRemoteMethodErrorNoOperation;
    }
}

SInt32 BIRemoteMethodArgGetTotalMemorySize(BIRemoteMethodArgRef methodArg)
{
    if (methodArg)
    {
        UInt32 sizeOfStruct = sizeof(struct BIRemoteMethodArg);
        UInt32 argTypeListSize = _BIRemoteMethodArgTypeListBufferSizeForCount(methodArg->argTypeBufferCount);
        return sizeOfStruct + BINextAlignment8(argTypeListSize) + BINextAlignment8(methodArg->argDataBufferLength);
    }
    else
    {
        return BIRemoteMethodErrorNoOperation;
    }
}

void *BIRemoteMethodArgFlatMemoryToBuffer(BIRemoteMethodArgRef methodArg, void *buffer)
{
    if (methodArg && buffer && !methodArg->isMemoryFlat)
    {
        UInt32 sizeOfStruct = sizeof(struct BIRemoteMethodArg);
        UInt64 argTypeListOffset = sizeOfStruct;//typelist的数据紧跟在struct主体之后
        UInt32 argTypeListSize = _BIRemoteMethodArgTypeListBufferSizeForCount(methodArg->argTypeBufferCount);
        UInt64 argDataOffset = argTypeListOffset + BINextAlignment8(argTypeListSize);//data放在typelist的数据之后
        
        memcpy(buffer, methodArg, sizeOfStruct);
        memcpy(BI_INCREATMENT_POINTER(buffer, argTypeListOffset), methodArg->argTypeList, argTypeListSize);
        memcpy(BI_INCREATMENT_POINTER(buffer, argDataOffset), methodArg->argData, methodArg->argDataLength);
        
        ((BIRemoteMethodArgRef)buffer)->isMemoryFlat = YES;
        ((BIRemoteMethodArgRef)buffer)->argTypeListOffset = argTypeListOffset;
        ((BIRemoteMethodArgRef)buffer)->argDataOffset = argDataOffset;
        
        return buffer;
    }
    else
    {
        return NULL;
    }
}

SInt32 BIRemoteMethodArgAddArg(BIRemoteMethodArgRef methodArg, void *data, UInt32 len, BOOL isData, BOOL isOutput)
{
    //if isData == YES, then the NULL pointer with zero length shall be valid.
//    if (methodArg && data && len > 0)
    BOOL isNULLBuffer = isData && (!data || len == 0);
    if (methodArg && (isNULLBuffer || (!isNULLBuffer && data && len > 0)))
    {
        if (isNULLBuffer)
        {
            data = NULL;
            len = 0;
        }
        
        UInt32 tmpRetVal = _BIRemoteMethodArgAddArgType(methodArg, len, isData, isOutput);

        if (tmpRetVal > 0 && !isNULLBuffer)
        {
            if (_BIRemoteMethodArgAddArgData(methodArg, data, len) > 0)
            {
                return BIRemoteMethodArgGetArgc(methodArg);
            }
            else
            {
                //rollback
                _BIRemoteMethodArgUndoLastArgTypeAdd(methodArg);
                return -1;
            }
        }
        else
        {
            return tmpRetVal;
        }
    }
    return BIRemoteMethodErrorNoOperation;
}

void BIRemoteMethodArgRelease(BIRemoteMethodArgRef methodArg)
{
    if (methodArg)
    {
        if (!methodArg->isMemoryFlat)
        {
            free(methodArg->argTypeList);
            free(methodArg->argData);
        }
        free(methodArg);
    }
}

BIRemoteMethodArgRef BIRemoteMethodArgCreateOutput(BIRemoteMethodArgRef methodArg)
{
    BIRemoteMethodArgRef retMethodArg = NULL;
    if (methodArg)
    {
        //@todo Performence:We could test whether there is any output argument first, and if NOT, we return immediately.
        retMethodArg = BIRemoteMethodArgCreate();
        if (retMethodArg)
        {
            UInt32 tmpDataLen;
            void *tmpData;
            BOOL tmpDataMask, tmpOutputMask;
            BOOL hasError = NO;
            for (int index = 0; index < methodArg->argc; index++)
            {
                tmpDataLen = BIRemoteMethodArgGetArgTypeAtIndex(methodArg, index, &tmpDataMask, &tmpOutputMask);
                tmpData = BIRemoteMethodArgGetArgAtIndex(methodArg, index);
                if (tmpOutputMask)//if output mask is set, the data should be copied.
                {
                    if (BIRemoteMethodArgAddArg(retMethodArg, tmpData, tmpDataLen, tmpDataMask, tmpOutputMask) <= 0)
                    {
                        hasError = YES;
                        break;
                    }
                }
                else//if output mask is NOT set, there should be a placeholder.
                {
                    _BIRemoteMethodArgAddArgType(retMethodArg, 0, tmpDataMask, tmpOutputMask);
                }
            }
            if (hasError || retMethodArg->argc == 0)
            {
                BIRemoteMethodArgRelease(retMethodArg);
                retMethodArg = NULL;
            }
        }
    }
    return retMethodArg;
}

UInt32 BIRemoteMethodArgGetSignature(BIRemoteMethodArgRef methodArg)
{
    UInt32 sig = 0;
    if (methodArg)
    {
        sig += methodArg->argc + methodArg->argDataLength;
        BOOL isData, isOutput;
        for (int i = 0; i < methodArg->argc; i++)
        {
            UInt32 type = BIRemoteMethodArgGetArgTypeAtIndex(methodArg, i, &isData, &isOutput);
            sig += type + isData + isOutput;
        }
    }
    return sig;
}

char* BIRemoteMethodArgDebugInfo(BIRemoteMethodArgRef methodArg)
{
    if (methodArg)
    {
        char* argTypeListDbgInfo = _BIRemoteMethodArgTypeListDebugInfo(BIRemoteMethodArgGetArgTypeList(methodArg), methodArg->argc);
        
        const char* dataDesc = NULL;
        void* data = BIRemoteMethodArgGetArgData(methodArg);
        if (data && methodArg->argDataLength > 0)
        {
            dataDesc = [[[NSData dataWithBytesNoCopy:data length:methodArg->argDataLength freeWhenDone:NO] debugDescription] UTF8String];
        }

        char* dbgInfo = calloc(1, BIRMC_DEBUG_INFO_BUFFER_UNIT + (argTypeListDbgInfo ? strlen(argTypeListDbgInfo) : 0) + (dataDesc ? strlen(dataDesc) : 0));
        
        if (dbgInfo)
        {
            sprintf(dbgInfo, "{this:%p, isMemeoryFlat:%d, argc:%d, argTypeBufferCount:%d, argTypeList:%s, argDataLength:%d, argDataBufferLength:%d, dataOffset:%llu, data:(%p)%s}", methodArg, methodArg->isMemoryFlat, methodArg->argc, methodArg->argTypeBufferCount, argTypeListDbgInfo?argTypeListDbgInfo:"", (unsigned int)methodArg->argDataLength, (unsigned int)methodArg->argDataBufferLength, (UInt64)methodArg->argDataOffset, data, dataDesc?dataDesc:"");
        }
        
        free(argTypeListDbgInfo);
        return dbgInfo;
    }
    return NULL;
}


