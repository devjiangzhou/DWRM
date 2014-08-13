//
//  BIRemoteMethodLayer.h
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-28.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BIRemoteMethodCall.h"
#import "BIRemoteMethodReturn.h"

/**
 * @brief BIRemoteMethodLayer is an abstract Layer, there's no send/recieve implementation.
 * There's a simple concrete layer 'BIRemoteMethodSocketLayer', which implements send/receive callbacks using unix socket APIs.
 */
typedef struct BIRemoteMethodLayer* BIRemoteMethodLayerRef;


typedef SInt32 (*BIRemoteMethodLayerSendCallback)(BIRemoteMethodLayerRef layer, void *data, UInt32 length);
typedef SInt32 (*BIRemoteMethodLayerReceiveCallback)(BIRemoteMethodLayerRef layer, void *buffer, UInt32 length);
typedef void (*BIRemoteMethodLayerCallback)(BIRemoteMethodLayerRef layer);
typedef void (*BIRemoteMethodLayerBeginCallback)(BIRemoteMethodLayerRef layer, UInt64 *identity);
typedef void (*BIRemoteMethodLayerEndCallback)(BIRemoteMethodLayerRef layer, UInt64 identity, UInt32 count, UInt32 status);


/**
 *  There can be servral 'send' callback calls between 'willSend' callback and 'didSend' callback.
 *  There can be servral 'receive' callback calls between 'willReceive' callback and 'didReceive' callback.
 *  When BIRemoteMethodLayer is about to be deallocated, 'destruct' callback is called.
 */
typedef struct
{
    BIRemoteMethodLayerBeginCallback willSend;
    BIRemoteMethodLayerSendCallback send;
    BIRemoteMethodLayerEndCallback didSend;
    
    BIRemoteMethodLayerBeginCallback willReceive;
    BIRemoteMethodLayerReceiveCallback receive;
    BIRemoteMethodLayerEndCallback didReceive;
    
    BIRemoteMethodLayerCallback destruct;
} BIRemoteMethodLayerCallbacks;


/**
 *  @param callbacks Callbacks should not be NULL.
 *  @param userInfo  User info is NOT copied.
 */
BIRemoteMethodLayerRef BIRemoteMethodLayerCreate(const BIRemoteMethodLayerCallbacks *callbacks, void *userInfo);

void BIRemoteMethodLayerSetPeerIdentity(BIRemoteMethodLayerRef layer, UInt64 identity);
UInt64 BIRemoteMethodLayerGetPeerIdentity(BIRemoteMethodLayerRef layer);
UInt64 BIRemoteMethodLayerGetLastCommunicatePeerIdentity(BIRemoteMethodLayerRef layer);


void *BIRemoteMethodLayerGetUserInfo(BIRemoteMethodLayerRef layer);


//call
/**
 *  Send method call
 *  @return The returned BIRemoteMethodReturn is in flat memeory state.The returned object is allocted and should be released.
 */
BIRemoteMethodReturnRef BIRemoteMethodLayerCallMethodAndCopyReturn(BIRemoteMethodLayerRef layer, BIRemoteMethodCallRef call);

//return
/**
 *  Read method call
 *  @return The returned BIRemoteMethodCall is in flat memeory state.The returned object is allocted and should be released.
 */
BIRemoteMethodCallRef BIRemoteMethodLayerReadCopyMethodCall(BIRemoteMethodLayerRef layer);
SInt32 BIRemoteMethodLayerSendMethodReturn(BIRemoteMethodLayerRef layer, BIRemoteMethodReturnRef methodReturn);

void BIRemoteMethodLayerRelease(BIRemoteMethodLayerRef layer);
