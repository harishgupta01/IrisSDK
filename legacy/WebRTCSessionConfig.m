//
//  WebRTCSessionConfig.m
//  xfinity-webrtc-sdk
//
//  Created by Pankaj on 26/08/14.
//  Copyright (c) 2014 Comcast. All rights reserved.
//

#import "WebRTCSessionConfig.h"

/*Defining default values for Bandwidth Indicator
 for RTT , Packet Loss and Available Send Bandwidth */
 
#define DEFAULT_MAX_THRESHOLD_RTT_LEVEL1 5000
#define DEFAULT_MAX_THRESHOLD_RTT_LEVEL2 1000
#define DEFAULT_MAX_THRESHOLD_RTT_LEVEL3 100
#define DEFAULT_MAX_THRESHOLD_RTT_LEVEL4 50

#define DEFAULT_MAX_THRESHOLD_PACKETLOSS_LEVEL1 50
#define DEFAULT_MAX_THRESHOLD_PACKETLOSS_LEVEL2 20
#define DEFAULT_MAX_THRESHOLD_PACKETLOSS_LEVEL3 10
#define DEFAULT_MAX_THRESHOLD_PACKETLOSS_LEVEL4 2

#define DEFAULT_MIN_REQUIRED_AVASENDBW_LEVEL1 100
#define DEFAULT_MIN_REQUIRED_AVASENDBW_LEVEL2 250
#define DEFAULT_MIN_REQUIRED_AVASENDBW_LEVEL3 450
#define DEFAULT_MIN_REQUIRED_AVASENDBW_LEVEL4 1000

#define PING_RESPONSE_TIMEOUT 4
#define PING_INTERVAL 1
#define DEFAULT_DATACHUNKSIZE 16
#define DEFAULT_MAXPARTICIPANTS 2 //For share and connect

NSString * const WebRTCBadNetworkQualityKey = @"WebRTCBadNetworkQualityKey";
NSString * const WebRTCPoorNetworkQualityKey = @"WebRTCPoorNetworkQualityKey";
NSString * const WebRTCFairNetworkQualityKey = @"WebRTCFairNetworkQualityKey";
NSString * const WebRTCGoodNetworkQualityKey = @"WebRTCGoodNetworkQualityKey";
NSString * const WebRTCExcellentNetworkQualityKey = @"WebRTCExcellentNetworkQualityKey";

@interface WebRTCSessionConfig ()
@property (nonatomic) WebrtcSessionOptions_t defaultSessionOption;
@end

@implementation WebRTCSessionConfig

// Internal parameters
@synthesize sessionOptions = _sessionOptions;
@synthesize audio = _audio;
@synthesize video = _video;
@synthesize data = _data;
@synthesize resolution = _resolution;
@synthesize isBroadcast = _isBroadcast;
@synthesize isOneWay = _isOneWay;
@synthesize callType = _callType;
@synthesize targetID = _targetID;
@synthesize callerID = _callerID;
@synthesize displayName = _displayName;
@synthesize rtcgSessionId = _rtcgSessionId;
@synthesize roomId = _roomId;
@synthesize streamConfig = _streamConfig;
@synthesize appName = _appName;
@synthesize isBWCheckEnable = _isBWCheckEnable;
@synthesize isConfigChange = _isConfigChange;
@synthesize isChannelTokenEnable = _isChannelTokenEnable;
@synthesize cimaToken = _cimaToken;
@synthesize rttThresholdLevels = _rttThresholdLevels;
@synthesize packetLossThresholdLevels = _packetLossThresholdLevels;
@synthesize sendBWThresholdLevels = _sendBWThresholdLevels;
@synthesize deviceID = _deviceID;
@synthesize pingResponseTimeout = _pingResponseTimeout;
@synthesize pingInterval = _pingInterval;
@synthesize preferredH264 = _preferredH264;
@synthesize EnableIPv6 = _EnableIPv6;
@synthesize ipv6patch = _ipv6patch;
@synthesize forceRelay = _forceRelay;
@synthesize dataChunkSize = _dataChunkSize;
@synthesize dataScaleFactor = _dataScaleFactor;
//xmpp
@synthesize notificationRequired = _notificationRequired;
@synthesize xmppCallType = _xmppCallType;
@synthesize participantsInfo = _participantsInfo;
@synthesize instanceId = _instanceId;
@synthesize deviceType = _deviceType;
@synthesize STBID = _STBID;
@synthesize maxParticipants = _maxParticipants;
//PSTN
@synthesize targetPhoneNum = _targetPhoneNum;
//@synthesize sourcePhoneNum = _sourcePhoneNum;

@synthesize sType = _sType;
@synthesize topic = _topic;
@synthesize videoBridge = _videoBridge;
@synthesize delaySendingCandidate = _delaySendingCandidate;
//Event Manager
@synthesize userData = _userData;
@synthesize timePosted = _timePosted;
@synthesize roomName = _roomName;

