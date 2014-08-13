//
//  BIRemoteMethod.h
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-5.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  @class BIRemoteMethod
 *	@brief BIRemoteMethod is an opaque type that describes the base information of a method including:
 *  1.Method name
 *  2.Method type(C/ObjC)
 */

typedef struct BIRemoteMethod * BIRemoteMethodRef;

//Create
/**
 *	@brief	BIRemoteMethodCreateC
 *
 *	@param 	methodName  A mathod name, null-terminated, empty string is allowed.
 *
 *	@return	A reference of BIRemoteMethod for c function, it is the user's responsibility to release the memory. @see BIRemoteMethodRelease()
 */
BIRemoteMethodRef BIRemoteMethodCreateC(const char *methodName);

/**
 *	@brief	BIRemoteMethodCreateObjC
 *
 *	@param 	selector 	The selector of A ObjC method.
 *
 *	@return	A reference of BIRemoteMethod for Objective-C method, it is the user's responsibility to release the memory. @see BIRemoteMethodRelease()
 */
BIRemoteMethodRef BIRemoteMethodCreateObjC(SEL selector);


/**
 *  Generate signature for the BIRemoteMethod |method|, @note that the method name is not MD5ed, but plused verbatim for performence.
 *
 *  @param method A reference to BIRemoteMethod
 *
 *  @return The signature
 */
UInt32 BIRemoteMethodGetSignature(BIRemoteMethodRef method);


//Get
/**
 *  The returned C string is a pointer to a structure inside the BIRemoteMethod |method|, which may have a lifetime shorter than the string object and will certainly not have a longer lifetime. Therefore, you should copy the C string if it needs to be stored outside of the memory context in which you called this method.
 *
 *  @param method A reference to BIRemoteMethod
 *
 *  @return The mathod name, null-terminated.
 */
const char *BIRemoteMethodGetName(BIRemoteMethodRef method);


//Flat memory
/**
 *  The memory size may be used for BIRemoteMethodFlatMemoryToBuffer()
 *
 *  @param method A reference to BIRemoteMethod
 *
 *  @return The total size of BIRemoteMethod |method|, including all memeory it has allocated internally.
 */
SInt32 BIRemoteMethodGetTotalMemorySize(BIRemoteMethodRef method);
/**
 *  Use BIRemoteMethodGetTotalMemorySize() to get a pri buffer size.
 *
 *  @param method A reference to BIRemoteMethod
 *  @param buffer Buffer size should be large enough to hold the |method|
 *
 *  @return The pointer to the buffer.
 */
void *BIRemoteMethodFlatMemoryToBuffer(BIRemoteMethodRef method, void *buffer);

//Release
void BIRemoteMethodRelease(BIRemoteMethodRef method);

//debug
char* BIRemoteMethodDebugInfo(BIRemoteMethodRef method);
