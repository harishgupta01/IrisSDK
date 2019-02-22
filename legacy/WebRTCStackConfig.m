//
//  WebRTCStackConfig.m
//  xfinity-webrtc-sdk
//
//  Created by Pankaj on 26/08/14.
//  Copyright (c) 2014 Comcast. All rights reserved.
//

#import "WebRTCStackConfig.h"

@implementation WebRTCStackConfig


@synthesize wsToken = _wsToken;
@synthesize isChannelAPIEnable = _isChannelAPIEnable;
@synthesize serverURL = _serverURL;
@synthesize usingRTC20 = _usingRTC20;
@synthesize userId = _userId;
@synthesize resourceURL = _resourceURL;
@synthesize httpRequestTimeout = _httpRequestTimeout;
//@synthesize custguIdHeader = _custguIdHeader;
//@synthesize trackingIdHeader = _trackingIdHeader;
@synthesize traceIdHeader = _traceIdHeader;
@synthesize serverNameHeader = _serverNameHeader;
@synthesize clientNameHeader = _clientNameHeader;
@synthesize sourceIdHeader = _sourceIdHeader;
@synthesize deviceIdHeader = _deviceIdHeader;
@synthesize routingId = _routingId;
@synthesize targetRoutingId = _targetRoutingId;
@synthesize originInstanceId = _originInstanceId;
@synthesize isOpenSipRequest = _isOpenSipRequest;
@synthesize sourcePhoneNum = _sourcePhoneNum;
@synthesize targetPhoneNum = _targetPhoneNum;
@synthesize getResourceResponse = _getResourceResponse;
@synthesize event = _event;
@synthesize nodeid = _nodeid;
@synthesize cnodeid = _cnodeid;
@synthesize unodeid = _unodeid;
@synthesize xmppRegisterURL = _xmppRegisterURL;
@synthesize xmppToken = _xmppToken;
@synthesize xmppTokenExpiryTime = _xmppTokenExpiryTime;

//Event Manager
@synthesize useEventManager = _useEventManager;
@synthesize jsonWebToken = _jsonWebToken;
- (id)initWithDefaultValue:(NSData*)token _serverURL:(NSString*)serverURL _portNumber:(NSInteger)portNumber _secure:(BOOL)secure  _statsURL:(NSString*)statsURL
{
    self = [super init];
    if (self!=nil) {
        
        _wsToken = token;
        _serverURL = serverURL;
        _portNumber = portNumber;
        _statsURL = statsURL;
        _isChannelAPIEnable = false;
        _isSecure = secure;
        _isNwSwitchEnable = false;
        _doManualDns = false;
        _usingRTC20 = false;
        _httpRequestTimeout = 60; //default 60 seconds
        _h264Codec = false;
        _getResourceResponse = nil;
        _useEventManager = false;
        _jsonWebToken = nil;
    }
    return self;
}

- (id)initRTCGWithDefaultValue:(NSData*)token _httpRequestURL:(NSString*)serverURL _userId:(NSString *)userId _statsURL:(NSString*)statsURL _usingRTC20:(BOOL)usingRTC20 _sourcePhoneNum:(NSString*)sourcePhoneNum _targetPhoneNum:(NSString *)targetPhoneNum
{
    self = [super init];
    if (self!=nil) {
        
        _wsToken = token;
        _serverURL = serverURL;
        _statsURL = statsURL;
        _isChannelAPIEnable = !usingRTC20;
        _isNwSwitchEnable = false;
        _doManualDns = false;
        _userId = [userId lowercaseString]; // US491798
        _usingRTC20 = usingRTC20;
        
        //_custguIdHeader = @"445955150715052014Comcast.USRIMS";
        //_trackingIdHeader = @"2971c7e0-e839-11e4"; //need to remove the hardcoded value
        _traceIdHeader = @"";
        _event = @"eventTypeShare";
        _serverNameHeader = @"RTCGSM";
        _clientNameHeader = @"Mobile";
        _sourceIdHeader = @"PBA";
        _deviceIdHeader = @"2971c7e0-e839-11e40"; //need to remove the hardcoded value
        _sourcePhoneNum = sourcePhoneNum;
        _targetPhoneNum = targetPhoneNum;
        _httpRequestTimeout = 60; //default 60 seconds
        _routingId = @"";
        _originInstanceId = [[NSUUID UUID] UUIDString];
        _isOpenSipRequest = @"false";
        _h264Codec = false;
        _useEventManager = false;
        _jsonWebToken = nil;
    }
    
    return self;

}


