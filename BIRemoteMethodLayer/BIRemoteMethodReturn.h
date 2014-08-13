//
//  BIRemoteMethodReturn.h
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-5.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BIRemoteMethodCall.h"

/**
 *  BIRemoteMethodReturn is an opaque type which holds a method call's return type and data.
 *  @note:After flatting its memory, any modifing operation is NOT allowed, and will have no effect. After flat, the object is guarantied to be stored in a continuous memory segment and thus can be can be treated as serialized.
 */
typedef struct BIRemoteMethodReturn * BIRemoteMethodReturnRef;

//Create
BIRemoteMethodReturnRef BIRemoteMethodReturnCreate(BIRemoteMethodCallRef call);

BIRemoteMethodReturnRef BIRemoteMethodReturnCreateFlatMemory(BIRemoteMethodReturnRef methodReturn);
BOOL BIRemoteMethodReturnIsMemoeryFlat(BIRemoteMethodReturnRef methodReturn);
UInt32 BIRemoteMethodReturnGetFlatMemorySize(BIRemoteMethodReturnRef methodReturn);

UInt32 BIRemoteMethodReturnGetIdentity(BIRemoteMethodReturnRef methodReturn);

//Get
/**
 *  @return The returning BIRemoteMethodArg is created by @see BIRemoteMethodArgCreateOutput, which means all input-only arguments are lost.
 */
BIRemoteMethodArgRef BIRemoteMethodReturnGetMethodArg(BIRemoteMethodReturnRef methodReturn);

/**
 *  @param buffer The buffer must be large enough to hold the return value;
 */
void BIRemoteMethodReturnGetReturnValue(BIRemoteMethodReturnRef ret, void *buffer);

/**
 *  @return The returned data is not copied, and will certainly be not live longer than the object
 */
void *BIRemoteMethodReturnGetReturnData(BIRemoteMethodReturnRef ret);

void *BIRemoteMethodReturnCopyReturnData(BIRemoteMethodReturnRef ret);

UInt32 BIRemoteMethodReturnGetReturnDataLength(BIRemoteMethodReturnRef ret);

//Set
/**
 *  @param ptr          Address of value
 */
void *BIRemoteMethodReturnSetValue(BIRemoteMethodReturnRef methodReturn, const void *ptr);
void *BIRemoteMethodReturnSetData(BIRemoteMethodReturnRef methodReturn, const void *ptr, UInt32 length);

//Release
void BIRemoteMethodReturnRelease(BIRemoteMethodReturnRef methodReturn);

//debug
char* BIRemoteMethodReturnDebugInfo(BIRemoteMethodReturnRef methodReturn);
