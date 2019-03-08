//
//  IrisRtcSession.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 9/26/16.
//  Copyright © 2016 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <sys/utsname.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "Reachability.h"
#import "IrisRtcJingleSession.h"
#import "XMPPWorker.h"
#import "WebRTC/WebRTC.h"
#import "IrisLogging.h"
#import "XMPPPresence+Iris.h"

#import "WebRTCStatReport.h"
#import "WebRTCJSON.h"

#import "ARDSDPUtils.h"
#import "WebRTCFactory.h"
#import "IrisRtcUtils.h"
#import "IrisRtcEventManager.h"
#import "WebRTCStatsCollector.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "IrisRtcStream.h"
#include "IrisRtcVideoSession.h"
#include "IrisRtcDataSession.h"
#include "IrisRtcAudioSession.h"
#import "IrisRtcStream+Internal.h"
#import "IrisRtcMediaTrack+Internal.h"
#import "IrisRtcJingleSession+Internal.h"
#import "WebRTCUtil.h"
#import "WebRTCSessionConfig.h"
#import "IrisRtcChatSession.h"
#import "IrisDataElement.h"
#import "IrisXMPPRoom.h"
#import "IrisJingleHandler.h"
#import "IrisRtcSdkStats.h"
#import "IrisRtcParticipant.h"
#import "XMPPJID+Iris.h"
#import "IrisXMPPRoom.h"
#import "IrisRtcConnection+Internal.h"
#import "IrisPhoneNumberUtil.h"
#define ICE_SERVER_TIMEOUT 3
#define OFFER_TIMEOUT 60
#define STREAM_STATS_TIMEOUT 1
#define NETWORK_CHECK_VAL 5
#define DATACHANNEL_STREAM_ID 1
#define DTMFTONE_DURATION 1000
#define DTMFTONE_GAP 50
#define NETWORK_CHECK_VAL 5
#define DEFAULT_STATS_TIMEINTERVAL 10
#define PARTICIPANT_PRESENCE_CHECK_TIMEINTERVAL 30
#define SESSION_CONNECTION_TIMEOUT 30


#define toneValueString(enum) [@[@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"0",@"*",@"#",@"A",@"B",@"C",@"D"] objectAtIndex:enum]


#define sipstatus(enum) [@[@"Initializing",@"Connecting",@"Connected",@"Disconnected",@"Hold"] objectAtIndex:enum]


BOOL BandthWidthflag = false ;
int sessionTimeCounter = 10;
/* Keys for setting network data info */
NSString * const IrisNetworkQualityLevelKey = @"WebRTCNetworkQualityLevelKey";
NSString * const IrisNetworkQualityReasonKey = @"WebRTCNetworkQualityReasonKey";
NSString * const IrisRtcSessionTag = @"IrisRtcSession";


@interface IrisRtcJingleSession()<RTCPeerConnectionDelegate,RTCDataChannelDelegate,XMPPWorkerSignalingDelegate,XMPPRoomDelegate,XMPPJingleDelegate,IrisRtcEventManagerDelegate,WebRTCStatsCollectorDelegate,IrisXMPPRoomDelegate,IrisRtcSdkStatsDelegate,IrisRtcSdkStreamDelegate>
{
    // Signalling server related parameters
    NSString *FromCaller;
    NSString *ToCaller;
    NSString *clientSessionId;
    NSString *rtcgSessionId;
    //NSString *roomId;
    NSString *rtcgid;
    NSString *Uid;
    NSString *DisplayName;
    NSString *ApplicationContext;
    NSString *AppId;
    NSString *peerConnectionId ;
    NSString *dtlsFlagValue;
    //NSTimer *_statsTimer;
    NSTimer *_iceConnCheckTimer;
    NSTimer *capTimer;
    NSTimer *participantPresenceTimer;
    NSTimer *_ringTimer;
    int streamCount;
    NSDate *initialDate;
    XMPPJID *participantJid;
    XMPPJID *pstnTargetJid;
    NSTimeInterval statstimerinterval;
    AVAudioPlayer *ringTonePlayer;
    BOOL isStartedRingTimer;
    // Peerconnection related parameters
    RTCPeerConnectionFactory *factory;
    RTCPeerConnection *peerConnection;
    
    RTCMediaConstraints *mediaConstraints, *pcConstraints;
    NSMutableArray *updatedIceServers,*iceServer;
    NSMutableArray *queuedRemoteCandidates;
    NSMutableArray *iceCandidates;
    NSMutableDictionary *participantsDict;
    NSMutableDictionary *callSummary;
    
    NSData *options;
    State state;
    RTCIceConnectionState newICEConnState;
    
    // Internal parameters
    WebrtcSessionCallTypes callType;  
  
    WebrtcSessionCallTypes startCallType;
    //sdp parameter
    NSDictionary *initialSDP;
    
    //For local sdp
    RTCSessionDescription* localsdp;
    NSMutableArray* allcandidates;
    BOOL isCandidateSent;
    BOOL isParticipantStreamReceived;
    BOOL isParticipantJoined;
    BOOL isChannelAPIEnable;
    BOOL isXMPPEnable;
    BOOL isXMPPJoined;
    BOOL isSessionRestarted;
    WebRTCStatReport* lastSr;
    
    NSDictionary* _iceServers;
    NSString* serverURL;
    BOOL isVideoSuspended;
    BOOL isReOffer;
    NSString* turnIPToStat;
    BOOL turnUsedToStat;
    BOOL dataFlagEnabled;
    NSString *fromJid;
    NSString *videoCodec;
    NSString *audioCodec;
    NSString *participantRoutingid;
    NSDictionary *iceservermsg;
    NSMutableArray *sessionstats;
    
    NSString *codecType;
    IrisRtcStream *localstream;
    IrisRtcJingleSession *session;
    NSString* notificationPayload;
    IrisDataElement* dataElement;
    IrisXMPPRoom* irisRoom;
    IrisRtcSdkStats* stats;
    IrisJingleHandler* jingleHandler;
    IrisRtcParticipant* irisParticipant;
    IrisPhoneNumberUtil* irisPhoneNumberUtil;
    BOOL isUpgrade ;
    BOOL isDialTonePlaying;
    NSTimer *sessionValidateTimer;
    BOOL isReceivedLeaveRoomMessage;
    BOOL isPSTNcallWithTN;
    NSString *oldJid;
    BOOL isLocalHold;
    BOOL isRemoteHold;
    BOOL didStopDialTone;
    BOOL hasErrorOccured;
}

/* Below set of API's are used for internal purpose */
- (void)sendMessage:(NSData*)msg;
- (void)onSessionSignalingMessage:(NSDictionary*)msg;
- (void)sendToChannel:(NSDictionary*)msg;
- (void)closeSession;
- (void)getStreamStatsTimer;
- (void)sendCapability;
- (NSDictionary *) getCapabilityData;
- (void)bandwidthCheck:(NSInteger)BW;
- (void)updateMediaConstraints:(NSInteger)min max:(NSInteger)max;
- (void)onCapabilityMessage:(NSDictionary*)msg;
- (void)checkNetworkState;
- (NetworkQuality)checkNetworkState_IncomingStats;
- (void)updateRTTLevel:(NSInteger)rttValue;
- (void)updatePacketLossLevel:(NSInteger)packetLossValue;
- (void)updateSendBWLevel:(NSInteger)sendBWValue;
//Below API's used to create and send data using data channel
- (BOOL)createDataChannel:(NSString*)channelLabel;
//xmpp API to set from Jid
- (void)setFromJid:(NSString*)jidFrom;

@property(nonatomic) IrisRtcSessionType sessionType;
@property(nonatomic) NSMutableArray* allcandidates;
@property(nonatomic) WebRTCStatsCollector* statsCollector;
//Bandwidth indicator variables
@property(nonatomic ) NSInteger rttValCounter;
@property(nonatomic ) NSInteger packetLossValCounter;
@property(nonatomic ) NetworkQuality networkQualityLevel;
@property(nonatomic ) NetworkQuality oldNetworkQualityLevel;
@property(nonatomic ) NetworkQuality currentRTTLevel;
@property(nonatomic ) NetworkQuality currentPacketLossLevel;
@property(nonatomic ) NetworkQuality currentBWLevel;
@property(nonatomic ) NetworkQuality newRTTLevel;
@property(nonatomic ) NetworkQuality newPacketLossLevel;
@property(nonatomic ) NetworkQuality newBWLevel;

@property(nonatomic ) NSInteger offsetTotalPacket;
@property(nonatomic ) NSInteger offsetPacketLoss;

@property(nonatomic ) NSMutableArray* rttArray;
@property(nonatomic ) NSMutableArray* packetLossArray;
@property(nonatomic ) NSMutableArray* bandwidthArray;
@property(nonatomic ) NSMutableArray* rxPacketLossArray;
@property(nonatomic ) NSMutableArray* ReceivedBWArray;
@property(nonatomic ) NSInteger arrayIndex;
@property(nonatomic ) NSInteger eventArrayindex;
@property(nonatomic ) NSMutableDictionary* eventsdict;
@property(nonatomic ) NSMutableArray* eventsArray;
@property (nonatomic, strong) NSMutableArray *statsQueue;


@property(nonatomic ) BOOL isReceivedPingResponse;
@property(nonatomic ) BOOL isSendingPingPongMsg;
@property(nonatomic ) NSTimer* checkPingResponseTime;
@property(nonatomic,weak) NSTimer *iceConnectionCheckTimer;
@property(nonatomic,weak) NSTimer *sessionIceConnectionCheckTimer;
@property(nonatomic)RTCDataChannel* dataChannel;

// XCMAV: Incoming stats
@property(nonatomic ) NSInteger offsetTotalPacket_Rx;
@property(nonatomic ) NSInteger offsetPacketLoss_Rx;
@property(nonatomic ) NSMutableArray* packetLossArray_Rx;
@property(nonatomic ) NSMutableArray* bandwidthArray_Rx;
@property(nonatomic) NSString* roomName;
@property(nonatomic) NSString* targetRoutingId;
@property(nonatomic) NSString* roomId;
@property(nonatomic) NSArray* targetRoutingIds;
@property(nonatomic) NSString* serverUrl;
@property(nonatomic) NSString* sourcePhoneNum;
@property(nonatomic) NSString* targetPhoneNum;
@property(nonatomic) NSString* notificationPayload;
@property(nonatomic) NSString* toDomain;
@property(nonatomic) BOOL isVideoBridgeEnable;

@property(nonatomic) RTCMediaStream* fakeMediaStream;
@property(nonatomic) RTCAudioTrack* fakeAudioTrack;
@property(nonatomic) RTCVideoTrack* fakeVideoTrack;
@property(nonatomic) IrisRtcEventManager *eventManager;
@property(nonatomic) IrisSIPStatus sipStatus;

@property(nonatomic,weak) id<IrisRtcJingleSessionDelegate,IrisRtcVideoSessionDelegate,IrisRtcDataSessionDelegate,IrisRtcAudioSessionDelegate,IrisRtcSdkSesionStatsDelegate,IrisRtcChatSessionDelegate,IrisXMPPSessionDelegate> sessionDelegate;

@property(nonatomic,weak) id<IrisRtcSdkSesionStatsDelegate> statsDelegate;


@end

@implementation IrisRtcJingleSession:NSObject {
    
    BOOL isAnswerSent,isOfferSent,isAnswerReceived;
    BOOL isDataChannelOpened;
    NSMutableData *concatenatedData;
    NSUInteger dataChunkSize;
    NSString* recievedDataId;
    NSString* startTimeForDataSentStr;
    NSDateFormatter* dateFormatter;
    NSDateFormatter* presenceDateFormatter;
    
    BOOL cancelSendData;
    
    BOOL dataSessionActive;
    NSString* routingId;
    NSString* xmppServer;
    NSString* xmppRoom;
    NSString* serviceId;
    NSString* logEvent_Calltype;
    BOOL isOccupantJoined;
    BOOL isFocusJoined;
    NSDictionary* offerJson;
    XMPPJID * targetJid;
    BOOL isStreamStatusUpdated;

}

@synthesize iceConnectionCheckTimer,useAnonymousRoom;

-(id)initWithSessionType:(IrisRtcSessionType)sessionType
{
    self = [super init];
    if (self!=nil) {
        callSummary = [[NSMutableDictionary alloc]init];
        
        self.sessionType = sessionType;
        isUpgrade = false;
        dtlsFlagValue = @"true";
        //self.roomName = roomName;
        //self.sourcePhoneNum = sourcephnum;
        //self.targetPhoneNum = targetnum;
        iceCandidates = [[NSMutableArray alloc]init];
        IRISLogInfo(@"IrisRtcSession::initWithSessionType obj = %@",self);
       // [self logEvents:@"SDK_Init" additionalinfo:nil];
        state = starting;
        irisRoom = nil;
		isXMPPJoined= false;
        isSessionRestarted = false;
        isStartedRingTimer = false;
        _ringTimer = nil;
        hasErrorOccured = false;
        //localstream = stream;
        if(sessionType == kSessionTypePSTN)
        {
            [[XMPPWorker sharedInstance]setEvent:@"eventTypeConnect PSTN"];
        }
        else
        {
            [[XMPPWorker sharedInstance]setEvent:@"eventTypeConnect"];
        }
        
       // [XMPPWorker sharedInstance].signalingDelegate = self;
        
        _allcandidates = [[NSMutableArray alloc]init];
        updatedIceServers =[[NSMutableArray alloc]init];
        _bandwidthArray = [[NSMutableArray alloc]init];
        _eventsdict = [[NSMutableDictionary alloc]init];
        _eventsArray = [[NSMutableArray alloc]init];
        sessionstats = [[NSMutableArray alloc]init];
        participantsDict = [[NSMutableDictionary alloc]init];
        callSummary = [[NSMutableDictionary alloc]init];
        _statsQueue = [[NSMutableArray alloc]init];
        _arrayIndex = 0;
        _eventArrayindex = 0;
        [updatedIceServers addObject:[[RTCIceServer alloc] initWithURLStrings:@[@"stun:stun.l.google.com:19302"]
                                                                     username:@""
                                                                   credential:@""]];
        
        stats = [[IrisRtcSdkStats alloc]initWithSession:self delegate:self];
        
        _statsCollector = [[WebRTCStatsCollector alloc]initWithDefaultValue:[self getMetaData] _appdelegate:(id<WebRTCStatsCollectorDelegate>)self];
        
        concatenatedData = [NSMutableData data];
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        presenceDateFormatter = [[NSDateFormatter alloc] init];
        [presenceDateFormatter setDateFormat:@"HH:mm:ss"];
        isCandidateSent = false;
        
        isOccupantJoined = false;
        offerJson = nil;
        streamCount = -1;
        
        isOfferSent = false;
        iceConnectionCheckTimer = nil;
        _sessionIceConnectionCheckTimer = nil;
        isAnswerReceived = false;
        isFocusJoined = false;
        _isVideoBridgeEnable = false;
        isParticipantStreamReceived = false;
        isParticipantJoined = false;
        _autoDisconnect = true;
        isDialTonePlaying = false;
        didStopDialTone = false;
        _traceId = nil;
        videoCodec = @"VP8";
        audioCodec = @"opus";
        dataChunkSize = DEFAULT_DATACHUNKSIZE * 1024;
        statstimerinterval = DEFAULT_STATS_TIMEINTERVAL;
        logEvent_Calltype = @"p2p";
        isStreamStatusUpdated = false;
        isPSTNcallWithTN = false;
        isLocalHold = false;
        isRemoteHold = false;
        useAnonymousRoom= false;
        
        
        [[[XMPPWorker sharedInstance] xmppStream]addDelegate:self delegateQueue:dispatch_get_main_queue()];

    }
    return self;
}

- (void) setSessionType:(IrisRtcSessionType)type{
    _sessionType = type;
    [callSummary setObject:[IrisRtcUtils sessionTypetoString:_sessionType] forKey:@"CallType"];
    isUpgrade = true;
}

-(void)createSessionWithRoomId:(NSString*)roomId notificationData:(NSString*)notificationData stream:(IrisRtcStream*)stream delegate:(id)delegate
{
    NSString* logEvent = [NSString stringWithFormat:@"SDK_CreateSession"];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    [dict setValue:logEvent_Calltype forKey:@"callType"];
    [dict setValue:[IrisRtcUtils sessionTypetoString:_sessionType] forKey:@"sessionType"];
    [self logEvents:logEvent additionalinfo:dict];
    
    localstream = stream;
    if(_traceId == nil || [_traceId length] == 0){
         _traceId = [[NSUUID UUID] UUIDString];
    }
    
    _roomId = roomId;
 //   self.roomId = roomId;
    self.sessionDelegate = delegate;
    self.notificationPayload = notificationData;
    callType = outgoing;
    startCallType = outgoing;
    _eventManager = [[IrisRtcEventManager alloc]initWithTraceId:_traceId _roomId:roomId delegate:self];
    [_eventManager setUseAnonymousRoom:useAnonymousRoom];
    //[self createRootEvent:roomId];
    if([localstream getStreamType] == kStreamTypeAudio){
        _sessionType = kSessionTypeAudio;
    }
    [self logEvents:@"SDK_StartMUCRequest" additionalinfo:nil];
    [_eventManager createRootEventWithPayload:notificationData _sessionType:_sessionType] ;
}


-(void)createAudioSessionWithRoomId:(NSString*)roomId participantId:(NSString*)participantId _sourceTelephoneNum:(NSString*)sourceTN _targetTelephoneNumber:(NSString*)targetTN notificationData:(NSString*)notificationData stream:(IrisRtcStream*)stream delegate:(id)delegate
{
    NSString* logEvent = [NSString stringWithFormat:@"SDK_CreateSession"];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    [dict setValue:logEvent_Calltype forKey:@"callType"];
    [dict setValue:[IrisRtcUtils sessionTypetoString:_sessionType] forKey:@"sessionType"];
    [self logEvents:logEvent additionalinfo:dict];
    
    localstream = stream;
    _roomId = roomId;
    self.sessionDelegate = delegate;
    self.targetRoutingId = participantId;
    self.notificationPayload = notificationData;
    callType = outgoing;
    startCallType = outgoing;
    self.sourcePhoneNum = sourceTN;
    self.targetPhoneNum = targetTN;
    if(_traceId == nil || [_traceId length] == 0){
        _traceId = [[NSUUID UUID] UUIDString];
    }

    //Changing the number format
    self.sourcePhoneNum = [@"+1" stringByAppendingString:_sourcePhoneNum];
    
     [self logEvents:@"SDK_StartMUCRequest" additionalinfo:nil];
    _eventManager = [[IrisRtcEventManager alloc]initWithTraceId:_traceId _roomId:roomId delegate:self];
   
	[_eventManager createRootEventWithPayload:notificationData _sessionType:_sessionType];
}


-(void)createAudioSessionWithTN:(NSString*)targetTN _sourceTelephoneNum:(NSString*)sourceTN notificationData:(NSString*)notificationData stream:(IrisRtcStream*)stream delegate:(id)delegate
{
    NSString* logEvent = [NSString stringWithFormat:@"SDK_CreateSession"];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    [dict setValue:logEvent_Calltype forKey:@"callType"];
    [dict setValue:[IrisRtcUtils sessionTypetoString:_sessionType] forKey:@"sessionType"];
    [self logEvents:logEvent additionalinfo:dict];
    didStopDialTone = false;
    irisPhoneNumberUtil = [[IrisPhoneNumberUtil alloc]initWithPhonenumber:targetTN];
    localstream = stream;
    self.sessionDelegate = delegate;
    self.notificationPayload = notificationData;
    callType = outgoing;
    startCallType = outgoing;
    isPSTNcallWithTN = true;
    
    self.sourcePhoneNum = [irisPhoneNumberUtil parsedNum:sourceTN];
    self.targetPhoneNum = [irisPhoneNumberUtil getRayoiqNumber];
    
    [[XMPPWorker sharedInstance]setSourceTelNum:_sourcePhoneNum];
    [[XMPPWorker sharedInstance]setTargetTelNum:[irisPhoneNumberUtil getMucRequestNumber]];
  
    if(_traceId == nil || [_traceId length] == 0){
        _traceId = [[NSUUID UUID] UUIDString];
    }
    
    [self startIceConnectionTimer];
    
    [self logEvents:@"SDK_StartMUCRequest" additionalinfo:nil];
    
    _eventManager = [[IrisRtcEventManager alloc]initWithTraceId:_traceId _roomId:nil delegate:self];
    [_eventManager setIsPSTNcallwithTN:true];
    [_eventManager createRootEventWithPayload:notificationData _sessionType:_sessionType];
}

-(void)joinSession:(IrisRootEventInfo*)rootEventInfo stream:(IrisRtcStream*)stream delegate:(id)delegate
{
    callType = incoming;
    startCallType = incoming;
    localstream = stream;
    self.sessionDelegate = delegate;
    
    if(_traceId == nil || [_traceId length] == 0){
        _traceId = [[NSUUID UUID] UUIDString];
    }
    _roomId = [rootEventInfo roomId];
    [self updatingIceServersData:[[XMPPWorker sharedInstance]turnServers]];
    
    dataElement = [[IrisDataElement alloc]initWithRootEventInfo:rootEventInfo _traceId:_traceId _callType:[IrisRtcUtils sessionTypetoString:_sessionType]];
    if(irisRoom == nil){
        irisRoom = [[IrisXMPPRoom alloc]initWithDataElement:dataElement _roomName:_roomId appDelegate:self];
    }
    
    if(_sessionType != kSessionTypePSTN && [localstream getStreamType] == kStreamTypeAudio){
        _sessionType = kSessionTypeAudio;
    }
    
    if(_sessionType == kSessionTypePSTN)
        [self startIceConnectionTimer];
    
     [[[XMPPWorker sharedInstance] activeSessions] setObject:self forKey:_roomId];
    
    [self start:iceservermsg];
    
    NSString* logEvent = [NSString stringWithFormat:@"SDK_JoinSession"];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    [dict setValue:logEvent_Calltype forKey:@"callType"];
    [dict setValue:[IrisRtcUtils sessionTypetoString:_sessionType] forKey:@"sessionType"];
    [self logEvents:logEvent additionalinfo:dict];
}

-(void)joinSession:(NSString*)roomId delegate:(id)delegate
{
    NSString* logEvent = [NSString stringWithFormat:@"SDK_JoinSession"];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    [dict setValue:logEvent_Calltype forKey:@"callType"];
    [dict setValue:[IrisRtcUtils sessionTypetoString:_sessionType] forKey:@"sessionType"];
    
    [self logEvents:logEvent additionalinfo:dict];
    callType = incoming;
    startCallType = incoming;
    localstream = nil;
    self.sessionDelegate = delegate;
    _roomId = roomId;
    
    if(_traceId == nil || [_traceId length] == 0){
        _traceId = [[NSUUID UUID] UUIDString];
    }
    
    [self updatingIceServersData:[[XMPPWorker sharedInstance]turnServers]];
    
    IRISLogInfo(@"IrisRtcJingleSession::Join = %d",_sessionType);
    //irisRoom = [[IrisRtcRoom alloc]initWithDataElement:dataElement _roomName:_roomId appDelegate:self];
     [self logEvents:@"SDK_GetCredentials" additionalinfo:nil];
     _eventManager = [[IrisRtcEventManager alloc]initWithTraceId:_traceId _roomId:roomId delegate:self];
    [_eventManager createRootEventWithPayload:nil _sessionType:_sessionType];
}


