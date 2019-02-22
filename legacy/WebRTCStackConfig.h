//
//  WebRTCStackConfig.h
//  xfinity-webrtc-sdk
//
//  Created by Pankaj on 26/08/14.
//  Copyright (c) 2014 Comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SignalHandler;

@interface WebRTCStackConfig : NSObject

@property (nonatomic) NSData *wsToken;
@property (nonatomic) NSString *serverURL;

@property (nonatomic) NSInteger portNumber;
@property (nonatomic) BOOL isChannelAPIEnable;
@property (nonatomic) BOOL isSecure;
@property (nonatomic) NSString *statsURL;
@property (nonatomic) BOOL isNwSwitchEnable;
@property (nonatomic) BOOL doManualDns;
@property (nonatomic) NSString *userId;
@property (nonatomic) NSTimeInterval httpRequestTimeout;
@property (nonatomic) NSData *getResourceResponse;

//RTC-2.0
@property (nonatomic) BOOL usingRTC20;
@property (nonatomic) NSString* sourcePhoneNum;
@property (nonatomic) NSString* targetPhoneNum;
@property (nonatomic) NSString* resourceURL;
//create room request http headers
//@property (nonatomic) NSString* custguIdHeader;
//@property (nonatomic) NSString* trackingIdHeader;
@property (nonatomic) NSString* traceIdHeader;
@property (nonatomic) NSString* serverNameHeader;
@property (nonatomic) NSString* clientNameHeader;
@property (nonatomic) NSString* sourceIdHeader;
@property (nonatomic) NSString* deviceIdHeader;
@property (nonatomic) NSMutableArray* targetRoutingId;
@property (nonatomic) NSString* originInstanceId;
@property (nonatomic) NSString* isOpenSipRequest;
@property (nonatomic) BOOL h264Codec;

//Attributes form newly added XML namespace for miscelleneous data for XMPP messages
@property (nonatomic) NSString* event;
@property (nonatomic) NSString* nodeid;
@property (nonatomic) NSString* cnodeid;
@property (nonatomic) NSString* unodeid;
//EventManager
@property (nonatomic) BOOL useEventManager;
@property (nonatomic) NSString* jsonWebToken;
@property (nonatomic) NSString* xmppRegisterURL;
@property (nonatomic) NSString* routingId;
@property (nonatomic) NSString* xmppRTCServer;
@property (nonatomic) NSString* xmppToken;
@property (nonatomic) NSString* xmppTokenExpiryTime;

- (id)initWithDefaultValue:(NSData*)token _serverURL:(NSString*)serverURL _portNumber:(NSInteger)portNumber _secure:(BOOL)secure _statsURL:(NSString*)statsURL;
- (id)initRTCGWithDefaultValue:(NSData*)token _httpRequestURL:(NSString*)serverURL _userId:(NSString *)userId _statsURL:(NSString*)statsURL _usingRTC20:(BOOL)usingRTC20 _sourcePhoneNum:(NSString*)sourcePhoneNum _targetPhoneNum:(NSString*)targetPhoneNum;
- (id)initXMPPWithDefaultValue:(NSData*)token _httpRequestURL:(NSString*)serverURL _userId:(NSString *)userId _statsURL:(NSString*)statsURL _usingRTC20:(BOOL)usingRTC20 _resourceURL:(NSString*)resourceURL _targetPhoneNum:(NSString*)targetPhoneNum _eventType:event;
- (id)initIRISStackConfigWithDefaultValue:(NSString*)registerInfoURL _sourceRoutingID:(NSString*)routingId  _statsURL:(NSString*)statsURL;

@end
