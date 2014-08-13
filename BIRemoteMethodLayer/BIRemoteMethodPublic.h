//
//  BIRemoteMethodLayer.h
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-5.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

/**
 *  BIRemoteMethodLayer is a library for invoking functions remotely.
 *  Any BIRemoteMethodLayer objects should only be released using the associated release functions.
 *  Some objects can enter state "flat memeory", and when in this state, the object should not be modified any more. A "flat memory" object is guarantied to be stored in a continuous memory segment and thus can be can be treated as serialized.
 *
 *  BIRemoteMethodLayer will:
 *  1.Help you serialize/deserialize c/c++/objc functions.
 *  2.Help you serialize/deserialize property list compatible objects.
 *  3.Help you invoke functions over socket.
 *
 *  but, BIRemoteMethodLayer won't:
 *  1.Automaticly parse arguments and returns which has runtime meaning.
 *  2.Serialize/Deserialize a non-property-list-compatible object.
 */

#import <Foundation/Foundation.h>

NS_ENUM(SInt32, BIRemoteMethodError)
{
    BIRemoteMethodErrorNoOperation = 0,
    
    BIRemoteMethodErrorCantAlloc = -10001,
    BIRemoteMethodErrorFlatMemory = -10002,
    
    BIRemoteMethodErrorArrayOverflow = -20001,
};

#include "BIRemoteMethodConst.h"
#import "BIRemoteMethod.h"
#import "BIRemoteMethodArgument.h"
#import "BIRemoteMethodCall.h"
#import "BIRemoteMethodCallObjC.h"
#import "BIRemoteMethodReturn.h"
#import "BIRemoteMethodInvoke.h"
#import "BIRemoteMethodSocketLayer.h"