-(void)muteRemoteVideo:(NSString*)participantId
{
    IRISLogInfo(@"IrisRtcJingleSession::muteRemoteVideo = %@", participantId);
    //Need to send a private IQ for disabling remote side local stream.
    if(newICEConnState == RTCIceConnectionStateConnected && irisRoom != nil){
        [irisRoom sendPrivateMessage:@"mute" target:participantId ];
    }
}

-(void)insertDTMFtone:(IrisDTMFInputType)tone {
    
    if(state == active)
    {
        NSString *toneValue = toneValueString(tone);
        IRISLogInfo(@"IrisRtcJingle::insertDTMFtone = %@",toneValue);
        [peerConnection insertDTMFtone:toneValue Duration:DTMFTONE_DURATION tonegap:DTMFTONE_GAP];
    }
   
}


-(void)unmuteRemoteVideo:(NSString*)participantId
{
    if(newICEConnState == RTCIceConnectionStateConnected && irisRoom != nil){
        [irisRoom sendPrivateMessage:@"unmute" target:participantId];
    }
    //Need to send a private IQ for enabling remote side local stream.
}


-(void)upgradeToVideo:(IrisRtcStream*)stream notificationData:(NSString*)notificationData{
    
    IRISLogInfo(@"upgradeToVideo");
    [self logEvents:@"SDK_UpgradeToVideo" additionalinfo:nil];
    if(_sessionType != kSessionTypeChat)
    return;
    
    _sessionType = kSessionTypeVideoUpgrade;
    [dataElement setSessionType:[IrisRtcUtils sessionTypetoString:_sessionType]];
    isUpgrade = true;
    localstream = stream;
    //[self createMUCRootEvent:notificationData];

    [self logEvents:@"SDK_RootEventRequest" additionalinfo:nil];

    [_eventManager createRootEventWithPayload:notificationData _sessionType:_sessionType];
}

-(void)downgradeToChat{
    
    if(_sessionType != kSessionTypeVideoUpgrade)
    return;
    [self logEvents:@"SDK_DowngradeToChat" additionalinfo:nil];
    isUpgrade = false;
    
    _sessionType = kSessionTypeChat;
    [dataElement setSessionType:[IrisRtcUtils sessionTypetoString:_sessionType]];
    IRISLogInfo(@"downgradeToChat");
    [irisRoom allocateConferenceFocus:kDeallocate];
    [[[XMPPWorker sharedInstance] activeSessions] setObject:self forKey:_roomId];
    [irisRoom joinRoom];
    [jingleHandler deactivateJingle];
    
    if(isReceivedLeaveRoomMessage){
        [self disconnect];
    }else{
        [self closeSession];
    }
   
}

-(void)startIceConnectionTimer{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        _sessionIceConnectionCheckTimer = [NSTimer scheduledTimerWithTimeInterval:SESSION_CONNECTION_TIMEOUT
                                                                       target:self
                                                                     selector:@selector(timerICEConnCheck)
                                                                     userInfo:nil
                                                                      repeats:NO
                                       ];
        
    });
}

#pragma mark - Event Manager delegate

- (void) onCreateRootEventSuccess:(IrisRootEventInfo*)rootEventInfo
{
    IRISLogInfo(@"Irissession::rootNodeId = %@",[rootEventInfo rootNodeId]);
    IRISLogInfo(@"Irissession::childNodeId = %@",[rootEventInfo childNodeId]);
    if(isPSTNcallWithTN){
        _roomId = [rootEventInfo roomId];
        _targetRoutingId = [rootEventInfo targetRoutingId];
    }
    
    if(_sessionType == kSessionTypeChat && !useAnonymousRoom)
       [rootEventInfo setRoomId:_roomId];
    
    IRISLogInfo(@"onCreateRootEventSuccess");
    //[[XMPPWorker sharedInstance] setUnodeId:stackConfig.unodeid];
     [[[XMPPWorker sharedInstance] activeSessions] setObject:self forKey:_roomId];
  
    if(isUpgrade) {
        [self logEvents:@"SDK_RootEventResponse" additionalinfo:nil];
        [dataElement setRoomToken:[rootEventInfo roomToken]];
        [dataElement setRoomExpiryTime:[rootEventInfo roomExpiryTime]];
        [self doJoinRoom:_roomId];
        
    }
    else{
        [self logEvents:@"SDK_StartMUCResponse" additionalinfo:nil];
        _roomId = [rootEventInfo roomId];
        if(_sessionType == kSessionTypePSTN){
            dataElement = [[IrisDataElement alloc]initWithToRoutingId:_targetRoutingId _rootEventInfo:rootEventInfo _traceId:_traceId _callType:[IrisRtcUtils sessionTypetoString:_sessionType] toDomain:_toDomain];
        }
        else{
            dataElement = [[IrisDataElement alloc]initWithRootEventInfo:rootEventInfo _traceId:_traceId _callType:[IrisRtcUtils sessionTypetoString:_sessionType]];
        }
        
        irisRoom = [[IrisXMPPRoom alloc]initWithDataElement:dataElement _roomName:_roomId appDelegate:self];
        
        if(irisParticipant != nil){
            [irisRoom setParticipant:irisParticipant];
        }
        
        NSString* roomToken =[rootEventInfo roomToken];
        NSInteger roomTokenExpiry =[[rootEventInfo roomExpiryTime]integerValue];

        //[self setRoomId:_roomId];
       
      //  [self logEvents:@"SDK_XMPPCreateRootEventSuccess" additionalinfo:nil];
        if([self.sessionDelegate respondsToSelector:@selector(onSessionCreated:traceId:)])
            [self.sessionDelegate onSessionCreated:_roomId traceId:_traceId];
        [self updatingIceServersData:[[XMPPWorker sharedInstance]turnServers]];
        [self start:iceservermsg];
    }

}

- (void) onRoomTokenRenewd:(NSString*)roomToken _roomTokenExpiry:(NSString*)roomTokenExpiry{
    if(state != inactive || !hasErrorOccured){
        
        if(dataElement != nil){
            [dataElement setRoomToken:roomToken];
            [dataElement setRoomExpiryTime:roomTokenExpiry];
            
            irisRoom = [[IrisXMPPRoom alloc]initWithDataElement:dataElement _roomName:_roomId appDelegate:self];
            
            if(irisParticipant != nil){
                [irisRoom setParticipant:irisParticipant];
            }
            [self logEvents:@"SDK_RenewTokenResponse" additionalinfo:nil];
            [self updatingIceServersData:[[XMPPWorker sharedInstance]turnServers]];
            [self start:iceservermsg];
        }
    }
}
- (void) onRoomInvalid{
    
    //[_statsCollector stopMetric:@"callDuration"];
    /*if (_autoDisconnect){
        IRISLogInfo(@"occupantDidLeave:disconnect:participant count 33= %lu",(unsigned long)[participantsDict count]);
        if(_sessionType ==kSessionTypePSTN){
            [self didReceiveSIPStatus:@"" status:@"Disconnected"];
        }
        [self disconnect];
    }*/
    
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:@"Remote participant already left" forKey:NSLocalizedDescriptionKey];
    NSError *error = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_PARTICIPANT_ALREADY_LEFT userInfo:details];
    [self onSessionError:error withAdditionalInfo:nil];
}

- (void) onEventManagerFailure:(NSError*)error additionalData:(NSDictionary *)additionalData
{
    [self onSessionError:error withAdditionalInfo:nil];
}

-(void)startPSTNCall:dialNum
{
    
    //NSString* targetNumber = [@"+1" stringByAppendingString:self.sourcePhoneNum];
    [irisRoom dial:dialNum from:self.sourcePhoneNum target:targetJid toRoutingId:_targetRoutingId];
}

-(void)endPSTNCall
{
   // IRISLogInfo(@"ending pstn call");
    [irisRoom hangup:@"" from:_sourcePhoneNum target:pstnTargetJid toRoutingId:_targetRoutingId];
}

-(BOOL)merge:(IrisRtcAudioSession*)session
{
    if (![[dataElement rtcServer] isEqualToString:[session getRtcServer]]) {
        return false;
    }
    if([session getSipStatus] == kHold){
        [session unhold];
        [irisRoom merge:participantJid secondParticipantJid:[session getParticipantJid]];
        if([self.sessionDelegate respondsToSelector:@selector(onSessionMerged:traceId:)])
            [self.sessionDelegate onSessionMerged:_roomId traceId:_traceId];
        return true;
    }
    if(([session getSipStatus] == kConnected) )
    {
        [irisRoom merge:participantJid secondParticipantJid:[session getParticipantJid]];
        if([self.sessionDelegate respondsToSelector:@selector(onSessionMerged:traceId:)])
            [self.sessionDelegate onSessionMerged:_roomId traceId:_traceId];
        return true;
    }
    else{
        IRISLogError(@"Second Audio session is not established yet !!");
        return false;
    }
   
    
}

-(void)hold
{
    IRISLogInfo(@"hold::participantJid = %@",participantJid);
    isLocalHold = true;
    if([self hasInboundOutboundParitcipants]){
        IRISLogInfo(@"hold::participantJid by removing stream = %@",participantJid);
        if(peerConnection != nil){
            [peerConnection removeStream:[localstream getMediaStream]];
        }
        [irisRoom sendPrivateMessage:@"Hold" target:participantRoutingid];
        _sipStatus = kHold;
        if([self.sessionDelegate respondsToSelector:@selector(onSessionSIPStatus:roomId:traceId:)])
            [self.sessionDelegate onSessionSIPStatus:_sipStatus roomId:_roomId traceId:_traceId];
        [self logEvents:[self SipStatusStateTypeToString:_sipStatus] additionalinfo:nil];
    }else{
         [irisRoom hold:self.targetPhoneNum from:self.sourcePhoneNum targetJid:pstnTargetJid];
        
        _sipStatus = kHold;
         if([self.sessionDelegate respondsToSelector:@selector(onSessionSIPStatus:roomId:traceId:)])
            [self.sessionDelegate onSessionSIPStatus:_sipStatus roomId:_roomId traceId:_traceId];
        [self logEvents:[self SipStatusStateTypeToString:_sipStatus] additionalinfo:nil];
    }
   
}

-(BOOL)hasInboundOutboundParitcipants{
    
    BOOL hasInboundParticipant = false;
    BOOL hasOutboundParticipant = false;
    
    for (NSString* obj in [participantsDict allKeys]) {        
        if([obj containsString:@"inbound"]){
            hasInboundParticipant = true;
        }else if([obj containsString:@"outbound"]){
            hasOutboundParticipant = true;
        }
    }
 
    if(hasInboundParticipant && hasOutboundParticipant){
        return true;
    }
 
    return false;
}

-(BOOL)hasNoActiveParticipants{
    
    BOOL hasNoActiveParticipants = false;  
    
    if(participantsDict == nil || [participantsDict count]==0)
        return true;
    
    for (NSString* obj in [participantsDict allKeys]) {
        if([obj containsString:@"inbound"] || [obj containsString:@"outbound"]){
            hasNoActiveParticipants = true;
        }else{
            return false;
        }
    }
    
    return hasNoActiveParticipants;
}

-(void)unHold
{
    isLocalHold = false;
    if([self hasInboundOutboundParitcipants]){
            if(!isRemoteHold){
               if(peerConnection != nil){
                   [peerConnection addStream:[localstream getMediaStream]];
               }
            }
            [irisRoom sendPrivateMessage:@"Unhold" target:participantRoutingid];
            _sipStatus = kConnected;
        if([self.sessionDelegate respondsToSelector:@selector(onSessionSIPStatus:roomId:traceId:)])
            [self.sessionDelegate onSessionSIPStatus:_sipStatus roomId:_roomId traceId:_traceId];
        [self logEvents:[self SipStatusStateTypeToString:_sipStatus] additionalinfo:nil];
            
    }else{
            [irisRoom unHold:self.targetPhoneNum from:self.sourcePhoneNum targetJid:pstnTargetJid];
        
            _sipStatus = kConnected;
            if([self.sessionDelegate respondsToSelector:@selector(onSessionSIPStatus:roomId:traceId:)])
                [self.sessionDelegate onSessionSIPStatus:_sipStatus roomId:_roomId traceId:_traceId];
        [self logEvents:[self SipStatusStateTypeToString:_sipStatus] additionalinfo:nil];
    }
}


-(void)getStreamQuality:(NSError**)outError{
   
    IrisStreamQuality quality;
    if(_sipStatus != kConnected){
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Audio call is not connected yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:IrisRtcSessionTag code:nil userInfo:details];
        return;
    }
    
    if([self hasInboundOutboundParitcipants]){
        quality = kHD;
    }else{
        quality = kNonHD;
    }
    
    if([self.sessionDelegate respondsToSelector:@selector(onStreamQualityIndicator:roomId:traceId:)])
        [self.sessionDelegate onStreamQualityIndicator:quality roomId:_roomId traceId:_traceId];
}

-(void)serverUrl:(NSString*)_websocketURL routingId:(NSString*)_routingId serviceId:(NSString *)_serviceId
{
    routingId = _routingId;
    xmppServer = _websocketURL;
    serviceId = _serviceId;
}

-(void) setXMPPEnable:(BOOL)val
{
    isChannelAPIEnable = !val;
    isXMPPEnable = val;
}

-(void)setFromJid:(NSString*)jidFrom
{
    fromJid = jidFrom;
}

- (void)onAudioMute:(BOOL)mute{
    [self logEvents:@"SDK_AudioMuteToggle" additionalinfo:nil];
    [irisRoom setIsAudioMute:mute];   
}

- (void)onVideoMute:(BOOL)mute{
     [self logEvents:@"SDK_VideoMuteToggle" additionalinfo:nil];
     [irisRoom setIsVideoMute:mute];
 }

- (void)_timerCallback:(NSTimer *)timer{
    
    IRISLogInfo(@" _timerCallback");
    
    // Check if we are still in iceconnecting sTAG4e
    if (state == ice_connecting)
    {
        // if not incoming
        if (!callType) {
            [self startSession:updatedIceServers];
        }
    }
    
}

// Start the webrtc session
- (void)start
{
    // TBD: If ice server times out, go back to STUN
    state = ice_connecting;
    
    // Start a timer to monitor the timeout of ice server request
    // If the iceserver reply doesnt come from a server, use google's STUN server
    
    NSTimer *_icetimer;
    _icetimer = [NSTimer scheduledTimerWithTimeInterval:ICE_SERVER_TIMEOUT
                                                 target:self
                                               selector:@selector(_timerCallback:)
                                               userInfo:nil
                                                repeats:NO
                 ];
    [self requestIceServers];
    
    
}

-(void)requestIceServers
{
    // Form JSON
    NSDictionary *reqIceD = @{ @"type" : @"requestIceServers" };
    NSError *jsonError = nil;
    NSData *reqIce = [WebRTCJSONSerialization dataWithJSONObject:reqIceD options:0 error:&jsonError];
    
    // Sending ice server request
    IRISLogInfo(@" Sending iceServer request");
    [self sendMessage:reqIce];
}

-(void)dataFlagEnabled:(BOOL)_dataFlag{
    
    dataFlagEnabled = _dataFlag;
}

- (void) updatingIceServersData:(NSDictionary*)msg
{
    [self onIceServers:msg];
}

-(void)onUnsupportedMessage:(NSDictionary*)msg
{
    IRISLogWarn(@" Unsupported message");
}

-(void)onIceServers:(NSDictionary*)msg
{
    
  // IRISLogInfo(@" onIceServers %@ ", msg);
    //NSDictionary *iceServers1;
    // Check if the current state is ice_connecting, if not it means we timed out so lets skip this
        
        //iceServers1 = [msg objectForKey:@"iceServers"];
        //IRISLogInfo(@"onIceServer::%@",[msg objectForKey:@"iceServers"]);
        NSArray* iceArray = [msg objectForKey:@"ice_servers"];
        NSDictionary* iceServers;
        for (iceServers in iceArray) {
            // do something with object
            
            NSString *username;
            if ([iceServers objectForKey:@"username"])
            {
                username = [iceServers objectForKey:@"username"];
            }
            else
            {
                username = @"";
            }
            NSString *credential;
        
            if ([iceServers objectForKey:@"credential"])
            {
                credential = [iceServers objectForKey:@"credential"];
            }
            else
            {
                credential = @"";
                
            }
            if([username isEqualToString:@""] && [credential isEqualToString:@""])
            {
                
                NSString *urisString = [iceServers objectForKey:@"urls"];
                if ([NSURL URLWithString:urisString] == nil)
                {
                    IRISLogError(@" Incorrect turn URI");
                    
                    ;
                }
                
                [updatedIceServers addObject:[[RTCIceServer alloc] initWithURLStrings:@[urisString] username:username
                                                   credential:credential]];
            }
            else
            {
                NSArray *uris = [iceServers objectForKey:@"urls"];
            
            
        
            if ([NSURL URLWithString:[uris lastObject]] == nil)
            {
                IRISLogError(@" Incorrect turn URI");
                continue;
            }
        
            IRISLogInfo(@"Webrtc:Session::  ice URL %@ username %@ credentials %@", [NSURL URLWithString:[uris lastObject]],username, credential  );
        
            for (int i=0; i < [uris count]; i++)
            {
                NSString * urlString = [uris objectAtIndex:i];
                [updatedIceServers addObject:[[RTCIceServer alloc] initWithURLStrings:@[urlString]
                                                                             username:username
                                                                           credential:credential]];
            }
                
          }
        }
        // TBD: To create a critical section so that there is no race conditon
        // updatedIceServers = [[RTCICEServer alloc] initWithURI:[NSURL URLWithString:@"stun:stun.l.google.com:19302"]
        //                                             username:@""
        //                                             password:@""];
        
    
//        if (!isChannelAPIEnable && !isXMPPEnable)
//        {
//            [self startSession:updatedIceServers];
//        }
}

// Start the webrtc session
- (void)start:(NSDictionary *)iceServers
{
    // TBD: If ice server times out, go back to STUN
    _iceServers = iceServers;
    
//    //Timer to get stats from peerconnection
//    _statsTimer = [NSTimer scheduledTimerWithTimeInterval:STREAM_STATS_TIMEOUT
//                                                   target:self
//                                                 selector:@selector(getStreamStatsTimer)
//                                                 userInfo:nil
//                                                  repeats:YES
//                   ];
    
      [stats startMonitoringUsingInterval:statstimerinterval];
      [irisRoom startStatsQueueTimer];
    [self sendAccumulatedEvent];
    
      lastSr = [[WebRTCStatReport alloc]init];
    

        // For xmpp, rtcgsessionid is the room name
        [self doJoinRoom:_roomId];

    
}


- (void)onSignalingMessage:(id)msg
{
    if (isXMPPEnable)
    {
        [self onSessionSignalingMessage:msg];
    }
    else
    {
        [self onSessionSignalingMessage:msg];
    }
}

// Called when a signaling message is received
- (void)onSessionSignalingMessage:(NSDictionary *)msg
{
    IRISLogInfo(@" onSignalingMessage %@",msg);
    NSString *type;
    
    /*//Parse into JSON object
     NSError *error = nil;
     NSDictionary *messageJSON = [WebRTCJSONSerialization
     JSONObjectWithData:[msg dataUsingEncoding:NSNonLossyASCIIStringEncoding]
     options:0 error:&error];
     
     // Check for errors
     NSAssert(!error, @"%@", [NSString stringWithFormat:@"Webrtc:Session:: Error handling message: %@", error.description]);
     NSAssert([messageJSON count] > 0, @"Webrtc:Session:: Invalid JSON object");
     
     // Get message type
     NSArray * args = [messageJSON objectForKey:@"args"];
     NSDictionary * objects = args[0];*/
    type = [[msg objectForKey:@"type"] lowercaseString];
    
    IRISLogInfo(@" type:: %@",type );
    
    // Check the type of the message
    if (![type compare:@"offer"])
    {
        [self onOfferMessage:msg];
    }
    else if (![type compare:@"answer"])
    {
        [self onAnswerMessage:msg];
    }
    else if (![type compare:@"reoffer"])
    {
        [self onReOfferMessage:msg];
    }
    else if (![type compare:@"reanswer"])
    {
        [self onReAnswerMessage:msg];
    }
    else if (![type compare:@"candidate"])
    {
        [self onCandidateMessage:msg];
    }
    else if (![type compare:@"candidates"])
    {
        [self onCandidatesMessage:msg];
    }
    else if (![type compare:@"bye"])
    {
        [self onByeMessage:msg];
    }
    else if (![type compare:@"cancel"])
    {
        [self onCancelMessage:msg];
    }
    else if (![type compare:@"notification"])
    {
        [self onNotificationMessage:msg];
    }
    else if (![type compare:@"ping"])
    {
        [self onPingMessage:msg];
    }
    else if (![type compare:@"pong"])
    {
        //[self onPongMessage:msg];
    }
    else if (![type compare:@"iceservers"])
    {
        [self onIceServers:msg];
    }
    else if (![type compare:@"capability"])
    {
        //if (webrtcstack.isCapabilityExchangeEnable)
        [self onCapabilityMessage:msg];
    }
    else if (![type compare:@"icefinished"])
    {
        IRISLogInfo(@"Ice candidate finished");
    }
    else if (![type compare:@"configselection"])
    {
        if([[msg objectForKey:@"reason"] lowercaseString])
        {
            IRISLogInfo(@"%@", [[msg objectForKey:@"reason"] lowercaseString]);
            
            // XCMAV: this can help handle Remote Video Pause state.
            NSString* configMsg = [[msg objectForKey:@"reason"] lowercaseString];
            IRISLogInfo(@"[XCMAV]: sending config message to Application: %@", configMsg);
           
           // [self.sessionDelegate onConfigMessage_xcmav:configMsg];
        }
    }
    else if (![type compare:@"appmsg"])
    {
     
      //  [self.sessionDelegate onSessionTextMessage:[[msg objectForKey:@"reason"] lowercaseString]];
    }
    else if (![type compare:@"remotereconnect"])
    {
        [self onRemoteReconnectedMessage:msg];
    }
    else if (![type compare:@"requesticeservers"]) //xmpp
    {
        IRISLogInfo(@"requesticeservers");
    }
    else
    {
        IRISLogInfo(@"Got Unknown server msg = %@",msg);
        //NSError *error = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_UNKNOWN_SERVER_MSG userInfo:nil];
        //[self.sessionDelegate onSessionSessionError:error.description errorCode:error.code additionalData:nil];
    }
}

