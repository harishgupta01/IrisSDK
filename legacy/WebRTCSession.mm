//
//  WebRTCSession.m
//  XfinityVideoShare
//
#ifdef ENABLE_LEGACY_CODE

#import "WebRTCSession.h"
#import "WebRTCFactory.h"
#import "WebRTC/WebRTC.h"

#import "WebRTCError.h"
#import "WebRTCStatReport.h"
#import "WebRTCJSON.h"
#import "WebRTCLogHandler.h"
#import "WebRTCLogging.h"
#import "XMPPWorker.h"
#import "XMPPJingle.h"
#import "ARDSDPUtils.h"
#import <AssetsLibrary/AssetsLibrary.h>//;
#import <UIKit/UIKit.h>

//Test
NSString* const Session = @"Session";
BOOL BWflag = false ;
BOOL StatFlag = false;

int timeCounter = 10;
#define ICE_SERVER_TIMEOUT 3
#define OFFER_TIMEOUT 60
#define ICE_CONNECTION_TIMEOUT 120
#define STREAM_STATS_TIMEOUT 1
#define NETWORK_CHECK_VAL 5

#define NETWORK_CHECK_VAL 5

/* Keys for setting network data info */
NSString * const WebRTCNetworkQualityLevelKey = @"WebRTCNetworkQualityLevelKey";
NSString * const WebRTCNetworkQualityReasonKey = @"WebRTCNetworkQualityReasonKey";


@interface WebRTCSession () <XMPPWorkerSignalingDelegate, XMPPRoomDelegate, XMPPJingleDelegate,XMPPFileTransferDelegate>
{
    // Signalling server related parameters
    NSString *FromCaller;
    NSString *ToCaller;
    NSString *clientSessionId;
    NSString *rtcgSessionId;
    NSString *roomId;
    NSString *rtcgid;
    NSString *Uid;
    NSString *DisplayName;
    NSString *ApplicationContext;
    NSString *AppId;
    NSString *peerConnectionId ;
    NSString *dtlsFlagValue;
    NSTimer *_statsTimer;
    NSTimer *capTimer;
    NSDate *initialDate;
   
    // Peerconnection related parameters
    RTCPeerConnectionFactory *factory;
    RTCPeerConnection *peerConnection;
    RTCVideoTrack *videoTrack;
    RTCMediaConstraints *mediaConstraints, *pcConstraints;
    RTCMediaStream *lms;
    NSMutableArray *updatedIceServers,*iceServer;
    NSMutableArray *queuedRemoteCandidates;
    NSMutableArray *iceCandidates;
    
    NSData *options;
    State state;
    RTCIceConnectionState newICEConnState;
    
    // Internal parameters
    WebrtcSessionCallTypes callType;
    WebRTCStack *webrtcstack;
    WebRTCStream *localstream;
    WebRTCChannel *channel;
    
    //sdp parameter
    NSDictionary *initialSDP;
    
    //For local sdp
    RTCSessionDescription* localsdp;
    NSMutableArray* allcandidates;
    BOOL isCandidateSent;
    
    BOOL isChannelAPIEnable;
    BOOL isXMPPEnable;
    WebRTCStatsCollector *statcollector;
    WebRTCStatReport* lastSr;
    
