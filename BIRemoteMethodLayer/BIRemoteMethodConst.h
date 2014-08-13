//
//  BIRemoteMethodConst.h
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-5.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#ifndef BIRemoteMethodLayer_BIRemoteMethodConst_h
#define BIRemoteMethodLayer_BIRemoteMethodConst_h


//version
#define BI_REMOTE_METHOD_LAYER_VERSION 1

//
//#define BIRMCDPRINT(xx, ...)  NSLog(@"BIRMC: %s(%d): " xx, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define BIRMCDPRINT(xx, ...)  ((void)0)


//alignment
#define COMBINE_HELPER(X,Y) X##Y  // helper macro
#define COMBINE(X,Y) COMBINE_HELPER(X,Y)
#define BI_ALIGNMENT_8BIT UInt8 COMBINE(BIAlign, __COUNTER__)
#define BI_ALIGNMENT_16BIT UInt16 COMBINE(BIAlign, __COUNTER__)
#define BI_ALIGNMENT_32BIT UInt32 COMBINE(BIAlign, __COUNTER__)
#define BI_ALIGNMENT_64BIT UInt64 COMBINE(BIAlign, __COUNTER__)
//pointer alignment
#ifdef __LP64__
#define BI_POINTER_64_ALIGNMENT
#else
#define BI_POINTER_64_ALIGNMENT ;BI_ALIGNMENT_32BIT
#endif
//union alignment
#define BI_UNION_64_ALIGNMENT BI_ALIGNMENT_64BIT


//BI_INLINE UInt32 BINextPowerOf2(UInt32 v)
//{
//    v--;
//    v |= v >> 1;
//    v |= v >> 2;
//    v |= v >> 4;
//    v |= v >> 8;
//    v |= v >> 16;
//    v++;
//    return v;
//}

#define BINextAlignment8(__v) (__v + (8-(__v%8))%8)
//#define BINextAlignment8(__v) (__v)


#define BIRMC_UNION_OFFSET_TYPE UInt64
//#define BIRMC_UNION_OFFSET_TYPE UInt32

//struct alignment
#define BI_STRUCT_ALIGNMENT_SIZE 8
#define BI_STRUCT_ALIGNMENT __attribute__((aligned(BI_STRUCT_ALIGNMENT_SIZE)))


///BI_INCREATMENT_POINTER is used for increament a pointer by __i bytes, instead of __i*sizeof(*pointer) bytes.
#define BI_INCREATMENT_POINTER(__p, __i) ((void*)__p + __i)


//inline
#if !defined(BI_INLINE)
# if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L
#  define BI_INLINE  static inline
# elif defined(__MWERKS__) || defined(__cplusplus)
#  define BI_INLINE  static inline
# elif defined(__GNUC__)
#  define BI_INLINE  static __inline__
# else
#  define BI_INLINE  static
# endif
#endif /* !defined(BI_INLINE) */


//extern
#if !defined(BI_EXTERN)
#  if defined(__cplusplus)
#   define BI_EXTERN extern "C"
#  else
#   define BI_EXTERN extern
#  endif
#endif /* !defined(BI_EXTERN) */


#define BIRMC_DEBUG_INFO_BUFFER_UNIT 512

#endif
