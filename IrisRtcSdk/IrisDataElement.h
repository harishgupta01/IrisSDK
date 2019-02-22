//
//  IrisDataElement.h
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 7/27/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#ifndef IrisDataElement_h
#define IrisDataElement_h
@import XMPPFramework; 
#import "IrisRootEventInfo.h"
#import "IrisRtcUtils.h"

@interface IrisDataElement : NSObject

@property(nonatomic) NSString* rtcServer;
@property(nonatomic) NSString* roomToken;
@property(nonatomic) NSString* roomExpiryTime;
@property(nonatomic) NSString* sessionType;
@property(nonatomic) NSString* oldJid;
@property(nonatomic) NSString* toDomain;

-(id)initWithRootEventInfo:(IrisRootEventInfo*)rootEventInfo _traceId:(NSString*)traceId _callType:(NSString*)sessionType;
-(id)initWithRoomToken:(NSString*)roomToken _roomExpiryTime:(NSString*)roomExpiryTime _traceId:(NSString*)traceId _callType:(NSString*)sessionType _rtcServer:(NSString*)rtcServer;

-(id)initWithToRoutingId:(NSString*)toRoutingId _rootEventInfo:(IrisRootEventInfo*)rootEventInfo _traceId:(NSString*)traceId _callType:(NSString*)sessionType toDomain:(NSString*)toDomain;

-(NSXMLElement*)bare;
-(NSXMLElement*)full;
-(NSXMLElement*)toRoutingId;
-(NSXMLElement*)allocate;
-(NSXMLElement*)deallocate;
-(NSXMLElement*)stats;
-(NSXMLElement*)periodic;

+(void)setHostName:(NSString*)host;

@end

#endif /* IrisDataElement_h */
