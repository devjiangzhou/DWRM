//
//  BIRemoteMethodReturnType.h
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-6.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(UInt8, BIRemoteMethodReturnTypeStructure)
{
    BIRemoteMethodReturnTypeStructureVoid,//< option1 option2 neither used
    BIRemoteMethodReturnTypeStructureValue,//< option2 used as length
    BIRemoteMethodReturnTypeStructureNulTerminatedData,//< option2 used as unit size, for example char* has option2 of value 1
    BIRemoteMethodReturnTypeStructureFixedLengthData,//option2 used as length
    BIRemoteMethodReturnTypeStructureArgumentLengthData,//< option1 used as argument index(The argument is assumed to be a UInt8/UInt16/UInt32/UInt64), option2 used as unit size
    BIRemoteMethodReturnTypeStructureDynamicData,//< option1 option2 neither used
    BIRemoteMethodReturnTypeStructureCalculatedData,//option1 used as the structure before calculated, option2 used as length
};

/**
 *	BIRemoteMethodReturnType describes the characteristic of a function's return type.
 */
struct BIRemoteMethodReturnType
{
    //-------- 64bit ---------
    UInt8 /*BIRemoteMethodReturnTypeStructure*/ structure;
    UInt8 option1;
    BI_ALIGNMENT_16BIT;
    UInt32 option2;
    //------------------------
}BI_STRUCT_ALIGNMENT;
typedef struct BIRemoteMethodReturnType BIRemoteMethodReturnType;



BI_INLINE BIRemoteMethodReturnType BIRemoteMethodReturnTypeMakeStructureValue(UInt32 length)
{
    BIRemoteMethodReturnType type; type.structure = BIRemoteMethodReturnTypeStructureValue; type.option2 = length; return type;
}

BI_INLINE BIRemoteMethodReturnType BIRemoteMethodReturnTypeMakeStructureNulTerminatedData(UInt32 unitSize)
{
    BIRemoteMethodReturnType type; type.structure = BIRemoteMethodReturnTypeStructureNulTerminatedData; type.option2 = unitSize; return type;
}

BI_INLINE BIRemoteMethodReturnType BIRemoteMethodReturnTypeMakeStructureFixLengthData(UInt32 length)
{
    BIRemoteMethodReturnType type; type.structure = BIRemoteMethodReturnTypeStructureFixedLengthData; type.option2 = length; return type;
}

BI_INLINE BIRemoteMethodReturnType BIRemoteMethodReturnTypeMakeStructureArgumentLengthData(UInt8 argIdx, UInt32 unitSize)
{
    BIRemoteMethodReturnType type; type.structure = BIRemoteMethodReturnTypeStructureArgumentLengthData; type.option1 = argIdx; type.option2 = unitSize; return type;
}

BI_INLINE BIRemoteMethodReturnType BIRemoteMethodReturnTypeMakeStructureCalculatedData(BIRemoteMethodReturnType originType, UInt32 length)
{
    BIRemoteMethodReturnType type; type.structure = BIRemoteMethodReturnTypeStructureCalculatedData; type.option1 = originType.structure; type.option2 = length; return type;
}



BI_EXTERN const BIRemoteMethodReturnType BIRemoteMethodReturnTypeVoid;
BI_EXTERN const BIRemoteMethodReturnType BIRemoteMethodReturnTypeDynamic;

//BIRemoteMethodReturnTypeStructureCalculatedData should be treated as Data type, because it can only be converted from Data type.
#define BIRemoteMethodReturnTypeStructureIsData(__t) ((__t).structure==BIRemoteMethodReturnTypeStructureNulTerminatedData||(__t).structure==BIRemoteMethodReturnTypeStructureFixedLengthData||(__t).structure==BIRemoteMethodReturnTypeStructureArgumentLengthData||(__t).structure==BIRemoteMethodReturnTypeStructureDynamicData||(__t).structure==BIRemoteMethodReturnTypeStructureCalculatedData)
#define BIRemoteMethodReturnTypeStructureIsValue(__t) ((__t).structure==BIRemoteMethodReturnTypeStructureValue)

UInt32 BIRemoteMethodReturnTypeGetNulTerminatedDataLength(void *data, UInt32 unitSize);
UInt32 BIRemoteMethodReturnTypeGetArgumentLengthDataLength(void *arg, UInt32 argLen, UInt32 unitSize);

UInt32 BIRemoteMethodReturnTypeTryGetDataLength(BIRemoteMethodReturnType type);
UInt32 BIRemoteMethodReturnTypeMakeSignature(BIRemoteMethodReturnType type);

//debug
char* BIRemoteMethodReturnTypeDebugInfo(BIRemoteMethodReturnType type);

