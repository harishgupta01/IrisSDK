//
//  WebRTCStack.h
//  XfinityVideoShare
//

#ifndef WEBRTC_STACK_H
#define WEBRTC_STACK_H

#import <Foundation/Foundation.h>
#import "RTCPeerConnectionFactory.h"
#import "WebRTCUtil.h"
#import "WebRTCStream.h"
#import "WebRTCStatsCollector.h"
#import "WebRTCHTTP.h"
#import "WebRTCSessionConfig.h"
#import "WebRTCStackConfig.h"
#import "Reachability.h"
@class WebRTCSession,SignalHandler,WebRTCHTTP,WebRTCStatsCollector, WebRTCStackConfig;
@protocol WebRTCSessionDelegate;

@protocol WebRTCStackDelegate <NSObject>

/* This callback is required only for RTC 1.0, it indicates the stack 
   is ready for calls */
- (void) onReady:(NSArray*) alias;

/* Called with track associated with local preview */
- (void) onLocalPreview:(RTCVideoTrack *)videoTrack;

/* Called when we are successfully connected to XMPP server */
- (void) onXmppConnect;

/* Called when we are disconnected from XMPP server */
- (void) onXmppDisconnect:(NSString*)msg;

/* When the stack is disconnected for WS server */
- (void) onDisconnect:(NSString*)msg;

/* Called when we receive any error */
- (void) onStackError:(NSString*)error errorCode:(NSInteger)code additionalData:(NSDictionary *)additionalData;

/* Called when network state changes */
- (void) onNetworkStateChange:(NetworkState)state;

/* For legacy backend architecture, this is called when we are
 registered to the backend */
- (void) onRegister;

/* Called when a image is received from backend */
- (void) onSessionDataWithImage:(NSString*)filePath;

/* Called when analytics related event need to be reported */
- (void) onLogToAnalytics:(NSString*)event;

/* Called with response for getresources */
- (void) onReceiveResources:(NSData*)event;

/* This callback is invoked when we receive an offer from the remote,
 this should not be used in the current context and kept for legacy
 purpose */
- (void) onOffer: (NSString*)from to:(NSString*)to;

@end

/* 
** 
** WebRTC stack interface 
**
*/
@interface WebRTCStack : NSObject<WebRTCStreamDelegate,WebRTCHTTPDelegate>
/* This is an API to initialize WebRTC SDK stack for legacy backend architectures */
- (id)initWithDefaultValue:(WebRTCStackConfig*)_stackConfig
              _appdelegate:(id<WebRTCStackDelegate>)_appdelegate;

/* This is an API to initialize WebRTC SDK stack for RTC 1.0 and 2.0
   Use initRTCGWithDefaultValue stackconfig option for RTC 1.0 - Channel based architecture
   Use initXMPPWithDefaultValue stackconfig option for RTC 2.0 */
- (id)initWithRTCG:(WebRTCStackConfig*)_stackConfig
      _appdelegate:(id<WebRTCStackDelegate>)_appdelegate;

/* This to initiate an outgoing video and audio call */
- (id)createSession:(WebRTCStream *)_stream
       _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate
       _configParam:(WebRTCSessionConfig *)_sessionConfig;

/* This to initiate an outgoing video and audio call */
- (id)createIncomingSession:(WebRTCStream *)_stream
               _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate
               _configParam:(WebRTCSessionConfig *)_sessionConfig;

/* API to create video and audio local stream using WebRTCStream class */
- (id)createStream:(WebRTCStreamConfig*)_streamConfig
_recordingDelegate:(id<WebRTCSessionDelegate>)appDelegate;

/* API to create audio only stream */
- (id)createAudioOnlyStream;

/* API to disconnect stack and all associated sessions */
- (void)disconnect;

/* API to Create session for data channel for sending image/text data */
- (id)createDataSession:(id<WebRTCSessionDelegate>)_appdelegate
           _configParam:(WebRTCSessionConfig *)_sessionConfig;

/* API to set recording state on the XMPP server */
- (void)setRecordingState:(NSString*)state;

/* Internal legacy APIs: Kept for internal purposes, do not use this in the application */
@property(nonatomic) BOOL isCapabilityExchangeEnable;
@property(nonatomic) BOOL isVideoBridgeEnable;
@property(nonatomic) NetworkTypes networkType;
@property(nonatomic) WebRTCStackConfig* stackConfig;
- (void)sendRTCMessage:(id)msg;
- (int)getMachineID;
- (NSMutableDictionary*)getMetaData;
- (void)onXmppServerConnected;
- (void)logToAnalytics:(NSString*)event;
- (void)enableIPV6:(BOOL)value;
- (NSString*)getTraceId;
@end
#endif

