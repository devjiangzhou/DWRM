//
//  BIRemoteMethodSocketLayer.m
//  BIRemoteMethodLayer
//
//  Created by Seven on 14-3-5.
//  Copyright (c) 2014 dreamingwish.com All rights reserved.
//

#import "BIRemoteMethodSocketLayer.h"
#import "BIRemoteMethodPublic.h"

#include <sys/stat.h>
#include <sys/un.h>
#include <netdb.h>
#include <unistd.h>
#include <arpa/inet.h>

#include <sys/time.h>

const UInt32 BIRemoteMethodSocketLayerDefaultPort = 49152;
const char* BIRemoteMethodSocketLayerLocalhostAddr = "127.0.0.1";
const UInt32 BIRemoteMethodSocketLayerDefaultMaxClient = 10;
const UInt32 BIRemoteMethodSocketLayerDefaultTimeoutSec = 5;

struct BIRemoteMethodSocketLayerInfo
{
    struct sockaddr_in sockServerAddr;
    int transmitSocket;
    int listenSocket;
    struct timeval sendTimeout;
    struct timeval receiveTimeout;
};


//============================= private ==============================
#pragma mark - private

#pragma mark send callbacks

void _BIRemoteMethodSocketLayerBeginSendCallback(BIRemoteMethodLayerRef layer, UInt64 *identity)
{
    struct BIRemoteMethodSocketLayerInfo *info = BIRemoteMethodLayerGetUserInfo(layer);
    if (info)
    {
        int socketFd = socket(PF_INET, SOCK_STREAM, 0);
        setsockopt(socketFd, SOL_SOCKET, SO_RCVTIMEO, &info->receiveTimeout, sizeof(info->receiveTimeout));
        setsockopt(socketFd, SOL_SOCKET, SO_SNDTIMEO, &info->sendTimeout, sizeof(info->sendTimeout));
#ifdef SO_NOSIGPIPE
        int n = 1;
        setsockopt(socketFd, SOL_SOCKET, SO_NOSIGPIPE, &n, sizeof(n));
#endif
        
        int connectStatus = connect(socketFd, (const struct sockaddr*)&(info->sockServerAddr), sizeof(info->sockServerAddr));
        if (connectStatus == 0)
        {
            if (info->transmitSocket > 0)
            {
                close(info->transmitSocket);
            }
            info->transmitSocket = socketFd;
        }
    }
}

SInt32 _BIRemoteMethodSocketLayerSendCallback(BIRemoteMethodLayerRef layer, void *data, UInt32 length)
{
    SInt32 returnState = BIRemoteMethodErrorNoOperation;
    struct BIRemoteMethodSocketLayerInfo *info = BIRemoteMethodLayerGetUserInfo(layer);
    if (data && length > 0 && info)
    {
        ssize_t sentSize = 0;
        while (sentSize < length)
        {
            ssize_t sent = write(info->transmitSocket, BI_INCREATMENT_POINTER(data, sentSize), length-sentSize);
            if (sent < 0)//returns 0 DO NOT indicates an error.
            {
                break;
            }
            //NSLog(@"%s sent:%zi", __PRETTY_FUNCTION__, sent);
            sentSize += sent;
        }
        if (sentSize == length)
        {
            returnState = (int)length;
        }
        else
        {
            returnState = -1;
        }
    }
    return returnState;
}

void _BIRemoteMethodSocketLayerEndSendCallback(BIRemoteMethodLayerRef layer, UInt64 identity, UInt32 count, UInt32 status)
{
    struct BIRemoteMethodSocketLayerInfo *info = BIRemoteMethodLayerGetUserInfo(layer);
    if (info)
    {
        if (info->transmitSocket)
        {
            BIRMCDPRINT(@"info->transmitSocket:%i", info->transmitSocket);
            close(info->transmitSocket);
            info->transmitSocket = 0;
        }
    }
}

