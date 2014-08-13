//
//  BIRemoteMethodCall.h
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-5.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BIRemoteMethod.h"
#import "BIRemoteMethodArgument.h"
#import "BIRemoteMethodReturnType.h"

/**
 *  BIRemoteMethodCall is an opaque type which describes a method call, and it also holds the associated arguments' data.
 *  @note: After flatting its memory, any modifing operation is NOT allowed, and will have no effect. After flat, the object is guarantied to be stored in a continuous memory segment and thus can be can be treated as serialized.
 */
typedef struct BIRemoteMethodCall * BIRemoteMethodCallRef;

//Create
BIRemoteMethodCallRef BIRemoteMethodCallCreateC(const char *method);

BIRemoteMethodCallRef BIRemoteMethodCallCreateFlatMemory(BIRemoteMethodCallRef call);
BOOL BIRemoteMethodCallIsMemoeryFlat(BIRemoteMethodCallRef call);
UInt32 BIRemoteMethodCallGetFlatMemorySize(BIRemoteMethodCallRef call);


//identity
UInt32 BIRemoteMethodCallGetIdentity(BIRemoteMethodCallRef call);


//Get arg
BIRemoteMethodRef BIRemoteMethodCallGetMethod(BIRemoteMethodCallRef call);
BIRemoteMethodArgRef BIRemoteMethodCallGetMethodArg(BIRemoteMethodCallRef call);
BIRemoteMethodReturnType BIRemoteMethodCallGetReturnType(BIRemoteMethodCallRef call);


//Set return
void BIRemoteMethodCallSetReturnType(BIRemoteMethodCallRef call, BIRemoteMethodReturnType type);


//Add Arguments
/**
 *  @param call A BIRemoteMethodCall
 *  @param pArg The address of an argument.
 *  @param len  The length of the argument, usually get from sizeof().
 *
 *  @return On success, returns the total count of arguments; On fail, return a negative value.
 */
SInt32 BIRemoteMethodCallAddArgument(BIRemoteMethodCallRef call, void *pArg, UInt32 len);

/**
 *  @param call A BIRemoteMethodCall
 *  @param buffer   The buffer.
 *  @param len      Length of the buffer.
 *  @param isOutPut Whether the argument is for output.
 *
 *  @return On success, returns the total count of arguments; On fail, return a negative value.
 */
SInt32 BIRemoteMethodCallAddArgumentCopyData(BIRemoteMethodCallRef call, void *buffer, UInt32 len, BOOL isOutPut);


//Release
void BIRemoteMethodCallRelease(BIRemoteMethodCallRef call);

//debug
char* BIRemoteMethodCallDebugInfo(BIRemoteMethodCallRef call);

