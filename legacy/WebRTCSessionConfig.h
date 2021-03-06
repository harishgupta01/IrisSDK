//
//  WebRTCSessionConfig.h
//  xfinity-webrtc-sdk
//
//  Created by Pankaj on 26/08/14.
//  Copyright (c) 2014 Comcast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "WebRTC/WebRTC.h"
#import "WebRTCUtil.h"
#import "WebRTCStreamConfig.h"





typedef enum {
    low,
    mid,
    high,
}WebRTCStreamResolution_e;

typedef enum {
    lowScale,
    midScale,
    original,
}WebRTCDataChannelScaleFactor_e;

typedef enum
{
    iPhone4,  // 4 series
    iPhone5,  // 5 series
    iPhone6,  // 6 series
    unknown
}iPhoneSeries;

typedef enum
{
    QVGA,
    VGA,
    HD,
    FHD
}CamResolution;

/* Kyes for configuring the threshold values for different levels 
 for  network quality */
extern NSString * const WebRTCBadNetworkQualityKey;
extern NSString * const WebRTCPoorNetworkQualityKey;
extern NSString * const WebRTCFairNetworkQualityKey;
extern NSString * const WebRTCGoodNetworkQualityKey;

@interface WebRTCSessionConfig : NSObject

@property (nonatomic) NSString *audio;
@property (nonatomic) NSString *video;
@property (nonatomic) NSString *data;
@property (nonatomic) WebRTCStreamResolution_e resolution;

//Call Type
@property (nonatomic) WebrtcSessionCallTypes callType;
@property (nonatomic) BOOL isOneWay;
@property (nonatomic) BOOL isBroadcast;
@property (nonatomic) WebrtcSessionOptions_t* sessionOptions;

//Call from/to info
@property (nonatomic) NSString* targetID;
@property (nonatomic) NSString* callerID;
@property (nonatomic) NSString* displayName;

//Need to check if this will be a part of session config
@property (nonatomic) NSString* rtcgSessionId;
@property (nonatomic) NSString* roomId;

@property (nonatomic) NSString* STBID;

//Bandwidth check
@property (nonatomic) BOOL isBWCheckEnable;
@property (nonatomic) WebRTCStreamConfig* streamConfig;

//CIMA token for eligibility token query
@property (nonatomic) BOOL isChannelTokenEnable;
@property (nonatomic) NSData* cimaToken;

@property (nonatomic) NSString* appName;
@property (nonatomic) NSString* deviceID;

//Network Quality Indicator Threshhold vales for Packet Loss/RTT/AvailableSendBW
@property (nonatomic) NSMutableDictionary* rttThresholdLevels;
@property (nonatomic) NSMutableDictionary* sendBWThresholdLevels;
@property (nonatomic) NSMutableDictionary* packetLossThresholdLevels;

//Ping Response timeout and ping interval for checking if remote client is alive
@property (nonatomic) NSInteger pingResponseTimeout;
@property (nonatomic) NSInteger pingInterval;

@property (nonatomic) BOOL isConfigChange;

@property (nonatomic)BOOL preferredH264;

@property (nonatomic)BOOL EnableIPv6;
@property (nonatomic)NSString* ipv6patch;

@property (nonatomic)BOOL forceRelay;


//Data chunk size (in bytes) while sending it to other party.
@property (nonatomic)NSInteger dataChunkSize;
@property (nonatomic)WebRTCDataChannelScaleFactor_e dataScaleFactor;

@property (nonatomic) NSString* rtcTargetJid;

//xmpp
@property (nonatomic) BOOL notificationRequired;
@property (nonatomic) NSString *xmppCallType;
@property (nonatomic) NSMutableArray *participantsInfo;
@property (nonatomic) NSString *instanceId;
@property (nonatomic) NSString *deviceType;
@property (nonatomic) NSInteger maxParticipants;
//PSTN
@property (nonatomic) NSString *targetPhoneNum;
//@property (nonatomic) NSString *sourcePhoneNum;

@property (nonatomic) NSString* sType;
@property (nonatomic) NSString* topic;

//counter for join room request retry
@property (nonatomic) NSInteger joinRoomRequestRetryCount;

@property (nonatomic)BOOL videoBridge;

@property (nonatomic)BOOL delaySendingCandidate;
//Event Manager
@property (nonatomic)NSDictionary* userData;
@property (nonatomic)NSInteger timePosted;
@property (nonatomic)NSString* roomName;

- (id)init;
-(NSString*)getResolutionString;
@end