-(void)onByeMessage:(NSDictionary*)msg
{
    
    // Check if the message has a failure
    BOOL isFailure = [[msg valueForKey:@"failure"]boolValue];
    
    IRISLogInfo(@" Got bye message for state:: %d Failure %d " , state ,isFailure);
    
    if(isFailure)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"RTCG Error" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_RTCG_ERROR userInfo:details];
        [callSummary setObject:@"Failure" forKey:@"callStatus"];
        [callSummary setObject:error.localizedDescription forKey:@"CallFailureReason"];
        [self onSessionError:error withAdditionalInfo:nil];
    }
    else
    {
       if([self.sessionDelegate respondsToSelector:@selector(onSessionEnded:traceId:)])
           [self.sessionDelegate onSessionEnded:_roomId traceId:_traceId];
        [_statsCollector stopMetric:@"callDuration"];
    }
     [self logEvents:@"SDK_ReceivedByeMessage" additionalinfo:nil];
    
//    if(_statsTimer != nil)
//        [_statsTimer invalidate];
//    _statsTimer = nil;
    
    //state = inactive;
    [self close];
    
  
    // [webrtcstack disconnect];
}


-(void)answer
{
    state = active;
    IRISLogInfo(@" answer");
    factory = [WebRTCFactory getPeerConnectionFactory];
    
    //Enabling IPv6 patch by default
    //[webrtcstack enableIPV6:true];
    
    [self remoteStream];
    NSString *tempSdp = [initialSDP objectForKey:@"sdp"];
   
    if(_sessionType == kSessionTypeBroadcast)
    {
        if(callType == incoming)
            tempSdp = [tempSdp stringByReplacingOccurrencesOfString:@"sendrecv" withString:@"sendonly"];
        else
            tempSdp = [tempSdp stringByReplacingOccurrencesOfString:@"sendrecv" withString:@"recvonly"];
    }
    NSString *backslashString = [tempSdp stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
    NSString *backslashrString = [backslashString stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
    NSString *forwardslashrString = [backslashrString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
    NSString *sdpString = [forwardslashrString stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    
    IRISLogInfo(@"setting offer SDP = %@",sdpString);
    
    NSString *modifiedSdp =[ARDSDPUtils descriptionForDescriptionString:sdpString preferredVideoCodec:videoCodec];
    
    NSString *sdpStirng = [ARDSDPUtils descriptionForDescriptionString:modifiedSdp preferredAudioCodec:audioCodec];

   
    // Create session description
    RTCSessionDescription *sdp = [[RTCSessionDescription alloc]
                                  //initWithType:RTCSdpTypeOffer sdp:[self preferISAC:sdpString]];
                                  initWithType:RTCSdpTypeOffer sdp:[self preferISAC:sdpStirng]];
    
    IRISLogInfo(@"Actually setting offer SDP = %@",sdp.description);
    __weak IrisRtcJingleSession *weakSelf = self;
    [peerConnection setRemoteDescription:sdp
                       completionHandler:^(NSError *error) {
                           IrisRtcJingleSession *strongSelf = weakSelf;
                           [strongSelf peerConnection:strongSelf->peerConnection
                    didSetSessionDescriptionWithError:error];
                       }];
    [self createAnswer];
    
}

-(void)createAnswer
{
    IRISLogInfo(@" createAnswer");
    if (!peerConnection) {
        [self remoteStream];
    }
    
    NSDictionary *mandatoryConstraints = @{
                                           @"OfferToReceiveAudio" : @"true",
                                           @"OfferToReceiveVideo" : @"true"
                                           };
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:mandatoryConstraints
     optionalConstraints:nil];
    
    __weak IrisRtcJingleSession *weakSelf = self;
    [peerConnection answerForConstraints:constraints
                       completionHandler:^(RTCSessionDescription *sdp,
                                           NSError *error) {
                           IrisRtcJingleSession *strongSelf = weakSelf;
                           [strongSelf peerConnection:strongSelf->peerConnection
                          didCreateSessionDescription:sdp
                                                error:error];
                       }];
    
    /*_statsTimer = [NSTimer scheduledTimerWithTimeInterval:STREAM_STATS_TIMEOUT
                                                   target:self
                                                 selector:@selector(getStreamStatsTimer)
                                                 userInfo:nil
                                                  repeats:YES
                   ];*/
    
//    lastSr = [[WebRTCStatReport alloc]init];
    if(_sessionType != kSessionTypePSTN)
   [_statsCollector startMetric:@"callDuration"];
    
    //isReOffer = true;
    
    // if(isXMPPEnable)
    //   [self.sessionDelegate onSessionConnecting];
    
}


-(void)onOfferMessage:(NSDictionary*)msg
{
    IRISLogInfo(@" Got an offer message");
    
    // Storing the data to retrieve further after recieving iceserver
   // [self logEvents:@"SDK_OfferReceived" additionalinfo:nil];
    peerConnectionId = [msg objectForKey:@"peerConnectionId"];
    initialSDP = msg;
   if(_sessionType != kSessionTypePSTN)
   [_statsCollector startMetric:_roomId _statName:@"mediaConnectionTime"];
    
    
    [self answer];
    
}

- (NSString *)preferH264:(NSString *)origSDP
{
    int mLineIndex = -1;
    NSString* isac16kRtpMap = nil;
    NSArray* lines = [origSDP componentsSeparatedByString:@"\r\n"];
    NSRegularExpression* isac16kRegex = [NSRegularExpression
                                         regularExpressionWithPattern:@"^a=rtpmap:(\\d+) H264/90000[\r]?$"
                                         options:0
                                         error:nil];
    for (int i = 0; (i < [lines count]) && (mLineIndex == -1 || isac16kRtpMap == nil); ++i) {
        
        NSString* line = [lines objectAtIndex:i];
        
        if ([line hasPrefix:@"m=video "]) {
            mLineIndex = i;
            continue;
        }
        
        NSTextCheckingResult* result = [isac16kRegex firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
        if (!result)
            isac16kRtpMap = nil;
        else
            isac16kRtpMap =  [line substringWithRange:[result rangeAtIndex:1]];
    }
    
    if (mLineIndex == -1) {
        IRISLogError(@" No m=audio line, so can't prefer H264");
        return origSDP;
    }
    if (isac16kRtpMap == nil) {
       IRISLogError(@" No ISAC/16000 line, so can't prefer iSAC");
        return origSDP;
    }
    NSArray* origMLineParts =
    [[lines objectAtIndex:mLineIndex] componentsSeparatedByString:@" "];
    NSMutableArray* newMLine =
    [NSMutableArray arrayWithCapacity:[origMLineParts count]];
    int origPartIndex = 0;
    // Format is: m=<media> <port> <proto> <fmt> ...
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:isac16kRtpMap];
    for (; origPartIndex < [origMLineParts count]; ++origPartIndex) {
        if ([isac16kRtpMap compare:[origMLineParts objectAtIndex:origPartIndex]]
            != NSOrderedSame) {
            [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex]];
        }
    }
    NSMutableArray* newLines = [NSMutableArray arrayWithCapacity:[lines count]];
    [newLines addObjectsFromArray:lines];
    [newLines replaceObjectAtIndex:mLineIndex
                        withObject:[newMLine componentsJoinedByString:@" "]];
    return [newLines componentsJoinedByString:@"\n"];
}

- (NSString *)preferISAC:(NSString *)origSDP {
 
    
    int mLineIndex = -1;
    NSString* isac16kRtpMap = nil;
    NSArray* lines = [origSDP componentsSeparatedByString:@"\\n"];
    NSRegularExpression* isac16kRegex = [NSRegularExpression
                                         regularExpressionWithPattern:@"^a=rtpmap:(\\d+) ISAC/16000[\r]?$"
                                         options:0
                                         error:nil];
    
 
    
    
    
    
    for (int i = 0; (i < [lines count]) && (mLineIndex == -1 || isac16kRtpMap == nil); ++i) {
        
        NSString* line = [lines objectAtIndex:i];
        
       
        if ([line hasPrefix:@"m=audio"]) {
          
            mLineIndex = i;
            continue;
        }
        
        
        NSTextCheckingResult* result = [isac16kRegex firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
        if (!result)
            isac16kRtpMap = nil;
        else
            isac16kRtpMap =  [line substringWithRange:[result rangeAtIndex:1]];
    }
    
    if (mLineIndex == -1) {
        IRISLogError(@" No m=audio line, so can't prefer iSAC");
        return origSDP;
    }
    if (isac16kRtpMap == nil) {
        IRISLogError(@" No ISAC/16000 line, so can't prefer iSAC");
        return origSDP;
    }
    NSArray* origMLineParts =
    [[lines objectAtIndex:mLineIndex] componentsSeparatedByString:@" "];
    NSMutableArray* newMLine =
    [NSMutableArray arrayWithCapacity:[origMLineParts count]];
    int origPartIndex = 0;
    // Format is: m=<media> <port> <proto> <fmt> ...
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:isac16kRtpMap];
    for (; origPartIndex < [origMLineParts count]; ++origPartIndex) {
        if ([isac16kRtpMap compare:[origMLineParts objectAtIndex:origPartIndex]]
            != NSOrderedSame) {
            [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex]];
        }
    }
    NSMutableArray* newLines = [NSMutableArray arrayWithCapacity:[lines count]];
    [newLines addObjectsFromArray:lines];
    [newLines replaceObjectAtIndex:mLineIndex
                        withObject:[newMLine componentsJoinedByString:@" "]];
    return [newLines componentsJoinedByString:@"\n"];
}

-(void)onCandidateMessage:(NSDictionary*)msg
{
    IRISLogInfo(@" Got a candidate message and the state is %d", state);
    NSString *mid = [msg objectForKey:@"id"];
    NSString *sdpLineIndex = [msg objectForKey:@"label"];
    NSString *sdp = [msg objectForKey:@"candidate"];
    
    //Harish::For IPv6 testing
    
    //    if(sessionConfig.forceRelay)
    //    {
    //        if(![sdp containsString:@"relay"])
    //        {
    //            //IRISLogInfo(@"ignoring %@",sdp);
    //            return;
    //        }
    //    }
    /*if([sdp containsString:@"host"])
    {
        //IRISLogVerbose(@"ignoring host candidates %@",sdp);
        return;
    }*/
    
    // Ignore missing sdp
    if(sdp == NULL)
        return;
    
    // Create ICE candidate
    RTCIceCandidate *candidate = [[RTCIceCandidate alloc] initWithSdp:sdp
                                                        sdpMLineIndex:sdpLineIndex.intValue
                                                               sdpMid:mid];
    
    // Add to queued or peer connection candidates
    if (peerConnection != nil && state == active)
    {
        IRISLogInfo(@" Adding candidates to peerconnection %@", candidate.description);
        [peerConnection addIceCandidate:candidate];
    }
    else
        [queuedRemoteCandidates addObject:candidate];
    
}

-(void)onAnswerMessage:(NSDictionary*)msg
{
    IRISLogInfo(@" Got an answer message");
    isAnswerReceived = true;
    [self logEvents:@"SDK_AnswerReceived" additionalinfo:nil];
    state = active;
   
    [_statsCollector startMetric:_roomId _statName:@"mediaConnectionTime"];
    if(_sessionType != kSessionTypePSTN)
    [_statsCollector startMetric:@"callDuration"];
    //Parse SDP string
    NSString *tempSdp = [msg objectForKey:@"sdp"];
    IRISLogInfo(@"sdp Before %@",tempSdp);
    
    
    //NSString *backslashString = [tempSdp stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
    NSString *sdpString = [tempSdp stringByReplacingOccurrencesOfString:@"\\\\r" withString:@"\r"];
    NSString *sdpString2 = [sdpString stringByReplacingOccurrencesOfString:@"\\\\n" withString:@"\n"];
    NSString *sdpString3 = [sdpString2 stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
    NSString *sdpString4 = [sdpString3 stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
    NSString *sdpString5 = [sdpString4 stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    IRISLogInfo(@"SDP After %@",sdpString3);
    // Reverting back the changes as call is getting crash with 3.53 sdk
    /*NSString *backslashrString = [backslashString stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
     NSString *forwardslashrString = [backslashrString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
     
     NSString *sdpString = [forwardslashrString stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];*/
    
    RTCSessionDescription *sdp = [[RTCSessionDescription alloc]
                                  initWithType:RTCSdpTypeAnswer sdp:[self preferISAC:sdpString5]];
    
   // dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __weak IrisRtcJingleSession *weakSelf = self;
        [peerConnection setRemoteDescription:sdp
                           completionHandler:^(NSError *error) {
                               IrisRtcJingleSession *strongSelf = weakSelf;
                               [strongSelf peerConnection:strongSelf->peerConnection
                        didSetSessionDescriptionWithError:error];
                           }];
   // });
    

    //  if(sessionConfig.delaySendingCandidate)
    //  {
    if(!_isVideoBridgeEnable)
    {
        for (id data in iceCandidates){
            [self sendMessage:data];
        }
        [iceCandidates removeAllObjects];
    }
    
    //  }
    
    // //IRISLogInfo(@"Webrtc:Session:: Got an answer message with sdp %@", sdpString3);
    
}

-(void)sendPingMessage
{
    //Form JSON
    NSDictionary *pingD = @{ @"type" : @"ping" };
    NSError *jsonError = nil;
    NSData *ping = [WebRTCJSONSerialization dataWithJSONObject:pingD options:0 error:&jsonError];
    _isReceivedPingResponse = false;
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        //sessconfig
        //Starting timer to check if received pong message
//        _checkPingResponseTime = [NSTimer scheduledTimerWithTimeInterval:sessionConfig.pingResponseTimeout                                                                  target:self
//                                                                selector:@selector(onPingResponseFailure)
//                                                                userInfo:nil
//                                                                 repeats:NO];
    });
    
    
    [self sendMessage:ping];
    
}

-(void)setUserProfile:(IrisRtcUserProfile*)userProfile
{
    
    if(userProfile.name != nil ||  userProfile.avatarUrl != nil){
        irisParticipant = [[IrisRtcParticipant alloc]init];
        [irisParticipant setName:userProfile.name];
        [irisParticipant setAvatarUrl:userProfile.avatarUrl];
      //  irisParticipant = [[IrisRtcParticipant alloc]initWithName:userProfile.name avatarUrl:userProfile.avatarUrl];
        if(irisRoom != nil){
            [irisRoom setParticipant:irisParticipant];
        }
    }
    
    
   // [[XMPPWorker sharedInstance]sendUserProfilePresence:userProfile.name avatarUrl:userProfile.avatarUrl];
}

-(void)setMaxNumberOfRemoteStream:(int)value{

    NSError *jsonError = nil;
    NSMutableDictionary* json = [[NSMutableDictionary alloc]init];
    NSNumber *participantval = [NSNumber numberWithInt:value];
    [json setValue:@"LastNChangedEvent" forKey:@"colibriClass"];
    [json setValue:participantval forKey:@"lastN"];
    
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:0 error:&jsonError];
    [self sendDataChannelMessage:data];
    
}

-(BOOL)activateRemoteStream:(NSString * _Nonnull)participantId{
    
    IRISLogInfo(@"activateRemoteStream for = %@",participantId);
    if(newICEConnState != RTCIceConnectionStateConnected){
        return false;
    }
    
    if(participantId == nil || [participantId length] == 0){
        return false;
    }
    
    if(![[participantsDict allKeys]containsObject:participantId]){
        return false;
    }
    
    NSError *jsonError = nil;
    
    NSMutableDictionary* json = [[NSMutableDictionary alloc]init];
    [json setValue:@"PinnedEndpointChangedEvent" forKey:@"colibriClass"];
    [json setValue:participantId forKey:@"pinnedEndpoint"];
    IRISLogInfo(@"pinParticipant::json = %@",json);
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:0 error:&jsonError];
    [self sendDataChannelMessage:data];
    
    return true;
}


-(void)onReOfferMessage:(NSDictionary*)msg
{
    IRISLogInfo(@" Got an reoffer message");
}

-(void)onReAnswerMessage:(NSDictionary*)msg
{
    IRISLogInfo(@" Got an reanswer message");
}

-(void)onCandidatesMessage:(NSDictionary*)msg
{
    IRISLogInfo(@" Got a candidates message");
}

-(void)onCancelMessage:(NSDictionary*)msg
{
    IRISLogInfo(@" Got cancel message");
  if([self.sessionDelegate respondsToSelector:@selector(onSessionEnded:traceId:)])
      [self.sessionDelegate onSessionEnded:_roomId traceId:_traceId];
    
}

-(void)onNotificationMessage:(NSDictionary*)msg
{
    IRISLogInfo(@" Got notification message");
}

-(void)onPingMessage:(NSDictionary*)msg
{
    IRISLogInfo(@" Got ping message");
    //Form JSON
    NSDictionary *pongD = @{ @"type" : @"pong" };
    NSError *jsonError = nil;
    NSData *pong = [WebRTCJSONSerialization dataWithJSONObject:pongD options:0 error:&jsonError];
    
    [self sendMessage:pong];
}


-(void)onPongMessage:(NSDictionary*)msg
{
    IRISLogInfo(@" Got ping Response");
    _isReceivedPingResponse = true;
    [_checkPingResponseTime invalidate];
    _checkPingResponseTime = nil;
    if(_isSendingPingPongMsg)
    {
        /*NSTimer *sendPingMsgTimer = [NSTimer scheduledTimerWithTimeInterval:sessionConfig.pingInterval
         target:self
         selector:@selector(sendPingMessage)
         userInfo:nil
         repeats:NO
         ];*/
       //sessconfig
     //   [self performSelector:@selector(sendPingMessage) withObject:self afterDelay:sessionConfig.pingInterval];
        
    }
    //[self sendPingMessage];
    
}

- (void)remoteStream
{
    
    if (peerConnection != nil)
    {
        IRISLogError(@"remoteStream peerconnection already created " );
        return;
        
    }
    
    //Peer connection constraints
    //Peer connection constraints
    NSDictionary *constraintPairs = @{
                                      @"OfferToReceiveAudio": @"true",
                                      @"OfferToReceiveVideo": @"true"
                                      };
    
    NSMutableDictionary *optionalConstraints = [[NSMutableDictionary alloc]init];
    [optionalConstraints setValue:dtlsFlagValue forKey:@"DtlsSrtpKeyAgreement"];
    /*[optionalConstraints setValue:@"true" forKey:@"googCpuOveruseDetection"];
    [optionalConstraints setValue:@"true" forKey:@"googCpuOveruseEncodeUsage"];
    [optionalConstraints setValue:@"25" forKey:@"googCpuUnderuseThreshold"];
    [optionalConstraints setValue:@"150" forKey:@"googCpuOveruseThreshold"];*/
    
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:constraintPairs
                                                                             optionalConstraints:optionalConstraints];

    
    queuedRemoteCandidates = [NSMutableArray array];
    
    //Create peer connection
    
 // Add this block for bridge only call
    if ([[targetJid full] containsString:@"f0cus"] || _isVideoBridgeEnable)
    {
	NSMutableArray *objectsToRemove = [NSMutableArray array];
    
    for (int i=0; i < [updatedIceServers count]; i++)
    {
        RTCIceServer * iceserver = [updatedIceServers objectAtIndex:i];
        if ([[iceserver urlStrings][0] containsString:@"turn:"])
        {
            [objectsToRemove addObject:iceserver];
        }
    }
    
    	[updatedIceServers removeObjectsInArray:objectsToRemove];
    }
    
    IRISLogInfo(@"remoteStream peerConnectionWithICEServers : iceservers %@ and constraints %@",[updatedIceServers description], [constraints description] );
    
  //  IRISLogInfo(@"Harish::Adding peerconnection constraint 22");
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    config.iceServers = updatedIceServers;
    peerConnection = [factory peerConnectionWithConfiguration:config
                                                  constraints:constraints delegate:self];
    
    if(startCallType == incoming){
        [callSummary setObject:@"inbound" forKey:@"CallDirection"];
    }else{
        [callSummary setObject:@"outbound" forKey:@"CallDirection"];
    }
    
    [callSummary setObject:[IrisRtcUtils sessionTypetoString:_sessionType] forKey:@"CallType"];
    
    [self.statsDelegate onPeerConnection:peerConnection statscollector:_statsCollector roomname:_roomId irisRoom:irisRoom];
  
    //}

    if(!(_sessionType == kSessionTypeData) && localstream != nil)
        [peerConnection addStream:localstream.getMediaStream];
    
    if(_sessionType == kSessionTypePSTN || _sessionType == kSessionTypeAudio)
        [peerConnection createDTMFtone:[[localstream getMediaStream]audioTracks][0]];
   // [self createSenders];
}

-(void)createSenders
{
    RTCAudioTrack* audioTrack_= [localstream getAudioTrack];
    RTCVideoTrack* videoTrack_= [localstream getVideoTrack];
    
    // Create RTC sender for audio if exists
    RTCRtpSender *asender =
    [peerConnection senderWithKind:kRTCMediaStreamTrackKindAudio
                          streamId:@"ARDAMS"];
    [peerConnection addStream:localstream.getMediaStream];
    
    
    if (audioTrack_)
    {
        asender.track = audioTrack_;
    }
    
    // Create RTC sender for video if exists
    RTCRtpSender *vsender =
    [peerConnection senderWithKind:kRTCMediaStreamTrackKindVideo
                          streamId:@"ARDAMS"];
    if (videoTrack_)
    {
        vsender.track = videoTrack_;
    }
    
    
   if(_sessionType == kSessionTypePSTN  || _sessionType == kSessionTypeAudio)
    [peerConnection createDTMFtone:[[localstream getMediaStream]audioTracks][0]];
}

-(void)onPingResponseFailure
{
    if(!_isReceivedPingResponse)
    {
        IRISLogError(@"Failed to get ping response");
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Unable to ping the remote client" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_REMOTE_UNREACHABLE userInfo:details];
       
        [self onSessionError:error withAdditionalInfo:nil];
        
    }
}


-(void)onRemoteReconnectedMessage:(NSDictionary*)msg
{
    [self networkReconnected];
}

-(void)networkReconnected
{

    
    if(callType != incoming)
    {
        [self createReOffer];
    }
    else
    {
        NSDictionary *reconnectD = @{ @"type" : @"remotereconnect" };
        NSError *jsonError = nil;
        NSData *reconnect = [WebRTCJSONSerialization dataWithJSONObject:reconnectD options:0 error:&jsonError];
        
        [self sendMessage:reconnect];
    }
}

-(void)sendAccumulatedEvent{
    if ((_statsQueue!=nil)&&([_statsQueue count]>0)){
        for (NSMutableDictionary *payload in _statsQueue) {
            [irisRoom sendStats:payload];
        }
        [_statsQueue removeAllObjects];
    }
}