#pragma mark receive callbacks
void _BIRemoteMethodSocketLayerBeginReceiveCallback(BIRemoteMethodLayerRef layer, UInt64 *identity)
{
    struct BIRemoteMethodSocketLayerInfo *info = BIRemoteMethodLayerGetUserInfo(layer);
    if (info)
    {
        BIRMCDPRINT(@"1");
        socklen_t len = 0;
        struct sockaddr_in client_addr;
        int clientSocketFd = accept(info->listenSocket, (struct sockaddr*)&client_addr, &len);
        setsockopt(clientSocketFd, SOL_SOCKET, SO_RCVTIMEO, &info->receiveTimeout, sizeof(info->receiveTimeout));
        setsockopt(clientSocketFd, SOL_SOCKET, SO_SNDTIMEO, &info->sendTimeout, sizeof(info->sendTimeout));
#ifdef SO_NOSIGPIPE
        int n = 1;
        setsockopt(clientSocketFd, SOL_SOCKET, SO_NOSIGPIPE, &n, sizeof(n));
#endif
        BIRMCDPRINT(@"clientSocketFd:%i", clientSocketFd);
        
        if (clientSocketFd > 0)
        {
            if (info->transmitSocket > 0)
            {
                close(info->transmitSocket);
            }
            info->transmitSocket = clientSocketFd;
        }
    }
}

SInt32 _BIRemoteMethodSocketLayerReceiveCallback(BIRemoteMethodLayerRef layer, void *buffer, UInt32 length)
{
    //NSLog(@"1 length:%i", length);
    SInt32 returnState = BIRemoteMethodErrorNoOperation;
    struct BIRemoteMethodSocketLayerInfo *info = BIRemoteMethodLayerGetUserInfo(layer);
    if (buffer && length > 0 && info)
    {
        //NSLog(@"2");
        ssize_t readSize = 0;
        while (readSize < length)
        {
            ssize_t ret = read(info->transmitSocket, BI_INCREATMENT_POINTER(buffer, readSize), length-readSize);
            //NSLog(@"%s read:%zi", __PRETTY_FUNCTION__, ret);
            if (ret <= 0)//returns 0 indicates the connection has been closed or there's a TCP Half-close.
            {
                break;
            }
            readSize += ret;
        }
        if (readSize == length)
        {
            returnState = (int)length;
        }
        else
        {
            returnState = -1;
        }
    }
    //NSLog(@"3 returnState:%i", returnState);
    return returnState;
}

void _BIRemoteMethodSocketLayerEndReceiveCallback(BIRemoteMethodLayerRef layer, UInt64 identity, UInt32 count, UInt32 status)
{
    struct BIRemoteMethodSocketLayerInfo *info = BIRemoteMethodLayerGetUserInfo(layer);
    if (info)
    {
        if (info->transmitSocket)
        {
            BIRMCDPRINT(@"info->transmitSocket:%i", info->transmitSocket);
            close(info->transmitSocket);
            info->transmitSocket = 0;
        }
    }
}

#pragma mark destruct callback
void _BIRemoteMethodSocketLayerDestructCallback(BIRemoteMethodLayerRef layer)
{
    struct BIRemoteMethodSocketLayerInfo *info = BIRemoteMethodLayerGetUserInfo(layer);
    if (info)
    {
        if (info->transmitSocket > 0)
        {
            close(info->transmitSocket);
        }
        if (info->listenSocket)
        {
            close(info->listenSocket);
        }
        free(info);
    }
}

//Client send first, then receive. After receive, it should close connection.
static const BIRemoteMethodLayerCallbacks gBIRemoteMethodLayerSocketClientCallbacks =
{
    _BIRemoteMethodSocketLayerBeginSendCallback,//In begin send callback, we connect server.
    _BIRemoteMethodSocketLayerSendCallback,
    NULL,//_BIRemoteMethodSocketLayerEndSendCallback,
    
    NULL,//_BIRemoteMethodSocketLayerBeginReceiveCallback,
    _BIRemoteMethodSocketLayerReceiveCallback,
    _BIRemoteMethodSocketLayerEndReceiveCallback,//In end receive callback, we close connect.
    
    _BIRemoteMethodSocketLayerDestructCallback
};