    WebRTCSessionConfig* sessionConfig;
    WebRTCStackConfig* stackConfig;
    NSDictionary* eligibilityToken;
    NSDictionary* _iceServers;
    NSString* serverURL;
    NSURLSessionDataTask *dataTask;
    BOOL isVideoSuspended;
    BOOL isReOffer;
    NSString* turnIPToStat;
    BOOL turnUsedToStat;
    BOOL dataFlagEnabled;
    NSString *fromJid;
    NSString *setCodec;
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
-(void)setFromJid:(NSString*)jidFrom;


@property(nonatomic,weak) id<WebRTCSessionDelegate>delegate;

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

@property(nonatomic ) BOOL isReceivedPingResponse;
@property(nonatomic ) BOOL isSendingPingPongMsg;
@property(nonatomic ) NSTimer* checkPingResponseTime;
@property(nonatomic ) NSTimer *iceConnectionCheckTimer;
@property(nonatomic)RTCDataChannel* dataChannel;

// XCMAV: Incoming stats
@property(nonatomic ) NSInteger offsetTotalPacket_Rx;
@property(nonatomic ) NSInteger offsetPacketLoss_Rx;
@property(nonatomic ) NSMutableArray* packetLossArray_Rx;
@property(nonatomic ) NSMutableArray* bandwidthArray_Rx;
@end

@implementation WebRTCSession
{
    BOOL isAnswerSent,isOfferSent,isAnswerReceived;
    BOOL isDataChannelOpened;
    NSMutableData *concatenatedData;
    NSUInteger dataChunkSize;
    NSString* recievedDataId;
    NSString* startTimeForDataSentStr;
    NSDateFormatter* dateFormatter;
    BOOL cancelSendData;
    BOOL dataSessionActive;
    NSString* routingId;
    NSString* xmppServer;
    NSString* xmppRoom;
    NSString* serviceId;
    BOOL isOccupantJoined;
    NSDictionary* offerJson;
    // XMPP
    XMPPJID * targetJid;
}
@synthesize iceConnectionCheckTimer;

NSString* const TAG4 = @"WebRTCSession";

- (WebRTCSession *)initWithDefaultValue:(WebRTCStack *)stack arClientSessionId:(NSString*)arClientSessionId  _configParam:(WebRTCSessionConfig *)_sessionConfig _stream:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate  _statcollector:(WebRTCStatsCollector *)_statcollector
{
    // Error check
    if ((arClientSessionId == NULL) || (_sessionConfig.callerID == NULL) || (_sessionConfig.targetID == NULL) || (_sessionConfig.displayName == NULL) || (_sessionConfig.deviceID == NULL))
    {
        LogDebug(@"Init with invalid parameters");
        return nil;
    }
    sessionConfig = _sessionConfig;
    callType = sessionConfig.callType;
    clientSessionId = arClientSessionId;
    state = starting;
    webrtcstack = stack;
    
    FromCaller = sessionConfig.callerID;
    ToCaller = sessionConfig.targetID;
    DisplayName = sessionConfig.displayName;
    localstream = _stream;
    self.delegate = _appdelegate;
    dtlsFlagValue = @"true";
    allcandidates = [[NSMutableArray alloc]init];
    updatedIceServers =[[NSMutableArray alloc]init];
    
    [updatedIceServers addObject:[[RTCIceServer alloc] initWithURLStrings:@[@"stun:stun.l.google.com:19302"]
                                                 username:@""
                                                 credential:@""]];
    isCandidateSent = false;
    isChannelAPIEnable = false;
    statcollector = _statcollector;
    eligibilityToken = nil;
    isVideoSuspended = false ;

    //Assign current state with strong
    _networkQualityLevel = WebRTCGoodNetwork;
    _oldNetworkQualityLevel = WebRTCBadNetwork;
    _currentRTTLevel = WebRTCGoodNetwork;
    _currentPacketLossLevel = WebRTCGoodNetwork;
    _currentBWLevel = WebRTCGoodNetwork;
    
    _rttValCounter = 0;
    _packetLossValCounter = 0;
    _offsetTotalPacket = 0;
    _offsetPacketLoss = 0;
    
    // XCMAV: Incoming stats
    _offsetTotalPacket_Rx = 0;
    _offsetPacketLoss_Rx = 0;
    _packetLossArray_Rx = [[NSMutableArray alloc]init];
    _bandwidthArray_Rx = [[NSMutableArray alloc]init];

    
    isReOffer = false;
    isAnswerSent = false;
    
    /* Declaring array to hold five values for each RTT/ Send-Recv BW/Packet loss
     at any point of time for quality calculation */
    
    _rttArray = [[NSMutableArray alloc]init];
    _packetLossArray = [[NSMutableArray alloc]init];
    _bandwidthArray = [[NSMutableArray alloc]init];
    _arrayIndex = 0;
    
    _isReceivedPingResponse = false;
    _isSendingPingPongMsg = false;
    _checkPingResponseTime = nil;
    isDataChannelOpened = false;
    dataChunkSize = _sessionConfig.dataChunkSize;
    concatenatedData = [NSMutableData data];
     dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    turnUsedToStat = false;
    isOccupantJoined = false;
    offerJson = nil;
    isOfferSent = false;
    isAnswerReceived = false;
    iceConnectionCheckTimer = nil;
    return self;
}

- (WebRTCSession *)initRTCGSessionWithDefaultValue:(WebRTCStack *)stack arClientSessionId:(NSString*)arClientSessionId  _configParam:(WebRTCSessionConfig *)_sessionConfig _stream:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate  _statcollector:(WebRTCStatsCollector *)_statcollector _serverURL:(NSString*)_serverURL
{
    
    // Error check
    if ((arClientSessionId == NULL) || (_sessionConfig.callerID == NULL) || (_sessionConfig.targetID == NULL) || (_sessionConfig.displayName == NULL) || (_sessionConfig.deviceID == NULL))
    {
        LogDebug(@" Init with invalid parameters");
        return nil;
    }
    sessionConfig = _sessionConfig;
    callType = sessionConfig.callType;
    clientSessionId = arClientSessionId;
    state = starting;
    webrtcstack = stack;
    isAnswerSent = false;
    FromCaller = [sessionConfig.callerID lowercaseString];
    ToCaller = [sessionConfig.targetID lowercaseString];
    DisplayName = sessionConfig.displayName;
    localstream = _stream;
    self.delegate = _appdelegate;
    dtlsFlagValue = @"true";
    allcandidates = [[NSMutableArray alloc]init];
    updatedIceServers =[[NSMutableArray alloc]init];
    
    [updatedIceServers addObject:[[RTCIceServer alloc] initWithURLStrings:@[@"stun:stun.l.google.com:19302"]
                                                                 username:@""
                                                               credential:@""]];
    isCandidateSent = false;
    isChannelAPIEnable = true;
    statcollector = _statcollector;
    eligibilityToken = nil;
    serverURL = _serverURL;
    isVideoSuspended = false ;
    //Assign current state with strong
    _networkQualityLevel = WebRTCGoodNetwork;
    _oldNetworkQualityLevel = WebRTCBadNetwork;
    _currentRTTLevel = WebRTCGoodNetwork;
    _currentPacketLossLevel = WebRTCGoodNetwork;
    _currentBWLevel = WebRTCGoodNetwork;
    _rttValCounter = 0;
    _packetLossValCounter = 0;
    _offsetTotalPacket = 0;
    _offsetPacketLoss = 0;

    // XCMAV: Incoming stats
    _offsetTotalPacket_Rx = 0;
    _offsetPacketLoss_Rx = 0;
    _packetLossArray_Rx = [[NSMutableArray alloc]init];
    _bandwidthArray_Rx = [[NSMutableArray alloc]init];
    
    isReOffer = false;
    _dataChannel = nil;
    
    /* Declaring array to hold five values for each RTT/SendBW/Packet loss
     at any point of time for quality calculation */
    
    _rttArray = [[NSMutableArray alloc]init];
    _packetLossArray = [[NSMutableArray alloc]init];
    _bandwidthArray = [[NSMutableArray alloc]init];
    _arrayIndex = 0;
    
    _isReceivedPingResponse = false;
    _isSendingPingPongMsg = false;
    _checkPingResponseTime = nil;
    isDataChannelOpened = false;
    dataChunkSize = _sessionConfig.dataChunkSize;
    concatenatedData = [NSMutableData data];
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    turnUsedToStat = false;
    isOccupantJoined = false;
     offerJson = nil;
    isOfferSent = false;
    iceConnectionCheckTimer = nil;
    isAnswerReceived = false;
    return self;

}

- (WebRTCSession *)initWithXMPPValue:(WebRTCStack *)stack _configParam:(WebRTCSessionConfig *)_sessionConfig _stream:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate  _statcollector:(WebRTCStatsCollector *)_statcollector
{
    // Error check
    if ((_sessionConfig.callerID == NULL) || (_sessionConfig.targetID == NULL) || (_sessionConfig.displayName == NULL) || (_sessionConfig.deviceID == NULL))
    {
        NSLog(@"Webrtc:Session:: Init with invalid parameters");
        return nil;
    }
    sessionConfig = _sessionConfig;
    callType = sessionConfig.callType;
    state = starting;
    webrtcstack = stack;
    
    FromCaller = sessionConfig.callerID;
    ToCaller = sessionConfig.targetID;
    DisplayName = sessionConfig.displayName;
    localstream = _stream;
    self.delegate = _appdelegate;
    [XMPPWorker sharedInstance].signalingDelegate = self;
    dtlsFlagValue = @"true";
    allcandidates = [[NSMutableArray alloc]init];
    updatedIceServers =[[NSMutableArray alloc]init];
    _bandwidthArray = [[NSMutableArray alloc]init];
    iceCandidates = [NSMutableArray array];
    _arrayIndex = 0;
    
    [updatedIceServers addObject:[[RTCIceServer alloc] initWithURLStrings:@[@"stun:stun.l.google.com:19302"]
                                                                 username:@""
                                                               credential:@""]];
    concatenatedData = [NSMutableData data];
    isCandidateSent = false;
    isChannelAPIEnable = false;
    isXMPPEnable = true;
    statcollector = _statcollector;
    eligibilityToken = nil;
    isReOffer = false;
    dataSessionActive = false;
    turnUsedToStat = false;
    isOccupantJoined = false;
     offerJson = nil;
    isOfferSent = false;
    iceConnectionCheckTimer = nil;
    isAnswerReceived = false;
    return self;
}

- (WebRTCSession *)initWithIncomingSession:(WebRTCStack *)stack arClientSessionId:(NSString*)arClientSessionId  _stream:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate channelapi:(BOOL)_isChannelAPIEnable _statcollector:(WebRTCStatsCollector *)_statcollector _configParam:(WebRTCSessionConfig *)_sessionConfig
{
    // Error check
    if ((arClientSessionId == NULL) || (_sessionConfig.deviceID == NULL) )
    {
        LogDebug(@"Init with invalid parameters");
        return nil;
    }
    callType = incoming;
    clientSessionId = arClientSessionId;
    state = inactive;
    webrtcstack = stack;
    sessionConfig = _sessionConfig;
    _dataChannel = nil;
        
   // Parse notification data
    //Parse SDP string
    FromCaller = [sessionConfig.callerID lowercaseString];
    ToCaller = [sessionConfig.targetID lowercaseString];
    DisplayName = sessionConfig.displayName;
    rtcgSessionId = sessionConfig.rtcgSessionId;
    roomId = sessionConfig.roomId;
    isAnswerSent = false;
    if ((FromCaller == NULL) || (ToCaller == NULL) )
    {
        LogDebug(@" Notification does not contain required parameters");
        return nil;
    }
    localstream = _stream;
    self.delegate = _appdelegate;
    [XMPPWorker sharedInstance].signalingDelegate = self;
    dtlsFlagValue = @"true";
    allcandidates = [[NSMutableArray alloc]init];
    isCandidateSent = false;
    isChannelAPIEnable = _isChannelAPIEnable;
    
    statcollector = _statcollector;
    lastSr = nil;
    updatedIceServers =[[NSMutableArray alloc]init];
    [updatedIceServers addObject:[[RTCIceServer alloc] initWithURLStrings:@[@"stun:stun.l.google.com:19302"]
                                                                 username:@""
                                                               credential:@""]];
    isVideoSuspended = false ;
    //Assign current state with strong
    _networkQualityLevel = WebRTCGoodNetwork;
    _oldNetworkQualityLevel = WebRTCBadNetwork;
    
    /* In case of incoming call, As there is no RTT value in stat,
     So, setting RTT level to excellent to neutralize 
     its effect for deciding final network level */
    
    _currentRTTLevel = WebRTCExcellentNetwork;
    _currentPacketLossLevel = WebRTCGoodNetwork;
    _currentBWLevel = WebRTCGoodNetwork;
    _rttValCounter = 0;
    _packetLossValCounter = 0;
    _offsetTotalPacket = 0;
    _offsetPacketLoss = 0;
    
    // XCMAV: Incoming stats
    _offsetTotalPacket_Rx = 0;
    _offsetPacketLoss_Rx = 0;
    _packetLossArray_Rx = [[NSMutableArray alloc]init];
    _bandwidthArray_Rx = [[NSMutableArray alloc]init];
    
    isReOffer = false;
    /* Declaring array to hold five values for each RTT/SendBW/Packet loss
     at any point of time for quality calculation */
    
    _rttArray = [[NSMutableArray alloc]init];
    _packetLossArray = [[NSMutableArray alloc]init];
    _bandwidthArray = [[NSMutableArray alloc]init];
    _arrayIndex = 0;
    
    _isReceivedPingResponse = false;
    _isSendingPingPongMsg = false;
    _checkPingResponseTime = nil;
    isDataChannelOpened = false;
    concatenatedData = [NSMutableData data];
     dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    dataSessionActive = false;
    turnUsedToStat = false;
    isOccupantJoined = false;
     offerJson = nil;
    isOfferSent = false;
    iceConnectionCheckTimer = nil;
    isAnswerReceived = false;
    return self;

}

//PSTN call Implementation
- (WebRTCSession *)initWithPSTNSession:(WebRTCStack *)stack _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate _configParam:(WebRTCStackConfig *)_stackConfig
{
    webrtcstack = stack;
    stackConfig = _stackConfig;
    self.delegate = _appdelegate;
    
    return self;
}

-(void)startPSTNCall:dialNum
{
    NSString* targetNumber = [@"+1" stringByAppendingString:webrtcstack.stackConfig.sourcePhoneNum];
    [[XMPPWorker sharedInstance] dial:dialNum from:targetNumber target:targetJid];
}

-(void)endPSTNCall
{
    NSLog(@"Harish::ending pstn call");
    [[XMPPWorker sharedInstance] hangup:@"" from:@"" target:targetJid];
}

-(void)merge
{
    [[XMPPWorker sharedInstance] merge];
}

-(void)hold:(NSString*)dialNum
{
    [[XMPPWorker sharedInstance] hold:dialNum from:stackConfig.sourcePhoneNum];
}

-(void)unHold:(NSString*)dialNum
{
    [[XMPPWorker sharedInstance] unHold:dialNum from:stackConfig.sourcePhoneNum];
}

-(void)setRoomId:(NSString*)roomId
{
    clientSessionId = roomId;
    xmppRoom = roomId;

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

// Start the webrtc session
- (void)_timerCallback:(NSTimer *)timer{
    
    LogDebug(@" _timerCallback");

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

-(void)dataFlagEnabled:(BOOL)_dataFlag{
 
    dataFlagEnabled = _dataFlag;
}

-(void)createChannel
{
    NSString *sType = @"";
    NSString *STBID = @"";
    
    state = ice_connecting;

    if(sessionConfig.isBroadcast && dataFlagEnabled)
    {
        sType = @"sharecast";
        STBID = sessionConfig.STBID;
    }
    else if (sessionConfig.isBroadcast && !dataFlagEnabled)
    {
        sType = @"livestream";
    }
    
    if(isChannelAPIEnable)
    {
        if (callType == incoming)
        {
            channel = [[WebRTCChannel alloc] initAfterChannelCreationValue:clientSessionId rtcgSessionId:rtcgSessionId instanceId:sessionConfig.deviceID target:ToCaller source:FromCaller];
            channel.delegate  = self;
            [webrtcstack logToAnalytics:@"SDK_OpenChannelRequest"];
            [channel sendOpen];
        }
        else
        {
            channel = [[WebRTCChannel alloc] initWithDefaultValue:clientSessionId instanceId:sessionConfig.deviceID target:ToCaller source:FromCaller eligibilityToken:eligibilityToken appID:sType STBID:STBID];
            channel.delegate  = self;
            [webrtcstack logToAnalytics:@"SDK_CreateChannelRequest"];
            [channel sendCreate];
        }
        
    }
    
    [self onIceServers:_iceServers];
}

// Method to join XMPP room
- (void)doJoinRoom:(NSString *)name
{
    [[XMPPWorker sharedInstance] activateJingle:self];
    
    // In order to join the room, first we should create a room name
    // Room name is <random string>@conference.<servername>
    NSString *roomName;
    
    if (name == nil)
    {
        roomName = [NSString stringWithFormat:@"%@@",
                        [[[NSUUID UUID] UUIDString] substringToIndex:8].lowercaseString];
    }
    else
    {
        // New DNS related changes
        roomName = [NSString stringWithFormat:@"%@@",
                name];
    }
    
    if (webrtcstack.isVideoBridgeEnable && (callType != incoming)){
        
        [[XMPPWorker sharedInstance] allocateConferenceFocus:roomName];
    }
    else if(webrtcstack.isVideoBridgeEnable && (sessionConfig.callType == pstncall)){
        
        [[XMPPWorker sharedInstance] allocateConferenceFocus:roomName];
    }
    else{
        
        roomName = [NSString stringWithFormat:@"%@%@", roomName, [[XMPPWorker sharedInstance] hostName]];
        roomName = [roomName stringByReplacingOccurrencesOfString:@"xmpp" withString:@"conference"];
    
        NSLog(@"XMPP Stack : State is Joining room %@", roomName);
        
        [[XMPPWorker sharedInstance] joinRoom:roomName appDelegate:self];
        
        // muc changes
        [[XMPPWorker sharedInstance] sendAliveIQ];
    }

}

// Start the webrtc session
- (void)start:(NSDictionary *)iceServers
{
    // TBD: If ice server times out, go back to STUN
    _iceServers = iceServers;
    
    //Timer to get stats from peerconnection
    _statsTimer = [NSTimer scheduledTimerWithTimeInterval:STREAM_STATS_TIMEOUT
                                                   target:self
                                                 selector:@selector(getStreamStatsTimer)
                                                 userInfo:nil
                                                  repeats:YES
                   ];
    
    lastSr = [[WebRTCStatReport alloc]init];

    
    
    // Manish for xmpp, first step is to join the room
    if (isXMPPEnable)
    {
        if (callType == incoming)
        {
            // For xmpp, rtcgsessionid is the room name
            [self doJoinRoom:roomId];
            [self startSession:updatedIceServers];
        }
        else
        {
            [self doJoinRoom:clientSessionId];
        }
    }
    else
    {
        if(sessionConfig.isChannelTokenEnable && callType != incoming)
        {
            [self sendChannelTokenRequest];
        }
        
        else
            [self createChannel];
    }
}

- (void)sendChannelTokenRequest
{
     LogDebug(@" sendChannelTokenRequest");
    [webrtcstack logToAnalytics:@"SDK_ChannelTokenRequest"];
    NSString *tokenDataString = [[NSString alloc] initWithData:sessionConfig.cimaToken encoding:NSUTF8StringEncoding];
    NSString* _tokenStr = [NSString stringWithFormat:@"Bearer %@", tokenDataString];
    
    //Adding channel token parameter and toID/UID in the orginal resource URL
   // NSString* channelTokenURL = [[serverURL stringByAppendingString:@"/channeltoken?to="]stringByAppendingString:sessionConfig.targetID];
    NSString* channelTokenURL = [[[[serverURL stringByAppendingString:@"/channeltoken?sourceUID="]stringByAppendingString:[sessionConfig.callerID lowercaseString] ]stringByAppendingString:@"&to="]stringByAppendingString:[sessionConfig.targetID lowercaseString]];
    
    LogInfo(@"Channel Tken URL = %@",channelTokenURL);
    
    NSURL *url = [NSURL URLWithString:channelTokenURL];
                                 
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    // Set POST method
    request.HTTPMethod = @"GET";
    
    // Set session config
    NSURLSessionConfiguration * sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPAdditionalHeaders = @{ @"Content-Type" : @"application/x-www-form-urlencoded", @"Authorization" : _tokenStr};
    
    NSURLSession * urlSession = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:nil delegateQueue:nil];
    
    dataTask = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data,
                                                                 NSURLResponse *response,
                                                                 NSError *error) {
	 
	 if(response == nil)
	 {
        LogDebug(@"Response is null...returning");
         //Task has been canceled
        return;
	 }
        LogInfo(@"Current state is = %d",state );
        if(state != inactive)
        {
            NSString *strData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];

            LogInfo(@"WebRTC HTTP: didReceiveData %@", strData);
            
            NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
            if (statusCode != 200) {
                NSError *httperror;
                
                if(statusCode == 401)
                {
                    [webrtcstack logToAnalytics:@"SDK_Error"];
                    NSMutableDictionary* details = [NSMutableDictionary dictionary];
                    [details setValue:@"Invalid credential for http connection" forKey:NSLocalizedDescriptionKey];
                    httperror = [NSError errorWithDomain:Session code:ERR_INVALID_CREDENTIALS userInfo:details];
                    if((self.delegate != nil) && ( state != inactive))
                        [self.delegate onSessionError:httperror.description errorCode:httperror.code additionalData:nil];
                    return ;
                }
                /* else
                 {
                 [details setValue:@"Invalid end point URL" forKey:NSLocalizedDescriptionKey];
                 httperror = [NSError errorWithDomain:Session code:ERR_ENDPOINT_URL userInfo:details];
                 }*/
                
                //[self.delegate onSessionError:httperror.description errorCode:httperror.code];
                //[self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
                //return;
            }
            
            
            NSDictionary* json =[WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            BOOL isUserValid = ![[json objectForKey:@"hasErrors"]boolValue];
            eligibilityToken =[json objectForKey:@"channelToken"];
            //isUserValid = false;
            if ( !isUserValid || eligibilityToken == nil)
            {
                [webrtcstack logToAnalytics:@"SDK_Error"];
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                [details setValue:@"User is not valid !!" forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:Session code:ERR_RTCG_ERROR userInfo:details];
                if((self.delegate != nil) && ( state != inactive))
                    [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
                return;
            }
            
            [webrtcstack logToAnalytics:@"SDK_ChannelTokenResponse"];
            
            if(state != inactive)
                [self createChannel];
        }
        
        
    }];
    
    [dataTask resume];

}


-(void)sendMessage:(NSData *)msg
{
    
    NSError* error;
    NSDictionary* json =[WebRTCJSONSerialization JSONObjectWithData:msg options:kNilOptions error:&error];
 
    NSMutableDictionary* jsonm = [NSMutableDictionary dictionaryWithDictionary:json];
    
    if(!clientSessionId)
        clientSessionId = [NSString stringWithFormat:@"%d", arc4random() % 1000000];
 
    [jsonm setValue:ToCaller forKey:@"target"];
    [jsonm setValue:FromCaller forKey:@"from"];
    [jsonm setValue:sessionConfig.appName forKey:@"appId"];
    [jsonm setValue:FromCaller forKey:@"uid"];
    [jsonm setValue:DisplayName forKey:@"fromDisplay"];
    [jsonm setValue:peerConnectionId forKey:@"peerConnectionId"];
    [jsonm setValue:@"default" forKey:@"applicationContext"];
    [jsonm setValue:clientSessionId forKey:@"clientSessionId"];

    LogDebug(@"sendMessage of type = %@",[jsonm objectForKey:@"type"]);
    
    // Add additional options for a offer message
    if ([[jsonm objectForKey:@"type"]  isEqual: @"offer"]  && (!isXMPPEnable)) {
        
        NSString *audioValue;
        NSString *videoValue;
        NSString *dataValue = @"dataChannel";
        
        // Check the options set by the user
        audioValue = sessionConfig.audio;
        videoValue = sessionConfig.video;
        dataValue = sessionConfig.data;

        NSDictionary * streamTypes = @{ @"audio": audioValue, @"video" : videoValue, @"data" : dataValue };
        
        [jsonm setValue:streamTypes forKey:@"streamTypes"];
        
        
        BOOL one_way = sessionConfig.isOneWay;
        BOOL broadcast = sessionConfig.isBroadcast;
        NSString* resolution = [sessionConfig getResolutionString];
        
        // TBD for resolution
        NSNumber *onewayvalue = [NSNumber numberWithBool:one_way];
        NSNumber *broadcastvalue = [NSNumber numberWithBool:false];
 
        NSDictionary * streamOptions = @{ @"one_way": onewayvalue, @"broadcast": broadcastvalue, @"resolution": @"default"};
        [jsonm setValue:streamOptions forKey:@"streamOptions"];

    }
    if(isChannelAPIEnable)
    {
        if ([[jsonm objectForKey:@"type"]  isEqual: @"candidate"])
         {
         [allcandidates addObject:jsonm];
         
         }
         else if([[jsonm objectForKey:@"type"]  isEqual: @"requestIceServers"])
         {
             //[webrtcstack sendRTCMessage:jsonm];
         }
         else
         {
             [self sendToChannel:jsonm];
         }
    }
    else if (isXMPPEnable)
    {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonm options:0 error:&error];
        NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        //if(callType == incoming)
       //    [self sendXMPPSignalingMessage:jsonStr toUser:fromJid];
        //else
           // [self sendXMPPSignalingMessage:jsonStr toUser:sessionConfig.rtcTargetJid];
        if ([[jsonm objectForKey:@"type"]  isEqual: @"candidate"])
        {
            [webrtcstack logToAnalytics:@"SDK_XMPPJingleTransportInfoSent"];
            [[XMPPWorker sharedInstance] sendJingleMessage:@"transport-info" data:jsonm target:targetJid];
        }
        
        
    }
    else
    {
        [webrtcstack sendRTCMessage:jsonm];
    }
 
}

- (void)onSignalingMessage:(id)msg
{
    if(isChannelAPIEnable)
    {
        // Check if the msg has an error
        bool hasErrors = false;
        hasErrors = [[msg objectForKey:@"hasErrors"] boolValue];
        
        if (hasErrors)
        {
            [webrtcstack logToAnalytics:@"SDK_Error"];
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"RTCG Error" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:Session code:ERR_RTCG_ERROR userInfo:details];
            [self.delegate onSessionError:error.description errorCode:error.code additionalData:msg];
        }
        else
        {
            [channel handleChannelEvent:msg];
        }
    }
    else if (isXMPPEnable)
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
    LogDebug(@" onSignalingMessage %@",msg);
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

    LogDebug(@" type:: %@",type );
    
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
         LogDebug(@"Ice candidate finished");
    }
    else if (![type compare:@"configselection"])
    {
        if([[msg objectForKey:@"reason"] lowercaseString])
        {
            LogDebug(@"%@", [[msg objectForKey:@"reason"] lowercaseString]);
            
            // XCMAV: this can help handle Remote Video Pause state.
            NSString* configMsg = [[msg objectForKey:@"reason"] lowercaseString];
            LogDebug(@"[XCMAV]: sending config message to Application: %@", configMsg);
            [self.delegate onConfigMessage_xcmav:configMsg];
        }
    }
    else if (![type compare:@"appmsg"])
    {
        [self.delegate onSessionTextMessage:[[msg objectForKey:@"reason"] lowercaseString]];
    }
    else if (![type compare:@"remotereconnect"])
    {
        [self onRemoteReconnectedMessage:msg];
    }
    else if (![type compare:@"requesticeservers"]) //xmpp
    {
         NSLog(@"requesticeservers");
    }
    else
    {
        NSLog(@"Got Unknown server msg = %@",msg);
        //NSError *error = [NSError errorWithDomain:Session code:ERR_UNKNOWN_SERVER_MSG userInfo:nil];
        //[self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
    }
}

#pragma mark - Internal methods

// Request ICEservers from signaling server
-(void)requestIceServers
{
    // Form JSON
    NSDictionary *reqIceD = @{ @"type" : @"requestIceServers" };
    NSError *jsonError = nil;
    NSData *reqIce = [WebRTCJSONSerialization dataWithJSONObject:reqIceD options:0 error:&jsonError];
    
    // Sending ice server request
     LogDebug(@" Sending iceServer request");
    [self sendMessage:reqIce];
}

-(void)onOfferMessage:(NSDictionary*)msg
{
     LogDebug(@" Got an offer message");
    
    // Storing the data to retrieve further after recieving iceserver
    [webrtcstack logToAnalytics:@"SDK_OfferReceived"];
    peerConnectionId = [msg objectForKey:@"peerConnectionId"];
    initialSDP = msg;
    
    [statcollector startMetric:self _statName:@"mediaConnectionTime"];
    
    if (isChannelAPIEnable)
    {
        //if (webrtcstack.isCapabilityExchangeEnable)
        //   [self sendCapability];
        
        [self answer];
    }
    else if(isXMPPEnable)
    {
        [self answer];
    }
	
}

