//
//  BIRemoteMethodSend.h
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-5.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BIRemoteMethodCall.h"
#import "BIRemoteMethodReturn.h"

//Send objc message
BIRemoteMethodReturnRef BIRemoteMethodCallSendObjCAndCreateMethodReturn(BIRemoteMethodCallRef call, id receiver);



//============================= Send c message =============================
//Client

#define BIRMCArgMarkBuf
#define BIRMCArgMarkOut
#define BIRMCArgMarkCStr

#define BIRemoteMethodCallCSendImplMethodCall   _call

#define BIRemoteMethodCallCSendImplBegin(_funcName)     BIRemoteMethodCallRef BIRemoteMethodCallCSendImplMethodCall = BIRemoteMethodCallCreateC(_funcName)
#define BIRemoteMethodCallCSendImplEnd()                BIRemoteMethodCallRelease(BIRemoteMethodCallCSendImplMethodCall)

#define BIRemoteMethodCallCSendImplAddArgPointer(_arg)       UInt64 _arg##__UInt64__ = (UInt64)_arg; BIRemoteMethodCallAddArgument(BIRemoteMethodCallCSendImplMethodCall, &_arg##__UInt64__, sizeof(UInt64))
#define BIRemoteMethodCallCSendImplAddArgValue(_arg)         BIRemoteMethodCallAddArgument(BIRemoteMethodCallCSendImplMethodCall, (void*)(&(_arg)), sizeof(typeof(_arg)))
#define BIRemoteMethodCallCSendImplAddArgData(_arg, _len, _output)    BIRemoteMethodCallAddArgumentCopyData(BIRemoteMethodCallCSendImplMethodCall, (void*)(_arg), (UInt32)(_len), (_output))
#define BIRemoteMethodCallCSendImplAddArgCString(_arg, _output)       BIRemoteMethodCallCSendImplAddArgData(_arg, (_arg) ? strlen(_arg)+1 : 0, (_output))
#define BIRemoteMethodCallCSendImplAddArgUniString(_arg, _output)     BIRemoteMethodCallCSendImplAddArgData(_arg, (_arg) ? BIRemoteMethodReturnTypeGetNulTerminatedDataLength(_arg,2)+2 : 0, (_output))

#define BIRemoteMethodCallCSendImplConfigReturnTypePointer()    BIRemoteMethodCallSetReturnType(BIRemoteMethodCallCSendImplMethodCall, BIRemoteMethodReturnTypeMakeStructureValue(sizeof(UInt64)))
#define BIRemoteMethodCallCSendImplConfigReturnTypeValue(_type) BIRemoteMethodCallSetReturnType(BIRemoteMethodCallCSendImplMethodCall, BIRemoteMethodReturnTypeMakeStructureValue(sizeof(_type)))
#define BIRemoteMethodCallCSendImplConfigReturnTypeCString()    BIRemoteMethodCallSetReturnType(BIRemoteMethodCallCSendImplMethodCall, BIRemoteMethodReturnTypeStructureNulTerminatedData(1))
#define BIRemoteMethodCallCSendImplConfigReturnTypeUniString()    BIRemoteMethodCallSetReturnType(BIRemoteMethodCallCSendImplMethodCall, BIRemoteMethodReturnTypeStructureNulTerminatedData(2))
#define BIRemoteMethodCallCSendImplConfigReturnTypeArgLen(_argIdx, _unitSize)    BIRemoteMethodCallSetReturnType(BIRemoteMethodCallCSendImplMethodCall, BIRemoteMethodReturnTypeMakeStructureArgumentLengthData(_argIdx, _unitSize))
#define BIRemoteMethodCallCSendImplConfigReturnTypeFixLen(_len)    BIRemoteMethodCallSetReturnType(BIRemoteMethodCallCSendImplMethodCall, BIRemoteMethodReturnTypeMakeStructureFixLengthData(_len))


#define BIRemoteMethodCallCSendImplParseReturnBegin(_methodReturnFlat)  if (_methodReturnFlat) { BIRemoteMethodReturnRef _ret = (_methodReturnFlat); BIRemoteMethodArgRef _oMethodArg = BIRemoteMethodReturnGetMethodArg(_ret)
#define BIRemoteMethodCallCSendImplParseReturnEnd()                     _ret = NULL; _oMethodArg = NULL;}

