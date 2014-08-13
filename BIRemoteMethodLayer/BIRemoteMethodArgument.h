//
//  BIRemoteMethodArgument.h
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-5.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *	BIRemoteMethodArg is an opaque type that holds method arguments, and the arguments are stored in the form of data-length pairs.
 */
typedef struct BIRemoteMethodArg * BIRemoteMethodArgRef;

//Create
/**
 *  Allocate a new BIRemoteMethodArg
 *
 *  @return A reference to the allocated BIRemoteMethodArg, it's users responsibility to free the memory.
 */
BIRemoteMethodArgRef BIRemoteMethodArgCreate();

/**
 *  On return, we should kick out the input-only arguments for reducing data size.
 *
 *  @param methodArg The origin BIRemoteMethodArg.
 *
 *  @return A reference to the allocated BIRemoteMethodArg, it's users responsibility to free the memory.
 */
BIRemoteMethodArgRef BIRemoteMethodArgCreateOutput(BIRemoteMethodArgRef methodArg);

UInt32 BIRemoteMethodArgGetSignature(BIRemoteMethodArgRef methodArg);

//Get
UInt8 BIRemoteMethodArgGetArgc(BIRemoteMethodArgRef methodArg);
/**
 *  @return The returned pointer is a reference to the internal data, you should not free it.
 */
UInt32 *BIRemoteMethodArgGetArgTypeList(BIRemoteMethodArgRef methodArg);

UInt32 BIRemoteMethodArgGetArgTypeAtIndex(BIRemoteMethodArgRef methodArg, int index, BOOL *isData, BOOL *isOutPut);

/**
 *  @return The returned pointer is a reference to the internal data, you should not free it.
 */
void *BIRemoteMethodArgGetArgData(BIRemoteMethodArgRef methodArg);

/**
 *  @return The returned pointer is a reference to the internal data, you should not free it.
 *  @note Return NULL may indicate the data is a placeholder with zero length.
 */
void *BIRemoteMethodArgGetArgAtIndex(BIRemoteMethodArgRef methodArg, int index);



//Flat memory
/**
 *  Get the total size of a BIRemoteMethodArg, use this size to allocate buffer for @see BIRemoteMethodArgFlatMemoryToBuffer
 *
 *  @return Size of total memory usage, or negative value on error.
 */
SInt32 BIRemoteMethodArgGetTotalMemorySize(BIRemoteMethodArgRef methodArg);

/**
 *  Copy BIRemoteMethodArg into buffer.
 *
 *  @param buffer    Using @see BIRemoteMethodArgGetTotalMemorySize to get an appropriate buffer size.
 *
 *  @return The buffer, or NULL on error.
 */
void *BIRemoteMethodArgFlatMemoryToBuffer(BIRemoteMethodArgRef methodArg, void *buffer);


//Add arg
/**
 *  @param methodArg A reference to the BIRemoteMethodArg
 *  @param data         Pointer to a value/buffer.
 *  @param len          Size of data in byte.
 *  @param copyData     If YES, the |data| is treated as a buffer, otherwise |data| is treated as the address of a varible.
 *  @param isOutput  Whether this arguments if for output.
 *
 *  @return Total count of argument after adding. or negative value on error.
 */
SInt32 BIRemoteMethodArgAddArg(BIRemoteMethodArgRef methodArg, void *data, UInt32 len, BOOL copyData, BOOL isOutput);


//Release
void BIRemoteMethodArgRelease(BIRemoteMethodArgRef methodArg);

//debug
char* BIRemoteMethodArgDebugInfo(BIRemoteMethodArgRef methodArg);