#pragma mark - Internal Methods

- (void)onSessionError:(NSError*)error withAdditionalInfo:(NSDictionary *)info{
    
    IRISLogInfo(@"IrisRtcJingleSession::onSessionError obj = %@",self);
    if(hasErrorOccured)
        return;
    
    hasErrorOccured = true;
    [self logEvents:@"SDK_Error" additionalinfo:nil];
    [callSummary setObject:@"Failure" forKey:@"callStatus"];
    [callSummary setObject:error.localizedDescription forKey:@"CallFailureReason"];
    
    if([self.sessionDelegate respondsToSelector:@selector(onSessionError:withAdditionalInfo:roomId:traceId:)])
        [self.sessionDelegate onSessionError:error withAdditionalInfo:nil roomId:_roomId traceId:_traceId];
}

-(void)startSession:(NSArray*)iceServers
{
    state = call_connecting;
    isCandidateSent = false;
    IRISLogInfo(@" Starting webrtc session");
    //dispatch_async(dispatch_get_main_queue(), ^(void){
        
        peerConnectionId = [[NSUUID UUID] UUIDString];
        
        factory = [WebRTCFactory getPeerConnectionFactory];
        
        //Enabling IPv6 patch by default
   
        //[webrtcstack enableIPV6:true];
        
        // Get the access to local stream and attach to peerconnection
        [self remoteStream];
        
       
        if(_sessionType == kSessionTypeData)
        {
            if(callType != incoming){
                if ([self createDataChannel] == true)
                {
                    [self createOffer];
                }
                else
                {
                    return;
                }
            }else{
                [self createDataChannel];
            }
            
        }

        else if(callType != incoming)
            [self createOffer];
    
   // });
    
    
}

-(BOOL)createDataChannel
{
    /* Check if the data channel was created */
    
    RTCDataChannelConfiguration *dataChannelConfig = [[RTCDataChannelConfiguration alloc] init];
    dataChannelConfig.channelId = DATACHANNEL_STREAM_ID;
    
//    RTCDataChannelConfiguration *config = [RTCDataChannelConfiguration new];
//    config.isOrdered=true;
//    config.isNegotiated=true;
 //   config.s
    
    _dataChannel =  [peerConnection dataChannelForLabel:@"datachannel"
                                          configuration:dataChannelConfig];

//    _dataChannel =  [peerConnection dataChannelForLabel:datachannelname
//                                          configuration:dataChannelConfig];

    
    _dataChannel.delegate = self;
    cancelSendData = false;
    IRISLogInfo(@"DataChannel::Inside createDataChannel");
    return true;
}


-(void)createOffer
{
   // LogDebug(@" createOffer");
    if (!peerConnection) {
        [self remoteStream];
    }
    
    isReOffer = false;
    //Peer connection constraints
    //Peer connection constraints
    NSDictionary *constraintPairs = @{
                                      @"googUseRtpMUX": @"true",
                                      @"OfferToReceiveAudio" : @"true",
                                      @"OfferToReceiveVideo" : @"true"
                                      };
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:constraintPairs optionalConstraints:nil];
    __weak IrisRtcJingleSession *weakSelf = self;
    [peerConnection offerForConstraints:constraints
                      completionHandler:^(RTCSessionDescription *sdp,
                                          NSError *error) {
                          IrisRtcJingleSession *strongSelf = weakSelf;
                          [strongSelf peerConnection:strongSelf->peerConnection
                         didCreateSessionDescription:sdp
                                               error:error];
                      }];

    
    
}


- (void)sendRTCMessage:(id)msg
{
    IRISLogInfo(@"Webrtc:Session:: sendRTCMessage");
    //  IRISLogInfo(@"type == %@", [msg valueForKey:@"type"]);
    NSData* jsonData = [WebRTCJSONSerialization dataWithJSONObject:msg
                                                           options:0 error:nil];
    //NSString *JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    
    //[statsCollector storeCallLogMessage:JSONString _msgType:@"clientRTC"];
    [_statsCollector storeCallLogMessage:msg _msgType:@"clientRTC"];
 
}


-(void)createReOffer
{
    IRISLogInfo(@" createReOffer");
    
    /*
    isReOffer = true;
    //Peer connection constraints
    NSArray * constraintPairs = @[[[RTCPair alloc] initWithKey:@"googUseRtpMUX" value:@"true"],
                                  [[RTCPair alloc] initWithKey:@"IceRestart" value:@"true"],
                                  ];
    
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:constraintPairs
                                                                             optionalConstraints:nil];
    [peerConnection createOfferWithDelegate:self constraints:constraints];*/
    
}


-(void)sendChatMessage:(IrisChatMessage*)message
{
    [irisRoom sendChatMessage:message];
}

-(void)sendChatState:(IrisChatState)state
{
    [irisRoom sendIrisChatState:state];
}
// Method to join XMPP room
- (void)doJoinRoom:(NSString *)name
{
    if(state != inactive){
        
        IRISLogInfo(@"Inside doJoinRoom");
        [localstream setStreamDelegate:self];
        
        if(_sessionType != kSessionTypeChat){
            jingleHandler = [[IrisJingleHandler alloc]initWithDataElement:dataElement roomId:_roomId];
            [jingleHandler activateJingle:self];
        }
        
        [irisRoom setStreamCount:streamCount];
        
        if (_isVideoBridgeEnable && _sessionType != kSessionTypeChat){
            
            if(isUpgrade){
                [irisRoom allocateConferenceFocus:kAllocate];
            }
            else{
                [irisRoom allocateConferenceFocus:kNormal];
            }
            
        }
        //[NSThread sleepForTimeInterval:0.200f];
        [irisRoom joinRoom];
    }
   
    
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection
      sendSuspendVideo:(BOOL)suspend_{
    //sessionconfig
//    if(sessionConfig.isBWCheckEnable){
//        IRISLogInfo(@"Video is suspended :: %d",suspend_);
//        
//        if(suspend_ && !isVideoSuspended)
//        {
//            NSDictionary *json = @{@"type" : @"appmsg" , @"reason" : @"Bandwidth going down, Remote Video suspended"};
//            [self onUserConfigSelection:json];
//            isVideoSuspended = true;
//           
//            [self.sessionDelegate onSessionTextMessage:[[json objectForKey:@"reason"] lowercaseString]];
//        }
//        else if(!suspend_ && isVideoSuspended)
//        {
//            NSDictionary *json = @{@"type" : @"appmsg" , @"reason" : @"Remote Video resumed "};
//            [self onUserConfigSelection:json];
//            isVideoSuspended = false;
//            
//            [self.sessionDelegate onSessionTextMessage:[[json objectForKey:@"reason"] lowercaseString]];
//        }
//        
//    }
    
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection
          sendLogToApp:(NSString*)str severity:(int)sev{
 
   // [self.sessionDelegate onSdkLogs:str severity:sev];
}



- (void) onUserConfigSelection:(NSDictionary*)json{
   
         //  [self sendRTCMessage:json];
        [_statsCollector storeCallLogMessage:json _msgType:@"clientRTC"];
       // [sh sendClientRTCMessage:json];
        [[XMPPWorker sharedInstance] sendMediaPresence:json target:targetJid];

}

//sessionconfig
//-(void)applySessionConfigChanges:(WebRTCSessionConfig*)configParam
//{
//    IRISLogInfo(@"Inside applySessionConfigChanges");
//    
//    for (RTCMediaStream *stream in peerConnection.localStreams)
//    {
//        lms = stream;
//        [peerConnection removeStream:stream];
//        
//    }
//
//   // [localstream applyStreamConfigChange:configParam.streamConfig];
// 
// //   [peerConnection addStream:lms constraints:nil];
// //   [peerConnection addStream:lms];
//    [peerConnection addStream:[localstream getMediaStream]];
//    
//}

- (void) sendCapability
{
    IRISLogInfo(@"Inside sendCapability");
    
    @try{
        NSDictionary *meta =
        @{@"devicetype" : [[self getMetaData] objectForKey:@"model"],
          @"manufacturer" : [[self getMetaData] objectForKey:@"manufacturer"],
          @"version" : [[self getMetaData] objectForKey:@"sdkVersion"]};
        
        NSDictionary *json=
        @{ @"type" : @"capability",
           @"meta" : meta,
           @"data" : [self getCapabilityData]};
        
        
    }
    @catch(NSException *e)
    {
   //     LogError(@" Exception in sendCapability %@",e);
    }
}

- (NSDictionary *) getCapabilityData
{
    int device = [self getMachineID];
    
    IRISLogInfo(@"getCapabilityData::device= %d",device );
    
    NSNumber *minBlocks;
    NSNumber *maxBlocks;
    
    switch (device)
    {
        case iPhone4:
            
            minBlocks = [NSNumber numberWithInt:VGA_MIN_BLOCKS];  //480p
            maxBlocks = [NSNumber numberWithInt:VGA_MAX_BLOCKS];
            break;
            
        case iPhone5:
            
            minBlocks = [NSNumber numberWithInt:HD_MIN_BLOCKS];   //720p
            maxBlocks = [NSNumber numberWithInt:HD_MAX_BLOCKS];
            break;
            
        case iPhone6:
            
            minBlocks = [NSNumber numberWithInt:FHD_MIN_BLOCKS];  //1080p
            maxBlocks = [NSNumber numberWithInt:FHD_MAX_BLOCKS];
            break;
            
        default:
            
            minBlocks = [NSNumber numberWithInt:DEFAULT_MINBLOCKS_RESOLUTION];
            maxBlocks = [NSNumber numberWithInt:DEFAULT_MAXBLOCKS_RESOLUTION];
            break;
    }
    
    NSString *secureProtocol = @"none";
    if([dtlsFlagValue isEqual:@"true"])
    {
        secureProtocol = @"srtpDtls";
    }
    
    // Set IPV6 enable or disabled
    //[webrtcstack enableIPV6:sessionConfig.ipv6patch];
    
    NSDictionary *data =
    @{@"minBlocks" : minBlocks,
      @"maxBlocks" : maxBlocks,
      @"secureProtocol" : secureProtocol,
      //sessionconfig
//      @"video" : sessionConfig.video,
//      @"audio" : sessionConfig.audio,
//      @"data" : sessionConfig.data,
//      @"one_way" : [NSNumber numberWithBool:sessionConfig.isOneWay],
//      @"broadcast" : [NSNumber numberWithBool:sessionConfig.isBroadcast],
//      @"app" : sessionConfig.appName,
//      @"ipv6patch" : sessionConfig.ipv6patch
      };
    
    return data;
}

- (int) getMachineID
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *device = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    // NSLog(@"getMachineID = %@",device);
    
    int deviceSeries;
    
    if([device isEqualToString:@"iPhone3,1"] || [device isEqualToString:@"iPhone3,2"] || [device isEqualToString:@"iPhone3,3"] ||
       [device isEqualToString:@"iPhone4,1"])
    {
        deviceSeries =  iPhone4;
    }
    else if([device isEqualToString:@"iPhone5,1"] || [device isEqualToString:@"iPhone5,2"] || [device isEqualToString:@"iPhone5,3"] ||
            [device isEqualToString:@"iPhone5,4"] || [device isEqualToString:@"iPhone6,1"] || [device isEqualToString:@"iPhone6,2"])
    {
        deviceSeries = iPhone5;
    }
    else if([device isEqualToString:@"iPhone7,2"] || [device isEqualToString:@"iPhone7,1"])
    {
        deviceSeries = iPhone6;
    }
    
    return deviceSeries;
}

-(NSMutableDictionary*)getMetaData
{
    
    /*NSString* name = [[UIDevice currentDevice] name];
     NSString* systemName =  [[UIDevice currentDevice] systemName];
     NSString* systemVersion = [[UIDevice currentDevice] systemVersion];
     NSString* model =  [[UIDevice currentDevice] model];*/
    NSString* NetConType = [self getNetworkConnectionType ];
    NSMutableDictionary* metadata = [[NSMutableDictionary alloc]init];
    //SString *uniqueIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString* sdkVersion = [UIDevice currentDevice].systemVersion;
    //[metadata setValue:name forKey:@"name"];
    // [metadata setValue:systemName forKey:@"systemName"];
    // [metadata setValue:systemVersion forKey:@"systemVersion"];
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *result = [NSString stringWithCString:systemInfo.machine
                                          encoding:NSUTF8StringEncoding];
    NSString* model = [self platformType:result];
    
    [metadata setValue:model forKey:@"model"];
    [metadata setValue:@"Apple" forKey:@"manufacturer"];
    [metadata setValue:NetConType forKey:@"NetworkType"];
    [metadata setValue:sdkVersion forKey:@"iOSSDKVersion"];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = [bundle infoDictionary];
    NSString *prodName = [info objectForKey:@"CFBundleDisplayName"];
    [metadata setValue:prodName forKey:@"packageName"];
    //[metadata setValue:prodName forKey:@"alias"];
    return metadata;
    
}

-(NSString*)getNetworkConnectionType
{
  //  NSArray *subviews = [[[[UIApplication sharedApplication] valueForKey:@"statusBar"] valueForKey:@"foregroundView"]subviews];
//    NSArray *subviews;
//    NSNumber *dataNetworkItemView = nil;
//
//    if ([[[UIApplication sharedApplication] valueForKeyPath:@"_statusBar"] isKindOfClass:NSClassFromString(@"UIStatusBar_Modern")]) {
//        subviews = [[[[[UIApplication sharedApplication] valueForKeyPath:@"_statusBar"] valueForKeyPath:@"_statusBar"] valueForKeyPath:@"foregroundView"] subviews];
//    } else {
//        subviews = [[[[UIApplication sharedApplication] valueForKeyPath:@"_statusBar"] valueForKeyPath:@"foregroundView"] subviews];
//    }
//
//    for (id subview in subviews) {
//        if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
//            dataNetworkItemView = subview;
//            break;
//        }
//    }
//    NSString* type;
//
//    switch ([[dataNetworkItemView valueForKey:@"dataNetworkType"]integerValue]) {
//        case 0:
//            type=@"No Wifi/Cellular connection";
//            _networkType = nonetwork;
//            break;
//
//        case 1:
//            type=@"2G";
//            _networkType = cellular2g;
//            break;
//
//        case 2:
//            type=@"3G";
//            _networkType = cellular3g;
//            break;
//
//        case 3:
//            type=@"4G";
//            _networkType = cellular4g;
//            break;
//
//        case 4:
//            type=@"LTE";
//            _networkType =  cellularLTE;
//            break;
//
//        case 5:
//            type=@"Wifi";
//            _networkType = wifi;
//            break;
//
//        default:
//            type=@"Not found !!";
//            break;
//    }
//    return type;
    
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [reachability currentReachabilityStatus];
    NSString *type=@"";
    if(status == NotReachable)
    {
        type=@"No Wifi/Cellular connection";
    }
    else if (status == ReachableViaWiFi)
    {
        type=@"Wifi";
    }
    else if (status == ReachableViaWWAN)
    {
        CTTelephonyNetworkInfo *telephonyInfo = [CTTelephonyNetworkInfo new];
        NSString *connectionType = telephonyInfo.currentRadioAccessTechnology;       
        if(connectionType != nil){
            if (([connectionType isEqualToString:CTRadioAccessTechnologyGPRS])
                ||([connectionType isEqualToString:CTRadioAccessTechnologyEdge])
                ||([connectionType isEqualToString:CTRadioAccessTechnologyCDMA1x]))
            {
                type=@"2G";
            }
            else if (([connectionType isEqualToString:CTRadioAccessTechnologyWCDMA])
                      ||([connectionType isEqualToString:CTRadioAccessTechnologyHSDPA])
                      ||([connectionType isEqualToString:CTRadioAccessTechnologyHSUPA])
                      ||([connectionType isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0])
                      ||([connectionType isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA])
                      ||([connectionType isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB])
                      ||([connectionType isEqualToString:CTRadioAccessTechnologyeHRPD]))
            {
                type=@"3G";
            }
            else if ([connectionType isEqualToString:CTRadioAccessTechnologyLTE])
            {
                type=@"4G";
            }
        }
    }
    return type;
}

- (NSString *) platformType:(NSString *)platform
{
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone 5c (GSM)";
    if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone 5c (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone 5s (GSM)";
    if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone 5s (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([platform isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([platform isEqualToString:@"iPhone8,1"])    return @"iPhone 6S";
    if ([platform isEqualToString:@"iPhone8,2"])    return @"iPhone 6S Plus";
    if ([platform isEqualToString:@"iPhone8,4"])    return @"iPhone SE";
    if ([platform isEqualToString:@"iPhone9,1"])    return @"iPhone 7 (CDMA)";
    if ([platform isEqualToString:@"iPhone9,3"])    return @"iPhone 7 (GSM)";
    if ([platform isEqualToString:@"iPhone9,2"])    return @"iPhone 7 Plus (CDMA)";
    if ([platform isEqualToString:@"iPhone9,4"])    return @"iPhone 7 Plus (GSM)";
    if ([platform isEqualToString:@"iPhone10,1"])    return @"iPhone 8 (CDMA)";
    if ([platform isEqualToString:@"iPhone10,2"])    return @"iPhone 8 Plus (CDMA)";
    if ([platform isEqualToString:@"iPhone10,5"])    return @"iPhone 8 Plus (GSM)";
    if ([platform isEqualToString:@"iPhone10,3"])    return @"iPhone X (CDMA)";
    if ([platform isEqualToString:@"iPhone10,6"])    return @"iPhone X (GSM)";
    if ([platform isEqualToString:@"iPhone11,2"])    return @"iPhone XS";
    if ([platform isEqualToString:@"iPhone11,4"])    return @"iPhone XS Max";
    if ([platform isEqualToString:@"iPhone11,6"])    return @"iPhone XS Max China";
    if ([platform isEqualToString:@"iPhone11,8"])    return @"iPhone XR";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini (GSM)";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3 (GSM)";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4 (GSM)";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad4,1"])      return @"iPad Air (WiFi)";
    if ([platform isEqualToString:@"iPad4,2"])      return @"iPad Air (Cellular)";
    if ([platform isEqualToString:@"iPad4,3"])      return @"iPad Air";
    if ([platform isEqualToString:@"iPad4,4"])      return @"iPad Mini 2G (WiFi)";
    if ([platform isEqualToString:@"iPad4,5"])      return @"iPad Mini 2G (Cellular)";
    if ([platform isEqualToString:@"iPad4,6"])      return @"iPad Mini 2G";
    if ([platform isEqualToString:@"iPad4,7"])      return @"iPad Mini (Wifi)";
    if ([platform isEqualToString:@"iPad6,7"])      return @"iPad Pro (12.9\")";
    if ([platform isEqualToString:@"iPad6,3"])      return @"iPad Pro (9.7\")";
    if ([platform isEqualToString:@"iPad6,4"])      return @"iPad Pro (9.7\")";
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
    return platform;
}


-(void)onCapabilityMessage:(NSDictionary*)msg
{
    /* Checking if the remote set top box is Pace platform.
     By default configured for Arris platform */
    //NSLog(@"WebRTCSession:onCapabilityMessage sessionConfig = %@",sessionConfig);
    NSDictionary* metaData = [msg objectForKey:@"meta"];
    NSString* platformType = [metaData objectForKey:@"platform"];
    bool isConfigResetRequired = false;
    NSMutableDictionary *newConfig = [[NSMutableDictionary alloc]init];
    
    
    
    //if ([platformType containsString:@"pace"]) {
    if ([platformType rangeOfString:@"pace"].location != NSNotFound) {
        IRISLogInfo(@"Remote platform is Pace box, Configuring frame rate accordingly");
        //sessionconfig
       // localstream.getStreamConfig.maxFrameRate = 20;
      //  localstream.getStreamConfig.minFrameRate = 15;
        
        
        isConfigResetRequired = true;
    }
    /*else
     //if([platformType containsString:@"arris"])
     if ([platformType rangeOfString:@"arris"].location != NSNotFound)
     {
     NSLog(@"Remote platform is Arris box, Configuring frame rate accordingly"];
     localstream.getStreamConfig.maxFrameRate = 20;
     localstream.getStreamConfig.minFrameRate = 30;
     isConfigResetRequired = true;
     
     }*/
    
    //if(webrtcstack.isCapabilityExchangeEnable)
    {
        IRISLogInfo(@"Inide onCapabilityMessage");
        
        NSInteger minBlocks = 0;
        NSInteger maxBlocks = 0;
        NSString *secureProtocol;
        NSString *video;
        NSString *audio;
        NSString *data;
        BOOL one_way;
        BOOL broadcast;
        BOOL ipv6Enabled = false;
        
        @try{
            
            NSDictionary *dataMsg = [msg objectForKey:@"data"];
            
            if ([dataMsg objectForKey:@"ipv6patch"] != Nil)
            {
                //flag
               // sessionConfig.ipv6patch = [dataMsg objectForKey:@"ipv6patch"];
                
                //flag
//                if([sessionConfig.ipv6patch  isEqual:@"true"])
//                {
//                    ipv6Enabled = true;
//                }
//                else if ([secureProtocol  isEqual:@"none"])
//                {
//                    ipv6Enabled = false;
//                }
                
                
                if(capTimer != nil){
                    [capTimer invalidate];
                    capTimer = nil;
                }
                
                IRISLogInfo(@"webrtcsdk::onCapabilityMessage:ipv6patch:%d",ipv6Enabled);
                //flag
              //   [sdk enableIPV6:ipv6Enabled];
                
            }
            
            if(capTimer != nil){
                [capTimer invalidate];
                capTimer = nil;
            }
            [self startSession:updatedIceServers];
            
            //streamconfig
//            if(webrtcstack.isCapabilityExchangeEnable)
//            {
//                if ([dataMsg objectForKey:@"minBlocks"] != Nil)
//                {
//                    minBlocks = [[dataMsg objectForKey:@"minBlocks"] integerValue];
//                }
//                if ([dataMsg objectForKey:@"maxBlocks"] != Nil)
//                {
//                    maxBlocks = [[dataMsg objectForKey:@"maxBlocks"] integerValue];
//                }
//                if ([dataMsg objectForKey:@"secureProtocol"] != Nil)
//                {
//                    secureProtocol = [dataMsg objectForKey:@"secureProtocol"];
//                    
//                    if([secureProtocol  isEqual:@"srtpDtls"])
//                    {
//                        [self setDTLSFlag:TRUE];
//                    }
//                    else if ([secureProtocol  isEqual:@"none"])
//                    {
//                        [self setDTLSFlag:FALSE];
//                    }
//                }
//                if ([dataMsg objectForKey:@"video"] != Nil)
//                {
//                    video = [dataMsg objectForKey:@"video"];
//                }
//                if ([dataMsg objectForKey:@"audio"] != Nil)
//                {
//                    audio = [dataMsg objectForKey:@"audio"];
//                }
//                if ([dataMsg objectForKey:@"data"] != Nil)
//                {
//                    data = [dataMsg objectForKey:@"data"];
//                }
//                if ([dataMsg objectForKey:@"one_way"] != Nil)
//                {
//                    one_way = [[dataMsg objectForKey:@"one_way"] boolValue];
//                }
//                if ([dataMsg objectForKey:@"broadcast"] != Nil)
//                {
//                    broadcast = [[dataMsg objectForKey:@"broadcast"] boolValue];
//                }
//                if ( (minBlocks == 0) || (maxBlocks == 0))
//                {
//                    
//                    LogError(@"onCapabilityMessage error : empty minBlocks/maxBlocks ");
//                }
//                else
//                {
//                    isConfigResetRequired = true;
//                    [self updateMediaConstraints:minBlocks max:maxBlocks];
//                }
//            }
        }
        
        @catch(NSException *e)
        {
            
          //  LogError(@"Exception in onCapabilityMessage %@", e);
        }
        
    }
    
    if(isConfigResetRequired)
    {
        /*dispatch_async(dispatch_get_main_queue(), ^(void){
         
         sessionConfig.isConfigChange = true;
         localstream.getStreamConfig.isFlipCamera = false;
         for (RTCMediaStream *stream in peerConnection.localStreams)
         {
         lms = stream;
         [peerConnection removeStream:stream];
         
         }
         
         sessionConfig.isConfigChange = TRUE;
         localstream.getStreamConfig.isFlipCamera = false;
         
         [self updateMediaConstraints:minBlocks max:maxBlocks];
         
         [localstream applyStreamConfigChange:localstream.getStreamConfig];
         
         // [self applySessionConfigChanges:sessionConfig];
         });*/
        
        //streamconfig
//        [newConfig setValue:[NSNumber numberWithInteger:localstream.getStreamConfig.maxFrameRate]  forKey:@"maxFrameRate"];
//        [newConfig setValue:[NSNumber numberWithInteger:localstream.getStreamConfig.minFrameRate]  forKey:@"minFrameRate"];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"ConfigurationDidChangeNotification" object:nil userInfo:newConfig];
    }
    
    
}

-(void)updateMediaConstraints:(NSInteger)minBlocks max:(NSInteger)maxBlocks
{
 
    int device = [self getMachineID];
    
    IRISLogInfo(@"updateMediaConstraints::machine ID= %d",device);
    //streamconfig
//    switch (device)
//    {
//        
//        case iPhone4:
//            
//            if (maxBlocks >= VGA_MAX_BLOCKS)
//                [localstream.getStreamConfig setMediaConstraints:VGA];
//            
//            else
//                [localstream.getStreamConfig setMediaConstraints:QVGA];
//            
//            break;
//            
//        case iPhone5:
//            
//            if (maxBlocks >= HD_MAX_BLOCKS)
//                [localstream.getStreamConfig setMediaConstraints:HD];
//            
//            else if(maxBlocks >= VGA_MAX_BLOCKS)
//                [localstream.getStreamConfig setMediaConstraints:VGA];
//            
//            else
//                [localstream.getStreamConfig setMediaConstraints:QVGA];
//            
//            break;
//            
//        case iPhone6:
//            
//            if(maxBlocks >= FHD_MAX_BLOCKS)
//                [localstream.getStreamConfig setMediaConstraints:FHD];
//            
//            else if(maxBlocks >= HD_MAX_BLOCKS)
//                [localstream.getStreamConfig setMediaConstraints:HD];
//            
//            else if(maxBlocks  >= VGA_MAX_BLOCKS)
//                [localstream.getStreamConfig setMediaConstraints:VGA];
//            
//            else
//                [localstream.getStreamConfig setMediaConstraints:QVGA];
//            
//            break;
//            
//        default:
//            
//            [localstream.getStreamConfig setMediaConstraints:unknown];
    
 //   }
}




-(void)sendDataChannelMessage:(NSData*)imgData
{
    IRISLogInfo(@"DataChannel::Inside sendDataChannelMessage");
    if(isDataChannelOpened && _dataChannel != nil)
    {
        IRISLogInfo(@"DataChannel::Sending buffer");
        //NSData *data = [[NSData alloc]initWithBase64EncodedString:@"hi...its harish here" options:NSDataBase64DecodingIgnoreUnknownCharacters];
        // NSData* data = [@"hi...its harish here" dataUsingEncoding:NSUTF8StringEncoding];
        RTCDataBuffer *buffer = [[RTCDataBuffer alloc]initWithData:imgData isBinary:false];
        BOOL retValue = [_dataChannel sendData:buffer];
        if(!retValue)
        {
            cancelSendData = true;
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Sending Image data failed" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_DATA_SEND userInfo:details];
            [self onSessionError:error withAdditionalInfo:nil];
        }
        IRISLogInfo(@"DataChannel::retValue = %d",retValue);
    }
    
}



-(void)sendMessage:(NSData *)msg
{
    
    NSError* error;
    NSDictionary* json =[WebRTCJSONSerialization JSONObjectWithData:msg options:kNilOptions error:&error];
    
    NSMutableDictionary* jsonm = [NSMutableDictionary dictionaryWithDictionary:json];
    
    if(!clientSessionId)
        clientSessionId = [NSString stringWithFormat:@"%d", arc4random() % 1000000];
    
    //[jsonm setValue:ToCaller forKey:@"target"];
    //[jsonm setValue:FromCaller forKey:@"from"];
    //[jsonm setValue:sessionConfig.appName forKey:@"appId"];
    //[jsonm setValue:FromCaller forKey:@"uid"];
    //[jsonm setValue:DisplayName forKey:@"fromDisplay"];
    [jsonm setValue:peerConnectionId forKey:@"peerConnectionId"];
    [jsonm setValue:@"default" forKey:@"applicationContext"];
    [jsonm setValue:clientSessionId forKey:@"clientSessionId"];
    
    IRISLogInfo(@"sendMessage of type = %@",[jsonm objectForKey:@"type"]);
    

    
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonm options:0 error:&error];
        NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
        if ([[jsonm objectForKey:@"type"]  isEqual: @"candidate"])
        {
            [self logEvents:@"SDK_XMPPJingleTransportInfoSent" additionalinfo:nil];
            [jingleHandler sendJingleMessage:@"transport-info" data:jsonm target:targetJid];
        }
 
}


- (void)_timerICEConnCheck:(NSTimer *)timer{
    
    IRISLogInfo(@"Webrtc:Stack:: _timerICEConnCheck");
    if(newICEConnState != RTCIceConnectionStateConnected){
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"ICE Connection Timeout" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_ICE_CONNECTION_TIMEOUT userInfo:details];
        [callSummary setObject:@"Failure" forKey:@"callStatus"];
        [callSummary setObject:error.localizedDescription forKey:@"CallFailureReason"];
        [self onSessionError:error withAdditionalInfo:nil];
    }
    
}

-(void) sendCompressedImageData:(NSData*)imgData
{
    
    /*if(isXMPPEnable){
     
     [[XMPPWorker sharedInstance] share:imgData];
     }
     else
     {*/
    
    //NSData *_imgData= [NSData dataWithContentsOfFile:filePath];
    IRISLogInfo(@"Inside sendCompressedImageData");
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSUInteger length = [imgData length];
        NSUInteger offset = 0;
        NSError *jsonError = nil;
        NSString* dataID = [[NSUUID UUID] UUIDString];
        
        NSString* currentDate = [dateFormatter stringFromDate:[NSDate date]];
        
        NSMutableDictionary* json = [[NSMutableDictionary alloc]init];
        
        [json setValue:@"start" forKey:@"action"];
        [json setValue:dataID forKey:@"dataId"];
        [json setValue:currentDate forKey:@"startTime"];
        IRISLogInfo(@"sendDataWithImage::Image ID = %@",dataID);
        IRISLogInfo(@"sendDataWithImage::total length = %ld",(unsigned long)length);
        
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:0 error:&jsonError];
        [self sendDataChannelMessage:data];
        
        do {
            if(cancelSendData)
                break;
            NSUInteger thisChunkSize = length - offset > dataChunkSize ? dataChunkSize : length - offset;
            IRISLogInfo(@"Sending imagePickerController::thisChunkSize = %ld offset = %ld",(unsigned long)thisChunkSize,(unsigned long)offset);
            NSData* chunk = [NSData dataWithBytesNoCopy:(char *)[imgData bytes] + offset
                                                 length:thisChunkSize
                                           freeWhenDone:NO];
            offset += thisChunkSize;
            
            [self sendDataChannelMessage:chunk];
        } while (offset < length);
        
        if(!cancelSendData)
        {
            [json removeAllObjects];
            [json setValue:@"stop" forKey:@"action"];
            [json setValue:dataID forKey:@"dataId"];
            data = [NSJSONSerialization dataWithJSONObject:json options:0 error:&jsonError];
            [self sendDataChannelMessage:data];
        }
    //});
    //}
    
}