-(void)onAnswerMessage:(NSDictionary*)msg
{
     LogDebug(@" Got an answer message");
    isAnswerReceived = true;
    [webrtcstack logToAnalytics:@"SDK_AnswerReceived"];
    state = active;
    [statcollector startMetric:self _statName:@"mediaConnectionTime"];
    
    [statcollector startMetric:@"callDuration"];
    //Parse SDP string
    NSString *tempSdp = [msg objectForKey:@"sdp"];
    LogDebug(@"sdp Before %@",tempSdp);
    //NSString *backslashString = [tempSdp stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
    NSString *sdpString = [tempSdp stringByReplacingOccurrencesOfString:@"\\\\r" withString:@"\r"];
    NSString *sdpString2 = [sdpString stringByReplacingOccurrencesOfString:@"\\\\n" withString:@"\n"];
    NSString *sdpString3 = [sdpString2 stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
    NSString *sdpString4 = [sdpString3 stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
    NSString *sdpString5 = [sdpString4 stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    LogDebug(@"SDP After %@",sdpString3);
    // Reverting back the changes as call is getting crash with 3.53 sdk
    /*NSString *backslashrString = [backslashString stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
    NSString *forwardslashrString = [backslashrString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];

    NSString *sdpString = [forwardslashrString stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];*/
   
    // Create session description
    
    RTCSessionDescription *sdp = [[RTCSessionDescription alloc]
                                  initWithType:RTCSdpTypeAnswer sdp:[self preferISAC:sdpString5]];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __weak WebRTCSession *weakSelf = self;
        [peerConnection setRemoteDescription:sdp
                            completionHandler:^(NSError *error) {
                                WebRTCSession *strongSelf = weakSelf;
                                [strongSelf peerConnection:strongSelf->peerConnection
                         didSetSessionDescriptionWithError:error];
                            }];
    });
    
    if(isChannelAPIEnable)
    {
        //Sending all candidated together
       [webrtcstack logToAnalytics:@"SDK_SendingAllCandidates"];
       [self sendCandidates:allcandidates];
        
        [allcandidates removeAllObjects];
    }
    if(sessionConfig.delaySendingCandidate)
    {
        for (id data in iceCandidates){
            [self sendMessage:data];
        }
    }

    // LogDebug(@"Webrtc:Session:: Got an answer message with sdp %@", sdpString3);

}

-(void)onReOfferMessage:(NSDictionary*)msg
{
     LogDebug(@" Got an reoffer message");
}

-(void)onReAnswerMessage:(NSDictionary*)msg
{
     LogDebug(@" Got an reanswer message");
}

-(void)onCandidateMessage:(NSDictionary*)msg
{
     LogDebug(@" Got a candidate message");
    NSString *mid = [msg objectForKey:@"id"];
    NSString *sdpLineIndex = [msg objectForKey:@"label"];
    NSString *sdp = [msg objectForKey:@"candidate"];
    
    //Harish::For IPv6 testing
    
    if(sessionConfig.forceRelay)
    {
         if(![sdp containsString:@"relay"])
         {
         LogDebug(@"ignoring %@",sdp);
         return;
         }
    }
    
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
         LogDebug(@" Adding candidates to peerconnection");
        [peerConnection addIceCandidate:candidate];
    }
    else
        [queuedRemoteCandidates addObject:candidate];

}

-(void)onCandidatesMessage:(NSDictionary*)msg
{
     LogDebug(@" Got a candidates message");
}

-(void)onByeMessage:(NSDictionary*)msg
{
    
    // Check if the message has a failure
    BOOL isFailure = [[msg valueForKey:@"failure"]boolValue];

    LogInfo(@" Got bye message for state:: %d Failure %d " , state ,isFailure);
    
    if(isFailure)
    {
       [webrtcstack logToAnalytics:@"SDK_Error"];
       NSMutableDictionary* details = [NSMutableDictionary dictionary];
       [details setValue:@"RTCG Error" forKey:NSLocalizedDescriptionKey];
       NSError *error = [NSError errorWithDomain:Session code:ERR_RTCG_ERROR userInfo:details];
       [self.delegate onSessionError:error.description errorCode:error.code additionalData:msg];
    }
    else
    {
        [self.delegate onSessionEnd:@"Remote disconnection"];
        [statcollector stopMetric:@"callDuration"];
    }
    [webrtcstack logToAnalytics:@"SDK_ReceivedByeMessage"];
    if(_statsTimer != nil)
        [_statsTimer invalidate];
    _statsTimer = nil;
    
    state = inactive;
    [self closeSession];
    
    if(isChannelAPIEnable)
    [channel onChannelClosed:msg];
    else
    [webrtcstack disconnect];
}

-(void)onCancelMessage:(NSDictionary*)msg
{
    LogDebug(@" Got cancel message");
    [self.delegate onSessionEnd:@"Remote cancel message"];

}

-(void)onNotificationMessage:(NSDictionary*)msg
{
     LogDebug(@" Got notification message");
}

-(void)onPingMessage:(NSDictionary*)msg
{
     LogDebug(@" Got ping message");
    //Form JSON
    NSDictionary *pongD = @{ @"type" : @"pong" };
    NSError *jsonError = nil;
    NSData *pong = [WebRTCJSONSerialization dataWithJSONObject:pongD options:0 error:&jsonError];
    
    [self sendMessage:pong];
}


-(void)onPongMessage:(NSDictionary*)msg
{
    LogDebug(@" Got ping Response");
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
        
        [self performSelector:@selector(sendPingMessage) withObject:self afterDelay:sessionConfig.pingInterval];
        
    }
    //[self sendPingMessage];
    
}

-(void)onPingResponseFailure
{
    if(!_isReceivedPingResponse)
    {
        [webrtcstack logToAnalytics:@"SDK_Error"];
        LogDebug(@"Failed to get ping response");
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Unable to ping the remote client" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Session code:ERR_REMOTE_UNREACHABLE userInfo:details];
        [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];

    }
}

-(void)sendPingMessage
{
    //Form JSON
    NSDictionary *pingD = @{ @"type" : @"ping" };
    NSError *jsonError = nil;
    NSData *ping = [WebRTCJSONSerialization dataWithJSONObject:pingD options:0 error:&jsonError];
    _isReceivedPingResponse = false;
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        
        //Starting timer to check if received pong message
        _checkPingResponseTime = [NSTimer scheduledTimerWithTimeInterval:sessionConfig.pingResponseTimeout                                                                  target:self
            selector:@selector(onPingResponseFailure)
            userInfo:nil
            repeats:NO];
    });

    
    [self sendMessage:ping];

}


-(void)onRemoteReconnectedMessage:(NSDictionary*)msg
{
    [self networkReconnected];
}
- (void) updatingIceServersData:(NSDictionary*)msg
{
    [self onIceServers:msg];
}

-(void)onIceServers:(NSDictionary*)msg
{
    
     LogDebug(@" onIceServers %@ isXMPPEnable %d", msg, isXMPPEnable);
    NSDictionary *iceServers;
    // Check if the current state is ice_connecting, if not it means we timed out so lets skip this
    if (state == ice_connecting || isXMPPEnable)
    {

        if (isXMPPEnable)
            iceServers = msg;
        else
            iceServers = [msg objectForKey:@"iceServers"];
        NSString *username;
        if ([iceServers objectForKey:@"username"] != Nil)
        {
            username = [iceServers objectForKey:@"username"];
        }
        else
        {
            username = @"";
        }
        NSString *credential;

        if ([iceServers objectForKey:@"credential"] != Nil)
        {
            credential = [iceServers objectForKey:@"credential"];
        }
        else
        {
            credential = @"";
        }
        NSArray *uris = [iceServers objectForKey:@"uris"];
   
        if ([NSURL URLWithString:[uris lastObject]] == nil)
        {
            LogDebug(@" Incorrect turn URI");
            return;
        }
        
        NSLog(@"Webrtc:Session::  ice URL %@ username %@ credentials %@", [NSURL URLWithString:[uris lastObject]],username, credential  );
        
        for (int i=0; i < [uris count]; i++)
        {
            NSString * urlString = [uris objectAtIndex:i];
            [updatedIceServers addObject:[[RTCIceServer alloc] initWithURLStrings:@[urlString]
                                                                         username:username
                                                                       credential:credential]];
        }

            if (!isChannelAPIEnable && !isXMPPEnable)
            {
                [self startSession:updatedIceServers];
            }
    }
}

-(void)onUnsupportedMessage:(NSDictionary*)msg
{
     LogDebug(@" Unsupported message");
}

-(void)startSession:(NSArray*)iceServers
{
    state = call_connecting;
    isCandidateSent = false;
     LogDebug(@" Starting webrtc session");
    dispatch_async(dispatch_get_main_queue(), ^(void){
        
    peerConnectionId = [[NSUUID UUID] UUIDString];

    factory = [WebRTCFactory getPeerConnectionFactory];
    
    //Enabling IPv6 patch by default
    [webrtcstack enableIPV6:true];
        
    // Get the access to local stream and attach to peerconnection
    [self remoteStream];
        
    if (isXMPPEnable)
    {
        if ( !(webrtcstack.isVideoBridgeEnable) && (callType != incoming))
        {
            if([sessionConfig.sType isEqualToString:@"sharecast"])
            {
                if ([self createDataChannel] == true)
                {
                    [self createOffer];
                }
                else
                {
                    return;
                }
            }
            else
            {
                [self createOffer];
            }
        }
    }
    else if(callType == dataoutgoing)
    {
        if ([self createDataChannel] == true)
        {
            [self createOffer];
        }
        else
        {
            return;
        }

    }
    else if(callType != incoming)
        [self createOffer];
    
    });

    
    if (self.delegate != nil)
        [self.delegate onSessionConnecting];

}

-(void)getStreamStatsTimer
{
    /*[peerConnection getStatsWithDelegate:self mediaStreamTrack:nil statsOutputLevel:RTCStatsOutputLevelDebug];*/
}

- (void)remoteStream
{

    if (peerConnection != nil)
    {
        LogDebug(@"remoteStream peerconnection already created " );
        return;

    }
    LogDebug(@"remoteStream DTLS Flag : %@",dtlsFlagValue );
 
    //Peer connection constraints
    NSDictionary *constraintPairs = @{
                                      @"OfferToRecieveAudio": @"true",
                                      @"OfferToRecieveVideo": @"true"
                                      };

    NSMutableDictionary *optionalConstraints = [[NSMutableDictionary alloc]init];
    
    [optionalConstraints addEntriesFromDictionary:@{
                                                    @"DtlsSrtpKeyAgreement": dtlsFlagValue,
                                                    @"googCpuOveruseDetection": @"true",
                                                    @"googCpuOveruseEncodeUsage": @"true",
                                                    @"googCpuUnderuseThreshold": @"25",
                                                    @"googCpuOveruseThreshold": @"150"
                                                    }];
    // Set IPv6 constraint if it is enabled
    if (sessionConfig.EnableIPv6)
    {
        [optionalConstraints addEntriesFromDictionary:@{
                                                        @"googIPv6": @"true",
                                                        }];
    }
    
    if(sessionConfig.isBWCheckEnable){
        [optionalConstraints addEntriesFromDictionary:@{
                                                        @"googSuspendBelowMinBitrate": @"true",
                                                        }];
    }
    
    if(webrtcstack.networkType == wifi)
    {
        [optionalConstraints addEntriesFromDictionary:@{
                                                        @"googImprovedWifiBwe": @"true",
                                                        @"googHighStartBitrate": @"1500",
                                                        }];
    }
    else if((webrtcstack.networkType == cellularLTE) || (webrtcstack.networkType == cellular4g) )
    {
        [optionalConstraints addEntriesFromDictionary:@{
                                                        @"googHighStartBitrate": @"800",
                                                        }];
    }
    else
    {
        [optionalConstraints addEntriesFromDictionary:@{
                                                        @"googHighStartBitrate": @"500",
                                                        }];
    }
        RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:constraintPairs optionalConstraints:optionalConstraints];
    

    queuedRemoteCandidates = [NSMutableArray array];
    
    //Create peer connection
    
    if (!isReOffer)
    {
        if (isXMPPEnable && webrtcstack.isVideoBridgeEnable)
        {
            NSMutableArray *objectsToRemove = [NSMutableArray array];

            for (int i=0; i < [updatedIceServers count]; i++)
            {
                RTCIceServer * iceserver = [updatedIceServers objectAtIndex:i];
                if ([[iceserver urlStrings][0] containsString:@"turn"])
                {
                    [objectsToRemove addObject:iceserver];
                }
            }
            
            [updatedIceServers removeObjectsInArray:objectsToRemove];
        }
        
        LogDebug(@"remoteStream peerConnectionWithICEServers : iceservers %@ and constraints %@",[updatedIceServers description], [constraints description] );
         if(!isXMPPEnable && !isChannelAPIEnable){
            
            [iceServer addObject:[updatedIceServers objectAtIndex:0]];
            NSLog(@"Harish::Adding peerconnection constraint 11");
             RTCConfiguration *config = [[RTCConfiguration alloc] init];
             config.iceServers = updatedIceServers;
            peerConnection = [factory peerConnectionWithConfiguration:config
                                                       constraints:constraints delegate:self];
            
        }
        else
        {
            NSLog(@"Harish::Adding peerconnection constraint 22");
            RTCConfiguration *config = [[RTCConfiguration alloc] init];
            config.iceServers = updatedIceServers;
            peerConnection = [factory peerConnectionWithConfiguration:config
                                                          constraints:constraints delegate:self];

        }
        [self createSenders];
    }
    
}

-(void)createSenders
{
    RTCAudioTrack* audioTrack_= [localstream getAudioTrack];
    RTCVideoTrack* videoTrack_= [localstream getVideoTrack];
    
    // Create RTC sender for audio if exists
    if (audioTrack_)
    {
        RTCRtpSender *sender =
        [peerConnection senderWithKind:kRTCMediaStreamTrackKindAudio
                               streamId:@"ARDAMS"];
        sender.track = audioTrack_;
    }
    
    // Create RTC sender for video if exists
    if (videoTrack_)
    {
        RTCRtpSender *sender =
        [peerConnection senderWithKind:kRTCMediaStreamTrackKindVideo
                              streamId:@"ARDAMS"];
        sender.track = videoTrack_;
    }
}

-(void)createOffer
{
     LogDebug(@" createOffer");
    if (!peerConnection) {
        [self remoteStream];
    }

    isReOffer = false;
    //Peer connection constraints
    //Peer connection constraints
    NSDictionary *constraintPairs = @{
                                      @"googUseRtpMUX": @"true"
                                      };
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:constraintPairs optionalConstraints:nil];
    __weak WebRTCSession *weakSelf = self;
    [peerConnection offerForConstraints:constraints
                       completionHandler:^(RTCSessionDescription *sdp,
                                           NSError *error) {
                           WebRTCSession *strongSelf = weakSelf;
                           [strongSelf peerConnection:strongSelf->peerConnection
                          didCreateSessionDescription:sdp
                                                error:error];
                       }];

}

-(NSString*)getClientSessionId
{
    return clientSessionId;
}
-(void)answer
{
    state = active;
    LogDebug(@" answer");
    factory = [WebRTCFactory getPeerConnectionFactory];
    
    //Enabling IPv6 patch by default
    [webrtcstack enableIPV6:true];
    
    [self remoteStream];
    NSString *tempSdp = [initialSDP objectForKey:@"sdp"];
    if(sessionConfig.isBroadcast)
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

    // Create session description
    RTCSessionDescription *sdp = [[RTCSessionDescription alloc]
                                  initWithType:RTCSdpTypeOffer sdp:[self preferISAC:sdpString]];

    __weak WebRTCSession *weakSelf = self;
    [peerConnection setRemoteDescription:sdp
                        completionHandler:^(NSError *error) {
                            WebRTCSession *strongSelf = weakSelf;
                            [strongSelf peerConnection:strongSelf->peerConnection
                     didSetSessionDescriptionWithError:error];
                        }];
    [self createAnswer];
    
}

