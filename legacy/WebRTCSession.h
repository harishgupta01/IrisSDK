//
//  WebRTCSession.h
//  XfinityVideoShare
//

#ifndef WEBRTC_SESSION_H
#define WEBRTC_SESSION_H

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "WebRTC/WebRTC.h"

#import "WebRTCStack.h"
#import "DTMF.h"
#import "WebRTCChannel.h"
#import "WebRTCStatsCollector.h"
#import "WebRTCStatReport.h"
#import "WebRTCSessionConfig.h"
#import "WebRTCStackConfig.h"
@class XfinityVideoShareVideoCall,WebRTCStatsCollector,WebRTCStatReport,WebRTCSessionConfig,WebRTCStackConfig;

/* Keys for setting network data info */
extern NSString * const WebRTCNetworkQualityLevelKey;
extern NSString * const WebRTCNetworkQualityReasonKey;

@protocol WebRTCSessionDelegate <NSObject>

/* Called when the session has ended */
- (void) onSessionEnd:(NSString*) msg;

/* Called when session is connecting */
- (void) onSessionConnecting;

/* Called when a peer message is received */
- (void) onSessionTextMessage:(NSString*)msg;

/* Called when session has connected */
- (void) onSessionConnect;

/* Called when rtcg session ack is received or when muc id is created 
   as a response to create room */
- (void) onSessionAck:(NSString *)SessiondId;

/* Called ICE gathering state changes */
- (void) onIceGatheringStateChange:(NSString*)state;

/* Called when ice connection state changes */
- (void) onIceConnectionStateChange:(NSString*)state;

/* Called when we receive remote video */
- (void) onSessionRemoteVideoAvailable:(RTCVideoTrack*)track;

/* Called when we stop receiving remote video */
- (void) onSessionRemoteVideoUnavailable;

/* Called when we receive an error */
- (void) onSessionError:(NSString*)error errorCode:(NSInteger)code additionalData:(NSDictionary *)additionalData;

/* Called when we receive stats related to session */
- (void) onStats:(NSDictionary*)toApp;

/* Called when we receive logs from lower layer */
- (void) onSdkLogs:(NSString*)str severity:(int)sev;

/* Called when we receive the final stats */
- (void) OnfinalStats:(NSMutableDictionary*)metaData timeseries:(NSMutableDictionary*)obj streamInfo:(NSMutableDictionary*)streamInfo ;

/*
 Event Type - Provide different session event e.g. NetworkQualityChanged
 Event Data -  Provide the network state (e.g. WebRTCWeakNetwork,WebRTCStrongNetwork etc)  and
 reason for the state */
- (void) onSessionEvent:(EventType)eventType eventData:(NSDictionary*)eventData;

/* Session delegate for data channel*/
- (void) onDataChannelConnect;

/* Delegate to recieve filepath of the recived image using data channel */
- (void) onSessionDataWithImage:(NSString*)filePath;

/* Delegate to recieve text data using data channel */
- (void) onSessionDataWithText:(NSString*)filePath;

/* XCMA specific callback */
- (void) onConfigMessage_xcmav:(NSString*) msg;

/* Called when we have joined XMPP MUC */
- (void) onXmppJoined:(NSString *)RoomName;

/* Called when a participant joined XMPP MUC */
- (void) onXmppParticipantJoined:(NSString *)ParticipantName;

/* Called when a participant left XMPP MUC */
- (void) onXmppParticipantLeft:(NSString *)ParticipantName;

@end

/*
 **
 ** WebRTC session interface
 **
 */

@interface WebRTCSession : NSObject <RTCPeerConnectionDelegate,WebRTCChannelDelegate, RTCDataChannelDelegate>

/* Below API's are called from the application for configuring the session*/

- (void)setDTLSFlag:(BOOL)value;
- (void)preferCodec:(BOOL)value;
- (void)applySessionConfigChanges:(WebRTCSessionConfig*)configParam;
- (void)onUserConfigSelection:(NSDictionary*)json;
- (void)disconnect;
- (NSDictionary *)getRemotePartyInfo;
- (void)sendDTMFTone:(Tone)_tone;

/* API to start a PSTN Call */
- (void)startPSTNCall:dialNum;

/* API to end a PSTN Call */
- (void)endPSTNCall;

/* API to merge a PSTN Call */
-(void)merge;

/* API to hold a PSTN Call */
- (void)hold:(NSString*)dialNum;

/* API to UnHold a PSTN Call */
- (void)unHold:(NSString*)dialNum;

// DataChannel: API's to send image and text data using data channel
-(void)sendDataWithImage:(NSString*)filePath;
-(void)sendCompressedImageData:(NSData*)imgData;
-(void)sendDataWithText:(NSString*)_textMsg;

/* This is an API to initialize WebRTC SDK session for legacy backend architectures */
- (WebRTCSession *)initWithDefaultValue:(WebRTCStack *)stack arClientSessionId:(NSString*)arClientSessionId  _configParam:(WebRTCSessionConfig *)_sessionConfig _stream:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate  _statcollector:(WebRTCStatsCollector *)_statcollector;

/* This is an API to initialize WebRTC SDK session for RTC 1.0- Channel based architecture */
- (WebRTCSession *)initRTCGSessionWithDefaultValue:(WebRTCStack *)stack arClientSessionId:(NSString*)arClientSessionId  _configParam:(WebRTCSessionConfig *)_sessionConfig _stream:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate  _statcollector:(WebRTCStatsCollector *)_statcollector _serverURL:(NSString*)_serverURL;

/* This is an API to initialize WebRTC SDK session for RTC 2.0 */
- (WebRTCSession *)initWithXMPPValue:(WebRTCStack *)stack  _configParam:(WebRTCSessionConfig *)_sessionConfig _stream:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate  _statcollector:(WebRTCStatsCollector *)_statcollector;

/* This is an API to initiate an outgoing video and audio call */
- (WebRTCSession *)initWithIncomingSession:(WebRTCStack *)stack arClientSessionId:(NSString*)arClientSessionId  _stream:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate channelapi:(BOOL)_isChannelAPIEnable _statcollector:(WebRTCStatsCollector *)_statcollector _configParam:(WebRTCSessionConfig *)_sessionConfig;

/* This is an API to initiate an PSTN Call*/
- (WebRTCSession *)initWithPSTNSession:(WebRTCStack *)stack _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate _configParam:(WebRTCStackConfig *)_stackConfig;


/* Internal legacy APIs: Kept for internal purposes, do not use this in the application */
- (void) updatingIceServersData:(NSDictionary*)msg;
- (void) start;
- (void) start:(NSDictionary *)iceServers;
- (void) onSignalingMessage:(id)msg;
- (void) reconnectSession;
- (NSString*) getClientSessionId;
- (void) networkReconnected;
- (void) sendMessage:(NSString*)targetId json:(NSDictionary*)json;
- (void) dataFlagEnabled:(BOOL)_dataFlag;
- (void) setXMPPEnable:(BOOL)val;
- (void) setRoomId:(NSString*)roomId;
- (void) serverUrl:(NSString*)_websocketURL routingId:(NSString*)_routingId serviceId:(NSString*)_serviceId;
-(void)endPSTNSession;

@end
#endif
