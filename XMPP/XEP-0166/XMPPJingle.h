//
//  XMPPJingle.h
//  xfinity-webrtc-sdk
//
//  Created by Ganvir, Manish (Contractor) on 2/5/15.
//  Copyright (c) 2015 Comcast. All rights reserved.
//

#ifndef xfinity_webrtc_sdk_XMPPJingle_h
#define xfinity_webrtc_sdk_XMPPJingle_h
#import <Foundation/Foundation.h>

#import "IrisRtcJingleSession.h"
#import "IrisDataElement.h"
#import "IrisXMPPStream.h"
@protocol XMPPJingleDelegate;

@interface XMPPJingle : XMPPModule
{
    NSString* from;
    NSString* to;
    IrisXMPPStream *myStream;
    NSString *UID;
    NSString *SID;

}

@property(nonatomic,weak) NSString *event;
@property(nonatomic,weak) NSString *traceId;
@property(nonatomic,weak) NSString *nodeId;
@property(nonatomic,weak) NSString *cnodeId;
@property(nonatomic,weak) NSString *unodeId;
@property(nonatomic,weak) NSString *roomId;
@property(nonatomic,weak) IrisDataElement *dataElement;

// delegate to post msg, TODO: managing queue for dispatching msgs
@property(nonatomic,weak) id<XMPPJingleDelegate> delegate;

// Set delegate method
- (void)SetDelegate:(id <XMPPJingleDelegate>)appDelegate;

// For Action (type) attribute: "session-accept", "session-info", "session-initiate", "session-terminate"
- (BOOL)sendSessionMsg:(NSString *)type  data:(NSDictionary *)data target:(XMPPJID *)target;

// For Action (type) attribute: "transport-accept", "transport-info", "transport-reject", "transport-replace"
- (BOOL)sendTransportMsg:(NSString *)type data:(NSDictionary *)data target:(XMPPJID *)target;

// For Action (type) attribute: "content-accept", "content-add", "content-modify", "content-reject", "content-remove"
- (BOOL)sendContentMsg:(NSString *)type data:(NSDictionary *)data;

- (NSXMLElement*)getVideoContent:(NSString *)type  data:(NSDictionary *)data target:(XMPPJID *)target;

-(NSString*)routingId:(NSString*)streamId;
@end

@protocol XMPPJingleDelegate <NSObject>

// For Action (type) attribute: "session-accept", "session-info", "session-initiate", "session-terminate"
- (void)didReceiveSessionMsg:(NSString *)sid type:(NSString *)type data:(NSDictionary *)data;

// For Action (type) attribute: "transport-accept", "transport-info", "transport-reject", "transport-replace"
- (void)didReceiveTransportMsg:(NSString *)sid type:(NSString *)type data:(NSDictionary *)data;

// For Action (type) attribute: "content-accept", "content-add", "content-modify", "content-reject", "content-remove"
- (void)didReceiveContentMsg:(NSString *)sid type:(NSString *)type data:(NSDictionary *)data;

// For Action (type) attribute: "description-info"
- (void)didReceiveDescriptionMsg:(NSString *)sid type:(NSString *)type data:(NSDictionary *)data;

// For Action(type) attritbute: "audiomuted" , "videomuted"
-(void)didReceiveMediaPresenceMsg:(NSString*)msg;

// For Action(type) attritbute: "userprofile"
-(void)didReceiveParticipantProfilePresenceMsg:(NSString *)routingID  userProfile:(IrisRtcUserProfile*)userprofile;

// For Action(type) attritbute: "pstn call status"
-(void)didReceiveSIPStatus:(NSString *)routingID  status:(NSString*)status;

// In case any error is received
- (void)didReceiveError:(NSString *)sid error:(NSDictionary *)data;

@end

#endif
