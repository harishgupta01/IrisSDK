//
//  IrisRtcConnection.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 9/29/16.
//  Copyright © 2016 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IrisRtcConnection.h"
#import "XMPPWorker.h"
#import "IrisRtcEventManager.h"
#import "IrisDataElement.h"
#import "Reachability.h"
#import "IrisLogging.h"
#import "IrisRtcJingleSession.h"
#import "IrisRtcJingleSession+Internal.h"

#define RECONNET_TRY_TIMEOUT 3

NSString* const Connection     = @"IrisRtcConnection";

@interface IrisRtcConnection () <XMPPWorkerWebSocketDelegate,IrisRtcEventManagerDelegate>{
    NSTimer *_reconnectTimeoutTimer;
    NetworkStatus networkStatus;
    BOOL networkSwitched;
    BOOL networkAvailable;
    BOOL isConnectionDisconnected;

}

@property(nonatomic, weak) id<IrisRtcConnectionDelegate> delegate;
@property(nonatomic) NSString* sourceId;
@property(nonatomic) NSString* serverUrl;
@property(nonatomic) NSString* jwToken;


@property(nonatomic) NSString* xmppToken;
@property(nonatomic) NSString* xmppTokenExpiryTime;
@property(nonatomic) NSString* xmppRTCServer;
@property(nonatomic) NSDictionary* turnServers;
@property(nonatomic) IrisRtcEventManager *eventManager;
@property (nonatomic) Reachability* internetReachability;
@property (nonatomic) BOOL isHitlessupgradeReconnect;

-(void)connectToServer:(NSString*)xmppServer _timestamp:(NSString*)timestamp _xmppToken:(NSString*)xmppToken;

@end

@implementation IrisRtcConnection

@synthesize state,enableReconnect,isAnonymousRoom;


+(IrisRtcConnection *)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static IrisRtcConnection *sharedConnection = nil;
    dispatch_once(&pred, ^{
        sharedConnection = [[self alloc] init];
    });
    
    return sharedConnection;
}

-(NSString*) getJsonWebToken{
    
    return self.jwToken;
}
-(id)init
{
    self = [super init];
    if (self!=nil) {
        state = kConnectionStateDisconnected;
        //Doing Init set up for XMPP Stream
        _pingTimeInterval = 0;
        _pingTimeoutInterval = 0;
        _reconnectTimeoutTimer = nil;
        [[XMPPWorker sharedInstance]startEngine];
        [[XMPPWorker sharedInstance] setWebSocketDelegate:self];
         _isHitlessupgradeReconnect = false;
        networkSwitched = false;
        enableReconnect = true;
        networkAvailable = true;
        isConnectionDisconnected = false;
        IRISLogVerbose(@"IrisRtcConnection Init Done::Info");
    }
    
    return self;
}

-(BOOL)connectUsingServer:(NSString* )serverUrl irisToken:(NSString*)irisToken routingId:(NSString*)routingId delegate:(nullable id)delegate error:( NSError* _Nullable *)outError
{
    IRISLogVerbose(@"IrisRtcConnection::connectUsingServer state is = %lu",(unsigned long)state);
    //TODO Need figure out a better way to print CURRENT_PROJECT_VERSION from plist
#ifdef SDK_VERSION
    IRISLogInfo(@"SDK version = %@",SDK_VERSION);
#endif
    
    if(state == kConnectionStateConnected || state == kConnectionStateReconnecting){
        IRISLogInfo(@"IrisRtcConnection is already connected !!");
        return true;
    }
    
    if(serverUrl == nil || irisToken == nil || routingId == nil || ([serverUrl length] ==0) || ([irisToken length] ==0) || ([routingId length] ==0))
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"One of the argument passed is null" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:Connection code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
    }
    if(_pingTimeInterval != 0)
        [[XMPPWorker sharedInstance] setPingTimeInterval:_pingTimeInterval];
    
    if(_pingTimeoutInterval != 0)
        [[XMPPWorker sharedInstance] setPingTimoutInterval:_pingTimeoutInterval];
    
    
    
    IRISLogInfo(@"connectUsingServer = %lu",(unsigned long)state);
    if(state ==  kConnectionStateDisconnected)
    {
        state = kConnectionStateConnecting;
        self.delegate = delegate;
        self.sourceId = routingId;
        self.serverUrl = serverUrl;
        self.jwToken = irisToken;
        [[XMPPWorker sharedInstance]setRoutingId:routingId];
        [self connect];
        [self setUpReachabilityCheck];
        return YES;
    }
    else
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not disconnected yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:Connection code:ERR_INCORRECT_STATE userInfo:details];
    }
    
    
    
    return NO;
}

