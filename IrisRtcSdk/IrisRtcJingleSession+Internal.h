//
//  IrisRtcSession+Internal.h
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 10/7/16.
//  Copyright © 2016 Gupta, Harish (Contractor). All rights reserved.
//

#ifndef IrisRtcSession_Internal_h
#define IrisRtcSession_Internal_h
#import "WebRTCStatsCollector.h"
#import "WebRTC/WebRTC.h"
#import "IrisXMPPRoom.h"
#import "IrisRtcAudioSession.h"
@protocol IrisRtcSdkSesionStatsDelegate <NSObject>

- (void)IrisRtcSession:(IrisRtcJingleSession *)sdkStats onSdkStatsDuringActiveSession:(NSDictionary *)sessionStats;

- (void)IrisRtcSession:(IrisRtcJingleSession *)sdkStats onCompleteSessionStatsWithTimeseries:(NSDictionary*)sessionTimeseries streamInfo:(NSDictionary*)streamInfo eventInfo:(NSMutableArray *)eventinfo;

- (void)onPeerConnection:(RTCPeerConnection*)peerconnection statscollector:(WebRTCStatsCollector*)statscollector roomname:(NSString*)roomname irisRoom:(IrisXMPPRoom *)irisroom;

- (void)onLogEvents:(NSDictionary *)event callSummary:(NSDictionary*)callsummary;

@end

@interface IrisRtcJingleSession (Internal)

-(NSString*)getRtcServer;
-(NSString*)getParticipantJid;
-(NSString*)getSessionType;

-(IrisSIPStatus)getSipStatus;

-(void)restartSession;

@end

#endif /* IrisRtcSession_Internal_h */
