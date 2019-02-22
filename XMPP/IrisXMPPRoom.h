//
//  IrisXMPPRoom.h
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 11/21/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#ifndef IrisXMPPRoom_h
#define IrisXMPPRoom_h
@import XMPPFramework;
#import "IrisChatMessage.h"
#import "IrisChatState.h"
#import "IrisDataElement.h"
#import "IrisRtcParticipant.h"


@protocol IrisXMPPRoomDelegate <NSObject>

-(void)onIrisRtcRoomError:(NSString*)errorDesc _errorCode:(NSInteger)errorCode;
- (void)xmppRoomDidCreate;
- (void)xmppRoomDidJoin;
-(void)occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence;
-(void)occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence;
-(void)didReceiveIrisMessage:(IrisChatMessage *)message fromOccupant:(XMPPJID *)occupantJID;
-(void)didReceiveIrisAckMessage:(IrisChatMessage *)ack responseCode:(int)responseCode;
-(void)didReceiveIrisChatState:(IrisChatState)state fromOccupant:(XMPPJID *)occupantJID;
-(void)didReceiveIrisLeaveRoomMessage:(NSString *)roomId;
-(void)didReceiveIrisStopVideoMessage;
-(void)didReceiveIrisStartVideoMessage;
-(void)didReceiveIrisHoldAudioMessage:(NSString *)routingId;
-(void)didReceiveIrisUnholdAudioMessage:(NSString *)routingId;
@end



@interface IrisXMPPRoom : NSObject

@property (nonatomic) NSInteger streamCount;
@property (nonatomic) BOOL isAudioMute;
@property (nonatomic) BOOL isVideoMute;
@property(nonatomic) IrisRtcParticipant* participant;

-(id)initWithDataElement:(IrisDataElement*)dataElement _roomName:(NSString*)roomName appDelegate:(id<IrisXMPPRoomDelegate>)roomDelegate;

- (void)allocateConferenceFocus:(ConferenceIQType)type;

-(void)joinRoom;

-(void)sendChatMessage:(IrisChatMessage*)message;

- (void)sendIrisChatState:(IrisChatState)chatState;

-(void)leaveRoom;

-(void)startPeriodicPresenceTimer;

-(void)stopPeriodicPresenceTimer;

-(void)startStatsQueueTimer;

-(void)stopStatsQueueTimer;


- (void)dial:(NSString*)toNumber from:(NSString*)fromNumber target:(XMPPJID*)targetJid toRoutingId:(NSString*)toRoutingId;

- (void)hangup:(NSString*)toNumber from:(NSString*)fromNumber target:(XMPPJID*)targetJid toRoutingId:(NSString*)toRoutingId;

- (void)merge:(XMPPJID*)targetJid secondParticipantJid:(NSString*)participantJid;

- (void)hold:(NSString*)to from:(NSString*)from targetJid:(XMPPJID*)targetJid;

- (void)unHold:(NSString*)to from:(NSString*)from targetJid:(XMPPJID*)targetJid;

- (void)sendStats:(NSDictionary *)metaData streamInfo:(NSDictionary *)streamInfo eventsInfo:(NSArray *)events timeSeries:(NSDictionary *)timeSeries callSummary:(NSDictionary *)callsummary;

-(NSString*) getPSTNParticipantJid:(XMPPJID*)targetJid;

-(void)sendPrivateMessage:(NSString *)msg target:(NSString *)target;

-(void)sendStats:(NSDictionary*)event;

@end



#endif /* IrisRtcRoom_h */
