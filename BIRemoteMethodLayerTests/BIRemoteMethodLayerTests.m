//
//  BIRemoteMethodLayerTests.m
//  BIRemoteMethodLayerTests
//
//  Created by Seven on 14-3-5.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#ifdef CheckMemLeak
#define XCTAssert(exp, ...) //NSLog(@#exp)
#else
#import <XCTest/XCTest.h>
#endif

#include <dlfcn.h>
#import "BIRemoteMethodPublic.h"


//============================== Dest ObjC ============================
@interface XCTBICore : NSObject

@end

@implementation XCTBICore
- (int)intAtIndex:(int)index
{
    return 333;
}
- (int)lengthOf:(char *)str
{
    return (int)strlen(str);
}

- (int)doubleOf:(int)intVal
{
    return intVal*2;
}

- (char *)version
{
    return "1.0.0.0";
}

- (void)reverse:(char *)p
{
    char *q = p;
    while(q && *q) ++q;
    for(--q; p < q; ++p, --q)
        *p = *p ^ *q,
        *q = *p ^ *q,
        *p = *p ^ *q;
}

@end



//============================== Dest c ============================
char *XCTBICoreVersion()
{
    return "2.1.3.4";
}

void XCTBICoreReverse(char *p)
{
    char *q = p;
    while(q && *q) ++q;
    for(--q; p < q; ++p, --q)
        *p = *p ^ *q,
        *q = *p ^ *q,
        *p = *p ^ *q;
}


//============================== Server c ============================
#define SUFFIX "Wrap"
void *XCTBICoreVersionWrap(BIRemoteMethodCallRef call)
{
    return XCTBICoreVersion();
}

void *XCTBICoreReverseWrap(BIRemoteMethodCallRef call)
{
    char *p = NULL;
    BIRemoteMethodArgRef methodArg = BIRemoteMethodCallGetMethodArg(call);
    if (methodArg)
    {
        void *arg = BIRemoteMethodArgGetArgAtIndex(methodArg, 0);
        if (arg)
        {
            p = arg;
        }
    }
    XCTBICoreReverse(p);
    return NULL;
}

//============================== Fake Layer ============================
@interface XCTBIRemote : NSObject
+ (BIRemoteMethodReturnRef)sendRemoteMessage:(BIRemoteMethodCallRef)call;
@end
@implementation XCTBIRemote
+ (BIRemoteMethodReturnRef)sendRemoteMessage:(BIRemoteMethodCallRef)call
{
    BIRemoteMethodCallRef callFlat = BIRemoteMethodCallCreateFlatMemory(call);
    UInt32 callId = BIRemoteMethodCallGetIdentity(callFlat);
    BIRemoteMethodReturnRef retFlat = [self receiveRemoteMessage:callFlat];
    UInt32 retId = BIRemoteMethodReturnGetIdentity(retFlat);
    BIRemoteMethodCallRelease(callFlat);
    if (callId != retId)
    {
        BIRemoteMethodReturnRelease(retFlat);
        return NULL;
    }
    return retFlat;
}

+ (BIRemoteMethodReturnRef)sendRemoteMessageC:(BIRemoteMethodCallRef)call
{
    BIRemoteMethodCallRef callFlat = BIRemoteMethodCallCreateFlatMemory(call);
    UInt32 callId = BIRemoteMethodCallGetIdentity(callFlat);
    BIRemoteMethodReturnRef retFlat = [self receiveRemoteMessageC:callFlat];
    UInt32 retId = BIRemoteMethodReturnGetIdentity(retFlat);
    BIRemoteMethodCallRelease(callFlat);
    if (callId != retId)
    {
        BIRemoteMethodReturnRelease(retFlat);
        return NULL;
    }
    return retFlat;
}

+ (BIRemoteMethodReturnRef)receiveRemoteMessage:(BIRemoteMethodCallRef)call
{
    XCTBICore *core = [[[XCTBICore alloc] init] autorelease];
    BIRemoteMethodReturnRef methodReturn = BIRemoteMethodCallSendObjCAndCreateMethodReturn(call, core);
    BIRemoteMethodReturnRef methodReturnFlat = BIRemoteMethodReturnCreateFlatMemory(methodReturn);
    BIRemoteMethodReturnRelease(methodReturn);
    return methodReturnFlat;
}

+ (BIRemoteMethodReturnRef)receiveRemoteMessageC:(BIRemoteMethodCallRef)call
{
    BIRemoteMethodReturnRef methodReturn = BIRemoteMethodCallSendCAndCreateMethodReturn(call, BIRemoteMethodCFuncHandlerCallWrapper, SUFFIX);
    BIRemoteMethodReturnRef methodReturnFlat = BIRemoteMethodReturnCreateFlatMemory(methodReturn);
    BIRemoteMethodReturnRelease(methodReturn);
    return methodReturnFlat;
}

@end




//============================== Tests ============================
@interface BIRemoteMethodLayerTests : XCTestCase
{
    XCTBICore *_core;
}
@end

@implementation BIRemoteMethodLayerTests

- (void)fake
{
    XCTBICoreReverseWrap(NULL);
    XCTBICoreVersionWrap(NULL);
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _core = [[XCTBICore alloc] init];
}