// Apply exif to the image
- (UIImage*)unrotateImage:(UIImage*)image {
    CGSize size = image.size;
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0,0,size.width ,size.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

-(void) sendDataWithImage:(NSString*)filePath
{
    
    cancelSendData = false;
    NSURL* imgURL = [NSURL URLWithString:filePath];
    // Create assets library
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init] ;
    IRISLogInfo(@"sendDataWithImage");
    // Try to load asset at imgURL
    [library assetForURL:imgURL resultBlock:^(ALAsset *asset) {
        if (asset) {
            
            ALAssetRepresentation *repr = [asset defaultRepresentation];
            IRISLogInfo(@"sendDataWithImage: calling sendCompressedImageData [repr size] = %ld",(long)[repr size]);
            UIImage *image = [UIImage imageWithCGImage:[repr fullResolutionImage] scale:[repr scale] orientation:(UIImageOrientation)repr.orientation];
            UIImage *image2 = [self unrotateImage:image];
            [self sendCompressedImageData:UIImageJPEGRepresentation(image2, 0.7)];
            
            // Based on the image, scale the image
            //sessionconfig
//            if(sessionConfig.dataScaleFactor == lowScale)
//            {
//                [self sendCompressedImageData:UIImageJPEGRepresentation(image2, 0.3)];
//            }
//            else
//                if(sessionConfig.dataScaleFactor == midScale)
//                {
//                  [self sendCompressedImageData:UIImageJPEGRepresentation(image2, 0.7)];
//                }
//                else
//                    if(sessionConfig.dataScaleFactor == original)
//                    {
//                        [self sendCompressedImageData:UIImageJPEGRepresentation(image2, [repr size])];
//                    }
//            
        } else {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Sending Image data failed" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_DATA_SEND userInfo:details];
            [self onSessionError:error withAdditionalInfo:nil];
        }
    } failureBlock:^(NSError *error) {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Incorrect Image URL" forKey:NSLocalizedDescriptionKey];
        error = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_INCORRECT_URL userInfo:details];
        [self onSessionError:error withAdditionalInfo:nil];
    }];
}

//Data channel API's to send either a NSString or a Json msg

-(void) sendDataWithText:(NSString*)_textMsg
{
    NSData* data = [_textMsg dataUsingEncoding:NSUTF8StringEncoding];
    [self sendDataChannelMessage:data];
}




- (void) sendXMPPSignalingMessage:(NSString *)message toUser:(NSString *)jidStr
{
    [[XMPPWorker sharedInstance] sendSignalingMessage:message toUser:jidStr];
}

- (void) sendXMPPJingleMessage:(NSString *)sid type:(NSString*)type data:(NSString *)data
{
    //[[XMPPWorker sharedInstance] sendJingleMessage:sid type:type data:data];
}






- (void)xmppWorker:(XMPPWorker *)sender didReceiveSignalingMessage:(XMPPMessage *)message
{
    if ([message isMessageWithBody]) {
        NSString *jidFrom = [[message from] bare];
        IRISLogInfo(@"jidFrom: %@", jidFrom);
        
        NSString *jsonStr = [message body];
        
        NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
        NSString *type = [jsonDict objectForKey:@"type"];
        IRISLogInfo(@"jidFrom: %@", type);
        
        if ([type compare:@"offer"] == NSOrderedSame) {
            IRISLogInfo(@"Set jidFrom");
            [self setFromJid:jidFrom];
        }
        
        [self onSignalingMessage:jsonDict];
    }
    
}



//- (void)preferCodec:(BOOL)value
//{
//    if(value)
//        setCodec = @"H264";
//    else
//        setCodec = @"VP8";
//    
//}

-(void) setPreferredVideoCodecType:(IrisRtcSdkVideoCodecType)type
{
    if(type == kCodecTypeVP8)
    {
        videoCodec = @"VP8";
    }
    else
    if(type == kCodecTypeH264)
    {
        videoCodec = @"H264";
    }
    
    IRISLogInfo(@"Setting codec type to = %@",videoCodec);
}

-(void) setPreferredAudioCodecType:(IrisRtcSdkAudioCodecType)type
{
    if(type == kCodecTypeOPUS)
    {
        audioCodec = @"OPUS";
    }
    else if(type == kCodecTypeISAC16000)
    {
        audioCodec = @"ISAC/16000";
    }
    else if(type == kCodecTypeISAC32000)
    {
        audioCodec = @"ISAC/32000";
    }
    
    IRISLogInfo(@"Setting codec type to = %@",audioCodec);
}
- (void) setVideoBridgeEnable: (bool) flag
{
    _isVideoBridgeEnable = flag;
    [XMPPWorker sharedInstance].isVideoBridgeEnable = flag;
    if(flag){
        logEvent_Calltype = @"videobridge";
    }else{
        logEvent_Calltype = @"p2p";
    }
   
}

- (void) setStatsWS: (bool) flag
{
    IRISLogInfo(@"Begin::setStatsWS value= %d",stats.sendStatsIq);
    stats.sendStatsIq = flag;
    [stats setStatsIq:flag];
    IRISLogInfo(@"End::setStatsWS value= %d",stats.sendStatsIq);
}

- (void) setMaximumStream: (int) streamcount
{
       streamCount = streamcount;

}

- (void) setAnonymousRoomflag:(BOOL)useAnonymousRoom
{
    self.useAnonymousRoom = useAnonymousRoom;    
}

-(void) setStatsCollectorInterval:(NSInteger)interval{
    
      statstimerinterval = interval;

}

-(void) setToDomain:(NSString*)toDomain{
    _toDomain = toDomain;
}

- (void)startSessionValidateTimer{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        sessionValidateTimer = [NSTimer scheduledTimerWithTimeInterval:2
                                                          target:self
                                                        selector:@selector(checkSessionState)
                                                        userInfo:nil
                                                         repeats:YES
                          ];
    });
    
}

-(void)checkSessionState{
       
    if([[XMPPWorker sharedInstance]isHitlessUpgrade] && ![[XMPPWorker sharedInstance] hasActiveAudioorVideoSession] ){
        
        if(sessionValidateTimer != nil)
            [sessionValidateTimer invalidate];
        
        [self disconnect];
    }
 
    /*if([[XMPPWorker sharedInstance]isSocketReconnected]){
         
         [self restartSession];
    }*/
}



/*-(NSString*)getClientSessionId
{
    return clientSessionId;
}*/

#pragma mark - Internal methods

// Request ICEservers from signaling server

-(void)freeObjects{
    if(peerConnection != nil){
        [peerConnection close];
        peerConnection = nil;
    }
    
    cancelSendData = true;
    if(_dataChannel != nil){
        _dataChannel.delegate = nil;
        [_dataChannel close];
        _dataChannel = nil;
    }
    
    isFocusJoined = false;
    updatedIceServers = nil;
    queuedRemoteCandidates = nil;
    localsdp = nil;
    allcandidates = nil;
    _statsQueue=nil;
   
    
}
- (void)closeSession
{
   
   // dispatch_async(dispatch_get_main_queue(), ^(void)
    //               {
                       // NSLog(@"DataTask cancel is done ");
                       //Closing data channel
    
                        [self freeObjects];
                        [_eventManager End];
                        
                       if(_statsCollector != nil){
                            [_statsCollector stopMetric:@"callDuration"];
                           _statsCollector = nil;
                       }
                    if(self.iceConnectionCheckTimer != nil)
                    {
                        IRISLogInfo(@"closeSession::iceConnectionCheckTimer::Invalidating");
                        [self.iceConnectionCheckTimer invalidate];
                        self.iceConnectionCheckTimer = nil;
                    }
    
                    if(_iceConnCheckTimer != nil)
                    {
                        [_iceConnCheckTimer invalidate];
                        _iceConnCheckTimer = nil;
                    }
    
                    if(self.sessionIceConnectionCheckTimer != nil)
                    {
                        IRISLogInfo(@"closeSession::sessionIceConnectionCheckTimer::Invalidating");
                        [self.sessionIceConnectionCheckTimer invalidate];
                        self.sessionIceConnectionCheckTimer = nil;
                    }
    
                       [[[XMPPWorker sharedInstance] xmppStream] removeDelegate:self];
                       //[stats setEventsArray:_eventsArray];
                       
                       if(localstream != nil && peerConnection != nil  ){
                           [peerConnection removeStream:localstream.getMediaStream];
                           localstream = nil;
                       }
    
                       irisPhoneNumberUtil = nil;
                       isStreamStatusUpdated = false;
                       mediaConstraints = nil;
                       pcConstraints = nil;
                     //  state = inactive;
                       if([[XMPPWorker sharedInstance]isSocketReconnected]){                          
                            localstream = nil;
                       }

                       factory = nil;
    
                       lastSr = nil;
                       _statsCollector = nil;
    
    
                        [self logEvents:@"SDK_SessionEnded" additionalinfo:nil];
                       _iceServers = nil;
                       serverURL = nil;
                       initialSDP = nil;
                       dataSessionActive = false;
                       jingleHandler = nil;
                       irisRoom = nil;
                       dataElement = nil;
                       participantsDict = nil;
                       
                       _eventManager = nil;
    
    
                    if(stats != nil){
                    [stats stopMonitoring];
                    stats = nil;
                    }
                       IRISLogInfo(@"IrisRtcJingleSession::Closed");
                       // [RTCPeerConnectionFactory deinitializeSSL];
                  // });
}


-(void)close
{
    if(state == inactive){
         IRISLogError(@"IrisRtcJingleSession::: RoomId = %@ for ObjectId : %@",_roomId,self);
        return;
    }
    IRISLogInfo(@"IrisRtcJingleSession::: RoomId = %@ for ObjectId : %@",_roomId,self);
    if(isUpgrade && _sessionType == kSessionTypeVideo)
    {
        IRISLogInfo(@"IrisRtcSession::downgradeToChat for roomId = %@",_roomId);
        [self downgradeToChat];
    }
    [self disconnect];
}

- (void)disconnect
{
    IRISLogInfo(@"IrisRtcSession Disconnect for roomId = %@ and objectId = %@",_roomId,self );
    state = inactive;
    [self stopRingTimer];
    [irisRoom stopPeriodicPresenceTimer];
    [[XMPPWorker sharedInstance]setIsRoomJoined:false];
    
    //if(sessionValidateTimer != nil)
     //   [sessionValidateTimer invalidate];
    
    if(participantPresenceTimer != nil){
        [participantPresenceTimer invalidate];
        participantPresenceTimer = nil;
    }

    if(_sessionType == kSessionTypePSTN)
        [self endPSTNCall];
   
    //[self logEvents:@"SDK_SessionEnded" additionalinfo:nil];
    [self sendMessage:[@"{\"type\" : \"bye\"}" dataUsingEncoding:NSUTF8StringEncoding]];
    // if (state == active)
   
    //Deactivate Jingle
    [jingleHandler deactivateJingle];
    [irisRoom leaveRoom];
    //[stats setEventsArray:_eventsArray];
    [self closeSession];
    if([self.sessionDelegate respondsToSelector:@selector(onSessionEnded:traceId:)])
        [self.sessionDelegate onSessionEnded:_roomId traceId:_traceId];
    _sessionDelegate = nil;
    
    if([[[XMPPWorker sharedInstance] activeSessions]objectForKey:_roomId])
        [[[XMPPWorker sharedInstance] activeSessions]removeObjectForKey:_roomId];
    
    if([[XMPPWorker sharedInstance]isHitlessUpgrade] && ![[XMPPWorker sharedInstance] hasActiveAudioorVideoSession]){
       
        [[XMPPWorker sharedInstance]setIsHitlessUpgrade:false];
        [[IrisRtcConnection sharedInstance]checkServerConnectionState];
    }
    //_traceId = nil;
    //[[XMPPWorker sharedInstance] stopEngine];
   
    
}

- (void)sendDTMFTone:(IrisDTMFInputType)_tone
{
    if ( state != active ) {
        IRISLogError(@"Connect not send DTMF tone while not in a session");
        //return;
    }
    NSString *toneValue = toneValueString(_tone);
    IRISLogInfo(@"Sending DTMF Tone %@",toneValue);
    //NSDictionary *initialDtmf = @{@"type":@"sessionMessage"};
    NSDictionary *sessionMessage = @{@"type": @"dtmf", @"tone": toneValue};
    NSDictionary *initialDtmf = @{@"type":@"sessionMessage", @"sessionMessage":sessionMessage};
    //[initialDtmf setValue:sessionMessage forKey:@"sessionMessage"];
    NSError *jsonError = nil;
    NSData *dtmf = [WebRTCJSONSerialization dataWithJSONObject:initialDtmf options:0 error:&jsonError];
    IRISLogInfo(@"check4");
    [self sendMessage:dtmf];
    
}

- (void)_timerOffer:(NSTimer *)timer{
    
    IRISLogInfo(@"Webrtc:Stack:: _timerOffer");
    
}

- (NSDictionary *)getRemotePartyInfo
{
    NSDictionary *json = @{ @"alias" : ToCaller };
    return json;
}

- (void)setDTLSFlag:(BOOL)value
{
    if (value == true)
    {
        dtlsFlagValue = @"true";
    }
    else
    {
        dtlsFlagValue = @"false";
    }
}


- (NSString*)ICEConnectionTypeToString:(RTCIceConnectionState)iceState {
    NSString *result = nil;
    
    switch(iceState) {
        case RTCIceConnectionStateNew:
            result = @"SDK_ICEConnectionNew";
            break;
        case RTCIceConnectionStateChecking:
            result = @"SDK_ICEConnectionChecking";
            break;
        case RTCIceConnectionStateConnected:
            result = @"SDK_ICEConnectionConnected";
            break;
        case RTCIceConnectionStateCompleted:
            result = @"SDK_ICEConnectionCompleted";
            break;
        case RTCIceConnectionStateFailed:
            result = @"SDK_ICEConnectionFailed";
            break;
        case RTCIceConnectionStateDisconnected:
            result = @"SDK_ICEConnectionDisconnected";
            break;
        case RTCIceConnectionStateClosed:
            result = @"SDK_ICEConnectionClosed";
            break;
        default:
            result = @"SDK_UnknownICEConnectionState";
    }
    
    return result;
}

