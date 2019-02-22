//
//  IrisXMPPStream.h
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 11/21/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#ifndef IrisXMPPStream_h
#define IrisXMPPStream_h
#import "IrisDataElement.h"
@import XMPPFramework;

@protocol IrisXMPPStreamDelegate <XMPPStreamDelegate>

- (void)xmppStream:(XMPPStream *)sender onPongMessage:(NSXMLElement *)error;
- (void)onXmppServerConnected;
- (void)xmppStream:(XMPPStream *)sender onError:(NSError *)error;
@end

@protocol IrisXMPPSessionDelegate <XMPPStreamDelegate>


- (void)xmppStream:(XMPPStream *)sender onSessionError:(NSError *)error additionalInfo:(NSDictionary*)info;
@end

@interface IrisXMPPStream : XMPPStream

@property (nonatomic) NSString *timestamp;
@property (nonatomic) NSString *token;
@property (nonatomic) NSString *routingId;
@property (nonatomic) NSString *traceId;
@property (nonatomic) NSString *callType;
@property (nonatomic) NSString *nodeId;
@property (nonatomic) NSString *cnodeId;
@property (nonatomic) NSString *unodeId;
@property (nonatomic) NSString *maxParticipants;
@property (nonatomic) BOOL IsXMPPRoomCreator;
@property (nonatomic) NSString *actualHostName;
@property (nonatomic) IrisDataElement *dataElement;



-(void)sendPing:(NSData*)data;
-(void)sendIQElement:(NSXMLElement *)element;
-(void)resetIQArray;
@end

#endif /* IrisXMPPStream_h */