- (void)tearDown
{
    [_core release];
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (int)lengthOf:(char *)str
{
    BIRemoteMethodCallRef call = BIRemoteMethodCallCreateObjC(_cmd);
    //config
    BIRemoteMethodCallAddArgumentCopyData(call, str, (UInt32)(strlen(str)+1), NO);
    BIRemoteMethodCallSetReturnType(call, BIRemoteMethodReturnTypeMakeStructureValue(sizeof(int)));
    //send message
    BIRemoteMethodReturnRef methodReturnFlat = [XCTBIRemote sendRemoteMessage:call];
    BIRemoteMethodCallRelease(call);
    //handle return
    if (methodReturnFlat)
    {
        int returnVal;
        BIRemoteMethodReturnGetReturnValue(methodReturnFlat, &returnVal);
        BIRemoteMethodReturnRelease(methodReturnFlat);
        return returnVal;
    }
    return 0;
}

- (void)testDataArg
{
    char *cstr = "haf";
    int ret = [self lengthOf:cstr];
    XCTAssert(ret == [_core lengthOf:cstr], @"");
}

- (void)reverse:(char *)str
{
    BIRemoteMethodCallRef call = BIRemoteMethodCallCreateObjC(_cmd);
    //config
    BIRemoteMethodCallAddArgumentCopyData(call, str, (UInt32)(strlen(str)+1), YES);
    //send message
    BIRemoteMethodReturnRef methodReturnFlat = [XCTBIRemote sendRemoteMessage:call];
    BIRemoteMethodCallRelease(call);
    //handle return
    if (methodReturnFlat)
    {
        BIRemoteMethodArgRef methodArg = BIRemoteMethodReturnGetMethodArg(methodReturnFlat);
        void *arg = BIRemoteMethodArgGetArgAtIndex(methodArg, 0);
        strcpy(str, (const char *)arg);
        BIRemoteMethodReturnRelease(methodReturnFlat);
    }
}


- (void)testArgInOut
{
#define STR "abced"
    
    char *str2 = strdup(STR);
    [_core reverse:str2];
    
    
    char *str1 = strdup(STR);
    [self reverse:str1];

    
    XCTAssert(strcmp(str1, str2) == 0, @"");
    
    free(str1);
    free(str2);
}


- (char *)version
{
    BIRemoteMethodCallRef call = BIRemoteMethodCallCreateObjC(_cmd);
    //config
    BIRemoteMethodCallSetReturnType(call, BIRemoteMethodReturnTypeMakeStructureNulTerminatedData(sizeof(char)));
    //send message
    BIRemoteMethodReturnRef methodReturnFlat = [XCTBIRemote sendRemoteMessage:call];
    BIRemoteMethodCallRelease(call);
    //handle return
    if (methodReturnFlat)
    {
        char *returnVal;
        returnVal = BIRemoteMethodReturnGetReturnData(methodReturnFlat);
        returnVal = strdup(returnVal);
        BIRemoteMethodReturnRelease(methodReturnFlat);
        return returnVal;
    }
    return NULL;
}

- (void)testDataReturn
{
    char *version = [self version];
    XCTAssert(strcmp(version, [_core version]) == 0, @"");
    
    free(version);
}


- (char *)XCTBICoreVersion
{
    BIRemoteMethodCallRef call = BIRemoteMethodCallCreateC("XCTBICoreVersion");
    //config
    BIRemoteMethodCallSetReturnType(call, BIRemoteMethodReturnTypeMakeStructureNulTerminatedData(sizeof(char)));
    //send message
    BIRemoteMethodReturnRef methodReturnFlat = [XCTBIRemote sendRemoteMessageC:call];
    BIRemoteMethodCallRelease(call);
    //handle return
    if (methodReturnFlat)
    {
        char *returnVal;
        returnVal = BIRemoteMethodReturnGetReturnData(methodReturnFlat);
        returnVal = strdup(returnVal);
        BIRemoteMethodReturnRelease(methodReturnFlat);
        return returnVal;
    }
    return NULL;
}

- (void)testDataReturnC
{
    char *version = [self XCTBICoreVersion];
    XCTAssert(strcmp(version, XCTBICoreVersion()) == 0, @"");
    
    free(version);
}


- (void)XCTBICoreReverse:(char *)str
{
    BIRemoteMethodCallRef call = BIRemoteMethodCallCreateC("XCTBICoreReverse");
    //config
    BIRemoteMethodCallAddArgumentCopyData(call, str, (UInt32)(strlen(str)+1), YES);
    //send message
    BIRemoteMethodReturnRef methodReturnFlat = [XCTBIRemote sendRemoteMessageC:call];
    BIRemoteMethodCallRelease(call);
    //handle return
    if (methodReturnFlat)
    {
        BIRemoteMethodArgRef methodArg = BIRemoteMethodReturnGetMethodArg(methodReturnFlat);
        void *arg = BIRemoteMethodArgGetArgAtIndex(methodArg, 0);
        strcpy(str, (const char *)arg);
        BIRemoteMethodReturnRelease(methodReturnFlat);
    }
}


- (void)testArgInOutC
{
#define STR "abced"
    
    char *str2 = strdup(STR);
    XCTBICoreReverse(str2);
    
    
    char *str1 = strdup(STR);
    [self XCTBICoreReverse:str1];
    
    
    XCTAssert(strcmp(str1, str2) == 0, @"");
    
    free(str1);
    free(str2);
}

@end