-(void)createAnswer
{
    LogDebug(@" createAnswer");
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
    
    __weak WebRTCSession *weakSelf = self;
    [peerConnection answerForConstraints:constraints
                        completionHandler:^(RTCSessionDescription *sdp,
                                            NSError *error) {
                            WebRTCSession *strongSelf = weakSelf;
                            [strongSelf peerConnection:strongSelf->peerConnection
                           didCreateSessionDescription:sdp
                                                 error:error];
                        }];
    
    _statsTimer = [NSTimer scheduledTimerWithTimeInterval:STREAM_STATS_TIMEOUT
                                                   target:self
                                                 selector:@selector(getStreamStatsTimer)
                                                 userInfo:nil
                                                  repeats:YES
                   ];
    
    lastSr = [[WebRTCStatReport alloc]init];
    [statcollector startMetric:@"callDuration"];
    
    isReOffer = true;
    
    if(isXMPPEnable)
        [self.delegate onSessionConnecting];

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
        LogDebug(@" No m=audio line, so can't prefer iSAC");
        return origSDP;
    }
    if (isac16kRtpMap == nil) {
        LogDebug(@" No ISAC/16000 line, so can't prefer iSAC");
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
        
        if ([line hasPrefix:@"m=audio "]) {
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
         LogDebug(@" No m=audio line, so can't prefer iSAC");
        return origSDP;
    }
    if (isac16kRtpMap == nil) {
         LogDebug(@" No ISAC/16000 line, so can't prefer iSAC");
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
/*
- (NSString *)SetMinMaxBandwidth:(NSString *)origSDP minRate:(NSInteger)minRate maxRate:(NSInteger)MaxRate {
    int mLineIndex = -1;
    NSString* isac16kRtpMap = nil;
    NSArray* lines = [origSDP componentsSeparatedByString:@"\\n"];
    NSRegularExpression* isac16kRegex = [NSRegularExpression
                                         regularExpressionWithPattern:@"^a=rtpmap:(\\d+) VP8/90000[\r]?$"
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
        LogDebug(@"Webrtc:Session:: No m=video line, so can't set bitrate");
        return origSDP;
    }
    if (isac16kRtpMap == nil) {
        LogDebug(@"Webrtc:Session:: No VP8/90000 line, so can't set bitrate");
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
*/
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

- (void)closeSession
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       // LogDebug(@"DataTask cancel is done ");
                       //Closing data channel
                       cancelSendData = true;
                       [_dataChannel close];
                       _dataChannel = nil;
                       
                       [dataTask cancel];
                       //[localstream stop];
                       [peerConnection close];
                       
                       peerConnection = nil;
                       
                       //renderer = nil;
                       videoTrack = nil;
                       mediaConstraints = nil;
                       pcConstraints = nil;
                       lms =nil;
                       state = inactive;
                       _delegate = nil;
                       webrtcstack = nil;
                       localstream = nil;
                       channel.delegate = nil;
                       channel = nil;
                       factory = nil;
                       updatedIceServers = nil;
                       queuedRemoteCandidates = nil;
                       localsdp = nil;
                       allcandidates = nil;
                       lastSr = nil;
                       //statcollector = nil;
                       sessionConfig = nil;
                       eligibilityToken = nil;
                       _iceServers = nil;
                       serverURL = nil;
                       initialSDP = nil;
                       dataSessionActive = false;
                      // [RTCPeerConnectionFactory deinitializeSSL];
                   });
}

- (void)disconnect
{
    if(_statsTimer != nil)
    [_statsTimer invalidate];
    [self closeSession];
    [webrtcstack logToAnalytics:@"SDK_SendingByeMessage"];
    [self sendMessage:[@"{\"type\" : \"bye\"}" dataUsingEncoding:NSUTF8StringEncoding]];
   // if (state == active)
        [statcollector stopMetric:@"callDuration"];
    if(isChannelAPIEnable)
    {
        [webrtcstack logToAnalytics:@"SDK_CloseChannelRequest"];
        [channel sendClose];
    }
    else if(isXMPPEnable)
      [[XMPPWorker sharedInstance] leaveRoom];
        
    channel = nil;
    [self finalStats];
    
}

- (void)sendDTMFTone:(Tone)_tone
{
    if ( state != active ) {
        LogDebug(@"Connect not send DTMF tone while not in a session");
        //return;
    }
    NSString *toneValue = toneValueString(_tone);
    LogInfo(@"Sending DTMF Tone %@",toneValue);
    //NSDictionary *initialDtmf = @{@"type":@"sessionMessage"};
    NSDictionary *sessionMessage = @{@"type": @"dtmf", @"tone": toneValue};
    NSDictionary *initialDtmf = @{@"type":@"sessionMessage", @"sessionMessage":sessionMessage};
    //[initialDtmf setValue:sessionMessage forKey:@"sessionMessage"];
    NSError *jsonError = nil;
    NSData *dtmf = [WebRTCJSONSerialization dataWithJSONObject:initialDtmf options:0 error:&jsonError];
    LogDebug(@"check4");
    [self sendMessage:dtmf];
    
}

#pragma mark - Sample RTCSessionDescriptonDelegate delegate
// Called when creating a session.
- (void)peerConnection:(RTCPeerConnection *)arPeerConnection
didCreateSessionDescription:(RTCSessionDescription *)arSdp
                 error:(NSError *)error
{
    if(error)
    {
        [webrtcstack logToAnalytics:@"SDK_Error"];
         LogDebug(@" didCreateSessionDescription SDP onFailure %@.", [arSdp description]);
        //NSAssert(NO, error.description);
        state = inactive;
        [self.delegate onSessionError:error.description errorCode:ERR_INVALID_SDP additionalData:nil];
        return;
    }
    
    //NSString * modifiedSDP = [self preferISAC:arSdp.description];
    NSMutableString * modifiedSDP = [arSdp.description mutableCopy];
    
    NSRange lineindex;
    lineindex = [modifiedSDP rangeOfString:@"a=rtpmap:100 VP8/90000\r\n"];
    
   // [modifiedSDP insertString:@"a=fmtp:100 x-google-min-bitrate=1500; x-google-max-bitrate=4096\r\n" atIndex:(lineindex.length+lineindex.location)];
    
   //  LogDebug(@"Webrtc:Session:: Local SDP onFailure %@.",modifiedSDP);

    // Create SDP and set local description
    RTCSessionDescription* sdp = [[RTCSessionDescription alloc] initWithType:arSdp.type sdp:modifiedSDP];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __weak WebRTCSession *weakSelf = self;
        [peerConnection setLocalDescription:sdp
                           completionHandler:^(NSError *error) {
                               WebRTCSession *strongSelf = weakSelf;
                               [strongSelf peerConnection:strongSelf->peerConnection
                        didSetSessionDescriptionWithError:error];
                           }];
    });
    
    // Convert description and replace with broadcast or two way
    NSString * sdpDesc = sdp.description;
    if(sessionConfig.isBroadcast) {
        sdpDesc = [sdpDesc stringByReplacingOccurrencesOfString:@"sendrecv" withString:@"sendonly"];
    }
    
    // Set this to prefer H264 instead VP8
    /*if(sessionConfig.preferredH264)
    {
        [localstream setAspectRatio43:true]; // For now we support 4:3 for H264
        sdpDesc = [self preferH264:sdpDesc];
    }*/
    
//Prefer H264 if available.
    RTCSessionDescription *sdp1 =[ARDSDPUtils descriptionForDescription:sdp preferredVideoCodec:setCodec];
    NSString * sdpDesc1 = sdp1.description;
    
    if(sessionConfig.isBroadcast) {
	 sdpDesc1 = [sdpDesc1 stringByReplacingOccurrencesOfString:@"sendrecv" withString:@"sendonly"];
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
    NSDictionary *json = @{ @"type" : sdpType, @"sdp" : sdpDesc1 };
    NSError *jsonError = nil;
    NSData *data = [WebRTCJSONSerialization dataWithJSONObject:json options:0 error:&jsonError];
    
    NSAssert(!jsonError, @"%@", [NSString stringWithFormat:@"Error: %@", jsonError.description]);
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        
        /* NSTimer *_offertimer;
         _offertimer = [NSTimer scheduledTimerWithTimeInterval:OFFER_TIMEOUT
         target:self
         selector:@selector(_timerOffer:)
         userInfo:nil
         repeats:NO
         ];*/
        NSLog(@"didCreateSessionDescription sdp = %@",sdpDesc);
        
        if (sdp.type == RTCSdpTypeAnswer)
        {
            [webrtcstack logToAnalytics:@"SDK_AnswerSent"];
            isAnswerSent = true;
        }
       else
        {
            //isOfferSent = true;
            //[webrtcstack logToAnalytics:@"SDK_OfferSent"];
            offerJson  = @{ @"sdp" : sdpDesc1 };
        }
        
        if ( isXMPPEnable && !(webrtcstack.isVideoBridgeEnable) && (callType != incoming))
        {
            if(isOccupantJoined && !isOfferSent)
            {
                offerJson  = @{ @"sdp" : sdpDesc1 };
                [[XMPPWorker sharedInstance] sendJingleMessage:@"session-initiate" data:offerJson target:targetJid];
                isOfferSent = true;
                [webrtcstack logToAnalytics:@"SDK_OfferSent"];
                
            }
        }
        else if(isXMPPEnable && (callType == incoming))
        {
            //Sending all candidates together
            for (int i=0; i < [allcandidates count]; i++)
            {
                NSDictionary *dict = allcandidates[i];
                [webrtcstack logToAnalytics:@"SDK_XMPPJingleTransportInfoSent"];

                [[XMPPWorker sharedInstance] sendJingleMessage:@"transport-info" data:dict target:targetJid];
            }
            
            NSDictionary *json = @{ @"sdp" : sdpDesc };
            [webrtcstack logToAnalytics:@"SDK_XMPPJingleSessionAcceptSent"];
            
            [[XMPPWorker sharedInstance] sendJingleMessage:@"session-accept" data:[json copy] target:targetJid];
            
            /*if (webrtcstack.isVideoBridgeEnable)
                [[XMPPWorker sharedInstance] sendVideoInfo:@"session-accept" data:[json copy] target:targetJid];*/

        }
        else if (isXMPPEnable)
        {
            NSDictionary *json = @{ @"sdp" : sdpDesc };
            [webrtcstack logToAnalytics:@"SDK_XMPPJingleSessionAcceptSent"];

            [[XMPPWorker sharedInstance] sendJingleMessage:@"session-accept" data:[json copy] target:targetJid];
            
            if (webrtcstack.isVideoBridgeEnable)
            [[XMPPWorker sharedInstance] sendVideoInfo:@"session-accept" data:[json copy] target:targetJid];
            
        }

        else
        {
            // Send data
            [self sendMessage:data];
	}
        
    });
    
    // if incoming call, send candidates now
    if (isChannelAPIEnable && (callType == incoming))
    {
        [webrtcstack logToAnalytics:@"SDK_SendingAllCandidates"];
        [self sendCandidates:allcandidates];
        [allcandidates removeAllObjects];
    }

}

- (void)_timerOffer:(NSTimer *)timer{
    
     LogDebug(@"Webrtc:Stack:: _timerOffer");
    
}

- (NSDictionary *)getRemotePartyInfo
{
    NSDictionary *json = @{ @"alias" : ToCaller };
    return json;
}

// Called when setting a local or remote description.
- (void)peerConnection:(RTCPeerConnection *)arPeerConnection
didSetSessionDescriptionWithError:(NSError *)error
{
    if(error)
    {
        [webrtcstack logToAnalytics:@"SDK_Error"];
        LogDebug(@" didSetSessionDescriptionWithError SDP onFailure. %@", [error description]);
        state = inactive;
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        NSString *string = [NSString stringWithFormat:@"Unable to set local or remote SDP : %@", [error description]];
        [details setValue:string forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Session code:ERR_INVALID_SDP userInfo:details];
        [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
       
        //Add ICE candidates
        if (peerConnection.remoteDescription)
        {
            for (RTCIceCandidate *candidate in queuedRemoteCandidates)
            {
                [peerConnection addIceCandidate:candidate];
            }
            queuedRemoteCandidates = nil;
        }
    });
}

#pragma mark - Sample RTCPeerConnectionDelegate delegate
// Triggered when there is an error.
- (void)peerConnectionOnError:(RTCPeerConnection *)peerConnection
{
    NSAssert(NO, @"Webrtc:Session:: PeerConnection error");
    state = inactive;
    [webrtcstack logToAnalytics:@"SDK_Error"];
    NSError *error = [NSError errorWithDomain:Session code:ERR_UNSPECIFIED_PEERCONNECTION userInfo:nil];
    [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
}

// Triggered when the SignalingState changed.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
 signalingStateChanged:(RTCSignalingState)stateChanged
{
    LogInfo(@"PCO onSignalingStateChange: %d",stateChanged);
}

// Triggered when media is received on a new stream from remote peer.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
           addedStream:(RTCMediaStream *)stream
{
     LogDebug(@" PCO onAddStream");
    
   // NSAssert([stream.audioTracks count] >= 1,
    //         @"Expected at least 1 audio stream");
    //NSAssert([stream.videoTracks count] >= 1,
    //         @"Expected at least 1 video stream");
    
    if ([stream.videoTracks count] > 0)
    {
        if ([self.delegate respondsToSelector:@selector(onSessionRemoteVideoAvailable:)]) {
            [self.delegate onSessionRemoteVideoAvailable:[stream.videoTracks objectAtIndex:0]];
        }
    }
   
}

// Triggered when a remote peer close a stream.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
         removedStream:(RTCMediaStream *)stream
{
     LogDebug(@" PCO onRemoveStream");
    [stream removeVideoTrack:[stream.videoTracks objectAtIndex:0]];
    
    if ([self.delegate respondsToSelector:@selector(sessionRemoveVideoTrack)]) {
        [self.delegate onSessionRemoteVideoUnavailable];
    }
}

// Triggered when renegotation is needed, for example the ICE has restarted.
- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection
{
     LogDebug(@" PCO onRenegotiationNeeded");
}


- (void)_timerICEConnCheck:(NSTimer *)timer{
    
    LogDebug(@"Webrtc:Stack:: _timerICEConnCheck");
    if(newICEConnState != RTCIceConnectionStateConnected){
        [webrtcstack logToAnalytics:@"SDK_Error"];
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"ICE Connection Timeout" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Session code:ERR_ICE_CONNECTION_TIMEOUT userInfo:details];
        [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
    }
    
}

// Called any time the ICEConnectionState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
  iceConnectionChanged:(RTCIceConnectionState)newState
{
    LogDebug(@"PCO onIceConnectionChange.%d", newState );
    LogDebug(@"Current State. %d", state);
    [webrtcstack logToAnalytics:[self ICEConnectionTypeToString:newState]];
    newICEConnState = newState;
    if (newState == RTCIceConnectionStateConnected)
    {
        // Change the audio session type to video chat as it has better audio processing logic
        AVAudioSession * audioSession = [AVAudioSession sharedInstance];
        if (audioSession != nil)
        {
            [audioSession setMode:AVAudioSessionModeVideoChat
                            error:nil];
            LogDebug(@"Webrtc:Session:: Audio mode is %@", audioSession.mode);
        }

        LogDebug(@"ICE Connection connected.");
        [statcollector stopMetric:self _statName:@"mediaConnectionTime"];
        
        //Set flag for updating turn server IP
        [WebRTCStatReport setTurnIPAvailabilityStatus:false];
        
        //Stop sending ping pong message as connection as established.
        //_isSendingPingPongMsg = false;
        
        if (self.delegate != nil)
            [self.delegate onSessionConnect];
        
        if(self.iceConnectionCheckTimer != nil)
        {
            [self.iceConnectionCheckTimer invalidate];
            self.iceConnectionCheckTimer = nil;
        }
        
    }
    else if(newState == RTCIceConnectionStateDisconnected)
    {
        LogDebug(@"ICE Connection disconnected");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.iceConnectionCheckTimer = [NSTimer scheduledTimerWithTimeInterval:sessionConfig.pingResponseTimeout
                                                                      target:self
                                                                    selector:@selector(timerICEConnCheck)
                                                                    userInfo:nil
                                                                     repeats:YES
                                      ];
            
        });
    }
    
    else if(newState == RTCIceConnectionStateChecking)
    {
        NSTimer *_iceConnCheckTimer;
        _iceConnCheckTimer = [NSTimer scheduledTimerWithTimeInterval:ICE_CONNECTION_TIMEOUT
                                                       target:self
                                                     selector:@selector(_timerICEConnCheck:)
                                                     userInfo:nil
                                                      repeats:NO
        ];

    }
    else if(newState == RTCIceConnectionStateFailed)
    {
        [webrtcstack logToAnalytics:@"SDK_Error"];
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"ICE Connection Couldn't be established" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Session code:ERR_ICE_CONNECTION_ERROR userInfo:details];
        [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
     
    }
    
   // NSAssert(newState != RTCICEConnectionFailed, @"ICE Connection failed!");

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