/*-(BOOL)connectUsingServer:(NSString*)serverUrl irisToken:(NSString*)irisToken routingId:(NSString*)routingId notificationPayload:(IrisNotificationPayload*)notificationPayload delegate:(nullable id)delegate error:(NSError* _Nullable *)outError
{
    if(serverUrl == nil || irisToken == nil || routingId == nil
                || notificationPayload == nil)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"One of the argument passed is null" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:Connection code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
    }
    
    if(_pingTimeInterval)
        [[XMPPWorker sharedInstance] setPingTimeInterval:_pingTimeInterval];
    
    if(state ==  kConnectionStateDisconnected)
    {
        state = kConnectionStateConnecting;
        self.delegate = delegate;
        self.sourceId = routingId;
        self.serverUrl = serverUrl;
        self.jwToken = irisToken;
        [[XMPPWorker sharedInstance]setRoutingId:routingId];
        [self connectToServer:notificationPayload.rtcServerUrl _timestamp:notificationPayload.timestamp _xmppToken:notificationPayload.xmppToken];
        return YES;
    }
    else
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not disconnected yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:Connection code:ERR_INCORRECT_STATE userInfo:details];
    }
    return NO;
}*/

-(void) connect
{
    NSString *formattedUrl = nil;
    if(![_serverUrl hasSuffix:@"/"]){
        _serverUrl =  [_serverUrl stringByAppendingString:@"/"];
    }
    if(isAnonymousRoom){
        formattedUrl = [NSString stringWithFormat:@"%@v1.1/wsturnserver/anonymoususer/%@", _serverUrl,_sourceId];
    }
    else{
        formattedUrl = [NSString stringWithFormat:@"%@v1/wsturnserverinfo/routingid/%@", _serverUrl,_sourceId];
    }
    //formattedUrl = [NSString stringWithFormat:@"%@v1/xmppregistrationinfo/routingid/%@", _serverUrl,_sourceId];
    
    
    
    NSString* jsonWebToken = [@"Bearer " stringByAppendingString:_jwToken];
    IRISLogInfo(@"Inside IrisrtcConnection::formatUrl = %@",formattedUrl);
    _eventManager = [[IrisRtcEventManager alloc]initWithURL:formattedUrl _token:jsonWebToken delegate:self];
    [[XMPPWorker sharedInstance]setJwToken:jsonWebToken];
    [_eventManager getXmppRegisterInfo];
    
}