- (NSString*)SignallingStateTypeToString:(RTCSignalingState)signallingState {
    NSString *result = nil;
    
    switch(signallingState) {
        case RTCSignalingStateStable:
            result = @"SDK_SignalingStateStable";
            break;
        case RTCSignalingStateHaveLocalOffer:
            result = @"SDK_SignalingStateHaveLocalOffer";
            break;
        case RTCSignalingStateHaveLocalPrAnswer:
            result = @"SDK_SignalingStateHaveLocalPranswer";
            break;
        case RTCSignalingStateHaveRemoteOffer:
            result = @"SDK_SignalingStateHaveRemoteOffer";
            break;
        case RTCSignalingStateHaveRemotePrAnswer:
            result = @"SDK_SignalingStateHaveRemotePranswer";
            break;
        case RTCSignalingStateClosed:
            result = @"SDK_SignalingStateClosed";
            break;
        default:
            result = @"SDK_SignalingState";
    }
    
    return result;
}

- (NSString*)SipStatusStateTypeToString:(IrisSIPStatus)sipStatus{
    NSString *result = nil;
    
    switch (sipStatus) {
        case kConnected:
            result = @"SDK_SIPConnected";
            break;
        case kConnecting:
            result = @"SDK_SIPConnecting";
            break;
        case kDisconnected:
            result = @"SDK_SIPDisConnected";
            break;
        case kInitializing:
            result = @"SDK_SIPInitializing";
            break;
        case kHold:
            result = @"SDK_SIPHold";
            break;
        default:
            result = @"SDK_InvalidState";           
            
    }
    return result;
            
}
// Triggered when there is an error.
- (void)peerConnectiononSessionError:(RTCPeerConnection *)peerConnection
{
    NSAssert(NO, @"Webrtc:Session:: PeerConnection error");
    [self close];
    [self logEvents:@"SDK_SessionError" additionalinfo:nil];
    NSError *error = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_UNSPECIFIED_PEERCONNECTION userInfo:nil];
    [callSummary setObject:@"Failure" forKey:@"callStatus"];
    [callSummary setObject:error.localizedDescription forKey:@"CallFailureReason"];
    [self close];
     [self onSessionError:error withAdditionalInfo:nil];
     self.sessionDelegate = nil;
     
}



#pragma mark - Sample RTCPeerConnectionDelegate delegate
// Triggered when the SignalingState changed.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeSignalingState:(RTCSignalingState)stateChanged {

    IRISLogInfo(@"PCO onSignalingStateChange: %d",stateChanged);
    
     [self logEvents:[self SignallingStateTypeToString:stateChanged] additionalinfo:nil];
}

// Triggered when media is received on a new stream from remote peer.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didAddStream:(RTCMediaStream *)stream {

    IRISLogInfo(@" PCO onAddStream = %lu ",(unsigned long)[stream.videoTracks count]);
    IRISLogInfo(@" PCO onAddStream label = %@ ",stream.streamId);

    // NSAssert([stream.audioTracks count] >= 1,
    //         @"Expected at least 1 audio stream");
    //NSAssert([stream.videoTracks count] >= 1,
    //         @"Expected at least 1 video stream");
    
    /*Added check for
        default : If dont add fake ssrc comes as a part of session-initiate
        mixedmslabel : If add fake ssrc comes as a part of session-initiate
     */
    if(_isVideoBridgeEnable && ([stream.streamId isEqual:@"default"] || [stream.streamId isEqual:@"mixedmslabel"]))
        return;
   
    if([stream.streamId isEqual:[localstream getMediaStream].streamId])
        return;
    
    if ([stream.videoTracks count] > 0)
    //if ([stream.videoTracks count] > 0)
    {
        IRISLogInfo(@" PCO onAddStream1111");
        
          //if ([self.sessionDelegate respondsToSelector:@selector(onAddRemoteStream:)]) {
             IrisRtcMediaTrack* _remoteStream = [[IrisRtcMediaTrack alloc]init];
            _remoteStream.videoTrack = [stream.videoTracks objectAtIndex:0];
        if ([self.sessionDelegate respondsToSelector:@selector(onAddRemoteStream:participantId:roomId:traceId:)]) {
            
            [self.sessionDelegate onAddRemoteStream:_remoteStream participantId:[jingleHandler routingId:stream.streamId] roomId:_roomId traceId:_traceId];
        }

        
        //}
    }
    
}

// Triggered when a remote peer close a stream.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
       didRemoveStream:(RTCMediaStream *)stream {

    IRISLogInfo(@" PCO onRemoveStream = %@",stream.streamId);
    if ([stream.videoTracks count] > 0 && ![stream.streamId isEqual:@"default"] && ![stream.streamId isEqual:@"mixedmslabel"])
    {
        [stream removeVideoTrack:[stream.videoTracks objectAtIndex:0]];
        IrisRtcMediaTrack* _remoteStream = [[IrisRtcMediaTrack alloc]init];
        _remoteStream.videoTrack = [stream.videoTracks objectAtIndex:0];

        if ([self.sessionDelegate respondsToSelector:@selector(onRemoveRemoteStream:participantId:roomId:traceId:)]) {
              
            [self.sessionDelegate onRemoveRemoteStream:_remoteStream participantId:[jingleHandler routingId:stream.streamId] roomId:_roomId traceId:_traceId];
        }
 
    }
}

// Triggered when renegotation is needed, for example the ICE has restarted.
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection {
    IRISLogInfo(@" PCO onRenegotiationNeeded");
}

// Called any time the ICEConnectionState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceConnectionState:(RTCIceConnectionState)newState {
    
    IRISLogInfo(@"PCO onIceConnectionChange.%d", newState );
    IRISLogInfo(@"Current State. %d", state);
    [self logEvents:[self ICEConnectionTypeToString:newState] additionalinfo:nil];
    newICEConnState = newState;
    if (newState == RTCIceConnectionStateConnected)
    {
        // Change the audio session type to video chat as it has better audio processing logic
        AVAudioSession * audioSession = [AVAudioSession sharedInstance];
        if (audioSession != nil)
        {
            [audioSession setMode:AVAudioSessionModeVideoChat
                            error:nil];
            IRISLogInfo(@"Webrtc:Session:: Audio mode is %@", audioSession.mode);
        }
        isSessionRestarted = false;
        IRISLogInfo(@"ICE Connection connected.");
       
        [_statsCollector stopMetric:_roomId _statName:@"mediaConnectionTime"];
        
        //Set flag for updating turn server IP
        [WebRTCStatReport setTurnIPAvailabilityStatus:false];
        
        //Stop sending ping pong message as connection as established.
        //_isSendingPingPongMsg = false;
        
        if (self.sessionDelegate != nil &&  ([self.sessionDelegate respondsToSelector:@selector(onSessionConnected:traceId:)]))
            [self.sessionDelegate onSessionConnected:_roomId traceId:_traceId];
        
        if(self.iceConnectionCheckTimer != nil)
        {
            IRISLogInfo(@"iceConnectionCheckTimer::Invalidating");
            [self.iceConnectionCheckTimer invalidate];
            self.iceConnectionCheckTimer = nil;
        }
        if(_iceConnCheckTimer != nil)
        {
            [_iceConnCheckTimer invalidate];
            _iceConnCheckTimer = nil;
        }
        
        
    }
    else if(newState == RTCIceConnectionStateDisconnected)
    {
        IRISLogInfo(@"ICE Connection disconnected");
        [self stopRingTimer];
  //      if([[XMPPWorker sharedInstance]isAttemmptingReconnect] || isSessionRestarted){
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
            //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                IRISLogInfo(@"RTCIceConnectionStateDisconnected::Starting timer");
                iceConnectionCheckTimer = [NSTimer scheduledTimerWithTimeInterval:ICE_CONNECTION_TIMEOUT
                                                                                target:self
                                                                              selector:@selector(timerICEConnCheck)
                                                                              userInfo:nil
                                                                               repeats:NO
                                                ];
                
            });
            
//        }else{
//             [self timerICEConnCheck];
//        }
        
    }
    
    else if(newState == RTCIceConnectionStateChecking)
    {
        dispatch_async(dispatch_get_main_queue(), ^(void){
        _iceConnCheckTimer = [NSTimer scheduledTimerWithTimeInterval:ICE_CONNECTION_TIMEOUT
                                                              target:self
                                                            selector:@selector(_timerICEConnCheck:)
                                                            userInfo:nil
                                                             repeats:NO
                              ];
             });
        
    }
    else if(newState == RTCIceConnectionStateFailed)
    {
        if(![[XMPPWorker sharedInstance]isAttemmptingReconnect] && !isSessionRestarted){
        IRISLogInfo(@"RTCIceConnectionStateFailed::error");
        [self timerICEConnCheck];
        }
    }
    
    // NSAssert(newState != RTCICEConnectionFailed, @"ICE Connection failed!");
    
}


// Called any time the ICEGatheringState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceGatheringState:(RTCIceGatheringState)newState {
    
    IRISLogInfo(@"PCO onIceGatheringChange.%d",newState  );
    //Delegate to inform ICE gathering state to APP
    [self logEvents:[self ICEGatheringTypeToString:newState] additionalinfo:nil];
    
}

// New Ice candidate have been found.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didGenerateIceCandidate:(RTCIceCandidate *)candidate {
    
    // Form JSON
    NSDictionary *json =
    @{ @"type" : @"candidate",
       @"label" : [NSNumber numberWithInt:candidate.sdpMLineIndex],
       @"id" : candidate.sdpMid,
       @"candidate" : candidate.sdp };
    
    IRISLogInfo(@"gotICECandidate = %@",candidate.sdp);
    //Harish::For IPv6 testing
    
    //flag
//    if(sessionConfig.forceRelay)
//    {
//        if(![candidate.sdp containsString:@"relay"])
//        {
//            NSLog(@"ignoring %@",candidate.sdp);
//            return;
//        }
//    }
    
    /*if([candidate.sdp containsString:@"host"])
    {
        NSLog(@"ignoring host candidates %@",candidate.sdp);
        return;
    }*/
    
    // Create data object
    NSError *error;
    NSData *data = [WebRTCJSONSerialization dataWithJSONObject:json options:0 error:&error];
    
    
    if (!error) {
        //if(dataFlagEnabled){
        if(callType == outgoing && !_isVideoBridgeEnable)
        {
            if(isOfferSent)
            {
                [self sendMessage:data];
            }
            else
            {
                IRISLogInfo(@"adding canddate to array");
                [iceCandidates addObject:data];
            }
        }
        else{
            [self sendMessage:data];
        }
        
    }    else {
        NSAssert(NO, @"Unable to serialize candidate JSON object with error: %@",
                 error.localizedDescription);
    }
    
    // Send if we have got enough candidates
    if (isAnswerSent)
    {

//        if (allcandidates.count > 10)
//        {
//            [self sendCandidates:allcandidates];
//            [allcandidates removeAllObjects];
//        }
    }
    
}
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates {
}

- (NSString*)ICEGatheringTypeToString:(RTCIceGatheringState)iceState {
    NSString *result = nil;
    
    switch(iceState) {
        case RTCIceGatheringStateNew:
            result = @"SDK_ICEGatheringNew";
            break;
        case RTCIceGatheringStateGathering:
            result = @"SDK_ICEGathering";
            break;
        case RTCIceGatheringStateComplete:
            result = @"SDK_ICEGatheringComplete";
            break;
        default:
            result = @"SDK_UnknownICEGatheringState";
    }
    
    return result;
}


- (void)sendCandidates:(NSMutableArray *) candidates
{
    if (candidates.count == 0)
    {
        return;
    }
    // Check if the candidates are large in number
    while (candidates.count > 10)
    {
        NSDictionary *candidateList = [[candidates subarrayWithRange:NSMakeRange(0, 10)] mutableCopy];
        //NSLog(@"Sending all candidates in a list: %@", candidateList.debugDescription);
        
      //  [self sendToChannel:candidateList];
        [candidates removeObjectsInRange:NSMakeRange(0, 10)];
    }
    NSDictionary* allcandidatesD = [candidates mutableCopy];
    //NSLog(@"Sending remaining candidates in a list: %@", allcandidatesD.debugDescription);
    
  //  [self sendToChannel:allcandidatesD];
}





- (void)capTimerCallback:(NSTimer *)timer{
    
    IRISLogInfo(@"webrtcsdk::capTimerCallback");
    
    // No capabilities to enable patch received setting to false
    //flag
 //   [sdk enableIPV6:false];
    
    [self startSession:updatedIceServers];
    
}


- (void)timerICEConnCheck{
    IRISLogInfo(@"timerICEConnCheck::newICEConnState = %ld",(long)newICEConnState);
    
    if((newICEConnState == RTCIceConnectionStateConnected ) || isSessionRestarted)
    {
        IRISLogInfo(@"timerICEConnCheck::newICEConnState  return");
        return;
    }
    
    if(newICEConnState != RTCIceConnectionStateConnected ){
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"ICE Connection Couldn't be established" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_ICE_CONNECTION_ERROR userInfo:details];
        [callSummary setObject:@"Failure" forKey:@"callStatus"];
        [callSummary setObject:error.localizedDescription forKey:@"CallFailureReason"];
        [self onSessionError:error withAdditionalInfo:nil];
    }
    
    if (self.iceConnectionCheckTimer != nil){
        IRISLogInfo(@"timerICEConnCheck::iceConnectionCheckTimer::Invalidating");
        [self.iceConnectionCheckTimer invalidate];
        self.iceConnectionCheckTimer = nil;
    }
    if (self.sessionIceConnectionCheckTimer != nil){
        IRISLogInfo(@"timerICEConnCheck::sessionIceConnectionCheckTimer::Invalidating");
        [self.sessionIceConnectionCheckTimer invalidate];
        self.sessionIceConnectionCheckTimer = nil;
    }
}

-(void)reconnectSession
{
  //  [channel sendReconnect];
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel;
{
    IRISLogInfo(@"DataChannel::Inside didOpenDataChannel");
    if (_dataChannel == nil)
    {
        _dataChannel = dataChannel;
        _dataChannel.delegate = self;
        isDataChannelOpened = true;
    }
}

#pragma mark - Sample RTCSessionDescriptonDelegate delegate

- (void)peerConnection:(RTCPeerConnection *)arPeerConnection
didCreateSessionDescription:(RTCSessionDescription *)arSdp
                 error:(NSError *)error
{
    if(error)
    {
        return;
    }
    IRISLogInfo(@"Raw SDP= %@",arSdp.description);
    
    
    NSMutableString * orgSDP = [arSdp.description mutableCopy];
    
    NSRange lineindex;
    lineindex = [orgSDP rangeOfString:@"a=rtpmap:100 VP8/90000\r\n"];
    
    NSString *modifiedSdp =[ARDSDPUtils descriptionForDescriptionString:orgSDP preferredVideoCodec:videoCodec];
 
    NSString *sdpStirng = [ARDSDPUtils descriptionForDescriptionString:modifiedSdp preferredAudioCodec:audioCodec];

//    RTCSessionDescription *sdp = [[RTCSessionDescription alloc]
//                                  //initWithType:RTCSdpTypeOffer sdp:[self preferISAC:sdpString]];
//                                  initWithType:arSdp.type sdp:[self preferISAC:modifiedSdp]];
    
    
    // Create SDP and set local description
    RTCSessionDescription* sdp = [[RTCSessionDescription alloc] initWithType:arSdp.type sdp:sdpStirng];
  
    __weak IrisRtcJingleSession *weakSelf = self;
        [peerConnection setLocalDescription:arSdp
                          completionHandler:^(NSError *error) {
                              IrisRtcJingleSession *strongSelf = weakSelf;
                              [strongSelf peerConnection:strongSelf->peerConnection
                       didSetSessionDescriptionWithError:error];
                          }];
    //});

    
  
    
    NSString * sdpDesc = sdp.description;

    if(localstream == nil && callType == outgoing) {
        sdpDesc = [sdpDesc stringByReplacingOccurrencesOfString:@"sendrecv" withString:@"recvonly"];
    }    // Form JSON
    NSString *sdpType;
    if (sdp.type == RTCSdpTypeOffer)
    {
        sdpType = @"offer";
    }
    else if (sdp.type == RTCSdpTypeAnswer)
    {
        sdpType = @"answer";
    }
    else
    {
        sdpType = @"proffer";
        
    }
    NSDictionary *json = @{ @"type" : sdpType, @"sdp" : sdpDesc };
    NSError *jsonError = nil;
    NSData *data = [WebRTCJSONSerialization dataWithJSONObject:json options:0 error:&jsonError];
    
    NSAssert(!jsonError, @"%@", [NSString stringWithFormat:@"Error: %@", jsonError.description]);
    
   // dispatch_async(dispatch_get_main_queue(), ^(void){
        
        /* NSTimer *_offertimer;
         _offertimer = [NSTimer scheduledTimerWithTimeInterval:OFFER_TIMEOUT
         target:self
         selector:@selector(_timerOffer:)
         userInfo:nil
         repeats:NO
         ];*/
        IRISLogInfo(@"didCreateSessionDescription sdp = %@",sdpDesc);
        
        if (sdp.type == RTCSdpTypeAnswer)
        {
          //  [self logEvents:@"SDK_AnswerSent" additionalinfo:nil];
            isAnswerSent = true;          
        }
        else
        {
            //isOfferSent = true;
            //[webrtcstack logToAnalytics:@"SDK_OfferSent"];
            offerJson  = @{ @"sdp" : sdpDesc};
        }
        
         if(callType == incoming)
        {
            //Sending all candidates together
            for (int i=0; i < [_allcandidates count]; i++)
            {
                NSDictionary *dict = _allcandidates[i];
                [self logEvents:@"SDK_XMPPJingleTransportInfoSent" additionalinfo:nil];
                [jingleHandler sendJingleMessage:@"transport-info" data:dict target:targetJid];
                
            }
            
            NSDictionary *json = @{ @"sdp" : sdpDesc };
            [self logEvents:@"SDK_XMPPJingleSessionAcceptSent" additionalinfo:nil];
            [jingleHandler sendJingleMessage:@"session-accept" data:[json copy] target:targetJid];
            
        }
        else if(_isVideoBridgeEnable)
        {
            NSDictionary *json = @{ @"sdp" : sdpDesc };
            [self logEvents:@"SDK_XMPPJingleSessionAcceptSent" additionalinfo:nil];
            [jingleHandler sendJingleMessage:@"session-accept" data:[json copy] target:targetJid];
            
            //[[XMPPWorker sharedInstance] sendVideoInfo:@"session-accept" data:[json copy] target:targetJid];
            
        }
        
   // });
    
}


// Called when setting a local or remote description.
- (void)peerConnection:(RTCPeerConnection *)arPeerConnection
didSetSessionDescriptionWithError:(NSError *)error
{
    if(error)
    {
        IRISLogInfo(@" didSetSessionDescriptionWithError SDP onFailure. %@", [error description]);
        [callSummary setObject:@"Failure" forKey:@"callStatus"];
        [callSummary setObject:[error description] forKey:@"CallFailureReason"];
        [self close];
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        NSString *string = [NSString stringWithFormat:@"Unable to set local or remote SDP : %@", [error description]];
        [details setValue:string forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_INVALID_SDP userInfo:details];
        [self onSessionError:error withAdditionalInfo:nil];
        self.sessionDelegate = nil;
        return;
        
    }
    
    //dispatch_async(dispatch_get_main_queue(), ^(void){
        
        //Add ICE candidates
        if (peerConnection.remoteDescription)
        {
            for (RTCIceCandidate *candidate in queuedRemoteCandidates)
            {
           //     LogDebug(@" Adding candidates to peerconnection %@", candidate.description);

               [peerConnection addIceCandidate:candidate];
            }
            queuedRemoteCandidates = nil;
        }
    //});
}



#pragma mark - DataChannel Delegate

// Called when the data channel state has changed.
- (void)dataChannelDidChangeState:(RTCDataChannel *)dataChannel
{
    IRISLogInfo(@"DataChannel::Inside channelDidChangeState");
    IRISLogInfo(@"channel.label = %@",dataChannel.label);
    IRISLogInfo(@"channel.state = %ld",(long)dataChannel.readyState);
    if(dataChannel.readyState == RTCDataChannelStateOpen)
    {
        isDataChannelOpened = true;
        if ([self.sessionDelegate respondsToSelector:@selector(onDataSessionConnected:)] )
        [self.sessionDelegate onDataSessionConnected:_roomId];
        [self logEvents:@"SDK_DataChannelOpened" additionalinfo:nil];
        
    }
    IRISLogInfo(@"channel.bufferedAmount = %lu",(unsigned long)dataChannel.bufferedAmount);
}

// Called when a data buffer was successfully received.
- (void)dataChannel:(RTCDataChannel *)dataChannel
didReceiveMessageWithBuffer:(RTCDataBuffer *)buffer
{
    NSData* dataBuff = [buffer data];
    IRISLogInfo(@"didReceiveMessageWithBuffer size = %lu",(unsigned long)[dataBuff length]);
    
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:dataBuff
                                                         options:kNilOptions
                                                           error:nil];
    IRISLogInfo(@"didReceiveMessageWithBuffer = %@",json);
    
 //   if([dataBuff length] < 500)
 //   {
    //    NSError* error;
    //    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:dataBuff
    //                                                         options:kNilOptions
    //                                                           error:&error];
        if(json == nil)
        {
            [concatenatedData appendData:dataBuff];
        }
        else
            if ([[json allKeys] containsObject:@"action"])
            {
                NSString* action  = [[json objectForKey:@"action"] lowercaseString];
                IRISLogInfo(@"DataChannel::Inside didReceiveMessageWithBuffer action = %@",action);
                if(![action compare:@"start"])
                {
                    recievedDataId = [json objectForKey:@"dataId"];
                    startTimeForDataSentStr = [json objectForKey:@"startTime"];
                    [concatenatedData setLength:0];
                    IRISLogInfo(@"didReceiveMessageWithBuffer: start recievedDataId= %@",recievedDataId);
                }
                else
                    if(![action compare:@"stop"])
                    {
                        NSString* stopDataId = [json objectForKey:@"dataId"];
                        NSDate* stopTimeForDataSent = [NSDate date];
                        IRISLogInfo(@"didReceiveMessageWithBuffer : stop recievedDataId = %@",recievedDataId);
                        IRISLogInfo(@"didReceiveMessageWithBuffer : stop total data length = %lu",
                              (unsigned long)[concatenatedData length]/1024);
                        NSDate* startTimeForDataSent = [dateFormatter dateFromString:startTimeForDataSentStr];
                        CGFloat differenceInSec = [stopTimeForDataSent timeIntervalSinceDate:startTimeForDataSent];
                        IRISLogInfo(@"didReceiveMessageWithBuffer:Total time for transfered file is = %f",differenceInSec);
                        
                        if(![stopDataId compare:recievedDataId])
                        {
                            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                            NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Image.jpg"];
                            [concatenatedData writeToFile:filePath atomically:YES];
                            if([self.sessionDelegate respondsToSelector:@selector(onSessionDataWithImage:roomId:)])
                            [self.sessionDelegate onSessionDataWithImage:filePath roomId:_roomId];
                            [concatenatedData setLength:0];
                        }
                        else
                        {
                            NSMutableDictionary* details = [NSMutableDictionary dictionary];
                            [details setValue:@"Data received is not complete" forKey:NSLocalizedDescriptionKey];
                            NSError *error = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_DATA_RECEIVED userInfo:details];
                            [self onSessionError:error withAdditionalInfo:nil];
                        }
                        
                    }
            }
            else{
                 if([json objectForKey:@"colibriClass"] != nil && [[json objectForKey:@"colibriClass"] isEqualToString:@"DominantSpeakerEndpointChangeEvent"]){
                     if([json objectForKey:@"dominantSpeakerEndpoint"] != nil &&  ([self.sessionDelegate respondsToSelector:@selector(onSessionDominantSpeakerChanged:roomId:traceId:)]))
                         [self.sessionDelegate onSessionDominantSpeakerChanged:[json objectForKey:@"dominantSpeakerEndpoint"] roomId:_roomId traceId:_traceId];
                }
                 else if([json objectForKey:@"colibriClass"] != nil && [[json objectForKey:@"colibriClass"] isEqualToString:@"LastNEndpointsChangeEvent"]){
                     if([json objectForKey:@"lastNEndpoints"] != nil){
                         
                         NSArray *participantId = [json objectForKey:@"lastNEndpoints"];
                         if(participantId != nil && participantId.count > 0 &&  ([self.sessionDelegate respondsToSelector:@selector(onSessionRemoteParticipantActivated:roomId:traceId:)])){
                             [self.sessionDelegate onSessionRemoteParticipantActivated:participantId[0] roomId:_roomId traceId:_traceId];
                         }
                         
                     }
                     
                 }
            }