// Called any time the ICEGatheringState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
   iceGatheringChanged:(RTCIceGatheringState)newState
{
    LogDebug(@"PCO onIceGatheringChange.%d",newState  );
    //Delegate to inform ICE gathering state to APP
    [webrtcstack logToAnalytics:[self ICEGatheringTypeToString:newState]];
    if (newState == RTCIceGatheringStateComplete)
    {
//        if (isChannelAPIEnable && (callType == incoming) )
        if (isChannelAPIEnable)
        {
            // Sending all candidates together
            
            [self sendCandidates:allcandidates];
            [allcandidates removeAllObjects];
        }
    }
}

- (NSString*)ICEGatheringTypeToString:(RTCIceGatheringState)iceState {
    NSString *result = nil;
    
    switch(iceState) {
        case RTCIceGatheringStateNew:
            result = @"SDK_ICEGatheringNew";
            break;
        case RTCIceGatheringStateGathering:
            result = @"SDK_ICEGatheringGathering";
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

        [self sendToChannel:candidateList];
        [candidates removeObjectsInRange:NSMakeRange(0, 10)];
    }
   NSDictionary* allcandidatesD = [candidates mutableCopy];
   //NSLog(@"Sending remaining candidates in a list: %@", allcandidatesD.debugDescription);

   [self sendToChannel:allcandidatesD];
}