-(void)disconnect
{
    IRISLogVerbose(@"IrisRtcConnection::disconnect state is = %lu",(unsigned long)state);
    if(state != kConnectionStateDisconnected){
        IRISLogVerbose(@"irisRtcConnection::disconnect");
        state = kConnectionStateDisconnected;
        [[XMPPWorker sharedInstance]setIsAttemmptingReconnect:false];
        _isHitlessupgradeReconnect = false;
        isConnectionDisconnected = true;
        [_eventManager End];
        [[XMPPWorker sharedInstance]disconnectWebSocket];
       // [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    }
    
    if(_reconnectTimeoutTimer != nil)
        [_reconnectTimeoutTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    _internetReachability = nil;
    _eventManager = nil;
    
}

-(void)disconnectOnError{    
  
    if(enableReconnect){
       
//        if(state != kConnectionStateDisconnected){
//            state = kConnectionStateDisconnected;
//
//        }
        state = kConnectionStateReconnecting;
        _isHitlessupgradeReconnect = false;
        [_eventManager End];
        [[XMPPWorker sharedInstance]disconnectWebSocket];
         [self startReconnectTimer];
       
        
//      if(networkSwitched && networkAvailable){
//        [self initiateReconnection];
//      }else if(!networkSwitched){
//        [self onXmppWebSocketDisconnected:nil];
//      }

    }else{
        [self disconnect];
        [self onXmppWebSocketDisconnected:nil];
    }
}
- (void)irisXmppWebSockConnect
{
    if((_xmppToken == nil) || (_xmppTokenExpiryTime == nil) ||
       (_xmppRTCServer == nil))
    {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Incorrect requied parameters xmppToken/xmppTokenExpiryTime/xmppRTCServer" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:Connection code:ERR_INCORRECT_PARAMS userInfo:details];
            [self.delegate onError:error withAdditionalInfo:nil];
    }
    
    [self connectToServer:_xmppRTCServer _timestamp:_xmppTokenExpiryTime _xmppToken:_xmppToken];
}

-(void)connectToServer:(NSString*)xmppServer _timestamp:(NSString*)timestamp _xmppToken:(NSString*)xmppToken
{
IRISLogVerbose(@"IrisRtcConnection::connectToServer state is = %lu",(unsigned long)state);
  //  IRISLogInfo(@"WebRTCStack: :websocketURL = %@",xmppServer);
  //  IRISLogInfo(@"WebRTCStack::timestamp = %@",timestamp);
  //  IRISLogInfo(@"WebRTCStack::xmppToken = %@",xmppToken);
    [IrisDataElement setHostName:xmppServer];
    [[XMPPWorker sharedInstance]setActualHostName:xmppServer];
 //   [[XMPPWorker sharedInstance]setHostName:xmppServer];
    
    //[[XMPPWorker sharedInstance]setHostName:@"poc-xmpp-cmc-e-002.rtc.sys.comcast.net"];
    [[XMPPWorker sharedInstance] setUserName:_sourceId];
    [[XMPPWorker sharedInstance] setToken:xmppToken];
    //[[XMPPWorker sharedInstance] setMucId:roomId];
    [[XMPPWorker sharedInstance] setTimestamp:timestamp];
    //[[XMPPWorker sharedInstance] setRoutingId:stackConfig.userId];
    [[XMPPWorker sharedInstance] setRoutingId:_sourceId];
    //[[XMPPWorker sharedInstance] setUserName:@"test1@st-xmpp-wbrn-001.rtc.sys.comcast.net"];
    [[XMPPWorker sharedInstance] setUserPwd:@""];
    
    
   
   // [[XMPPWorker sharedInstance] setEvent:stackConfig.event];

    //[[XMPPWorker sharedInstance] setMaxParticipants: [NSString stringWithFormat:@"%d", (int)__sessionConfig.maxParticipants]];
    //[self logToAnalytics:@"SDK_XMPPServerConnectRequest"];
    
    //Saving event manager url which will used by session for cretaroot api call
    
    [[XMPPWorker sharedInstance]setEventManagerUrl:_serverUrl];
    [[XMPPWorker sharedInstance] connect];
}

-(void)setUpReachabilityCheck{
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification object:nil];
    
    _internetReachability = [Reachability reachabilityForInternetConnection];
    [_internetReachability startNotifier];
    
    networkStatus = _internetReachability.currentReachabilityStatus;
    
 
}

-(BOOL)setIrisToken:(nonnull NSString *)token error:(NSError* _Nullable *)outError{
    if([token length] == 0)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"One of the argument passed is null or empty" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:Connection code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
    }
    //IRISLogInfo(@"Setting new Iris Token = %@",token);
    _jwToken = token;
    NSString* jsonWebToken = [@"Bearer " stringByAppendingString:token];
    [[XMPPWorker sharedInstance]setJwToken:jsonWebToken];
    return YES;
}