- (id)init
{
    self = [super init];
    if (self!=nil) {
        // Use default options
        _defaultSessionOption.EnableAudioRecv = true;
        _defaultSessionOption.EnableAudioSend = true;
        _defaultSessionOption.EnableBroadcast = false;
        _defaultSessionOption.EnableDataRecv = false;
        _defaultSessionOption.EnableDataSend = false;
        _defaultSessionOption.EnableOneWay = false;
        _defaultSessionOption.EnableVideoRecv = true;
        _defaultSessionOption.EnableVideoSend = true;
        _callType = outgoing;
        _resolution = mid;
        _streamConfig = nil;
		_appName = @"PBApp";
        _isBWCheckEnable = false;
        _isConfigChange = false;
        _pingResponseTimeout = PING_RESPONSE_TIMEOUT;
        _pingInterval = PING_INTERVAL;
        _preferredH264 = false;
        _EnableIPv6 = false;
        _ipv6patch = @"true";
        _forceRelay = false;
        _dataScaleFactor = midScale;
        _dataChunkSize = DEFAULT_DATACHUNKSIZE * 1024;
        _maxParticipants = DEFAULT_MAXPARTICIPANTS; 
        //Initializing default values for RTT/PacketLoss/Send Bandwidth threshold values
        _rttThresholdLevels = [[NSMutableDictionary alloc]init];
        [_rttThresholdLevels setValue:[NSNumber numberWithInteger:DEFAULT_MAX_THRESHOLD_RTT_LEVEL1]
                forKey:WebRTCBadNetworkQualityKey];
        [_rttThresholdLevels setValue:[NSNumber numberWithInteger:DEFAULT_MAX_THRESHOLD_RTT_LEVEL2]
                forKey:WebRTCPoorNetworkQualityKey];
        [_rttThresholdLevels setValue:[NSNumber numberWithInteger:DEFAULT_MAX_THRESHOLD_RTT_LEVEL3]
                forKey:WebRTCFairNetworkQualityKey];
        [_rttThresholdLevels setValue:[NSNumber numberWithInteger:DEFAULT_MAX_THRESHOLD_RTT_LEVEL4]
                forKey:WebRTCGoodNetworkQualityKey];

        _packetLossThresholdLevels = [[NSMutableDictionary alloc]init];
        [_packetLossThresholdLevels setValue:[NSNumber numberWithInteger:DEFAULT_MAX_THRESHOLD_PACKETLOSS_LEVEL1]
                forKey:WebRTCBadNetworkQualityKey];
        [_packetLossThresholdLevels setValue:[NSNumber numberWithInteger:DEFAULT_MAX_THRESHOLD_PACKETLOSS_LEVEL2]
                forKey:WebRTCPoorNetworkQualityKey];
        [_packetLossThresholdLevels setValue:[NSNumber numberWithInteger:DEFAULT_MAX_THRESHOLD_PACKETLOSS_LEVEL3]
                forKey:WebRTCFairNetworkQualityKey];
        [_packetLossThresholdLevels setValue:[NSNumber numberWithInteger:DEFAULT_MAX_THRESHOLD_PACKETLOSS_LEVEL4]
                forKey:WebRTCGoodNetworkQualityKey];
        
        _sendBWThresholdLevels = [[NSMutableDictionary alloc]init];
        [_sendBWThresholdLevels setValue:[NSNumber numberWithInteger:DEFAULT_MIN_REQUIRED_AVASENDBW_LEVEL1]
                forKey:WebRTCBadNetworkQualityKey];
        [_sendBWThresholdLevels setValue:[NSNumber numberWithInteger:DEFAULT_MIN_REQUIRED_AVASENDBW_LEVEL2]
                forKey:WebRTCPoorNetworkQualityKey];
        [_sendBWThresholdLevels setValue:[NSNumber numberWithInteger:DEFAULT_MIN_REQUIRED_AVASENDBW_LEVEL3]
                forKey:WebRTCFairNetworkQualityKey];
        [_sendBWThresholdLevels setValue:[NSNumber numberWithInteger:DEFAULT_MIN_REQUIRED_AVASENDBW_LEVEL4]
                forKey:WebRTCGoodNetworkQualityKey];
	 //xmpp
        _notificationRequired = true;
        _xmppCallType = @"video";
        _participantsInfo = [[NSMutableArray alloc]init];
         _instanceId = [[NSUUID UUID] UUIDString];
        _targetPhoneNum = @"";
        //_sourcePhoneNum = @"123456";
        _deviceType = @"mobile";
        _sType = @"livestream";
        _topic = @"bc";
        _joinRoomRequestRetryCount = 0;
        _videoBridge = true;
        _delaySendingCandidate = false;

    }
    
    return self;
}

-(NSString*)getResolutionString
{
    switch(_resolution){
        case low:
            return @"qcif";
        case mid:
            return @"default";
        case high:
            return @"hd";
        default:
            return @"default";
    }
}


-(void)setSessionOptions:(WebrtcSessionOptions_t*)sessionOptions
{
    _data = @"dataChannel";
    
    if(sessionOptions == nil)
        *_sessionOptions = _defaultSessionOption;
    else
        _sessionOptions = sessionOptions;

    // Check the options set by the user
    if (_sessionOptions->EnableAudioRecv && _sessionOptions->EnableAudioSend)
    {
        _audio = @"sendrecv";
    }
    else if (_sessionOptions->EnableAudioRecv)
    {
        _audio = @"recvonly";
    }
    else
    {
        _audio = @"sendonly";
    }
    
    if (_sessionOptions->EnableVideoRecv && _sessionOptions->EnableVideoSend)
    {
        _video = @"sendrecv";
    }
    else if (_sessionOptions->EnableVideoRecv)
    {
        _video = @"recvonly";
    }
    else if(_sessionOptions->EnableVideoSend)
    {
        _video = @"sendonly";
    }
    else
    {
        _video = @"inactive";
        _data = @"inactive";
    }
    
    if (_sessionOptions->EnableOneWay)
    {
        _isOneWay = true;
    }
    else
    {
        _isOneWay = false;
    }

    if (_sessionOptions->EnableBroadcast)
    {
        _isBroadcast = true;
    }
    else
    {
        _isBroadcast = false;
    }

}
@end