/*    }
    else
    {
         [concatenatedData appendData:dataBuff];
    }
 */
    
}

- (void)dataChannel:(RTCDataChannel *)dataChannel
didChangeBufferedAmount:(uint64_t)amount
{
    
}

#pragma mark - XMPP session delegate

- (void)xmppWorker:(XMPPWorker *)sender didReceiveSessionInitiate:(NSString *)to  sid:(NSString*)sid;
{
    IRISLogInfo(@"xmppWorker : didReceiveSessionInitiate,");
}

- (void)xmppWorker:(XMPPWorker *)sender didReceiveSetRemoteDescription:(NSXMLElement*)jingle type:(NSString*)type;
{
    IRISLogInfo(@"xmppWorker : didReceiveSetRemoteDescription,");
}

- (void)xmppWorker:(XMPPWorker *)sender didReceiveAddIceCandidates:(NSXMLElement*)jingleContent;
{
    IRISLogInfo(@"xmppWorker : didReceiveAddIceCandidates,");
}

- (void)xmppWorker:(XMPPWorker *)sender didJoinRoom:(NSString*)roomName;
{
    IRISLogInfo(@"xmppWorker : didJoinRoom");
    
    //[[XMPPWorker sharedInstance] joinRoom:roomName appDelegate:self];
}

- (void)xmppWorker:(XMPPWorker *)sender didParticipantUnavailable:(NSString*)roomName participantName:(NSString*)name{
   
    /*dispatch_async(dispatch_get_main_queue(), ^(void)
                   {[self close];
    });*/
    
   // [self.sessionDelegate onSessionParticipantNotReachable:roomName  participantName:name];
}



//XMPP: Incoming file path for sharecast
- (void)xmppWorker:(XMPPWorker *)sender didReceiveFileWithPath:(NSString *)filePath
{
    IRISLogInfo(@"xmppWorker : didReceiveFileWithPath");
    
  //  [self.sessionDelegate onSessionDataWithImage:filePath];
    
}

- (void)xmppWorker:(XMPPWorker *)sender didFailWithError:(NSError *)error
{
    IRISLogInfo(@"xmppWorker : didFailWithError");
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:error.description forKey:NSLocalizedDescriptionKey];
    NSError *err = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_DATA_RECEIVED userInfo:details];
 
    [self onSessionError:error withAdditionalInfo:nil];
    
}

//xmpp connection error
-(void)onIrisXMPPRoomError:(NSString*)errorDesc _errorCode:(NSInteger)errorCode;
{
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:errorDesc forKey:NSLocalizedDescriptionKey];
    NSError *err = [NSError errorWithDomain:IrisRtcSessionTag code:errorCode userInfo:details];
    [callSummary setObject:@"Failure" forKey:@"callStatus"];
    [callSummary setObject:errorDesc forKey:@"CallFailureReason"];
     [self onSessionError:err withAdditionalInfo:nil];
    
}
#pragma mark - Iris XMPP Stream delegate
- (void)xmppStream:(XMPPStream *)sender onSessionError:(NSError *)error additionalInfo:(NSDictionary *)info{
    //IRISLogInfo(@"Iris XMPP Stream delegate : onSessionError");
    [callSummary setObject:@"Failure" forKey:@"callStatus"];
    [callSummary setObject:error.localizedDescription forKey:@"CallFailureReason"];
    if(error.code == ERR_XMPP_NOACK){
         [self logEvents:@"SDK_XMPPNOACK" additionalinfo:info];        
    }else{
        [self onSessionError:error withAdditionalInfo:nil];
    }
}

#pragma mark - Iris XMPP room delegate

- (void)xmppRoomDidCreate
{
    IRISLogInfo(@"XMPP Stack : xmppRoomDidCreate");
    [self logEvents:@"SDK_XMPPRoomCreated" additionalinfo:nil];
    
    // [self.xmppRoom changeRoomSubject:self.roomSubject];
    
}

- (void)xmppRoomDidJoin
{
    IRISLogInfo(@"XMPP Stack : xmppRoomDidJoin:startCallType = %d isOccupantJoined = %d",startCallType,isOccupantJoined);
    
    if(startCallType == incoming){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if(!isOccupantJoined){
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                [details setValue:@"Remote participant already left" forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_PARTICIPANT_ALREADY_LEFT userInfo:details];
                [self onSessionError:error withAdditionalInfo:nil];
                return;
                }
            });
        }

    [irisRoom startPeriodicPresenceTimer];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    [dict setObject:_roomId forKey:@"roomName"];
    
    
    //[[XMPPWorker sharedInstance] activateJingle:self];
    [self logEvents:@"SDK_XMPPJoined" additionalinfo:dict];
    if([self.sessionDelegate respondsToSelector:@selector(onSessionJoined:traceId:)])
        [self.sessionDelegate onSessionJoined:_roomId traceId:_traceId];
    isXMPPJoined = true;
    [[XMPPWorker sharedInstance]setIsRoomJoined:true];
    //[self startSessionValidateTimer];
    
    if(_isVideoBridgeEnable){
    //if(sender.isModerator)
    if(!isOccupantJoined)
    {
        IRISLogInfo(@"xmppRoomDidJoin::outgoing");
        callType = outgoing;
    }
    else
    {
        IRISLogInfo(@"xmppRoomDidJoin::incoming");
        callType = incoming;
    }
    }
    
    if(_sessionType == kSessionTypePSTN && startCallType == outgoing && isFocusJoined && !isSessionRestarted)
    {
        //sesionconfig     
       [self startPSTNCall:self.targetPhoneNum];
    }
    
    if (!_isVideoBridgeEnable)
    {
        IRISLogInfo(@"XMPP Stack : starting session in xmppRoomDidJoin");
        [self startSession:updatedIceServers];
    }
}



- (void)occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    IRISLogInfo(@"XMPP Stack : xmppRoom occupantDidJoin %@ with presence %@", [occupantJID bare], [presence description]);
    
    if(participantsDict != nil)
    {
        IRISLogInfo(@"occupantDidJoin::Number of participant = %d",[participantsDict count]);
    }
   
    //if (webrtcstack.isVideoBridgeEnable)
    {
        if ([[occupantJID full] containsString:@"focus"] || [[occupantJID full] containsString:@"xrtc_sp00f_f0cus"])
        {
            // Note down the occupant JID
            
            if(!isFocusJoined){
                targetJid = occupantJID;
                [self logEvents:@"SDK_XMPPFocusJoined" additionalinfo:nil];
                isFocusJoined = true;
            
            
            if(_sessionType == kSessionTypePSTN && startCallType == outgoing && isXMPPJoined && !isSessionRestarted)
            {
                //sesionconfig
                IRISLogInfo(@"Sending dial IQ after focus joined");
                [self startPSTNCall:self.targetPhoneNum];
            }
                
            }
            
            
        }
        else
        {
            participantJid =[presence from];
            
            //Added "pstnTargetJid" to get the correct targetId for Hold/Unhold/Hangup Iqs
            NSString* from =[[presence from] description];
            IRISLogInfo(@"OccupantDidJoin::from = %@",from);
            IRISLogInfo(@"OccupantDidJoin::myRoutingId = %@",[[[XMPPWorker sharedInstance] userJid] bare]);
            if( ![from containsString:[[[XMPPWorker sharedInstance] userJid] bare] ]){
                IRISLogInfo(@"OccupantDidJoin::joined");
            isOccupantJoined = true;
            }
                
            NSString* routingId = [[XMPPWorker sharedInstance] routingId];
            if(![from containsString:routingId] && ([from containsString:@"inbound"] || [from containsString:@"outbound"]) ){
                pstnTargetJid = [presence from];
            }
            
            
            
            if ([presence elementForName:@"media"] )
            {
                [self logEvents:@"SDK_XMPPOccupantHasStreams" additionalinfo:nil];
                
            }
            //else
            //{
                
                NSDate *date;
                date = [presenceDateFormatter dateFromString:[presenceDateFormatter stringFromDate:[NSDate date]]];
                IRISLogInfo(@"occupantDidJoin::presence:from = %@",[presence from] );
                NSString *name,*avatarUrl;
                IrisRtcParticipant* participant;
                
                if(![participantsDict objectForKey:[occupantJID resource]]){
                        IRISLogInfo(@"occupantDidJoin::adding participant = %@",[presence from] );
                    //    participant =[[IrisRtcParticipant alloc]initWithParticipant:[occupantJID resource] timeElapse:date];
                    participant =[[IrisRtcParticipant alloc] init];
                    [participant setParticipantId:[occupantJID resource]];
                    [participant setTimeElapse:date];
                    
                    NSXMLElement *nick = [presence elementForName:@"nick"];
                    
                    if(nick != nil){
                        
                        IrisRtcUserProfile *userprofile = [[IrisRtcUserProfile alloc]init];
                        
                        if([nick attributeStringValueForName:@"name"] != nil){
                            name = [nick attributeStringValueForName:@"name"];
                            [userprofile setName:[nick attributeStringValueForName:@"name"]];
                            [participant setName:name];
                        }
                        
                        
                        if([nick attributeStringValueForName:@"avatar"] != nil){
                            avatarUrl = [nick attributeStringValueForName:@"avatar"];
                            [userprofile setAvatarUrl:[nick attributeStringValueForName:@"avatar"]];
                            [participant setAvatarUrl:avatarUrl];
                        }
                        if([self.sessionDelegate respondsToSelector:@selector(onSessionParticipantProfile:userProfile:roomId:traceId:)])
                            [self.sessionDelegate onSessionParticipantProfile:[occupantJID resource] userProfile:userprofile roomId:_roomId traceId:_traceId];
                        
                        
                    }
                    
                    if([presence sessionType] != nil){
                        [participant setEventType:[presence sessionType]];
                        if ([self.sessionDelegate respondsToSelector:@selector(onSessionTypeChanged:participantId:roomId:traceId:)]) {
                            [self.sessionDelegate onSessionTypeChanged:[presence sessionType] participantId:[occupantJID resource] roomId:_roomId traceId:_traceId];
                        }
                    }
                    
                    NSXMLElement *audiomute = [presence elementForName:@"audiomuted"];
                    if(audiomute){
                        [participant setAudioMute:[audiomute stringValueAsBool]];
                        if([self.sessionDelegate respondsToSelector:@selector(onSessionParticipantAudioMuted:participantId:roomId:traceId:)])
                            [self.sessionDelegate onSessionParticipantAudioMuted:[audiomute stringValueAsBool] participantId:[occupantJID resource] roomId:_roomId traceId:_traceId];
                    }
                    
                    NSXMLElement *videomute = [presence elementForName:@"videomuted"];
                    if(videomute){
                        [participant setVideoMute:[videomute stringValueAsBool]];
                        if([self.sessionDelegate respondsToSelector:@selector(onSessionParticipantVideoMuted:participantId:roomId:traceId:)])
                            [self.sessionDelegate onSessionParticipantVideoMuted:[videomute stringValueAsBool] participantId:[occupantJID resource] roomId:_roomId traceId:_traceId];
                    }
                    
                    
                    
                }
                else{
                    participant = [participantsDict objectForKey:[occupantJID resource]];
                    
                    NSXMLElement *nick = [presence elementForName:@"nick"];
                    
                    if(nick != nil){
                        
                        IrisRtcUserProfile *userprofile = [[IrisRtcUserProfile alloc]init];
                        
                        
                        if([nick attributeStringValueForName:@"name"] != nil){
                            name = [nick attributeStringValueForName:@"name"];
                            [userprofile setName:[nick attributeStringValueForName:@"name"]];
                        }
                        
                        
                        if([nick attributeStringValueForName:@"avatar"] != nil){
                            avatarUrl = [nick attributeStringValueForName:@"avatar"];
                            [userprofile setAvatarUrl:[nick attributeStringValueForName:@"avatar"]];
                        }
                        
                        
                        if((![participant.name isEqualToString: name]) || (![participant.avatarUrl isEqualToString: avatarUrl])){
                            [participant setName:name];
                            [participant setAvatarUrl:avatarUrl];
                            if([self.sessionDelegate respondsToSelector:@selector(onSessionParticipantProfile:userProfile:roomId:traceId:)])
                                [self.sessionDelegate onSessionParticipantProfile:[occupantJID resource] userProfile:userprofile roomId:_roomId traceId:_traceId];
                            
                            
                        }
                        
                    }
                    [participant setTimeElapse:date];
                    
                    
                    
                    if(![[participant eventType] isEqualToString: [presence sessionType]]){
                        
                        [participant setEventType:[presence sessionType]];
                        
                        if ([self.sessionDelegate respondsToSelector:@selector(onSessionTypeChanged:participantId:roomId:traceId:)]) {
                            
                            [self.sessionDelegate onSessionTypeChanged:[presence sessionType] participantId:[occupantJID resource] roomId:_roomId traceId:_traceId];
                        }
                    }
                    
                    
                    
                    NSXMLElement *audiomuteelem = [presence elementForName:@"audiomuted"];
                    if(audiomuteelem && !([participant audioMute] == [audiomuteelem stringValueAsBool])){
                        
                      
                        [participant setAudioMute:[audiomuteelem stringValueAsBool]];
                        if([self.sessionDelegate respondsToSelector:@selector(onSessionParticipantAudioMuted:participantId:roomId:traceId:)])
                            [self.sessionDelegate onSessionParticipantAudioMuted:[audiomuteelem stringValueAsBool] participantId:[occupantJID resource] roomId:_roomId traceId:_traceId];
                    }
                    
                    NSXMLElement *videomuteelem = [presence elementForName:@"videomuted"];
                    if(videomuteelem && !([participant videoMute] == [videomuteelem stringValueAsBool])){
                        
                       
                        [participant setVideoMute:[videomuteelem stringValueAsBool]];
                        if([self.sessionDelegate respondsToSelector:@selector(onSessionParticipantVideoMuted:participantId:roomId:traceId:)])
                            [self.sessionDelegate onSessionParticipantVideoMuted:[videomuteelem stringValueAsBool] participantId:[occupantJID resource] roomId:_roomId traceId:_traceId];
                    }
                    
                    [participantsDict setObject:participant forKey:[occupantJID resource]];
                    
                }
                
                
                if(![participantsDict objectForKey:[occupantJID resource]]){
              
                    
                    if(!isParticipantJoined) {
                        isParticipantJoined = true;
                        [self startPresencetTimer:PARTICIPANT_PRESENCE_CHECK_TIMEINTERVAL];
                    }
                    
                    if(_sessionType == kSessionTypePSTN && (![[occupantJID resource] containsString:@"inbound"] && ![[occupantJID resource] containsString:@"outbound"])){
                        participantRoutingid = [occupantJID resource];
                    }
                    
                   
                    NSXMLElement *data = [presence elementForName:@"data"];
                    if(data != nil)
                    {
                        NSString *oldjid = [[data attributeForName:@"oldjid"] stringValue];
                        if(oldjid != nil)
                        {
                            if(participantsDict != nil  && [[participantsDict allKeys] containsObject:oldjid]){
                                [participantsDict removeObjectForKey:oldjid];
                            }
                        }
                    }
                    
                    
                    
                    if(![[occupantJID resource] isEqualToString:[[XMPPWorker sharedInstance] oldjid]]){
                         [participantsDict setObject:participant forKey:[occupantJID resource]];
                    }    
                    
                   
                  
                /*NSXMLElement *x = [presence elementForName:@"x" xmlns:XMPPMUCUserNamespace];
                //Girish: set traceid at pariticipant end with traceid of moderator
                for (NSXMLElement *item in [x elementsForName:@"item"])
                {
                    
                    
                    if ([[item attributeStringValueForName:@"role"]isEqualToString:@"moderator"])
                    {
                        
                    }
                }*/
                
                
               
                if (!_isVideoBridgeEnable)
                    targetJid = occupantJID;
                
                NSMutableDictionary *userinfo = [[NSMutableDictionary alloc]init];
               // [userinfo setObject:[NSString stringWithFormat:@"%@",sender.myRoomJID] forKey:@"user_jid"];
                [userinfo setObject:@"participant" forKey:@"user_role"];
                
                NSMutableArray *array = [[NSMutableArray alloc]init];
                [array setObject:userinfo atIndexedSubscript:0];
                
                NSMutableDictionary *participantinfo =[[NSMutableDictionary alloc]init];
                [participantinfo setObject:array forKey:@"participantInfo"];
                if([occupantJID resource]!=nil)
                [participantinfo setObject:[occupantJID resource] forKey:@"participantId"];
                
                [self logEvents:@"SDK_XMPPOccupantJoined" additionalinfo:participantinfo];
                
                /* Let the app know who has the joined the participant */
                if (self.sessionDelegate != nil)
                {
                    IRISLogInfo(@"occupant resource %@",[occupantJID resource]);
                 if([self.sessionDelegate respondsToSelector:@selector(onSessionParticipantJoined:roomId:traceId:)])
                     [self.sessionDelegate onSessionParticipantJoined:[occupantJID resource] roomId:_roomId traceId:_traceId];
                    
                }
                
                if(callType != incoming && !_isVideoBridgeEnable && !isOfferSent)
                {
                    [jingleHandler sendJingleMessage:@"session-initiate" data:offerJson target:targetJid];
                    
                    isOfferSent = true;
                    [self logEvents:@"SDK_OfferSent" additionalinfo:nil];
                                       //for (id data in iceCandidates){
                    //    [self sendMessage:data];
                    //}
                    
                    //[iceCandidates removeAllObjects];
                }
                
            }
               
            
            //}
            
        }
    }
    /*else
     {
     // Note down the occupant JID
     targetJid = occupantJID;
     
     [webrtcstack logToAnalytics:@"SDK_XMPPOccupantJoined"];
     / Let the app know who has the joined the participant /
     if (self.sessionDelegate != nil)
     {
     [self.sessionDelegate onXmppParticipantJoined: [occupantJID resource]];
     }
     
     // If this is a pull call, send the session-initiate message
     if ((callType != incoming) && !dataSessionActive)
     {
     dataSessionActive = true;
     [self startSession:updatedIceServers];
     }
     }*/
}

-(void)startPresencetTimer:(NSInteger)interval
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if(participantPresenceTimer != nil){
            [participantPresenceTimer invalidate];
        }
        
        participantPresenceTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                       target:self
                                                     selector:@selector(checkParticipantPresence)
                                                     userInfo:nil
                                                      repeats:YES
                       ];
    });
    
}

-(void)checkParticipantPresence{
    
    if(participantsDict != nil){
        
        for(id key in participantsDict)
        {
            if(![key containsString:@"inbound"] && ![key containsString:@"outbound"]){
                IrisRtcParticipant* participant;
                
                participant = [participantsDict objectForKey:key];
                
                NSDate *date;
                date = [presenceDateFormatter dateFromString:[presenceDateFormatter stringFromDate:[NSDate date]]];
                
                NSDate *participantTimeElapse = participant.timeElapse;
                
                NSTimeInterval  timeElapse= [date timeIntervalSinceDate:participantTimeElapse];
                
                if(timeElapse > PARTICIPANT_PRESENCE_CHECK_TIMEINTERVAL &&  ([self.sessionDelegate respondsToSelector:@selector(onSessionParticipantNotResponding:roomId:traceId:)])){
                    [self.sessionDelegate onSessionParticipantNotResponding:participant.participantId roomId:_roomId traceId:_traceId];
                }            
            }
        }
    }
}


-(void)startMonitoringStats:(id)delegate{
    
    self.statsDelegate = delegate;
    
}

-(NSMutableArray *)getstats{
    
    return [stats getstats];
}

-(void)onSessionParticipantConnected{
    
}


- (void)occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    IRISLogInfo(@"XMPP Stack : xmppRoom occupantDidLeave %@ objectId = %@", [occupantJID resource],self);
    if(participantsDict != nil){
        IRISLogInfo(@"occupantDidLeave::participant count 11= %d",[participantsDict count]);
    }
    if ([[occupantJID full] containsString:@"focus"] || [[occupantJID full] containsString:@"xrtc_sp00f_f0cus"])
    {
        // Note down the occupant JID
        [self logEvents:@"SDK_XMPPFocusLeft" additionalinfo:nil];
        isFocusJoined = false;
        return;
    }
    
    
    NSMutableDictionary *participantinfo =[[NSMutableDictionary alloc]init];
    if([occupantJID resource]!=nil)
    [participantinfo setObject:[occupantJID resource] forKey:@"participantId"];
    
    [self logEvents:@"SDK_XMPPOccupantLeft" additionalinfo:participantinfo];
    
    /* Let the app know who has the joined the participant */
    if (self.sessionDelegate != nil)
    {
       if([self.sessionDelegate respondsToSelector:@selector(onSessionParticipantLeft:roomId:traceId:)])
           [self.sessionDelegate onSessionParticipantLeft:[occupantJID resource] roomId:_roomId traceId:_traceId];
    }
    

    if ([[occupantJID full] containsString:@"jirecon"])
    {
            return;
    }

    //For SDK to SDK call, call should end if actual remote participant leave the room
    
    //Close session
    if([participantsDict objectForKey:[occupantJID resource]]){
        IRISLogInfo(@"occupantDidLeave::Removing = %@",[occupantJID resource]);
        [participantsDict removeObjectForKey:[occupantJID resource]];
        IRISLogInfo(@"occupantDidLeave::participant count 22= %lu",(unsigned long)[participantsDict count]);
        //for SDK to SDK call ending session with remote aprticipant leave
        if(([self isRemoteSDKParticipant:[occupantJID description]] && [self hasInboundOutboundParitcipants]) || [participantsDict count] < 1){
            
                [_statsCollector stopMetric:@"callDuration"];
                if (_autoDisconnect && [self hasNoActiveParticipants]){
                    IRISLogInfo(@"occupantDidLeave:disconnect:participant count 33= %lu",(unsigned long)[participantsDict count]);
                    if(_sessionType ==kSessionTypePSTN){
                        [self didReceiveSIPStatus:@"" status:@"Disconnected"];
                    }
                    [self disconnect];
                }
            
        }
        
        
    }
 
    //[self.sessionDelegate onSessionEnded:self sessionId:_roomId];
   
