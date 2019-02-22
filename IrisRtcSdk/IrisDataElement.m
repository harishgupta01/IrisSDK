//
//  IrisDataElement.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 7/27/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IrisDataElement.h"

@interface IrisDataElement()
{
    IrisRootEventInfo* mRootEventInfo;
    NSString* mTraceId;
    NSString* mRoutingId;
    NSString* mType;
    NSString* mRoomId;
}

@end

NSString* hostName;

@implementation IrisDataElement

-(id)initWithRootEventInfo:(IrisRootEventInfo*)rootEventInfo _traceId:(NSString*)traceId _callType:(NSString*)sessionType{

    self = [self initWithRoomToken:[rootEventInfo roomToken] _roomExpiryTime:[rootEventInfo roomExpiryTime] _traceId:traceId _callType:sessionType _rtcServer:[rootEventInfo rtcServer]];
    mRootEventInfo = rootEventInfo;
    mRoomId = [rootEventInfo roomId];
    return self;
}

-(id)initWithTraceId:(NSString*)traceId _callType:(NSString*)sessionType{
    self = [super init];
    mTraceId = traceId;
    mType = @"allocate";
    self.sessionType = sessionType;
    return self;
}

-(id)initWithRoomToken:(NSString*)roomToken _roomExpiryTime:(NSString*)roomExpiryTime _traceId:(NSString*)traceId _callType:(NSString*)sessionType _rtcServer:(NSString*)rtcServer{
    self = [super init];
    _roomToken = roomToken;
    _rtcServer = rtcServer;
    _roomExpiryTime = roomExpiryTime;
    mType = @"allocate";
    mTraceId = traceId;
    self.sessionType = sessionType;
    return self;
}

-(id)initWithToRoutingId:(NSString*)toRoutingId _rootEventInfo:(IrisRootEventInfo*)rootEventInfo _traceId:(NSString*)traceId _callType:(NSString*)sessionType toDomain:(NSString*)toDomain{
    self = [self initWithRootEventInfo:rootEventInfo _traceId:traceId _callType:sessionType];
    
    mRoutingId = toRoutingId;
    self.toDomain = toDomain;
    return self;
}

-(NSXMLElement*)bare{
    
    NSXMLElement *dataElement = [NSXMLElement elementWithName:@"data" xmlns:@"urn:xmpp:comcast:info"];
    [dataElement addAttributeWithName:@"event" stringValue:_sessionType];
    if(!([mTraceId length] == 0))
        [dataElement addAttributeWithName:@"traceid" stringValue:mTraceId];
    if(!([hostName length] == 0))
        [dataElement addAttributeWithName:@"host" stringValue:hostName];
    
    return dataElement;

}

-(NSXMLElement*)full{
    
    NSXMLElement *dataElement = [self bare];
    if(!([[mRootEventInfo rootNodeId] length] == 0))
        [dataElement addAttributeWithName:@"rootnodeid" stringValue:[mRootEventInfo rootNodeId]];
    if(!([[mRootEventInfo childNodeId] length] == 0))
        [dataElement addAttributeWithName:@"childnodeid" stringValue:[mRootEventInfo childNodeId]];
    if(!([[mRootEventInfo roomToken] length] == 0))
        [dataElement addAttributeWithName:@"roomtoken" stringValue:_roomToken];
    if(!([mRootEventInfo roomExpiryTime] == 0))
        [dataElement addAttributeWithName:@"roomtokenexpirytime" integerValue:[_roomExpiryTime integerValue]];
    if(!([_oldJid length] == 0))
        [dataElement addAttributeWithName:@"oldjid" stringValue:_oldJid];
    return dataElement;
    
}

-(NSXMLElement*)toRoutingId{
    
    NSXMLElement *dataElement = [self full];
    if(!([mRoutingId length] == 0))
        [dataElement addAttributeWithName:@"toroutingid" stringValue:mRoutingId];
    if(!([_toDomain length] == 0))
        [dataElement addAttributeWithName:@"todomain" stringValue:_toDomain];
    return dataElement;
    
}

-(NSXMLElement*)allocate{
    
    NSXMLElement *dataElement = [self full];
    [dataElement addAttributeWithName:@"type" stringValue:@"allocate"];
    [dataElement addAttributeWithName:@"event" stringValue:_sessionType];
    return dataElement;
    
}

-(NSXMLElement*)deallocate{
    
    NSXMLElement *dataElement = [self full];
    [dataElement addAttributeWithName:@"type" stringValue:@"deallocate"];
    [dataElement addAttributeWithName:@"event" stringValue:_sessionType];
    return dataElement;
    
}

-(NSXMLElement*)periodic{
    NSXMLElement *dataElement = [self bare];
    [dataElement addAttributeWithName:@"type" stringValue:@"periodic"];    
    return dataElement;
}

-(NSXMLElement*)stats{
    
    NSXMLElement *dataElement = [NSXMLElement elementWithName:@"data" xmlns:@"urn:xmpp:comcast:info"];
    if(!([mTraceId length] == 0))
        [dataElement addAttributeWithName:@"traceid" stringValue:mTraceId];
    if(!([mRoomId length] == 0))
        [dataElement addAttributeWithName:@"roomid" stringValue:mRoomId];
        [dataElement addAttributeWithName:@"event" stringValue:@"callstats"];
        [dataElement addAttributeWithName:@"action" stringValue:@"log"];
  
    
    return dataElement;    
}


+(void)setHostName:(NSString*)host{
    
    hostName = host;
}

@end