- (void)reachabilityChanged:(NSNotification*)notification
{
   
    Reachability* curReach = [notification object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);

    if(enableReconnect){
        if(curReach.currentReachabilityStatus == NotReachable && networkStatus !=  curReach.currentReachabilityStatus)
        {
            IRISLogWarn(@"reachabilityChanged::Disconnecting due to reachability change = %ld", (long)_internetReachability.currentReachabilityStatus);
            
            networkStatus = curReach.currentReachabilityStatus;
            networkSwitched = true;
            networkAvailable = false;
//            _reconnectTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:RECONNET_TRY_TIMEOUT
//                                                                      target:self
//                                                                    selector:@selector(onConnectionReconnect)
//                                                                    userInfo:nil
//                                                                     repeats:YES
//                                      ];

        }
        else if(networkStatus != curReach.currentReachabilityStatus)
        {
            IRISLogWarn(@"reachabilityChanged::Reconnecting due to change in reachability state = %ld ", (long)_internetReachability.currentReachabilityStatus);

            networkStatus = curReach.currentReachabilityStatus;
            networkSwitched = true;
            networkAvailable = true;
            [_reconnectTimeoutTimer fire];
//            if(state == kConnectionStateDisconnected){
//                [self initiateReconnection];
//            }
            
//            if(_reconnectTimeoutTimer != nil){
//                [_reconnectTimeoutTimer invalidate];
//                [self initiateReconnection];
//            }

        }
    }else{
        if (curReach == self.internetReachability)
        {
            if(state != kConnectionStateDisconnected){
                         IRISLogWarn(@"reachabilityChanged::Disconnecting due to reachability change = %ld", (long)_internetReachability.currentReachabilityStatus);
                        [self disconnectOnError];
            }
        }
    }
}

- (void)initiateReconnection{
    [self.delegate onReconnecting];
    IRISLogWarn(@"initiateReconnection:: state = %lu networkAvailable  = %@", (unsigned long)state, networkAvailable ? @"YES":@"NO");
    [[XMPPWorker sharedInstance]setIsAttemmptingReconnect:true];
    if(state == kConnectionStateReconnecting && networkAvailable){
        // [self connectUsingServer:_serverUrl irisToken:_jwToken routingId:_sourceId delegate:_delegate error:&error];
        state = kConnectionStateConnecting;
        [self connect];
    }
   
}

#pragma mark - Event Manager Delegate

- (void) onXmppRegisterInfoSuccess:(NSString*)rtcServer _xmppToken:(NSString*)token _tokenExpiryTime:(NSString*)expiryTime _turnServer:(NSDictionary*)turnServer;
{
    
    self.xmppRTCServer = rtcServer;
    self.xmppToken = token;
    self.xmppTokenExpiryTime = expiryTime;
    self.turnServers = turnServer;
    [[XMPPWorker sharedInstance]setTurnServers:turnServer];
    [self irisXmppWebSockConnect];
   // IRISLogInfo(@"onIRISRegisterInfo rtcServer = %@, token = %@, expiryTime = %@",rtcServer,token,expiryTime);
    //Creating WS connection
    //[self createWebSockAndXMPPConnection:@"" _timestamp:expiryTime _xmppToken:token _xmppServer:rtcServer];
}

- (void) onEventManagerFailure:(NSError*)error additionalData:(NSDictionary *)additionalData
{
    if([error code] == ERR_JWT_EXPIRE && _reconnectTimeoutTimer != nil){
        [_reconnectTimeoutTimer invalidate];
    }
    state = kConnectionStateDisconnected;
    [self.delegate onError:error withAdditionalInfo:additionalData]; 
}

#pragma mark - XMPP WebSocket Delegate

- (void)onXmppWebSocketConnected
{
    //[self logToAnalytics:@"SDK_XMPPServerConnected1"];
    state = kConnectionStateConnected;
}

- (void)onXmppWebSocketAuthenticated
{
    IRISLogVerbose(@"IrisRtcConnection::onXmppWebSocketAuthenticated state is = %lu",(unsigned long)state);
    if(_reconnectTimeoutTimer != nil)
        [_reconnectTimeoutTimer invalidate];
   
    if(state != kConnectionStateDisconnected){
        state = kConnectionStateAuthenticated;
        [[XMPPWorker sharedInstance] startAliveIQTimer];
        [[XMPPWorker sharedInstance]setIsAttemmptingReconnect:false];
        
        
        //if(networkSwitched){
            if([[[XMPPWorker sharedInstance] activeSessions] count] > 0){
                NSArray* keys = [[[XMPPWorker sharedInstance] activeSessions] allKeys];
                for (NSString* roomId in keys){
                    [[[[XMPPWorker sharedInstance] activeSessions] objectForKey:roomId ] restartSession];
                }
            }
            //networkSwitched = false;
        //}
        
        [self.delegate onConnected];
    }
}