- (id)initXMPPWithDefaultValue:(NSData*)token _httpRequestURL:(NSString*)serverURL _userId:(NSString *)userId _statsURL:(NSString*)statsURL _usingRTC20:(BOOL)usingRTC20 _resourceURL:(NSString *)resourceURL _targetPhoneNum:(NSString *)targetPhoneNum _eventType:event
{
    self = [super init];
    if (self!=nil) {
        
        _wsToken = token;
        _serverURL = serverURL;
        _statsURL = statsURL;
        _isChannelAPIEnable = !usingRTC20;
        _isNwSwitchEnable = false;
        _doManualDns = false;
        _userId = [userId lowercaseString]; // US491798
        _usingRTC20 = usingRTC20;
        _resourceURL = resourceURL;
        
        //_custguIdHeader = @"445955150715052014Comcast.USRIMS";
        //_trackingIdHeader = @"2971c7e0-e839-11e4"; //need to remove the hardcoded value
        _event = event;
        _traceIdHeader = @"";
        _serverNameHeader = @"RTCGSM";
        _clientNameHeader = @"Mobile";
        _sourceIdHeader = @"PBA";
        _deviceIdHeader = @"2971c7e0-e839-11e40"; //need to remove the hardcoded value
        _sourcePhoneNum = @"";
        _targetPhoneNum = targetPhoneNum;
        _routingId = @"";
        _targetRoutingId= [[NSMutableArray alloc]init];
        _originInstanceId = [[NSUUID UUID] UUIDString];
        _isOpenSipRequest = @"false";
        _h264Codec = false;
        _getResourceResponse = nil;
        _useEventManager = false;
        _jsonWebToken = nil;
    }
    return self;
}

- (id)initIRISStackConfigWithDefaultValue:(NSString*)registerInfoURL _sourceRoutingID:(NSString*)routingId  _statsURL:(NSString*)statsURL
{
    self = [super init];
    if (self!=nil) {
        
        _wsToken = nil;
        _xmppRegisterURL = registerInfoURL;
        _statsURL = statsURL;
        _isChannelAPIEnable = false;
        _isNwSwitchEnable = false;
        _doManualDns = false;
        _userId = nil; // US491798
        _usingRTC20 = true;
        _resourceURL = nil;
        
        //_custguIdHeader = @"445955150715052014Comcast.USRIMS";
        //_trackingIdHeader = @"2971c7e0-e839-11e4"; //need to remove the hardcoded value
        _event = @"";
        _traceIdHeader = @"";
        _serverNameHeader = @"RTCGSM";
        _clientNameHeader = @"Mobile";
        _sourceIdHeader = @"PBA";
        _deviceIdHeader = @"2971c7e0-e839-11e40"; //need to remove the hardcoded value
        _sourcePhoneNum = @"";
        _targetPhoneNum = @"";
        _routingId = routingId;
        _targetRoutingId= [[NSMutableArray alloc]init];
        _originInstanceId = [[NSUUID UUID] UUIDString];
        _isOpenSipRequest = @"false";
        _h264Codec = false;
        _getResourceResponse = nil;
        _useEventManager = true;
        _jsonWebToken = nil;
        
        _xmppTokenExpiryTime = nil;
        _xmppToken = nil;
        _xmppRTCServer = nil;
    }
    return self;
}
@end
