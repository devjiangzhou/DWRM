//
//  BIRemoteMethodSend.m
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-5.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#include <dlfcn.h>
#import "BIRemoteMethodInvoke.h"

//============================= private ==============================
#pragma mark - private

BIRemoteMethodReturnRef _parseRawReturnDataAndCreateMethodReturn(BIRemoteMethodCallRef call, void *returnVal)
{
    if (!call)
    {
        return NULL;
    }
    
    BIRemoteMethodReturnRef methodReturn = BIRemoteMethodReturnCreate(call);
    BIRemoteMethodReturnType returnType = BIRemoteMethodCallGetReturnType(call);
    BIRMCDPRINT(@"returntype structure:%i", returnType.structure);
    switch (returnType.structure)
    {
        case BIRemoteMethodReturnTypeStructureValue:
        {
            void *addrOfVal = returnVal;
            BIRemoteMethodReturnSetValue(methodReturn, addrOfVal);
            break;
        }
            
        case BIRemoteMethodReturnTypeStructureNulTerminatedData:
        {
            UInt32 length = BIRemoteMethodReturnTypeGetNulTerminatedDataLength(returnVal, returnType.option2);
            BIRemoteMethodReturnSetData(methodReturn, returnVal, length);
            break;
        }
        
        //this case is unexpected.
        case BIRemoteMethodReturnTypeStructureCalculatedData:
        {
            BIRemoteMethodReturnSetData(methodReturn, returnVal, returnType.option2);
            break;
        }
        
        case BIRemoteMethodReturnTypeStructureFixedLengthData:
        {
//            void *dataBuffer = (void *)(*((UInt64 *)returnVal));
            void *dataBuffer = returnVal;
            UInt32 dataLen = BIRemoteMethodReturnTypeTryGetDataLength(returnType);
            BIRemoteMethodReturnSetData(methodReturn, dataBuffer, dataLen);
            break;
        }
            
        case BIRemoteMethodReturnTypeStructureArgumentLengthData:
        {
            BIRemoteMethodArgRef methodArg = BIRemoteMethodCallGetMethodArg(call);
            int argIndex = returnType.option1;
            void *arg = BIRemoteMethodArgGetArgAtIndex(methodArg, argIndex);
            UInt32 argLen = BIRemoteMethodArgGetArgTypeAtIndex(methodArg, argIndex, NULL, NULL);
            UInt32 dataLen = BIRemoteMethodReturnTypeGetArgumentLengthDataLength(arg, argLen, returnType.option2);
//            void *dataBuffer = (void *)(*((UInt64 *)returnVal));
            void *dataBuffer = returnVal;
            BIRemoteMethodReturnSetData(methodReturn, dataBuffer, dataLen);
            break;
        }
            
        case BIRemoteMethodReturnTypeStructureDynamicData:
            //not implemented
            assert(0);
            break;
            
        case BIRemoteMethodReturnTypeStructureVoid:
        default:
            break;
    }
    return methodReturn;
}

extern void* IPTCoreExtGetSingletonCore_bi_remote_(BIRemoteMethodCallRef call, BOOL *freeReturnData);
void *_BIRemoteMethodCFuncHandlerCallWrapper(BIRemoteMethodCallRef call, const char *suffix, BOOL *freeReturnData)
{
    BIRemoteMethodRef method = BIRemoteMethodCallGetMethod(call);
    const char *methodName = BIRemoteMethodGetName(method);
    
    if (!methodName)
    {
        return NULL;
    }
    
    void *pFunc = NULL;
    if (suffix)
    {
        char * methodWrapName = malloc(strlen(methodName) + strlen(suffix) + 1);
        if (methodWrapName)
        {
            methodWrapName[0] = '\0';
            strcat(methodWrapName, methodName);
            strcat(methodWrapName, suffix);
            pFunc = dlsym(RTLD_DEFAULT, methodName);
            free(methodWrapName);
        }
    }
    else
    {
        pFunc = dlsym(RTLD_DEFAULT, methodName);
    }
    
    if (pFunc)
    {
        BIRMCDPRINT(@"call methodName %s, call %p", methodName, call);
        return ((BIRemoteMethodCFuncHandlerCalledWrapperFunc)pFunc)(call, freeReturnData);
    }
    else
    {
        BIRMCDPRINT(@"dlsym function:%s not found.", methodName);
        return NULL;
    }
}
BIRemoteMethodCFuncHandler BIRemoteMethodCFuncHandlerCallWrapper = (BIRemoteMethodCFuncHandler)_BIRemoteMethodCFuncHandlerCallWrapper;



//============================= public ==============================
#pragma mark - public

BIRemoteMethodReturnRef BIRemoteMethodCallSendObjCAndCreateMethodReturn(BIRemoteMethodCallRef call, id receiver)
{
    if (call && receiver)
    {
        BIRemoteMethodRef method = BIRemoteMethodCallGetMethod(call);
        BIRemoteMethodArgRef methodArg = BIRemoteMethodCallGetMethodArg(call);
        const char *methodNameCString = BIRemoteMethodGetName(method);
        NSString *methodName = [NSString stringWithUTF8String:methodNameCString];
        SEL selector = NSSelectorFromString(methodName);
        NSMethodSignature *sig = [receiver methodSignatureForSelector:selector];
        if (sig)
        {
            NSInvocation* invo = [NSInvocation invocationWithMethodSignature:sig];
            [invo setTarget:receiver];
            [invo setSelector:selector];
            if (methodArg)
            {
                int argc = BIRemoteMethodArgGetArgc(methodArg);
                for (int index = 0; index < argc; index++)
                {
                    void *arg = BIRemoteMethodArgGetArgAtIndex(methodArg, index);
                    BOOL isData;
                    BIRemoteMethodArgGetArgTypeAtIndex(methodArg, index, &isData, NULL);
                    if (isData)
                    {
                        [invo setArgument:&arg atIndex:index+2];
                    }
                    else
                    {
                        [invo setArgument:arg atIndex:index+2];
                    }
                }
            }
            [invo invoke];
            //get return value
            id returnData = nil;
            if (sig.methodReturnLength > 0)
            {
                [invo getReturnValue:&returnData];
            }
            return _parseRawReturnDataAndCreateMethodReturn(call, returnData);
        }
    }
    return NULL;
}

BIRemoteMethodReturnRef BIRemoteMethodCallSendCAndCreateMethodReturn(BIRemoteMethodCallRef call, BIRemoteMethodCFuncHandler handler, void *userInfo)
{
    if (call && handler)
    {
        BOOL shouldFreeReturnData = NO;
        //returnData may be NULL, and it shall be valid.
        void *returnData = handler(call, userInfo, &shouldFreeReturnData);
        BIRemoteMethodReturnRef methodReturnRef = _parseRawReturnDataAndCreateMethodReturn(call, returnData);
        if (shouldFreeReturnData)
        {
            free(returnData);
        }
        return methodReturnRef;
    }
    return NULL;
}