- (void)onXmppWebSocketReconnect
{
    IRISLogVerbose(@"IrisRtcConnection::onXmppWebSocketReconnect state is = %lu",(unsigned long)state);
    _isHitlessupgradeReconnect = true;
    if([[[XMPPWorker sharedInstance] activeSessions] count] <= 0){
      
        if(state != kConnectionStateDisconnected){
            IRISLogVerbose(@"irisRtcConnection::disconnect");
            [[XMPPWorker sharedInstance]disconnectWebSocket];
        }
    }else{
       
        [[XMPPWorker sharedInstance]setIsHitlessUpgrade:true];
    }
    
}

-(void)startReconnectTimer{
    
    if(![_reconnectTimeoutTimer isValid]){        
       
        _reconnectTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:RECONNET_TRY_TIMEOUT
                                                                  target:self
                                                                selector:@selector(initiateReconnection)
                                                                userInfo:nil
                                                                 repeats:YES
                                  ];
    } 
}

- (void)onXmppWebSocketError:(NSString*) error
{
    /*if(state != kConnectionStateDisconnected){
        IRISLogInfo(@"onXmppWebSocketError::Initiating disconnect from SDK");
        [[self disconnect];
         [self onXmppWebSocketDisconnected:nil];]
        //IRISLogInfo(@"XMPP Stack : Received an error  :: %@", error);
        //[self logToAnalytics:@"SDK_Error"];
        //[self logToAnalytics:@"SDK_XMPPAuthenticationFailed"];
        /*NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:error forKey:NSLocalizedDescriptionKey];
        NSError *error1 = [NSError errorWithDomain:Socket code:ERR_XMPP_AUTHENTICATION_FAILED userInfo:details];
        [self.delegate onError:error1 withAdditionalInfo:nil];
        //self.delegate = nil;
    }*/
    [self disconnectOnError];
}

- (void)onXmppWebSocketDisconnected:(NSString*) error
{
    IRISLogVerbose(@"IrisRtcConnection::onXmppWebSocketDisconnected state is = %lu",(unsigned long)state);
    IRISLogWarn(@"XMPP Stack : onDisconnect  :: %@", error);
    
    if(isConnectionDisconnected){
        isConnectionDisconnected = false;
        if (_reconnectTimeoutTimer != nil) {
            [_reconnectTimeoutTimer invalidate];
        }
        //[self logToAnalytics:@"SDK_XMPPServerDisconnected"];
        if(state != kConnectionStateDisconnected){
            state = kConnectionStateDisconnected;
            [self.delegate onDisconnected];
            
            if(_isHitlessupgradeReconnect){
                _isHitlessupgradeReconnect = false;
                state = kConnectionStateReconnecting;
                [self initiateReconnection];
            }else{
                self.delegate = nil;
                [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
                _internetReachability = nil;
                _eventManager = nil;
            }
        }
    }
}

- (void)onXmppWebSocketPingPongFailure{
    IRISLogVerbose(@"IrisRtcConnection::onXmppWebSocketPingPongFailure state is = %lu",(unsigned long)state);
    IRISLogError(@"onXmppWebSocketPingPongFailure");
    [self disconnectOnError];
}
- (void)onXmppWebSocketError:(NSString *)error errorCode:(NSInteger)code;
{
     IRISLogVerbose(@"IrisRtcConnection::onXmppWebSocketError state is = %lu",(unsigned long)state);
     /*if(state != kConnectionStateDisconnected){
        IRISLogInfo(@"onXmppWebSocketError::Initiating disconnect from SDK");
         [self disconnect];
         [self onXmppWebSocketDisconnected:nil];
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:error forKey:NSLocalizedDescriptionKey];
        NSError *error1 = [NSError errorWithDomain:Socket code:code userInfo:details];
        [self.delegate onError:error1 withAdditionalInfo:nil];
         self.delegate = nil;
     }*/
    
    [self disconnectOnError];
}

- (void)onXmppWebSocketNotification:(NSDictionary*) data
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onNotification:)])
    {
        [self.delegate onNotification:data];
    }
}


@end

@implementation IrisNotificationPayload

@synthesize rtcServerUrl;
@synthesize xmppToken;
@synthesize timestamp;

@end

@implementation IrisRtcConnection (Internal)
-(void)checkServerConnectionState{
        if(state != kConnectionStateDisconnected){
            IRISLogVerbose(@"irisRtcConnection::disconnect");
            [[XMPPWorker sharedInstance]disconnectWebSocket];
        }
}
@end
