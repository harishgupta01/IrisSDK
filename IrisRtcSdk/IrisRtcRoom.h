//
//  IrisRtcRoom.h
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 7/28/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#ifndef IrisRtcRoom_h
#define IrisRtcRoom_h

#import "IrisDataElement.h"
#import "XMPPWorker.h"
#import "IrisChatState.h"
#import "IrisRtcParticipant.h"

@protocol IrisRtcRoomDelegate<NSObject>

-(void)onIrisRtcRoomError:(NSString*)errorDesc _errorCode:(NSInteger)errorCode;

@end

@interface IrisRtcRoom : NSObject

@property (nonatomic) id<IrisRtcRoomDelegate> delegate;
@property (nonatomic) NSInteger streamCount;
@property (nonatomic) BOOL isAudioMute;
@property (nonatomic) BOOL isVideoMute;
@property(nonatomic) IrisRtcParticipant* participant;

-(id)initWithDataElement:(IrisDataElement*)dataElement _roomName:(NSString*)roomName appDelegate:(id<XMPPRoomDelegate>)roomDelegate;

- (void)allocateConferenceFocus:(ConferenceIQType)type;

-(void)joinRoom;

-(void)sendChatMessage:(IrisChatMessage*)message;

- (void)sendIrisChatState:(IrisChatState)chatState;

-(void)leaveRoom;

-(void)startPeriodicPresenceTimer;

-(void)stopPeriodicPresenceTimer;

- (void)dial:(NSString*)toNumber from:(NSString*)fromNumber target:(XMPPJID*)targetJid toRoutingId:(NSString*)toRoutingId;

- (void)hangup:(NSString*)toNumber from:(NSString*)fromNumber target:(XMPPJID*)targetJid toRoutingId:(NSString*)toRoutingId;

- (void)merge:(XMPPJID*)targetJid secondParticipantJid:(NSString*)participantJid;

- (void)hold:(NSString*)to from:(NSString*)from targetJid:(XMPPJID*)targetJid;

- (void)unHold:(NSString*)to from:(NSString*)from targetJid:(XMPPJID*)targetJid;

-(NSString*) getPSTNParticipantJid:(XMPPJID*)targetJid;
@end
#endif /* IrisRtcRoom_h */