//    [_statsCollector stopMetric:@"callDuration"];

//    if(_statsTimer != nil)
//        [_statsTimer invalidate];
//    
//    state = inactive;
//    [self disconnect];
    
}

-(BOOL)isRemoteSDKParticipant:(NSString*)participantId{
    
    if([participantId containsString:@"inbound"] ||
       [participantId containsString:@"outbound"] ||
       [participantId containsString:[[[XMPPWorker sharedInstance] userJid] bare] ]){
       return false;
           
       }
       
       return true;
}
- (void)didReceiveIrisMessage:(IrisChatMessage *)message fromOccupant:(XMPPJID *)occupantJID
{
    IRISLogInfo(@"XMPP Stack : xmppRoom didReceiveMessage = %@",[message data]);
    if([self.sessionDelegate respondsToSelector:@selector(onSessionParticipantMessage:participantId:roomId:traceId:)])
    [self.sessionDelegate onSessionParticipantMessage:message participantId:[occupantJID routingId] roomId:[occupantJID user] traceId:_traceId];
    
  //  [self.sessionDelegate onChatMessage:message participantId:[occupantJID routingId] roomId:[occupantJID user]];
    
}


- (void)didReceiveIrisAckMessage:(IrisChatMessage *)ack responseCode:(int)responseCode
{
    IRISLogInfo(@"XMPP Stack : xmppRoom didReceiveAckMessage");
    
    if(responseCode == 200){
      if([self.sessionDelegate respondsToSelector:@selector(onChatMessageSuccess:roomId:traceId:)])
        [self.sessionDelegate onChatMessageSuccess:ack roomId:_roomId traceId:_traceId];
    }else{
       if([self.sessionDelegate respondsToSelector:@selector(onChatMessageError:withAdditionalInfo:roomId:traceId:)])
        [self.sessionDelegate onChatMessageError:[ack messageId] withAdditionalInfo:nil roomId:_roomId traceId:_traceId];
    }
    
    
}

- (void)didReceiveIrisChatState:(IrisChatState)state fromOccupant:(XMPPJID *)occupantJID{
    IRISLogInfo(@"XMPP Stack : xmppRoom didReceiveChatState");
     if ([self.sessionDelegate respondsToSelector:@selector(onChatMessageState:participantId:roomId:traceId:)]) {
         [self.sessionDelegate onChatMessageState:state participantId:[occupantJID routingId] roomId:[occupantJID user] traceId:_traceId];
     }
    
}

- (void)didReceiveIrisStartVideoMessage{
    if(localstream != nil){
    [localstream startPreview];
    [self onVideoMute:false];
    }
}

- (void)didReceiveIrisStopVideoMessage{
    if(localstream != nil){
     [localstream stopPreview];
    [self onVideoMute:true];
    }
}

-(void)didReceiveIrisHoldAudioMessage:(NSString *)routingId{
       if(peerConnection != nil){
        isRemoteHold = true;
        IRISLogInfo(@"IrisRtcJingleSession::didReceiveIrisHoldAudioMessage");
        [peerConnection removeStream:[localstream getMediaStream]];
        /*if([self.sessionDelegate respondsToSelector:@selector(onSessionSIPStatus:roomId:)])
            [self.sessionDelegate onSessionSIPStatus:kHold roomId:_roomId];*/
    }
}
-(void)didReceiveIrisUnholdAudioMessage:(NSString *)routingId{
    if(peerConnection != nil){
        isRemoteHold = false;
        IRISLogInfo(@"IrisRtcJingleSession::didReceiveIrisUnholdAudioMessage");
        if(!isLocalHold)
         [peerConnection addStream:[localstream getMediaStream]];
        /*if([self.sessionDelegate respondsToSelector:@selector(onSessionSIPStatus:roomId:)])
            [self.sessionDelegate onSessionSIPStatus:kHold roomId:_roomId];*/
    }
}



-(void)didReceiveIrisLeaveRoomMessage:(NSString *)roomId{
    
    if(roomId != nil && ![[[[[XMPPWorker sharedInstance]activeSessions]objectForKey:roomId]getSessionType]  isEqual: @"groupchat"]){
        isReceivedLeaveRoomMessage = true;
    }else{
        [self disconnect];
    }
    
}

#pragma mark - XMPP Jingle delegate

// For Action (type) attribute: "session-accept", "session-info", "session-initiate", "session-terminate"
- (void)didReceiveSessionMsg:(NSString *)sid type:(NSString *)type data:(NSDictionary *)data
{
    //IRISLogInfo(@"XMPP Stack : xmppJingle didReceiveSessionMsg of type %@ with session id %@ with data %@", type, sid, data);
    
    // Check the type of the message
    // For session-initiate, treat as incoming call and start the session
    // For session-accept, treat as outgoing call and set the answer SDP
    // For session-terminate, treat as bye message
    if ([type isEqualToString:@"session-accept"])
    {
        [self logEvents:@"SDK_XMPPJingleSessionAcceptReceived" additionalinfo:nil];
        
        [self onAnswerMessage:data];
    }
    else if ([type isEqualToString:@"session-initiate"])
    {
        [self logEvents:@"SDK_XMPPJingleSessionInitiateReceived" additionalinfo:nil];
        
        [self onOfferMessage:data];
    }
    else if ([type isEqualToString:@"source-add"])
    {
        
        [self logEvents:@"SDK_XMPPJingleSourceAddReceived" additionalinfo:nil];
        // Storing the data to retrieve further after recieving iceserver
        peerConnectionId = [data objectForKey:@"peerConnectionId"];
        initialSDP = data;
        
        //Parse SDP string
        NSString *tempSdp = [initialSDP objectForKey:@"sdp"];
        
        if(tempSdp != nil){
            
            NSString *backslashString = [tempSdp stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
            NSString *backslashrString = [backslashString stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
            NSString *forwardslashrString = [backslashrString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
            NSString *sdpString = [forwardslashrString stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
            
            IRISLogInfo(@"setting source-add SDP = %@",sdpString);
            
            RTCSessionDescription *sdp = [[RTCSessionDescription alloc]
                                          initWithType:RTCSdpTypeOffer sdp:[self preferISAC:sdpString]];
            
            // dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            __weak IrisRtcJingleSession *weakSelf = self;
            [peerConnection setRemoteDescription:sdp
                               completionHandler:^(NSError *error) {
                                   IrisRtcJingleSession *strongSelf = weakSelf;
                                   [strongSelf peerConnection:strongSelf->peerConnection
                            didSetSessionDescriptionWithError:error];
                               }];
            
            
            
        }
        
    }
    else if ([type isEqualToString:@"source-remove"])
    {
        IRISLogInfo(@"WebRTCSession:didReceiveSessionMsg:source-remove");
       
        [self logEvents:@"SDK_XMPPJingleSourceRemoveReceived" additionalinfo:nil];
        // Storing the data to retrieve further after recieving iceserver
        peerConnectionId = [data objectForKey:@"peerConnectionId"];
        initialSDP = data;
        
        //Parse SDP string
        NSString *tempSdp = [initialSDP objectForKey:@"sdp"];
        
        if(tempSdp != nil){
            
            NSString *backslashString = [tempSdp stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
            NSString *backslashrString = [backslashString stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
            NSString *forwardslashrString = [backslashrString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
            NSString *sdpString = [forwardslashrString stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
            
            IRISLogInfo(@"setting source-remove SDP = %@",sdpString);
            
            RTCSessionDescription *sdp = [[RTCSessionDescription alloc]
                                          initWithType:RTCSdpTypeOffer sdp:[self preferISAC:sdpString]];
            
            // dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            __weak IrisRtcJingleSession *weakSelf = self;
            [peerConnection setRemoteDescription:sdp
                               completionHandler:^(NSError *error) {
                                   IrisRtcJingleSession *strongSelf = weakSelf;
                                   [strongSelf peerConnection:strongSelf->peerConnection
                            didSetSessionDescriptionWithError:error];
                               }];
 
            
        }
        
    }
}

// For Action (type) attribute: "transport-accept", "transport-info", "transport-reject", "transport-replace"
- (void)didReceiveTransportMsg:(NSString *)sid type:(NSString *)type data:(NSDictionary *)data
{
    IRISLogInfo(@"XMPP Stack : xmppJingle didReceiveTransportMsg %@", data);
    
    if ([type isEqualToString:@"transport-info"])
    {
      
        [self logEvents:@"SDK_XMPPTransportInfoReceived" additionalinfo:nil];
        
        [self onCandidateMessage:data];
    }
    
}

// For Action (type) attribute: "content-accept", "content-add", "content-modify", "content-reject", "content-remove"
- (void)didReceiveContentMsg:(NSString *)sid type:(NSString *)type data:(NSDictionary *)data
{
    IRISLogInfo(@"XMPP Stack : xmppJingle didReceiveContentMsg");
    
}

// For Action (type) attribute: "description-info"
- (void)didReceiveDescriptionMsg:(NSString *)sid type:(NSString *)type data:(NSDictionary *)data
{
    IRISLogInfo(@"XMPP Stack : xmppJingle didReceiveDescriptionMsg");
    
}

//For Action(type) attribute: "mute","unmute","video on","video off"
-(void)didReceiveMediaPresenceMsg:(NSString*)msg{
   
  //  [self.sessionDelegate onConfigMessage_xcmav:msg];
}

-(void)didReceiveParticipantProfilePresenceMsg:(NSString *)routingID  userProfile:(IrisRtcUserProfile*)userprofile{
    
 //   [self.sessionDelegate onSessionParticipantProfile:routingID userProfile:userprofile roomId:_roomId];
    
}

// For Action(type) attritbute: "pstn call status"
-(void)didReceiveSIPStatus:(NSString *)routingID  status:(NSString*)status{
    
    IRISLogInfo(@"didReceiveSIPStatus for object = %@ is = %@",self,status);
    
    BOOL isHoldCall = false;
    
    if([status containsString:sipstatus(kDisconnected)]){
        
        _sipStatus = kDisconnected;
        if(startCallType != incoming){
            IRISLogInfo(@"dicdReceiveSIPStatus stopRingTimer 11= %@",_traceId);
        [self stopRingTimer];
        }
        
    }else if([status containsString:sipstatus(kConnected)]){
       
        [_statsCollector startMetric:@"callDuration"];
        if (_sipStatus == kHold){
            isHoldCall = true;
        }
        _sipStatus = kConnected;
        if(startCallType != incoming){
            IRISLogInfo(@"didReceiveSIPStatus stopRingTimer 22= %@",_traceId);
        [self stopRingTimer];
        }
        
    }else if([status containsString:sipstatus(kConnecting)]){
        
        if(startCallType != incoming){
        if(!isStartedRingTimer){
            isStartedRingTimer = true;
            IRISLogInfo(@"didReceiveSIPStatus startRingTimer 33= %@",_traceId);
            [self startRingTimer];
        }
        NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"*"];
        if ([status rangeOfCharacterFromSet:cset].location != NSNotFound) {
            if([self.sessionDelegate respondsToSelector:@selector(onSessionEarlyMedia:traceId:)])
                [self.sessionDelegate onSessionEarlyMedia:_roomId traceId:_traceId];
            if(isDialTonePlaying){
                IRISLogInfo(@"didReceiveSIPStatus stopRingTimer 44= %@",_traceId);
                [_ringTimer invalidate];
                [self stopRingTimer];
                _ringTimer = nil;
                isStartedRingTimer = false;
            }
            isDialTonePlaying = true;
        }
        }
        _sipStatus = kConnecting;
        
    }else if([status containsString:@"Ringing"]){
        if(startCallType != incoming){
            IRISLogInfo(@"didReceiveSIPStatus playRingTone 55= %@",_traceId);
        [self playRingTone];
        }
        return;
        //_sipStatus = kRinging;
        
    }else if([status containsString:sipstatus(kInitializing)]){
        _sipStatus = kInitializing;
    }
    else if([status containsString:sipstatus(kHold)]){
        _sipStatus = kHold;
    }
    
    if(_sipStatus == kHold || isHoldCall == true) {
        IRISLogInfo(@"Ignoring Hold/unhold case");
    } else {
        if([self.sessionDelegate respondsToSelector:@selector(onSessionSIPStatus:roomId:traceId:)])
            [self.sessionDelegate onSessionSIPStatus:_sipStatus roomId:_roomId traceId:_traceId];
        [self logEvents:[self SipStatusStateTypeToString:_sipStatus] additionalinfo:nil];
    }
    
    if(_sipStatus == kConnected && !isStreamStatusUpdated){
        isStreamStatusUpdated = true;
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self getStreamQuality:nil];
        });
    }
  
}

-(void)stopRingTimer {
    
    didStopDialTone = true;
    IRISLogInfo(@"didReceiveSIPStatus:Stoping  ringTonePlayer traceId = %@",_traceId);
    if(ringTonePlayer != nil){
        IRISLogInfo(@"didReceiveSIPStatus:Stoping  ringTonePlayer 11 = %@",_traceId);
    [ringTonePlayer stop];
        ringTonePlayer = nil;
    }
    if(_ringTimer != nil){
        IRISLogInfo(@"didReceiveSIPStatus:Stoping  ringTonePlayer 22 = %@",_traceId);
        [_ringTimer invalidate];
        _ringTimer  = nil;
        isStartedRingTimer = false;
    }
    isDialTonePlaying = false;
}



- (void)startRingTimer {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
 IRISLogInfo(@"didReceiveSIPStatus:startRingTimer 11 = %@",_traceId);
        _ringTimer = [NSTimer scheduledTimerWithTimeInterval:3
                                                       target:self
                                                     selector:@selector(playRingTone)
                                                     userInfo:nil
                                                      repeats:NO
                       ];
    });

}

-(void)playRingTone {
    
    if(didStopDialTone){
        IRISLogInfo(@"didReceiveSIPStatus:playRingTone stopped = %@",_traceId);
        return;
    }
    
    if(!isDialTonePlaying){
        IRISLogInfo(@"didReceiveSIPStatus:Inside playRingTone = %@",_traceId);
        isDialTonePlaying = true;
        NSError *error;
        NSBundle *frameworkBundle = [NSBundle bundleForClass:[self class]];
        NSString *resourcePath = [frameworkBundle pathForResource:@"dialtone" ofType:@"mp3"];
        
        NSURL *soundUrl = [NSURL fileURLWithPath:resourcePath];
        ringTonePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:&error];
        
        if (error)
        {
            IRISLogInfo(@"didReceiveSIPStatus:Inside playRingTone error 11 = %@",_traceId);
            IRISLogError(@"Error in audioPlayer: %@",
                  [error localizedDescription]);
        } else {
            IRISLogInfo(@"didReceiveSIPStatus:Inside playRingTone 11 = %@",_traceId);
            [ringTonePlayer enableRate];
            [ringTonePlayer prepareToPlay];
            [ringTonePlayer setVolume:1.0];
            //[ringTonePlayer setRate:1];
            [ringTonePlayer setNumberOfLoops:-1];
            [ringTonePlayer play];
        }
    }
}


// In case any error is received
- (void)didReceiveError:(NSString *)sid error:(NSDictionary *)data
{
    IRISLogError(@"XMPP Stack : xmppJingle didReceiveError");
    NSError *error = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_XMPP_ERROR userInfo:data];
    [callSummary setObject:@"Failure" forKey:@"callStatus"];
    [callSummary setObject:error.localizedDescription forKey:@"CallFailureReason"];
    [self onSessionError:error withAdditionalInfo:nil];
    
}


- (void)onXmppServerConnected
{
    [self logEvents:@"SDK_XMPPServerConnected" additionalinfo:nil];
}


-(void)logEvents:(NSString *)event additionalinfo:(NSMutableDictionary *)info{
    
    IRISLogInfo(@"Log Analytics: Event = %@:: TraceId = %@:: RoomId = %@ obj = %@ statsObjId = %@",event,_traceId, _roomId,self,stats);
    if([self.sessionDelegate respondsToSelector:@selector(onLogAnalytics:roomId:traceId:)])
        [self.sessionDelegate onLogAnalytics:event roomId:_roomId traceId:_traceId];

     //dispatch_async(dispatch_get_main_queue(), ^(void){
    
         IRISLogInfo(@"logEvents::statsObjId = %@",stats);
//         NSDate* date = [dateFormatter dateFromString:[dateFormatter stringFromDate:[NSDate date]]];
//         NSString *timestamp = [NSString stringWithFormat:@"%@",date];
         if(stats == nil)
             return;
         NSMutableDictionary* jsonPayload = [[NSMutableDictionary alloc]init];
         
         
         NSDateFormatter *isoDateFormatter = [[NSDateFormatter alloc] init];
         NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
         [isoDateFormatter setTimeZone:timeZone];
         [isoDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
         
         NSDate *now = [NSDate date];
         NSString *timestamp = [isoDateFormatter stringFromDate:now];
        
         [jsonPayload setObject:event forKey:@"n"];
         [jsonPayload setObject:timestamp forKey:@"timestamp"];
    
    
         NSMutableDictionary* dict = [[NSMutableDictionary alloc]init];
         
         if(_traceId != nil)
         [dict setObject:_traceId forKey:@"traceId"];
         if(_roomId != nil)
         [dict setObject:_roomId forKey:@"roomId"];
         [dict setObject:[[[XMPPWorker sharedInstance] userJid] full] forKey:@"routingId"];
         
         for (NSString* key in info) {
             
             if([key isEqualToString:@"participantId"] || [key isEqualToString:@"StanzaId"])
                 [jsonPayload setObject:[info objectForKey:key] forKey:key];
             
             [dict setObject:[info objectForKey:key] forKey:key];
         }
         
         [jsonPayload setObject:dict forKey:@"attr"];
         if(stats)
         [jsonPayload setObject:[stats getMetaData] forKey:@"meta"];
         
         //Sending each event stat to stat server using WS
         
         if(stats.sendStatsIq){
             if(event != nil && [event isEqualToString:@"SDK_SessionEnded"]) {
                 
                 NSMutableDictionary* dict = [[NSMutableDictionary alloc]init];
                 dict = [stats getCallSummaryStats];
                 if([dict objectForKey:@"callsummary"] != nil) [jsonPayload setObject:[dict objectForKey:@"callsummary"] forKey:@"callsummary"];
                 if([dict objectForKey:@"streaminfo"] != nil) [jsonPayload setObject:[dict objectForKey:@"streaminfo"] forKey:@"streaminfo"];
             }
             if (irisRoom==nil)
                 [_statsQueue addObject:jsonPayload];
             else
                 [irisRoom sendStats:jsonPayload];
         }
         
        [self.statsDelegate onLogEvents:jsonPayload callSummary:callSummary];
         [_eventsArray setObject:jsonPayload atIndexedSubscript:_eventArrayindex];
    
         _eventArrayindex++;
         
         if(stats)
          [stats setEventsArray:_eventsArray];
        
   // });
   
}

- (void)onStats:(NSDictionary *)sessionStats{

  //  [self.sessionDelegate onStats:sessionStats];
}

- (void)onSummary:(NSDictionary*)sessionTimeseries streamInfo:(NSDictionary*)streamInfo metaData:(NSDictionary*)metaData{
    
  //  [self.sessionDelegate onSummary:sessionTimeseries streamInfo:streamInfo metaData:metaData];
}

# pragma mark WebRTCStatsCollectorDelegate delegate methods

-(void) onUpdateStats:(NSString*) statKey _statValue:(id)statsValue{
    
    NSMutableDictionary *stats = [[NSMutableDictionary alloc]init];
    [stats setObject:statsValue forKey:@"value"];
    [stats setObject:statKey forKey:@"key"];
    
    [self.statsDelegate IrisRtcSession:self onSdkStatsDuringActiveSession:stats];

}
@end

@implementation IrisRtcUserProfile

@synthesize name;
@synthesize avatarUrl;


@end

@implementation IrisRtcSessionConfig

@synthesize maxStreamCount;
@synthesize statsCollectorInterval;

@end

@implementation IrisRtcJingleSession (Internal)

-(NSString*)getParticipantJid{
    IRISLogInfo(@"calling getTargetJid and targetJid =  %@",participantJid);
    return [irisRoom getPSTNParticipantJid:pstnTargetJid];
}

-(IrisSIPStatus)getSipStatus{
    return _sipStatus;
}

-(NSString*)getSessionType{
    return [IrisRtcUtils sessionTypetoString:_sessionType];
}

-(NSString*)getRtcServer{
    return [dataElement rtcServer];
}

-(void)restartSession{
    
  //  [self disconnect];
    if(hasErrorOccured){
        IRISLogInfo(@"Aborting Session Reconnect");
        return;
    }
    if(isSessionRestarted)
        return;
    
    IRISLogInfo(@"Restarting session");
    isSessionRestarted = true;
    startCallType = incoming;
    isOccupantJoined = false;
    oldJid = [[XMPPWorker sharedInstance] oldjid];
    
    if(oldJid != nil)
        [dataElement setOldJid:oldJid];
    
    if(participantsDict != nil)
    [participantsDict removeAllObjects];
    
    [irisRoom stopPeriodicPresenceTimer];
    
    [jingleHandler deactivateJingle];
    [[XMPPWorker sharedInstance]setIsSocketReconnected:false];
    [self freeObjects];
    
    if(_sessionType == kSessionTypePSTN)
        [self startIceConnectionTimer];
    
    [self logEvents:@"SDK_SessionReconnect" additionalinfo:nil];
    if(_eventManager == nil){
        _eventManager = [[IrisRtcEventManager alloc]initWithTraceId:_traceId _roomId:nil delegate:self];
    }
    [self logEvents:@"SDK_RenewTokenRequest" additionalinfo:nil];
    [_eventManager renewToken:_roomId];
    
}

                
@end


                