//Server receive first, then send. After send, it should close connection.
static const BIRemoteMethodLayerCallbacks gBIRemoteMethodLayerSocketServerCallbacks =
{
    NULL,//_BIRemoteMethodSocketLayerBeginSendCallback,
    _BIRemoteMethodSocketLayerSendCallback,
    _BIRemoteMethodSocketLayerEndSendCallback,//In end send callback, we close connect.
    
    _BIRemoteMethodSocketLayerBeginReceiveCallback,//In begin receive callback, we accept connect from client.
    _BIRemoteMethodSocketLayerReceiveCallback,
    NULL,//_BIRemoteMethodSocketLayerEndReceiveCallback,
    
    _BIRemoteMethodSocketLayerDestructCallback
};


//============================= public ==============================
#pragma mark - public
BIRemoteMethodLayerRef BIRemoteMethodSocketLayerCreateClient(const char* destAddr, UInt32 port)
{
    if (destAddr && port > 0)
    {
        struct BIRemoteMethodSocketLayerInfo *info = calloc(1, sizeof(struct BIRemoteMethodSocketLayerInfo));
        if (info)
        {
            //create socket addr struct
            struct sockaddr_in serverAddr = {0};//bzero(&serverAddr, sizeof(serverAddr));
            serverAddr.sin_family = AF_INET;
            serverAddr.sin_port = htons(port);
            inet_pton(AF_INET, destAddr, &serverAddr.sin_addr);
            
            info->sockServerAddr = serverAddr;
            struct timeval timeout = {BIRemoteMethodSocketLayerDefaultTimeoutSec, 0};
            info->sendTimeout = timeout;
            info->receiveTimeout = timeout;
            
            BIRemoteMethodLayerRef layer = BIRemoteMethodLayerCreate(&gBIRemoteMethodLayerSocketClientCallbacks, info);
            return layer;
        }
    }
    return NULL;
}

BIRemoteMethodLayerRef BIRemoteMethodSocketLayerCreateServer(const char* destAddr, UInt32 port, UInt32 maxClient)
{
    if (destAddr && port > 0 && maxClient > 0)
    {
        int listenSocketFd = socket(PF_INET, SOCK_STREAM, 0);
        if (listenSocketFd > 0)
        {
            //set socket options
            int setsockoptStatus = 1;//we ignored it
            setsockopt(listenSocketFd, SOL_SOCKET, SO_REUSEADDR, &setsockoptStatus, sizeof(int));
            
            struct timeval timeout = {BIRemoteMethodSocketLayerDefaultTimeoutSec, 0};
            setsockopt(listenSocketFd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
            setsockopt(listenSocketFd, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof(timeout));
#ifdef SO_NOSIGPIPE
            int n = 1;
            setsockopt(listenSocketFd, SOL_SOCKET, SO_NOSIGPIPE, &n, sizeof(n));
#endif
            //bind
            struct sockaddr_in serverAddr = {0};//bzero(&serverAddr, sizeof(serverAddr));
            serverAddr.sin_family = AF_INET;
            serverAddr.sin_port = htons(port);
            inet_pton(AF_INET, destAddr, &serverAddr.sin_addr);
            int bindStatus = bind(listenSocketFd, (struct sockaddr*)&serverAddr, sizeof(struct sockaddr_in));
            
            if(bindStatus >= 0)
            {
                //listen
                int listenStatus = listen(listenSocketFd, maxClient);
                if (listenStatus >= 0)
                {
                    //create layer
                    struct BIRemoteMethodSocketLayerInfo *info = malloc(sizeof(struct BIRemoteMethodSocketLayerInfo));
                    if (info)
                    {
                        info->listenSocket = listenSocketFd;
                        info->sockServerAddr = serverAddr;
                        info->sendTimeout = timeout;
                        info->receiveTimeout = timeout;
                        
                        BIRemoteMethodLayerRef layer = BIRemoteMethodLayerCreate(&gBIRemoteMethodLayerSocketServerCallbacks, info);
                        return layer;
                    }
                }
            }
        }
    }
    return NULL;
}