#define BIRemoteMethodCallCSendImplParseReturnPointer(_returnVal)     UInt64 _retVal = 0; BIRemoteMethodReturnGetReturnValue(_ret, &_retVal);(_returnVal) = (typeof(_returnVal))(_retVal)
#define BIRemoteMethodCallCSendImplParseReturnValue(_returnVal)     BIRemoteMethodReturnGetReturnValue(_ret, &_returnVal)
#define BIRemoteMethodCallCSendImplParseReturnData(_returnVal) (_returnVal) = BIRemoteMethodReturnCopyReturnData(_ret)

#define BIRemoteMethodCallCSendImplParseOutputArg(_argIndex, _buf, _len)  if (_buf && _oMethodArg && _len > 0) { void *_oDat = BIRemoteMethodArgGetArgAtIndex(_oMethodArg, _argIndex); if(_oDat) {memcpy(_buf, _oDat, _len);} }


//server
#define BIRemoteMethodMaxCFuncArg 64
#define BIRemoteMethodCallCWrapImplBegin(_methodCall)   void *_ret = NULL; BIRemoteMethodArgRef _methodArg = BIRemoteMethodCallGetMethodArg((_methodCall))
#define BIRemoteMethodCallCWrapImplEnd()                _methodArg = NULL; return _ret

#define BIRemoteMethodCallCWrapImplBeginParseArg()      if (_methodArg) { int _argc = BIRemoteMethodArgGetArgc(_methodArg); if (_argc > 0) { void* _arg[BIRemoteMethodMaxCFuncArg] = {0}; BOOL _argIsData[BIRemoteMethodMaxCFuncArg] = {0}; for (int i = 0; i < _argc; i++) {_arg[i] = BIRemoteMethodArgGetArgAtIndex(_methodArg, i); BIRemoteMethodArgGetArgTypeAtIndex(_methodArg, i, &(_argIsData[i]), NULL); }
#define BIRemoteMethodCallCWrapImplEndParseArg()        }}

#define BIRemoteMethodCallCWrapImplCallReturnValue                              _tmpRet
#define BIRemoteMethodCallCWrapImplBeginCall(_returnType, _pFreeRetData)        _returnType BIRemoteMethodCallCWrapImplCallReturnValue; int _typeSize = sizeof(_returnType); _ret = calloc(1, _typeSize); if(_pFreeRetData) { *_pFreeRetData = YES;}
#define BIRemoteMethodCallCWrapImplBeginCallReturnTypeIsData(_pFreeRetData)     void* BIRemoteMethodCallCWrapImplCallReturnValue; if(_pFreeRetData) { *_pFreeRetData = YES;}
#define BIRemoteMethodCallCWrapImplEndCall()                                    memcpy(_ret, &BIRemoteMethodCallCWrapImplCallReturnValue, _typeSize);
#define BIRemoteMethodCallCWrapImplEndCallReturnTypeIsData()                    _ret = BIRemoteMethodCallCWrapImplCallReturnValue;


#define BIRemoteMethodCallCWrapImplArgCastToType(_index, _type)                     (*((_type *)_arg[_index]))
#define BIRemoteMethodCallCWrapImplArgCastToPointer(_index)                         (_argIsData[_index] ? ((void *)_arg[_index]) : (void *)(BIRemoteMethodCallCWrapImplArgCastToType(_index, UInt64)))


//handler
typedef void*(*BIRemoteMethodCFuncHandler)(BIRemoteMethodCallRef, const void *, BOOL *freeReturnData);

typedef void*(*BIRemoteMethodCFuncHandlerCalledWrapperFunc)(BIRemoteMethodCallRef, BOOL *freeReturnData);
//Predefined handlers
/**
 *  This predefined handler accept userInfo as Wrapper Function's name suffix.
 *  For example: We got a function named 'myFunc' to be called, and the suffix is 'SUFFIX', then the wrapper function's prototype should be exactly
 *  void* myFuncSUFFIX(BIRemoteMethodCallRef, BOOL*), @see BIRemoteMethodCFuncHandlerCallWrapperFunc
 */
BI_EXTERN BIRemoteMethodCFuncHandler BIRemoteMethodCFuncHandlerCallWrapper;

/**
 *  Send c function through the handler |handler|
 *
 *  @param call     A reference to BIRemoteMethodCall.
 *  @param handler  Handler should not be nil, you may pass the predefined handlers.
 *  @param userInfo UserInfo will be passed to the handler.
 *
 *  @return A reference to BIRemoteMethodReturn, it's your reponsibility to free the memory.
 */
BIRemoteMethodReturnRef BIRemoteMethodCallSendCAndCreateMethodReturn(BIRemoteMethodCallRef call, BIRemoteMethodCFuncHandler handler, void *userInfo);