// New Ice candidate have been found.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
       gotICECandidate:(RTCIceCandidate *)candidate
{
    // Form JSON
    NSDictionary *json =
    @{ @"type" : @"candidate",
       @"label" : [NSNumber numberWithInt:candidate.sdpMLineIndex],
       @"id" : candidate.sdpMid,
       @"candidate" : candidate.sdp };
    
    //Harish::For IPv6 testing
    
    if(sessionConfig.forceRelay)
    {
         if(![candidate.sdp containsString:@"relay"])
         {
         LogDebug(@"ignoring %@",candidate.sdp);
         return;
         }
    }
    
    // Create data object
    NSError *error;
    NSData *data = [WebRTCJSONSerialization dataWithJSONObject:json options:0 error:&error];
    [iceCandidates addObject:data];
    
 if (!error) {
        //if(dataFlagEnabled){
            if(callType == outgoing || dataFlagEnabled)
            {
                if(isOfferSent && !sessionConfig.delaySendingCandidate)
                {
                    for (id data in iceCandidates){
                        [self sendMessage:data];
                    }
                    [iceCandidates removeAllObjects];
                }else if( isAnswerReceived && sessionConfig.delaySendingCandidate)
                {
                    for (id data in iceCandidates){
                        [self sendMessage:data];
                    }
                    [iceCandidates removeAllObjects];
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
        if (allcandidates.count > 10)
        {
            [self sendCandidates:allcandidates];
            [allcandidates removeAllObjects];
        }
    }

}


-(void)sendToChannel:(NSDictionary*)msg
{
    LogDebug(@"sendToChannel");

    //Need to add something more
    [channel sendSessionMessage:msg];
}

//Channel delegates
-(void)onChannelOpened
{
    LogDebug(@"onChannelOpened");
    [webrtcstack logToAnalytics:@"SDK_ChannelOpenNotification"];
    if (callType != incoming)
    {
        //if (webrtcstack.isCapabilityExchangeEnable)
        {
           [self sendCapability];
            
            capTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                         target:self
                                                       selector:@selector(capTimerCallback:)
                                                       userInfo:nil
                                                        repeats:NO
                         ];
        }
        
    }
    else{
        
           [self sendCapability];
    }
}

- (void)capTimerCallback:(NSTimer *)timer{
    
    LogDebug(@"webrtcsdk::capTimerCallback");
    
    // No capabilities to enable patch received setting to false
    [webrtcstack enableIPV6:false];
    
    [self startSession:updatedIceServers];

}

- (void)timerICEConnCheck{
    
    if(newICEConnState != RTCIceConnectionStateConnected ){
        
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"ICE Connection disconnected" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Session code:ERR_REMOTE_UNREACHABLE userInfo:details];
        [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
    }
    else
    {
        [self.iceConnectionCheckTimer invalidate];
        self.iceConnectionCheckTimer = nil;
    }
}

-(void)onChannelClosed
{
    LogDebug(@"onChannelClosed");
    [webrtcstack logToAnalytics:@"SDK_ChannelClosedAckReceived"];
    //if(state == active)
   {
       [webrtcstack disconnect];
   }
}

-(void)onChannelMessage:(NSDictionary *)msg
{
    [self onSessionSignalingMessage:msg];
}

-(void)sendChannelRTCMessage:(NSDictionary *)msg
{
    NSError* error;
    
    //NSDictionary* json =[WebRTCJSONSerialization JSONObjectWithData:msg options:kNilOptions error:&error];
    
    NSMutableDictionary* jsonm = [NSMutableDictionary dictionaryWithDictionary:msg];
    
    if(!clientSessionId)
        clientSessionId = [NSString stringWithFormat:@"%d", arc4random() % 1000000];
    
    [jsonm setValue:ToCaller forKey:@"to"];
    [jsonm setValue:FromCaller forKey:@"from"];
    [jsonm setValue:DisplayName forKey:@"fromDisplay"];
    [jsonm setValue:clientSessionId forKey:@"clientSessionId"];
    [jsonm setValue:FromCaller forKey:@"uid"];
    [jsonm setValue:ToCaller forKey:@"target"];
    [jsonm setValue:peerConnectionId forKey:@"peerConnectionId"];
    [jsonm setValue:@"default" forKey:@"applicationContext"];
    if(sessionConfig.appName != nil)
    [jsonm setValue:sessionConfig.appName forKey:@"appId"];
    
    
    
    [webrtcstack sendRTCMessage:jsonm];
}

- (void) onChannelError:(NSString*)error errorCode:(NSInteger)code
{
    [webrtcstack logToAnalytics:@"SDK_Error"];
    [self.delegate onSessionError:error errorCode:code additionalData:nil];
}

- (void) onChannelAck:(NSString *)sessionId
{
    if(callType != incoming)
    [webrtcstack logToAnalytics:@"SDK_CreateChannelAck"];
    
    if ([_delegate respondsToSelector:@selector(onSessionAck:)]) {
    
        [self.delegate onSessionAck:sessionId];
    }
    else
    {
         LogDebug(@" onChannelAck delegate not available to post");
    }
    
    rtcgid = sessionId;
    
    //Includeing rtcgsessionId as stats field
    NSDictionary *sessionIDInfo = @{ @"rtcgSessionId" :sessionId  };
    [statcollector storeReaccuring:self _statName:@"rtcgSessionId" _values:sessionIDInfo];
}

-(void)reconnectSession
{
    [channel sendReconnect];
}


    
- (void)peerConnection:(RTCPeerConnection*)peerConnection
      sendSuspendVideo:(BOOL)suspend_{
    
if(sessionConfig.isBWCheckEnable){
    LogDebug(@"Video is suspended :: %d",suspend_);
   
    if(suspend_ && !isVideoSuspended)
    {
        NSDictionary *json = @{@"type" : @"appmsg" , @"reason" : @"Bandwidth going down, Remote Video suspended"};
        [self onUserConfigSelection:json];
        isVideoSuspended = true;
        [self.delegate onSessionTextMessage:[[json objectForKey:@"reason"] lowercaseString]];
    }
    else if(!suspend_ && isVideoSuspended)
    {
        NSDictionary *json = @{@"type" : @"appmsg" , @"reason" : @"Remote Video resumed "};
        [self onUserConfigSelection:json];
        isVideoSuspended = false;
        [self.delegate onSessionTextMessage:[[json objectForKey:@"reason"] lowercaseString]];
    }
    
 }
    
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection
          sendLogToApp:(NSString*)str severity:(int)sev{
    [self.delegate onSdkLogs:str severity:sev];
}


- (void)peerConnection:(RTCPeerConnection*)peerConnection
           didGetStats:(NSArray*)stats  // NSArray of RTCStatsReport*.
{
    //NSLog(@"Harish :: Complete stats = %@",stats);
    //WebRTCStatReport* sr = [[WebRTCStatReport alloc]init];
    //LogDebug(@"[XCMAV_LB]: didGetStats(): Complete Stats:: %@", stats);
    
    [lastSr parseReport:stats];
    NSDictionary *turnInfo = @{ @"turnIP" :[lastSr turnServerIP]};
    [statcollector storeReaccuring:self _statName:@"turnIP" _values:turnInfo];
    turnInfo = @{ @"turnUsed" :[NSNumber numberWithBool:[WebRTCStatReport isTurnIPAvailable]]};
    [statcollector storeReaccuring:self _statName:@"turnUsed" _values:turnInfo];
    turnIPToStat = [lastSr turnServerIP];
    turnUsedToStat = [WebRTCStatReport isTurnIPAvailable];
    
    
    [self.delegate onStats:[lastSr toJSON]];


     
    //Need to send the stats to the server only after 10 sec.
    if(timeCounter == 10)
    {
        //lastSr = sr;
        [statcollector storeReaccuring:@"streamInfo" _values:[lastSr toJSON]];
        timeCounter = 0;
    }
    timeCounter++;
    
    NSInteger _packetLoss = 0;
    NSInteger _totalPackets = 0;
    NSInteger bandwidthInt = 0;
    
    // XCMAV: Incoming stats
    NSInteger _packetLoss_Rx = 0;
    NSInteger _totalPackets_Rx = 0;
    NSInteger bandwidthInt_Rx = 0;
    
    if((callType == incoming) && (sessionConfig.isOneWay == true))
    {
        //LogDebug(@"[XCMAV_LB]: didGetStats(): donotUpdate _rttArray. callType(%d), isOneWay(%d)", callType, sessionConfig.isOneWay);
        _packetLoss =  [lastSr packetLossRecv];
        _totalPackets = [lastSr totalPacketRecv];
        bandwidthInt = [lastSr recvBandwidth];
        //NSLog(@"Harish::bandwidthInt = %ld",(long)bandwidthInt);
        //NSLog(@"Harish::_packetLoss = %ld",(long)_packetLoss);
        //NSLog(@"Harish::_totalPackets = %ld",(long)_totalPackets);
    }
    else
    {
        _packetLoss =  [lastSr packetLossSent];
        _totalPackets = [lastSr totalPacketSent];
        bandwidthInt = [lastSr sendBandwidth];
        
        /*LogDebug(@"[XCMAV_LB]: didGetStats(): Update _rttArray. INFO: callType(%d), isOneWay(%d): BW (send=%d, recv=%d), "
                 "_packetLoss(%d), _totalPackets(%d), rtt(%d)",
                 callType, sessionConfig.isOneWay, [lastSr sendBandwidth], [lastSr recvBandwidth], _packetLoss, _totalPackets, [lastSr rtt]);*/

        [_rttArray setObject:[NSNumber numberWithInteger:
                              [lastSr rtt]] atIndexedSubscript:_arrayIndex];
        
        // XCMAV: Incoming stats
        if (sessionConfig.isOneWay == false) {
            _packetLoss_Rx =  [lastSr packetLossRecv];
            _totalPackets_Rx = [lastSr totalPacketRecv];
            bandwidthInt_Rx = [lastSr recvBandwidth];
            //LogDebug(@"[XCMAV_LB]: didGetStats(): _packetLoss_Rx(%d), _totalPackets_Rx(%d), bandwidthInt_Rx(%d)",
                   //  _packetLoss_Rx, _totalPackets_Rx, bandwidthInt_Rx);
        }

    }
    
    //LogDebug(@"[XCMAV_LB]: didGetStats(): callType(%d) _arrayIndex(%d) _packetLoss(%d), _totalPackets(%d), bandwidthInt(%d)",
             //callType, _arrayIndex, _packetLoss, _totalPackets, bandwidthInt);

    //Converting BW to kbps
    bandwidthInt = bandwidthInt/1024;
    

    
    [_bandwidthArray setObject:[NSNumber numberWithInteger:bandwidthInt] atIndexedSubscript:_arrayIndex];
    
    
    NSInteger _packetLossVariance = (((_packetLoss - _offsetPacketLoss)*100)/(_totalPackets - _offsetTotalPacket));
    [_packetLossArray setObject:[NSNumber numberWithInteger:_packetLossVariance] atIndexedSubscript:_arrayIndex];
    
    
    //LogDebug(@"[XCMAV_LB]: didGetStats(): _packetLossVariance(%d), _packetLossArray(%@), _rttArray(%@), _bandwidthArray(%@)",
             //_packetLossVariance, _packetLossArray, _rttArray, _bandwidthArray);

    // XCMAV: Incoming stats
    if (sessionConfig.isOneWay == false) {
        _packetLossVariance = -1;
        _packetLossVariance = (((_packetLoss_Rx - _offsetPacketLoss_Rx)*100)/(_totalPackets_Rx - _offsetTotalPacket_Rx));
        [_packetLossArray_Rx setObject:[NSNumber numberWithInteger:_packetLossVariance] atIndexedSubscript:_arrayIndex];
        
        //Converting BW to kbps
        bandwidthInt_Rx = bandwidthInt_Rx/1024;
        [_bandwidthArray_Rx setObject:[NSNumber numberWithInteger:bandwidthInt_Rx] atIndexedSubscript:_arrayIndex];
        
        
        //LogDebug(@"[XCMAV_LB]: didGetStats(): _packetLossVariance(%d) _packetLossArray_Rx(%@), _rttArray(%@), _bandwidthArray_Rx(%@)",
                // _packetLossVariance, _packetLossArray_Rx, _rttArray, _bandwidthArray_Rx);
    }
    
    _arrayIndex++;
    if(_arrayIndex == NETWORK_CHECK_VAL)
    {
        _arrayIndex = 0;
    }
    
    //LogDebug(@"[XCMAV_LB]: didGetStats(): _offsetPacketLoss(%d -> %d), _offsetTotalPacket (%d -> %d), "
            // "_offsetPacketLoss_Rx(%d -> %d), _offsetTotalPacket_Rx(%d -> %d)",
            // _offsetPacketLoss, _packetLoss, _offsetTotalPacket, _totalPackets,
            // _offsetPacketLoss_Rx, _packetLoss_Rx, _offsetTotalPacket_Rx, _totalPackets_Rx);
    
    _offsetPacketLoss = _packetLoss;
    _offsetTotalPacket = _totalPackets;
    
    _offsetPacketLoss_Rx = _packetLoss_Rx;
    _offsetTotalPacket_Rx = _totalPackets_Rx;
    
    
    //NSLog(@"PacketLoss is = %@",_packetLossArray);
    //NSLog(@"RTT is = %@",_rttArray);
    //NSLog(@"AvailableSendBandwidth(kbps) is = %@",_bandwidthArray);
    
    //Determining NetworkState using packet loss and  RTT values
    [self checkNetworkState];
    [lastSr streamStatArrayAlloc];
    [lastSr resetParams];
    
}

-(void)checkNetworkState
{
    //LogDebug(@"[XCMAV_LB]: checkNetworkState(ENTER): callType(%d), _currentRTTLevel(%d), _newRTTLevel(%d), maxRTT(%d)",
            // callType, _currentRTTLevel, _newRTTLevel, [[_rttArray valueForKeyPath:@"@max.self"]integerValue]);

    if((callType != incoming) || (sessionConfig.isOneWay == false))
    {
        //LogDebug(@"[XCMAV_LB]: checkNetworkState(): determining RTT Level: callType(%d), isOneWay(%d)", callType, sessionConfig.isOneWay);

        /* Determining RTT level */
        
        NSInteger maxRTT=[[_rttArray valueForKeyPath:@"@max.self"]integerValue];
        [self updateRTTLevel:maxRTT];
        
        if(_newRTTLevel <= _currentRTTLevel)
        {
            NSInteger minRTT=[[_rttArray valueForKeyPath:@"@min.self"]integerValue];
            [self updateRTTLevel:minRTT];
            if(_newRTTLevel < _currentRTTLevel)
                _currentRTTLevel = _newRTTLevel;
        }
        else
        {
            _currentRTTLevel = _newRTTLevel;
        }
        
         //NSLog(@"_currentRTTLevel = %u",_newRTTLevel);
    }
    
    /* Determining Packet Loss level */
    
    NSInteger maxPacketLoss=[[_packetLossArray valueForKeyPath:@"@max.self"]integerValue];
    [self updatePacketLossLevel:maxPacketLoss];
    
    /*LogDebug(@"[XCMAV_LB]: checkNetworkState(): maxPacketLoss(%d), _newPacketLossLevel(%d), _currentPacketLossLevel(%d)",
             maxPacketLoss, _newPacketLossLevel, _currentPacketLossLevel);*/

    if(_newPacketLossLevel <= _currentPacketLossLevel)
    {
        NSInteger minPacketLoss=[[_packetLossArray valueForKeyPath:@"@min.self"]integerValue];
        [self updatePacketLossLevel:minPacketLoss];
        
        //LogDebug(@"[XCMAV_LB]: checkNetworkState(): minPacketLoss(%d)", minPacketLoss);

        if(_newPacketLossLevel < _currentPacketLossLevel)
            _currentPacketLossLevel = _newPacketLossLevel;
    }
    else
    {
        _currentPacketLossLevel = _newPacketLossLevel;
    }
    //NSLog(@"_currentPacketLossLevel = %u",_currentPacketLossLevel);
    
    /* Determining Send Bandwidth level */
    
    NSInteger minBW = [[_bandwidthArray valueForKeyPath:@"@min.self"]integerValue];
    [self updateSendBWLevel:minBW];
    
    //LogDebug(@"[XCMAV_LB]: checkNetworkState(): minBW(%d), _newBWLevel(%d), _currentBWLevel(%d)", minBW, _newBWLevel, _currentBWLevel);

    if(_newBWLevel <= _currentBWLevel)
    {
        NSInteger maxSendBW=[[_bandwidthArray valueForKeyPath:@"@max.self"]integerValue];
        [self updateSendBWLevel:maxSendBW];
        
        //LogDebug(@"[XCMAV_LB]: checkNetworkState(): maxSendBW(%d)", maxSendBW);

        if(_newBWLevel < _currentBWLevel)
            _currentBWLevel = _newBWLevel;
    }
    else
    {
        _currentBWLevel = _newBWLevel;
    }
    //NSLog(@"_currentBWLevel = %u",_currentBWLevel);

    NSMutableDictionary* networkDetail = [NSMutableDictionary dictionary];
    NetworkQuality newNetworkQualityLevel;
    
    newNetworkQualityLevel =  MIN(_currentBWLevel, MIN(_currentPacketLossLevel, _currentRTTLevel));
    
    //LogDebug(@"[XCMAV_LB]: checkNetworkState(): newNetworkQualityLevel(%d):: MIN(_currentBWLevel[%d], "
             //"MIN((_currentPacketLossLevel=%d, _currentRTTLevel=%d), state(%d)",
             //newNetworkQualityLevel, _currentBWLevel, _currentPacketLossLevel, _currentRTTLevel, state);

    if(state == active)
    {
        //LogDebug(@"[XCMAV_LB]: checkNetworkState(): Network quality [new:%d old:%d], _currentBWLevel(%d), _currentPacketLossLevel(%d), _currentRTTLevel(%d) ", newNetworkQualityLevel, _oldNetworkQualityLevel, _currentBWLevel, _currentPacketLossLevel, _currentRTTLevel);

        if(newNetworkQualityLevel > _oldNetworkQualityLevel)
        {
            [networkDetail setValue:@"Network quality got improved !!!" forKey:WebRTCNetworkQualityReasonKey];
            
//            // XCMAV: This appears redundant, so move out the if-else.
//            [networkDetail setValue:[NSNumber numberWithInteger:newNetworkQualityLevel] forKey:WebRTCNetworkQualityLevelKey];
//            [self.delegate onSessionEvent:NetworkQualityIndicator eventData:networkDetail];
//            _oldNetworkQualityLevel = newNetworkQualityLevel;
        }
        else
            if(newNetworkQualityLevel != _oldNetworkQualityLevel)
            {
                if(_currentBWLevel <= _currentPacketLossLevel)
                {
                    if(_currentBWLevel <= _currentRTTLevel)
                    {
                        [networkDetail setValue:@"Network quality is weak due to low bandwidth" forKey:WebRTCNetworkQualityReasonKey];
                        newNetworkQualityLevel = _currentBWLevel;
                    }
                    else
                    {
                        [networkDetail setValue:@"Network quality is weak due to high RTT" forKey:WebRTCNetworkQualityReasonKey];
                        newNetworkQualityLevel = _currentRTTLevel;
                    }
                }
                else
                {
                    if(_currentPacketLossLevel <= _currentRTTLevel)
                    {
                        [networkDetail setValue:@"Network quality is weak due to packet loss" forKey:WebRTCNetworkQualityReasonKey];
                        newNetworkQualityLevel = _currentPacketLossLevel;
                    }
                    else
                    {
                        [networkDetail setValue:@"Network quality is weak due to high RTT" forKey:WebRTCNetworkQualityReasonKey];
                        newNetworkQualityLevel = _currentRTTLevel;
                        
                    }
                }
                
                // XCMAV: This appears redundant, so move out the if-else.
//                [networkDetail setValue:[NSNumber numberWithInteger:newNetworkQualityLevel] forKey:WebRTCNetworkQualityLevelKey];
//                [self.delegate onSessionEvent:NetworkQualityIndicator eventData:networkDetail];
//                _oldNetworkQualityLevel = newNetworkQualityLevel;
                
            }
        
        // XCMAV: Incoming stats
        if (sessionConfig.isOneWay == false) {
            // This logic keeps Incoming Stats consideration for 2wayVideo only.
            NetworkQuality nwQual_IncomingStats = [self checkNetworkState_IncomingStats];
            //LogDebug(@"[XCMAV_LB]: checkNetworkState(): Network quality: Rx(%d), Tx(%d), final(%d), state(%d)",
                 //    nwQual_IncomingStats, newNetworkQualityLevel, MIN(nwQual_IncomingStats, newNetworkQualityLevel), //state);
            
            if ([lastSr rxVideoFlag] == true) {
                // This logic delays considering Incoming stats, till Video frames are received.
                //LogDebug(@"[XCMAV_LB]: 2wayVideo checkNetworkState(): Network quality: Rx(%d)=used now, Tx(%d), //final(%d), state(%d)",
                       //  nwQual_IncomingStats, newNetworkQualityLevel, MIN(nwQual_IncomingStats, newNetworkQualityLevel), state);
                
                newNetworkQualityLevel = MIN (nwQual_IncomingStats, newNetworkQualityLevel);
            }
        }

        // XCMAV: This was redundant, so move out the if-else to here.
        [networkDetail setValue:[NSNumber numberWithInteger:newNetworkQualityLevel] forKey:WebRTCNetworkQualityLevelKey];
        [self.delegate onSessionEvent:NetworkQualityIndicator eventData:networkDetail];
        _oldNetworkQualityLevel = newNetworkQualityLevel;

    }
    
    
}

// XCMAV: Incoming stats
// This function calculates NetworkQuality for Incoming Stats (_packetLossArray, _bandwidthArray).
-(NetworkQuality)checkNetworkState_IncomingStats
{
    //NetworkQuality newNetworkQualityLevel;
    //LogDebug(@"[XCMAV_LB]: checkNetworkState_IncomingStats(ENTER): callType(%d), _packetLossArray_Rx(%@), _bandwidthArray_Rx(%@)",
             //callType, _packetLossArray_Rx, _bandwidthArray_Rx);
    
    /* Determining Packet Loss level */
    NSInteger maxPacketLoss=[[_packetLossArray_Rx valueForKeyPath:@"@max.self"]integerValue];
    [self updatePacketLossLevel:maxPacketLoss];
    
    //LogDebug(@"[XCMAV_LB]: checkNetworkState_IncomingStats(): maxPacketLoss(%d), _newPacketLossLevel(%d), _currentPacketLossLevel(%d)",
            // maxPacketLoss, _newPacketLossLevel, _currentPacketLossLevel);
    
    if(_newPacketLossLevel <= _currentPacketLossLevel)
    {
        NSInteger minPacketLoss=[[_packetLossArray_Rx valueForKeyPath:@"@min.self"]integerValue];
        [self updatePacketLossLevel:minPacketLoss];
        
        //LogDebug(@"[XCMAV_LB]: checkNetworkState_IncomingStats(): minPacketLoss(%d)", minPacketLoss);
        
        if(_newPacketLossLevel < _currentPacketLossLevel)
            _currentPacketLossLevel = _newPacketLossLevel;
    }
    else
    {
        _currentPacketLossLevel = _newPacketLossLevel;
    }
    //LogDebug(@"[XCMAV_LB]: checkNetworkState_IncomingStats(): _currentPacketLossLevel(%d)", _currentPacketLossLevel);
    
    /* Determining Receive Bandwidth level */
    NSInteger minBW = [[_bandwidthArray_Rx valueForKeyPath:@"@min.self"]integerValue];
    [self updateSendBWLevel:minBW]; // Varun: need to create a new function for ReceiveBWLevel
    
    //LogDebug(@"[XCMAV_LB]: checkNetworkState_IncomingStats(): minBW(%d), _newBWLevel(%d), _currentBWLevel(%d)", minBW, _newBWLevel, _currentBWLevel);
    
    if(_newBWLevel <= _currentBWLevel)
    {
        NSInteger maxSendBW=[[_bandwidthArray_Rx valueForKeyPath:@"@max.self"]integerValue];
        [self updateSendBWLevel:maxSendBW];
        
        //LogDebug(@"[XCMAV_LB]: checkNetworkState_IncomingStats(): maxSendBW(%d)", maxSendBW);
        
        if(_newBWLevel < _currentBWLevel)
            _currentBWLevel = _newBWLevel;
    }
    else
    {
        _currentBWLevel = _newBWLevel;
    }
    //LogDebug(@"[XCMAV_LB]: checkNetworkState_IncomingStats(): _currentBWLevel(%d)", _currentBWLevel);
    
    NetworkQuality newNetworkQualityLevel;
    newNetworkQualityLevel = MIN(_currentPacketLossLevel, _currentBWLevel);
    
    //LogDebug(@"[XCMAV_LB]: checkNetworkState_IncomingStats(): newNetworkQualityLevel(%d):: //MIN((_currentPacketLossLevel=%d, _currentBWLevel=%d)",
           //  newNetworkQualityLevel, _currentPacketLossLevel, _currentBWLevel);
    
    
    return newNetworkQualityLevel;
}



-(void)updatePacketLossLevel:(NSInteger)packetLossValue
{
    
    if(packetLossValue <  [[sessionConfig.packetLossThresholdLevels
                            objectForKey:WebRTCGoodNetworkQualityKey]integerValue])
    {
        _newPacketLossLevel = WebRTCExcellentNetwork;
    }
    else
    if((packetLossValue > [[sessionConfig.packetLossThresholdLevels
                            objectForKey:WebRTCGoodNetworkQualityKey]integerValue]) &&
        (packetLossValue < [[sessionConfig.packetLossThresholdLevels
                             objectForKey:WebRTCFairNetworkQualityKey]integerValue]))
    {
        _newPacketLossLevel = WebRTCGoodNetwork;
    }
    else
    if((packetLossValue > [[sessionConfig.packetLossThresholdLevels
                            objectForKey:WebRTCFairNetworkQualityKey]integerValue]) &&
        (packetLossValue < [[sessionConfig.packetLossThresholdLevels
                             objectForKey:WebRTCPoorNetworkQualityKey]integerValue]))
    {
        _newPacketLossLevel = WebRTCFairNetwork;
    }
    else
    if((packetLossValue > [[sessionConfig.packetLossThresholdLevels
                            objectForKey:WebRTCPoorNetworkQualityKey]integerValue]) &&
        (packetLossValue < [[sessionConfig.packetLossThresholdLevels
                             objectForKey:WebRTCBadNetworkQualityKey]integerValue]))
    {
        _newPacketLossLevel = WebRTCPoorNetwork;
    }
    else
    if(packetLossValue >  [[sessionConfig.packetLossThresholdLevels
                            objectForKey:WebRTCBadNetworkQualityKey]integerValue])
    {
        _newPacketLossLevel = WebRTCBadNetwork;
    }
    //LogDebug(@"[XCMAV_LB]: updatePacketLossLevel(): packetLossValue(%d), _newPacketLossLevel(%d)", packetLossValue, _newPacketLossLevel);
}

-(void)updateSendBWLevel:(NSInteger)sendBWValue
{
    if(sendBWValue >  [[sessionConfig.sendBWThresholdLevels
                        objectForKey:WebRTCGoodNetworkQualityKey]integerValue])
    {
        _newBWLevel = WebRTCExcellentNetwork;
    }
    else
    if((sendBWValue < [[sessionConfig.sendBWThresholdLevels
                        objectForKey:WebRTCGoodNetworkQualityKey]integerValue]) &&
        (sendBWValue > [[sessionConfig.sendBWThresholdLevels
                         objectForKey:WebRTCFairNetworkQualityKey]integerValue]))
    {
        _newBWLevel = WebRTCGoodNetwork;
    }
    else
    if((sendBWValue < [[sessionConfig.sendBWThresholdLevels
                        objectForKey:WebRTCFairNetworkQualityKey]integerValue]) &&
        (sendBWValue > [[sessionConfig.sendBWThresholdLevels
                         objectForKey:WebRTCPoorNetworkQualityKey]integerValue]))
    {
        _newBWLevel = WebRTCFairNetwork;
    }
    else
    if((sendBWValue < [[sessionConfig.sendBWThresholdLevels
                        objectForKey:WebRTCPoorNetworkQualityKey]integerValue]) &&
        (sendBWValue > [[sessionConfig.sendBWThresholdLevels
                         objectForKey:WebRTCBadNetworkQualityKey]integerValue]))
    {
        _newBWLevel = WebRTCPoorNetwork;
    }
    else
    if(sendBWValue <  [[sessionConfig.sendBWThresholdLevels
                        objectForKey:WebRTCBadNetworkQualityKey]integerValue])
    {
        _newBWLevel = WebRTCBadNetwork;
    }
    //LogDebug(@"[XCMAV_LB]: updateSendBWLevel(): sendBWValue(%d), _newBWLevel(%d)", sendBWValue, _newBWLevel);
}

-(void)updateRTTLevel:(NSInteger)rttValue
{
    
    if(rttValue <  [[sessionConfig.rttThresholdLevels
                     objectForKey:WebRTCGoodNetworkQualityKey]integerValue])
    {
        _newRTTLevel = WebRTCExcellentNetwork;
    }
    else
    if((rttValue > [[sessionConfig.rttThresholdLevels
                     objectForKey:WebRTCGoodNetworkQualityKey]integerValue]) &&
        (rttValue < [[sessionConfig.rttThresholdLevels
                      objectForKey:WebRTCFairNetworkQualityKey]integerValue]))
    {
        _newRTTLevel = WebRTCGoodNetwork;
    }
    else
    if((rttValue > [[sessionConfig.rttThresholdLevels
                     objectForKey:WebRTCFairNetworkQualityKey]integerValue]) &&
        (rttValue < [[sessionConfig.rttThresholdLevels
                      objectForKey:WebRTCPoorNetworkQualityKey]integerValue]))
    {
        _newRTTLevel = WebRTCFairNetwork;
    }
    else
    if((rttValue > [[sessionConfig.rttThresholdLevels
                     objectForKey:WebRTCPoorNetworkQualityKey]integerValue]) &&
        (rttValue < [[sessionConfig.rttThresholdLevels
                      objectForKey:WebRTCBadNetworkQualityKey]integerValue]))
    {
        _newRTTLevel = WebRTCPoorNetwork;
    }
    else
    if(rttValue >  [[sessionConfig.rttThresholdLevels
                     objectForKey:WebRTCBadNetworkQualityKey]integerValue])
    {
        _newRTTLevel = WebRTCBadNetwork;
    }
    
    //LogDebug(@"[XCMAV_LB]: updateRTTLevel(): rttValue(%d), _newRTTLevel(%d)", rttValue, _newRTTLevel);
}

-(void)bandwidthCheck:(NSInteger)BW
{
    
        if (  BW != 0 && BW < 30) {
            if (BWflag == false) {
                [localstream stopVideo];
            }
            BWflag = true;
            NSDictionary *json = @{@"type" : @"configselection" , @"reason" : @"Poor bandwidth,Video is shuttered"};
            [self onUserConfigSelection:json];
        }
        if (BW > 50 && BWflag == true) {
            [localstream startVideo];
            BWflag = false;
            NSDictionary *json = @{@"type" : @"configselection" , @"reason" : @"video is unshuttered"};
            [self onUserConfigSelection:json];
            
        }
    
    //LogDebug(@"[XCMAV_LB]: bandwidthCheck(): BW(%d), BWflag(%d)", BW, BWflag);
    
}

- (void) onUserConfigSelection:(NSDictionary*)json{
    if(isChannelAPIEnable){
        [self sendToChannel:json];
        
    }
    else
    {
        [webrtcstack sendRTCMessage:json];
        [[XMPPWorker sharedInstance] sendMediaPresence:json target:targetJid];
    }
}

-(void)applySessionConfigChanges:(WebRTCSessionConfig*)configParam
{
    LogDebug(@"Inside applySessionConfigChanges");
    
   /* for (RTCMediaStream *stream in peerConnection.localStreams)
    {
        lms = stream;
        [peerConnection removeStream:stream];
        
    }
    
    [localstream applyStreamConfigChange:configParam.streamConfig];
    
   //[peerConnection addStream:lms constraints:nil];
   //[peerConnection addStream:lms];
     [peerConnection addStream:[localstream getMediaStream]];*/
    
}

- (void) sendCapability
{
    LogDebug(@"Inside sendCapability");
    
    @try{
        
        NSDictionary *meta =
        @{@"devicetype" : [webrtcstack.getMetaData objectForKey:@"model"],
          @"manufacturer" : [webrtcstack.getMetaData objectForKey:@"manufacturer"],
          @"version" : [webrtcstack.getMetaData objectForKey:@"sdkVersion"]};
        
        NSDictionary *json=
        @{ @"type" : @"capability",
           @"meta" : meta,
           @"data" : [self getCapabilityData]};
            
        if(isChannelAPIEnable){
            [self sendToChannel:json];
        }
    
    }
    @catch(NSException *e)
    {
        LogError(@" Exception in sendCapability %@",e);
    }
}

- (NSDictionary *) getCapabilityData
{
    int device = webrtcstack.getMachineID;
    
    LogDebug(@"getCapabilityData::device= %d",device );
    
    NSNumber *minBlocks;
    NSNumber *maxBlocks;
    
    switch (webrtcstack.getMachineID)
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
      @"video" : sessionConfig.video,
      @"audio" : sessionConfig.audio,
      @"data" : sessionConfig.data,
      @"one_way" : [NSNumber numberWithBool:sessionConfig.isOneWay],
      @"broadcast" : [NSNumber numberWithBool:sessionConfig.isBroadcast],
      @"app" : sessionConfig.appName,
      @"ipv6patch" : sessionConfig.ipv6patch};

    return data;
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
        LogDebug(@"Remote platform is Pace box, Configuring frame rate accordingly");
        localstream.getStreamConfig.maxFrameRate = 20;
        localstream.getStreamConfig.minFrameRate = 15;
        
        
        isConfigResetRequired = true;
    }
   /*else
    //if([platformType containsString:@"arris"])
    if ([platformType rangeOfString:@"arris"].location != NSNotFound)
    {
        LogDebug(@"Remote platform is Arris box, Configuring frame rate accordingly"];
        localstream.getStreamConfig.maxFrameRate = 20;
        localstream.getStreamConfig.minFrameRate = 30;
        isConfigResetRequired = true;

    }*/
    
    //if(webrtcstack.isCapabilityExchangeEnable)
    {
        LogDebug(@"Inide onCapabilityMessage");
        
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
                sessionConfig.ipv6patch = [dataMsg objectForKey:@"ipv6patch"];
                
                if([sessionConfig.ipv6patch  isEqual:@"true"])
                {
                    ipv6Enabled = true;
                }
                else if ([secureProtocol  isEqual:@"none"])
                {
                    ipv6Enabled = false;
                }
                
                
                if(capTimer != nil){
                    [capTimer invalidate];
                    capTimer = nil;
                }
                
                LogDebug(@"webrtcsdk::onCapabilityMessage:ipv6patch:%d",ipv6Enabled);
                [webrtcstack enableIPV6:ipv6Enabled];
                
            }
            
            if(capTimer != nil){
                [capTimer invalidate];
                capTimer = nil;
            }
            [self startSession:updatedIceServers];
            
            if(webrtcstack.isCapabilityExchangeEnable)
            {
                if ([dataMsg objectForKey:@"minBlocks"] != Nil)
                {
                    minBlocks = [[dataMsg objectForKey:@"minBlocks"] integerValue];
                }
                if ([dataMsg objectForKey:@"maxBlocks"] != Nil)
                {
                    maxBlocks = [[dataMsg objectForKey:@"maxBlocks"] integerValue];
                }
                if ([dataMsg objectForKey:@"secureProtocol"] != Nil)
                {
                    secureProtocol = [dataMsg objectForKey:@"secureProtocol"];
                    
                    if([secureProtocol  isEqual:@"srtpDtls"])
                    {
                        [self setDTLSFlag:TRUE];
                    }
                    else if ([secureProtocol  isEqual:@"none"])
                    {
                        [self setDTLSFlag:FALSE];
                    }
                }
                if ([dataMsg objectForKey:@"video"] != Nil)
                {
                    video = [dataMsg objectForKey:@"video"];
                }
                if ([dataMsg objectForKey:@"audio"] != Nil)
                {
                    audio = [dataMsg objectForKey:@"audio"];
                }
                if ([dataMsg objectForKey:@"data"] != Nil)
                {
                    data = [dataMsg objectForKey:@"data"];
                }
                if ([dataMsg objectForKey:@"one_way"] != Nil)
                {
                    one_way = [[dataMsg objectForKey:@"one_way"] boolValue];
                }
                if ([dataMsg objectForKey:@"broadcast"] != Nil)
                {
                    broadcast = [[dataMsg objectForKey:@"broadcast"] boolValue];
                }
                if ( (minBlocks == 0) || (maxBlocks == 0))
                {
                    
                    LogError(@"onCapabilityMessage error : empty minBlocks/maxBlocks ");
                }
                else
                {
                    isConfigResetRequired = true;
                    [self updateMediaConstraints:minBlocks max:maxBlocks];
                }
            }
        }
        
        @catch(NSException *e)
        {

            LogError(@"Exception in onCapabilityMessage %@", e);
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
        [newConfig setValue:[NSNumber numberWithInteger:localstream.getStreamConfig.maxFrameRate]  forKey:@"maxFrameRate"];
        [newConfig setValue:[NSNumber numberWithInteger:localstream.getStreamConfig.minFrameRate]  forKey:@"minFrameRate"];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"ConfigurationDidChangeNotification" object:nil userInfo:newConfig];
    }
    

}

-(void)updateMediaConstraints:(NSInteger)minBlocks max:(NSInteger)maxBlocks
{
    int device = webrtcstack.getMachineID;

    LogDebug(@"updateMediaConstraints::machine ID= %d",device);
    
    switch (device)
    {
        case iPhone4:
            
            if (maxBlocks >= VGA_MAX_BLOCKS)
                [localstream.getStreamConfig setMediaConstraints:VGA];
            
            else
                [localstream.getStreamConfig setMediaConstraints:QVGA];
            
            break;
            
        case iPhone5:
            
            if (maxBlocks >= HD_MAX_BLOCKS)
                [localstream.getStreamConfig setMediaConstraints:HD];
            
            else if(maxBlocks >= VGA_MAX_BLOCKS)
                [localstream.getStreamConfig setMediaConstraints:VGA];
            
            else
                [localstream.getStreamConfig setMediaConstraints:QVGA];
            
            break;
            
        case iPhone6:
            
            if(maxBlocks >= FHD_MAX_BLOCKS)
                [localstream.getStreamConfig setMediaConstraints:FHD];
           
            else if(maxBlocks >= HD_MAX_BLOCKS)
                [localstream.getStreamConfig setMediaConstraints:HD];
            
            else if(maxBlocks  >= VGA_MAX_BLOCKS)
                [localstream.getStreamConfig setMediaConstraints:VGA];
            
            else
                [localstream.getStreamConfig setMediaConstraints:QVGA];
            
            break;
            
        default:
            
            [localstream.getStreamConfig setMediaConstraints:unknown];
            
    }
}

-(void)createReOffer
{
    LogDebug(@" createReOffer");
    
    /*
    isReOffer = true;
    //Peer connection constraints
    NSArray * constraintPairs = @[[[RTCPair alloc] initWithKey:@"googUseRtpMUX" value:@"true"],
                                  [[RTCPair alloc] initWithKey:@"IceRestart" value:@"true"],
                                  ];
    
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:constraintPairs
                                                                             optionalConstraints:nil];
    [peerConnection createOfferWithDelegate:self constraints:constraints];
    */
}

-(void)networkReconnected
{
    [channel onChannelReconnectAck:nil];
    
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

-(void)sendMessage:(NSString *)targetId json:(NSDictionary *)json
{
    
    [self onUserConfigSelection:json];
}

-(BOOL)createDataChannel
{
    /* Check if the data channel was created */
    /*if([dtlsFlagValue isEqual:@"false"])
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"DataChannel creation failed, most probably since DTLS is not enabled" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Session code:ERR_INCORRECT_PARAMS userInfo:details];
        if(self.delegate != nil)
        {
            [webrtcstack logToAnalytics:@"SDK_Error"];
            [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
        }
        return false;
    }
    
    RTCDataChannelInit* datainit = [[RTCDataChannelInit alloc] init];
    _dataChannel = [peerConnection createDataChannelWithLabel:@"datachannel" config:nil];
    
    _dataChannel.delegate = self;
    cancelSendData = false;
    NSLog(@"DataChannel::Inside createDataChannel");*/
    return true;
}

-(void)sendDataChannelMessage:(NSData*)imgData
{
    NSLog(@"DataChannel::Inside sendDataChannelMessage");
    /*if(isDataChannelOpened && _dataChannel != nil)
    {
        NSLog(@"DataChannel::Sending buffer");
        //NSData *data = [[NSData alloc]initWithBase64EncodedString:@"hi...its harish here" options:NSDataBase64DecodingIgnoreUnknownCharacters];
       // NSData* data = [@"hi...its harish here" dataUsingEncoding:NSUTF8StringEncoding];
        RTCDataBuffer *buffer = [[RTCDataBuffer alloc]initWithData:imgData isBinary:true];
        BOOL retValue = [_dataChannel sendData:buffer];
        if(!retValue)
        {
            cancelSendData = true;
            [webrtcstack logToAnalytics:@"SDK_Error"];
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Sending Image data failed" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:Session code:ERR_DATA_SEND userInfo:details];
            [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
        }
        NSLog(@"DataChannel::retValue = %d",retValue);
    }
  */
}

#pragma mark - DataChannel Delegate
#if 0
// Called when the data channel state has changed.
- (void)channelDidChangeState:(RTCDataChannel*)channel;
{
    NSLog(@"DataChannel::Inside channelDidChangeState");
    NSLog(@"channel.label = %@",channel.label);
    NSLog(@"channel.state = %d",channel.state);
    if(channel.state == kRTCDataChannelStateOpen)
    {
        isDataChannelOpened = true;
        [self.delegate onDataChannelConnect];
    }
    NSLog(@"channel.bufferedAmount = %lu",(unsigned long)channel.bufferedAmount);
}

// Called when a data buffer was successfully received.
- (void)channel:(RTCDataChannel*)channel
didReceiveMessageWithBuffer:(RTCDataBuffer*)buffer;
{
    NSData* dataBuff = [buffer data];
    NSLog(@"didReceiveMessageWithBuffer size = %lu",(unsigned long)[dataBuff length]);
    
    
    if([dataBuff length] < 500)
    {
        NSError* error;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:dataBuff
                                                             options:kNilOptions
                                                               error:&error];
        if(json == nil)
        {
            [concatenatedData appendData:dataBuff];
        }
        else
        if ([[json allKeys] containsObject:@"action"])
        {
            NSString* action  = [[json objectForKey:@"action"] lowercaseString];
            NSLog(@"DataChannel::Inside didReceiveMessageWithBuffer action = %@",action);
            if(![action compare:@"start"])
            {
                recievedDataId = [json objectForKey:@"dataId"];
		        startTimeForDataSentStr = [json objectForKey:@"startTime"];
                [concatenatedData setLength:0];
                NSLog(@"didReceiveMessageWithBuffer: start recievedDataId= %@",recievedDataId);
            }
            else
                if(![action compare:@"stop"])
                {
                    NSString* stopDataId = [json objectForKey:@"dataId"];
                    NSDate* stopTimeForDataSent = [NSDate date];
                    NSLog(@"didReceiveMessageWithBuffer : stop recievedDataId = %@",recievedDataId);
                    NSLog(@"didReceiveMessageWithBuffer : stop total data length = %lu",
                                            (unsigned long)[concatenatedData length]/1024);
                    NSDate* startTimeForDataSent = [dateFormatter dateFromString:startTimeForDataSentStr];
                    CGFloat differenceInSec = [stopTimeForDataSent timeIntervalSinceDate:startTimeForDataSent];
                    NSLog(@"didReceiveMessageWithBuffer:Total time for transfered file is = %f",differenceInSec);
                    
                    if(![stopDataId compare:recievedDataId])
                    {
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Image.jpg"];
                        [concatenatedData writeToFile:filePath atomically:YES];
                        [self.delegate onSessionDataWithImage:filePath];
                        [concatenatedData setLength:0];
                    }
                    else
                    {
                        [webrtcstack logToAnalytics:@"SDK_Error"];
                        NSMutableDictionary* details = [NSMutableDictionary dictionary];
                        [details setValue:@"Data received is not complete" forKey:NSLocalizedDescriptionKey];
                        NSError *error = [NSError errorWithDomain:Session code:ERR_DATA_RECEIVED userInfo:details];
                        [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
                    }
                    
                }
        }
    }
    else
    {
        [concatenatedData appendData:dataBuff];
    }
    
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel;
{
    NSLog(@"DataChannel::Inside didOpenDataChannel");
    if (_dataChannel == nil)
    {
        _dataChannel = dataChannel;
        _dataChannel.delegate = self;
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
    NSLog(@"Inside sendCompressedImageData");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSUInteger length = [imgData length];
        NSUInteger offset = 0;
        NSError *jsonError = nil;
        NSString* dataID = [[NSUUID UUID] UUIDString];

        NSString* currentDate = [dateFormatter stringFromDate:[NSDate date]];
	
        NSMutableDictionary* json = [[NSMutableDictionary alloc]init];
	
        [json setValue:@"start" forKey:@"action"];
        [json setValue:dataID forKey:@"dataId"];
	    [json setValue:currentDate forKey:@"startTime"];
        NSLog(@"sendDataWithImage::Image ID = %@",dataID);
        NSLog(@"sendDataWithImage::total length = %ld",(unsigned long)length);
        
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:0 error:&jsonError];
        [self sendDataChannelMessage:data];
        
        do {
            if(cancelSendData)
                break;
            NSUInteger thisChunkSize = length - offset > sessionConfig.dataChunkSize ? sessionConfig.dataChunkSize : length - offset;
            NSLog(@"Sending imagePickerController::thisChunkSize = %ld offset = %ld",(unsigned long)thisChunkSize,(unsigned long)offset);
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
    });
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
    NSLog(@"sendDataWithImage");
    // Try to load asset at imgURL
    [library assetForURL:imgURL resultBlock:^(ALAsset *asset) {
        if (asset) {
            
            ALAssetRepresentation *repr = [asset defaultRepresentation];
            NSLog(@"sendDataWithImage: calling sendCompressedImageData [repr size] = %ld",(long)[repr size]);
            UIImage *image = [UIImage imageWithCGImage:[repr fullResolutionImage] scale:[repr scale] orientation:(UIImageOrientation)repr.orientation];
            UIImage *image2 = [self unrotateImage:image];
            
            // Based on the image, scale the image
            if(sessionConfig.dataScaleFactor == lowScale)
            {
                [self sendCompressedImageData:UIImageJPEGRepresentation(image2, 0.3)];
            }
            else
            if(sessionConfig.dataScaleFactor == midScale)
            {
                [self sendCompressedImageData:UIImageJPEGRepresentation(image2, 0.7)];
            }
            else
            if(sessionConfig.dataScaleFactor == original)
            {
                [self sendCompressedImageData:UIImageJPEGRepresentation(image2, [repr size])];
            }
            
        } else {
            
            [webrtcstack logToAnalytics:@"SDK_Error"];
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Sending Image data failed" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:Session code:ERR_DATA_SEND userInfo:details];
            [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
        }
    } failureBlock:^(NSError *error) {
        
        [webrtcstack logToAnalytics:@"SDK_Error"];
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Incorrect Image URL" forKey:NSLocalizedDescriptionKey];
        error = [NSError errorWithDomain:Session code:ERR_INCORRECT_URL userInfo:details];
        [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];
    }];
}

//Data channel API's to send either a NSString or a Json msg

-(void) sendDataWithText:(NSString*)_textMsg
{
    NSData* data = [_textMsg dataUsingEncoding:NSUTF8StringEncoding];
    [self sendDataChannelMessage:data];
}

#endif

-(void)finalStats{
   
    NSMutableDictionary* metaData1 = [[NSMutableDictionary alloc]init];
    NSMutableDictionary* metaData = [[NSMutableDictionary alloc]init];
    NSMutableDictionary* streamInfo1 = [[NSMutableDictionary alloc]init];
    NSMutableDictionary* streamInfo = [[NSMutableDictionary alloc]init];
    
    
    streamInfo1 =  [statcollector streamInfo];
    metaData1 = [webrtcstack getMetaData];
    
    
    //MetaData
    [metaData setObject:[NSString stringWithFormat:@"%@", [metaData1 objectForKey:@"alias"]] forKey:@"alias"];
    [metaData setObject:[NSString stringWithFormat:@"%@", [metaData1 objectForKey:@"iOSSDKVersion"]] forKey:@"iOSSDKVersion"];
    [metaData setObject:[NSString stringWithFormat:@"%@", [metaData1 objectForKey:@"manufacturer"]] forKey:@"manufacturer"];
    [metaData setObject:[NSString stringWithFormat:@"%@", [metaData1 objectForKey:@"model"]] forKey:@"model"];
    [metaData setObject:[NSString stringWithFormat:@"%@", [metaData1 objectForKey:@"networkType"]] forKey:@"networkType"];
    [metaData setObject:[NSString stringWithFormat:@"%@", [metaData1 objectForKey:@"packageName"]] forKey:@"packageName"];
    [metaData setObject:[NSString stringWithFormat:@"%@", [metaData1 objectForKey:@"sdkVersion"]] forKey:@"sdkVersion"];
    
    NSString *startTime = [NSString stringWithFormat:@"%@", [streamInfo1 objectForKey:@"startTime"]];
    NSString *stopTime = [NSString stringWithFormat:@"%@",[streamInfo1 objectForKey:@"stopTime"]];
    NSString *duration = [NSString stringWithFormat:@"%@", [streamInfo1 objectForKey:@"duration"]];
    NSString *traceId = [webrtcstack getTraceId];
    
    if(startTime != nil)[streamInfo setObject:startTime forKey:@"startTime"];
    if(stopTime != nil)
    {
        [streamInfo setObject:stopTime forKey:@"stopTime"];
        [metaData setObject:stopTime forKey:@"timestamp"];
    }
    if(duration != nil)[streamInfo setObject:duration forKey:@"duration"];
    if(xmppRoom != nil)[streamInfo setObject:xmppRoom forKey:@"roomId"];
    if(routingId != nil)[streamInfo setObject:routingId forKey:@"routingId"];
    if(serviceId !=nil)[streamInfo setObject:serviceId forKey:@"serviceId"];
    if(xmppServer != nil)[streamInfo setObject:xmppServer forKey:@"XMPPServer"];    
    if(rtcgid != nil)[streamInfo setObject:rtcgid forKey:@"rtcgSessionId"];
    if(turnIPToStat != nil)[streamInfo setObject:turnIPToStat forKey:@"turnIP"];
    if([streamInfo1 objectForKey:@"duration"] == nil)
    {

        [streamInfo setObject:[NSNumber numberWithBool:YES] forKey:@"turnUsed"];
    }
    else
    {
        [streamInfo setObject:[NSNumber numberWithBool:turnUsedToStat] forKey:@"turnUsed"];
    }
    if(traceId != nil)[streamInfo setObject:traceId forKey:@"traceId"];
    
    [self.delegate OnfinalStats:metaData timeseries:[lastSr stats] streamInfo:streamInfo];
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
        NSLog(@"jidFrom: %@", jidFrom);
        
        NSString *jsonStr = [message body];
        
        NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
        NSString *type = [jsonDict objectForKey:@"type"];
        NSLog(@"jidFrom: %@", type);
        
        if ([type compare:@"offer"] == NSOrderedSame) {
            NSLog(@"Set jidFrom");
             [self setFromJid:jidFrom];
        }
        
        [self onSignalingMessage:jsonDict];
    }
    
}

#pragma mark - XMPP session delegate

- (void)xmppWorker:(XMPPWorker *)sender didReceiveSessionInitiate:(NSString *)to  sid:(NSString*)sid;
{
    NSLog(@"xmppWorker : didReceiveSessionInitiate,");
}

- (void)xmppWorker:(XMPPWorker *)sender didReceiveSetRemoteDescription:(NSXMLElement*)jingle type:(NSString*)type;
{
    NSLog(@"xmppWorker : didReceiveSetRemoteDescription,");
}

- (void)xmppWorker:(XMPPWorker *)sender didReceiveaddIceCandidates:(NSXMLElement*)jingleContent;
{
    NSLog(@"xmppWorker : didReceiveaddIceCandidates,");
}

- (void)xmppWorker:(XMPPWorker *)sender didJoinRoom:(NSString*)roomName;
{
    NSLog(@"xmppWorker : didJoinRoom");
    
    [[XMPPWorker sharedInstance] joinRoom:roomName appDelegate:self];
}


//XMPP: Incoming file path for sharecast
- (void)xmppWorker:(XMPPWorker *)sender didReceiveFileWithPath:(NSString *)filePath
{
    NSLog(@"xmppWorker : didReceiveFileWithPath");
    
    [self.delegate onSessionDataWithImage:filePath];
    
}

- (void)xmppWorker:(XMPPWorker *)sender didFailWithError:(NSError *)error
{
    NSLog(@"xmppWorker : didFailWithError");
    [webrtcstack logToAnalytics:@"SDK_Error"];
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:error.description forKey:NSLocalizedDescriptionKey];
    NSError *err = [NSError errorWithDomain:Session code:ERR_DATA_RECEIVED userInfo:details];
    [self.delegate onSessionError:err.description errorCode:err.code additionalData:nil];
    
}

//xmpp connection error
-(void)xmppError:(NSString *)error errorCode:(NSInteger)code
{
    [webrtcstack logToAnalytics:@"SDK_Error"];
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:error forKey:NSLocalizedDescriptionKey];
    NSError *err = [NSError errorWithDomain:Session code:code userInfo:details];
    [self.delegate onSessionError:err.description errorCode:err.code additionalData:nil];

}


#pragma mark - XMPP room delegate

- (void)xmppRoomDidCreate:(XMPPRoom *)sender
{
    NSLog(@"XMPP Stack : xmppRoomDidCreate");
    [webrtcstack logToAnalytics:@"SDK_XMPPRoomCreated"];

    // [self.xmppRoom changeRoomSubject:self.roomSubject];
    
}

- (void)xmppRoomDidJoin:(XMPPRoom *)sender
{
    NSLog(@"XMPP Stack : xmppRoomDidJoin");
    //[[XMPPWorker sharedInstance] activateJingle:self];
    [webrtcstack logToAnalytics:@"SDK_XMPPJoined"];

    [self.delegate onXmppJoined:[[sender roomJID] user]];
    
    if(sessionConfig.callType == pstncall)
    {
        [self startPSTNCall:sessionConfig.targetPhoneNum];
    }
if ((callType != incoming)  && !webrtcstack.isVideoBridgeEnable)
    {
        NSLog(@"XMPP Stack : starting session in xmppRoomDidJoin");
        [self startSession:updatedIceServers];
    } }

- (void)xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    NSLog(@"XMPP Stack : xmppRoom occupantDidJoin %@ with presence %@", [occupantJID bare], [presence description]);
    
    //if (webrtcstack.isVideoBridgeEnable)
    {
        if ([[occupantJID full] containsString:@"focus"] || [[occupantJID full] containsString:@"xrtc_sp00f_f0cus"])
        {
            // Note down the occupant JID
            targetJid = occupantJID;
            [webrtcstack logToAnalytics:@"SDK_XMPPFocusJoined"];
            
            if (callType == incoming)
                [webrtcstack setIsVideoBridgeEnable:true];
            
        }
        else
        {
            
            if ([presence elementForName:@"media"] )
            {
                [webrtcstack logToAnalytics:@"SDK_XMPPOccupantHasStreams"];
            }
           else
            {
                isOccupantJoined = true;
                [webrtcstack logToAnalytics:@"SDK_XMPPOccupantJoined"];
                /* Let the app know who has the joined the participant */
                if (self.delegate != nil)
                {
                    [self.delegate onXmppParticipantJoined: [occupantJID resource]];
                }
                
                // Note down the occupant JID
                if (!webrtcstack.isVideoBridgeEnable)
                    targetJid = occupantJID;
                
                // If this is a pull call, send the session-initiate message
                if ((callType != incoming)  && !webrtcstack.isVideoBridgeEnable && !isOfferSent)
                {
                    //dataSessionActive = true;
                    //[self startSession:updatedIceServers];
                    if (isOccupantJoined && isXMPPEnable && !(webrtcstack.isVideoBridgeEnable) && (callType != incoming))
                    {
                        [[XMPPWorker sharedInstance] sendJingleMessage:@"session-initiate" data:offerJson target:targetJid];
                        isOfferSent = true;
                        [webrtcstack logToAnalytics:@"SDK_OfferSent"];
                        
                        if(!sessionConfig.delaySendingCandidate)
                        {
                            for (id data in iceCandidates){
                             [self sendMessage:data];
                             }
                        }
                        
                        
                    }
                }
                
               
            }
            
        }
    }
    /*else
     {
     // Note down the occupant JID
     targetJid = occupantJID;
     
     [webrtcstack logToAnalytics:@"SDK_XMPPOccupantJoined"];
     / Let the app know who has the joined the participant /
     if (self.delegate != nil)
     {
     [self.delegate onXmppParticipantJoined: [occupantJID resource]];
     }
     
     // If this is a pull call, send the session-initiate message
     if ((callType != incoming) && !dataSessionActive)
     {
     dataSessionActive = true;
     [self startSession:updatedIceServers];
     }
     }*/
}
- (void)xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    NSLog(@"XMPP Stack : xmppRoom occupantDidLeave %@", [occupantJID bare]);
    [webrtcstack logToAnalytics:@"SDK_XMPPOccupantLeft"];

    /* Let the app know who has the joined the participant */
    if (self.delegate != nil)
    {
        [self.delegate onXmppParticipantLeft:[occupantJID bare]];
    }
    
    if (webrtcstack.isVideoBridgeEnable)
    {
        if ([[occupantJID full] containsString:@"jirecon"])
        {
            return;
        }
    }
    
    //Close session
    [self.delegate onSessionEnd:@"Remote left room"];
    [statcollector stopMetric:@"callDuration"];

    if(_statsTimer != nil)
    [_statsTimer invalidate];

    state = inactive;
    [self closeSession];

    // Disconnect socket
    [[XMPPWorker sharedInstance] disconnect];

    //Deactivate Jingle
    [[XMPPWorker sharedInstance] deactivateJingle];
    
}

- (void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID
{
    NSLog(@"XMPP Stack : xmppRoom didReceiveMessage");

}

#pragma mark - XMPP Jingle delegate

// For Action (type) attribute: "session-accept", "session-info", "session-initiate", "session-terminate"
- (void)didReceiveSessionMsg:(NSString *)sid type:(NSString *)type data:(NSDictionary *)data
{
    NSLog(@"XMPP Stack : xmppJingle didReceiveSessionMsg of type %@ with session id %@ with data %@", type, sid, data);
    
    // Check the type of the message
    // For session-initiate, treat as incoming call and start the session
    // For session-accept, treat as outgoing call and set the answer SDP
    // For session-terminate, treat as bye message
    if ([type isEqualToString:@"session-accept"])
    {
        [webrtcstack logToAnalytics:@"SDK_XMPPJingleSessionAcceptReceived"];

        [self onAnswerMessage:data];
    }
    else if ([type isEqualToString:@"session-initiate"])
    {
        [webrtcstack logToAnalytics:@"SDK_XMPPJingleSessionInitiateReceived"];

        [self onOfferMessage:data];
    }
    else if ([type isEqualToString:@"source-add"])
    {
        NSLog(@"WebRTCSession:didReceiveSessionMsg:source-add");
    }
    else if ([type isEqualToString:@"source-remove"])
    {
        NSLog(@"WebRTCSession:didReceiveSessionMsg:source-remove");
    }
}

// For Action (type) attribute: "transport-accept", "transport-info", "transport-reject", "transport-replace"
- (void)didReceiveTransportMsg:(NSString *)sid type:(NSString *)type data:(NSDictionary *)data
{
    NSLog(@"XMPP Stack : xmppJingle didReceiveTransportMsg %@", data);
    
    if ([type isEqualToString:@"transport-info"])
    {
        [webrtcstack logToAnalytics:@"SDK_XMPPJingleTransportInfoReceived"];

        [self onCandidateMessage:data];
    }

}

// For Action (type) attribute: "content-accept", "content-add", "content-modify", "content-reject", "content-remove"
- (void)didReceiveContentMsg:(NSString *)sid type:(NSString *)type data:(NSDictionary *)data
{
    NSLog(@"XMPP Stack : xmppJingle didReceiveContentMsg");

}

// For Action (type) attribute: "description-info"
- (void)didReceiveDescriptionMsg:(NSString *)sid type:(NSString *)type data:(NSDictionary *)data
{
    NSLog(@"XMPP Stack : xmppJingle didReceiveDescriptionMsg");

}

//For Action(type) attribute: "mute","unmute","video on","video off"
-(void)didReceiveMediaPresenceMsg:(NSString*)msg{
    
    [self.delegate onConfigMessage_xcmav:msg];
}

// In case any error is received
- (void)didReceiveError:(NSString *)sid error:(NSDictionary *)data
{
    NSLog(@"XMPP Stack : xmppJingle didReceiveError");
    NSError *error = [NSError errorWithDomain:Session code:ERR_XMPP_ERROR userInfo:data];
    [self.delegate onSessionError:error.description errorCode:error.code additionalData:nil];

}

- (void)onXmppServerConnected
{
    [webrtcstack onXmppServerConnected];
}

//Random String Calculation
- (NSString *)generateRandomString
{
    NSUInteger noOfChars = 14;
    char data[noOfChars];
    for (int x=0;x<noOfChars;data[x++] = (char)('a' + (arc4random_uniform(26))));
    return [[NSString alloc] initWithBytes:data length:noOfChars encoding:NSUTF8StringEncoding];
}
-(NSString *)getRandomNumber
{
    NSMutableString *returnString = [NSMutableString stringWithCapacity:10];
    
    NSString *numbers = @"0123456789";
    
    // First number cannot be 0
    [returnString appendFormat:@"3"];
    
    for (int i = 0; i < 10; i++)
    {
        [returnString appendFormat:@"%C", [numbers characterAtIndex:arc4random() % [numbers length]]];
    }
    
    return returnString;
}

- (void)preferCodec:(BOOL)value
{
    if(value)
        setCodec = @"H264";
    else
        setCodec = @"VP8";

}
@end
#endif
