 //
//  WebRTCStack.m
//  XfinityVideoShare
#ifdef ENABLE_LEGACY_CODE

#import "WebRTCSession.h"
#import "WebRTCStack.h"
#import "WebRTCError.h"
#import "SignalHandler.h"
#import <UIKit/UIKit.h>
#import "WebRTCJSON.h"
#import <sys/utsname.h>
#import "XMPPWorker.h"
#import "WebRTCLogHandler.h"
#import "WebRTCLogging.h"
#import <arpa/inet.h>
#import <CFNetwork/CFNetwork.h>
#import <netinet/in.h>
#import <netdb.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <net/ethernet.h>
#import <net/if_dl.h>

NSString* const Stack     = @"Stack";

#define ICE_SERVER_TIMEOUT 3
#define RECONNET_TRY_TIMEOUT 3

#define LIBSDK_VERSION "2.0.1.16" // Need to find a better way of doing this.

typedef enum {
    XmppInitialized,
    XmppRegistering,
    XmppRegistered,
    XmppWebSocketConnecting,
    XmppWebSocketConnected,
    
    
    
}WebRTCEventManagerState;

@interface WebRTCSession()

@end

// Defining all internal variables needed for this class
@interface WebRTCStack() <SignalHandlerDelegate,XMPPWorkerWebSocketDelegate>
{
    SignalHandler *sh;
    NSDictionary *sessions;
    WebRTCHTTP* httpconn;
    WebRTCEventManager* eventManager;
    NSData *wsToken;
    NSString *emailId;
    NSString *clientSessionId;
    NSDictionary *offerMsg;
    NSDictionary *iceservermsg;
    NSString *to;
    NSString *from;

    BOOL isChannelAPIEnable;
    BOOL isXMPPEnable;

    NSString* username;
    NSString *path;
    NSString* encodedcredential;
    BOOL isReconnecting;
    NSTimer *_reconnectTimer;
    WebRTCStatsCollector *statsCollector;

    
    Reachability* reachability;
    NetworkState nwState;
    NetworkStatus oldStatus;
    BOOL isNetworkAvailable;
    BOOL isNetworkStateUpdated;
    NSTimer *_reconnectTimeoutTimer;
    BOOL isWifiModePrev;
    BOOL isWifiMode;
    BOOL _dataFlag;
    WebRTCEventManagerState eventManagerState;
}

/* Below set of API's are used for internal purpose */
- (void)onRTCServerMessage:(NSString*)msg;
- (void)onRegMessage:(NSString*)msg;
- (void)onAuthMessage:(NSString*)msg;
- (void)rejectCall;
- (void)registerOnServer;
- (void)sendRegMessage:(id)msg;
- (void)OnLocalStream:(RTCVideoTrack *)videoTrack;
- (NSString*)getNetworkConnectionType;
- (void)onStackError:(NSString*)error errorCode:(NSInteger)code;
- (void)initiateReconnect;
- (NSString *) platformType:(NSString *)platform;
- (void)sendpreferredH264:(BOOL)preferH264;
- (void)sendCreateRoomRequest:(WebRTCSessionConfig*)sessionConfig;
- (void)sendJoinRoomRequest:(WebRTCSessionConfig*)sessionConfig;
- (void)sendCloseRoomRequest:(WebRTCSessionConfig*)sessionConfig;
- (void)setVideoBridgeEnable: (bool) flag;
- (void)parseGetResourceResponse:(NSData*)resources;
-(void)sendCreateXmppRootEventRequestWithRoomName:(WebRTCSessionConfig*)sessionConfig;
-(void)sendCreateXmppRootEventRequest:(WebRTCSessionConfig*)sessionConfig;
-(void)createWebSockAndXMPPConnection:(NSString*)roomId _timestamp:(NSString*)timestamp _xmppToken:(NSString*)xmppToken _xmppServer:(NSString*)xmppServer;
@property(nonatomic) id<WebRTCStackDelegate> delegate;



//xmpp
@property(nonatomic ) NSString* roomID;
@property(nonatomic ) WebRTCSession* session;
@property(nonatomic ) BOOL isIncomingCall;
@property(nonatomic ) BOOL isPSTNVoiceSession;
@property(nonatomic ) WebRTCSessionConfig *_sessionConfig;
@property(nonatomic ) BOOL isSMRoomCreated;
@property(nonatomic ) NSData* resourcesResponse;
@property(nonatomic ) NSDictionary* webSocketJson;
@property(nonatomic ) NSDictionary* iceServerJson;
@end


@implementation WebRTCStack

NSString* const TAG5 = @"WebRTCStack";

@synthesize networkType = _networkType;
@synthesize stackConfig = stackConfig;
- (id)initWithRTCG:(WebRTCStackConfig*)_stackConfig _appdelegate:(id<WebRTCStackDelegate>)_appdelegate
{
    if((!_stackConfig.serverURL) )
    {
        //TODO Need to return object type instead of enum
        //return ERR_INCORRECT_PARAMS;
        return nil;
    }
    else
    {
        NSURL *testURL = [NSURL URLWithString:_stackConfig.serverURL];

        // Check if the URL is valid
        if (!testURL || !testURL.scheme || !testURL.host) {
            LogDebug(@"initWithRTCG incorrect URL %@", _stackConfig.serverURL);
            return nil;
        }
    }
    
    self = [super init];
    if (self!=nil) {
        stackConfig = _stackConfig;
        
	_roomID = nil;
        _isIncomingCall = false;        //Stats logging implementation
        NSMutableDictionary* metaData = [self getMetaData];
        LogDebug(@"MetaData is = %@",metaData);
        //NSString* statEndpoint = @"http://st-uestats-fxbo.sys.comcast.net/stats";
        NSString* statEndpoint = stackConfig.statsURL;
       // NSString* statEndpoint = @"http://76.26.116.203";

        statsCollector = [[WebRTCStatsCollector alloc]initWithDefaultValue:metaData _appdelegate:(id<WebRTCStatsCollectorDelegate>)_appdelegate];
        
        // For now while dev is moving fast its nice if call logs are always reported
        // By the client we can eventually turn this off by default and have it turned on only by
        // debug signaling
        //[statsCollector setOmitCallLogInReport:false];
        
        //Making http request to get Websocket url and ice server
        //Currently hardcoding port number for testing purpose
        // NSString* httpReqURL = [NSString stringWithFormat:@"http://%@:8080/RTCGChannel-1.0/resources/websocket",serverUrl];
        wsToken = stackConfig.wsToken;
        
        NSMutableDictionary* jsonHeaders = [[NSMutableDictionary alloc]init];
        
        // Check if we have a URL ending with /
        if(!_stackConfig.usingRTC20)
        {
            if ([_stackConfig.serverURL hasSuffix:@"/"])
            {
                _stackConfig.serverURL = [_stackConfig.serverURL substringToIndex:[_stackConfig.serverURL length] - 1];
            }
            
            self.delegate = (id<WebRTCStackDelegate>)_appdelegate;
            
            NSString *formattedUrl = [NSString stringWithFormat:@"%@?sourceUID=%@", _stackConfig.serverURL,  _stackConfig.userId];
            httpconn = [[WebRTCHTTP alloc]initWithDefaultValue:formattedUrl _token:stackConfig.wsToken];
            httpconn.delegate = self;

            [self logToAnalytics:@"SDK_GetResourceRequest"];
            [httpconn sendResourceRequest:jsonHeaders _usingRTC20:false _requestTimeout:_stackConfig.httpRequestTimeout];
            
             isChannelAPIEnable = true;
            _reconnectTimeoutTimer = nil;
            
            isReconnecting = false;
            _isCapabilityExchangeEnable = false;
            _isVideoBridgeEnable = true;
            isNetworkAvailable = true;
            isNetworkStateUpdated = false;
            _isSMRoomCreated = false;
        }
        else
        {
            NSLog(@"WebRTCStack::initWithRTCG for XMPP");
            [jsonHeaders setObject:[[NSUUID UUID] UUIDString] forKey:@"x-tracking-id"];
            [jsonHeaders setObject:stackConfig.serverNameHeader forKey:@"x-server-name"];
            [jsonHeaders setObject:stackConfig.clientNameHeader forKey:@"x-client-name"];
            [jsonHeaders setObject:stackConfig.sourceIdHeader forKey:@"x-source-id"];
            [jsonHeaders setObject:stackConfig.deviceIdHeader forKey:@"Device-Id"];
            NSString *trace = [@"trace-id=" stringByAppendingString:stackConfig.traceIdHeader];
            [jsonHeaders setObject:trace forKey:@"x-trace"];

            isChannelAPIEnable = false;
            isXMPPEnable = true;
            _isVideoBridgeEnable = true;
            self.delegate = (id<WebRTCStackDelegate>)_appdelegate;
             if(!_stackConfig.useEventManager)
            {
                NSString *formattedUrl = [NSString stringWithFormat:@"%@?sourceUID=%@", _stackConfig.resourceURL,  _stackConfig.userId];
                httpconn = [[WebRTCHTTP alloc]initWithDefaultValue:formattedUrl _token:stackConfig.wsToken];
                httpconn.delegate = self;
                [self logToAnalytics:@"SDK_GetResourceRequest"];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [httpconn sendResourceRequest:jsonHeaders _usingRTC20:stackConfig.usingRTC20 _requestTimeout:_stackConfig.httpRequestTimeout];
                });
            }
            
            
            isReconnecting = false;
            _isCapabilityExchangeEnable = false;
            isNetworkAvailable = true;
            isNetworkStateUpdated = false;
            _reconnectTimeoutTimer = nil;
            

        }
        
        if(_stackConfig.isNwSwitchEnable)
        {
            // Set up Reachability
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(reachabilityChanged:)
                                                         name:kReachabilityChangedNotification object:nil];
            
            reachability = [Reachability reachabilityForInternetConnection];
            [reachability startNotifier];
            oldStatus = [reachability currentReachabilityStatus];
            
            if (reachability.currentReachabilityStatus == ReachableViaWiFi){
                isWifiMode = true;
                isWifiModePrev = false;
            }
            else{
                isWifiMode = false;
                isWifiModePrev = true;
            }

        }
    }

    LogDebug(@"Stack being initialised with version %s",LIBSDK_VERSION );

    return self;
}

- (id)initWithRTCGResources:(WebRTCStackConfig*)_stackConfig _appdelegate:(id<WebRTCStackDelegate>)_appdelegate;
{
    if((!_stackConfig.getResourceResponse) )
    {
        //TODO Need to return object type instead of enum
        //return ERR_INCORRECT_PARAMS;
        return nil;
    }
    
    self = [super init];
    if (self!=nil) {
        stackConfig = _stackConfig;
        
        _roomID = nil;
        _isIncomingCall = false;        //Stats logging implementation
        _resourcesResponse = nil;
        NSMutableDictionary* metaData = [self getMetaData];
        LogDebug(@"MetaData is = %@",metaData);
        
        NSString* statEndpoint = stackConfig.statsURL;
        wsToken = stackConfig.wsToken;
        
        // Check if we have a URL ending with /
        if(!_stackConfig.usingRTC20)
        {
            self.delegate = (id<WebRTCStackDelegate>)_appdelegate;
            //[self logToAnalytics:@"SDK_GetResourceRequest"];
            isChannelAPIEnable = true;
            _reconnectTimeoutTimer = nil;
            
            isReconnecting = false;
            _isCapabilityExchangeEnable = false;
            _isVideoBridgeEnable = false;
            isNetworkAvailable = true;
            isNetworkStateUpdated = false;
           // NSError * error;
            //NSDictionary* json =[WebRTCJSONSerialization JSONObjectWithData:stackConfig.getResourceResponse options:kNilOptions error:&error];
            [self parseGetResourceResponse:stackConfig.getResourceResponse];
            _resourcesResponse = stackConfig.getResourceResponse;
        }
        else
        {
            NSLog(@"WebRTCStack::initWithRTCG for XMPP");
            isChannelAPIEnable = false;
            isXMPPEnable = true;
            _isVideoBridgeEnable = false;
            self.delegate = (id<WebRTCStackDelegate>)_appdelegate;
            
            isReconnecting = false;
            _isCapabilityExchangeEnable = false;
            isNetworkAvailable = true;
            isNetworkStateUpdated = false;
            _reconnectTimeoutTimer = nil;
            
        }
        
        if(_stackConfig.isNwSwitchEnable)
        {
            // Set up Reachability
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(reachabilityChanged:)
                                                         name:kReachabilityChangedNotification object:nil];
            
            reachability = [Reachability reachabilityForInternetConnection];
            [reachability startNotifier];
            oldStatus = [reachability currentReachabilityStatus];
            
            if (reachability.currentReachabilityStatus == ReachableViaWiFi){
                isWifiMode = true;
                isWifiModePrev = false;
            }
            else{
                isWifiMode = false;
                isWifiModePrev = true;
            }
            
        }
    }
    
    LogDebug(@"Stack being initialised with version %s",LIBSDK_VERSION );
    
    return self;

}

- (id)initIRISWithDefaultValues:(WebRTCStackConfig*)_stackConfig
                   _appdelegate:(id<WebRTCStackDelegate>)_appdelegate
{
    if((!_stackConfig.xmppRegisterURL) )
    {
        //TODO Need to return object type instead of enum
        //return ERR_INCORRECT_PARAMS;
        return nil;
    }
    
    self = [super init];
    if (self!=nil) {
        stackConfig = _stackConfig;
         self.delegate = (id<WebRTCStackDelegate>)_appdelegate;
        httpconn = [[WebRTCHTTP alloc]init];
        httpconn.delegate = self;
        
        //Doing Init set up for XMPP Stream
        [[XMPPWorker sharedInstance]startEngine];
        //[[XMPPWorker sharedInstance] setXMPPDelegate:self];
        [[XMPPWorker sharedInstance] setWebSocketDelegate:self];
        
        eventManagerState = XmppInitialized;
        
    }
    
    return self;
}



-(void)parseGetResourceResponse:(NSData*)resources
{
    NSError * error;
    NSDictionary* json =[WebRTCJSONSerialization JSONObjectWithData:resources options:kNilOptions error:&error];
     _webSocketJson =[json objectForKey:@"webSocket"];
     _iceServerJson =[json objectForKey:@"iceServers"];
    
    if(stackConfig.usingRTC20)
    {
        if (_iceServerJson == nil)
        {
            [self logToAnalytics:@"SDK_Error"];
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Received incorrect parameters from RTCG : Turn Servers are missing" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:Session code:ERR_INCORRECT_PARAMS userInfo:details];
            [self.delegate onStackError:error.description errorCode:error.code additionalData:nil];
            return;
        }
        iceservermsg = _iceServerJson;
        return;
    }
    NSLog(@"_webSocketJson = %@",_webSocketJson);
        NSLog(@"_iceServerJson = %@",_iceServerJson);
    if (_webSocketJson == nil || _iceServerJson == nil)
    {
        [self logToAnalytics:@"SDK_Error"];
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Received incorrect parameters from RTCG" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Session code:ERR_INCORRECT_PARAMS userInfo:details];
        [self.delegate onStackError:error.description errorCode:error.code additionalData:nil];
        return;
    }
    
    //Need to use this URL for handshaking
    NSArray* uris = [_webSocketJson objectForKey:@"uris"];
    NSURL *validURL = [NSURL URLWithString: [uris objectAtIndex:0]];
    
    if((![validURL host]) || (![validURL port]))
    {
        [self logToAnalytics:@"SDK_Error"];
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"URL/Port is not valid" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Session code:ERR_INCORRECT_PARAMS userInfo:details];
        [self.delegate onStackError:error.description errorCode:error.code additionalData:nil];
        return;
    }
}

-(void)connect
{
    
    LogDebug(@"Inside connect ");

    
    if ((_webSocketJson == nil) || (_iceServerJson == nil))
        return;
    NSString* credential = [_webSocketJson objectForKey:@"credential"];
    //@"T7R^6;@Z$$2TYzI+/!*'();:@&=+$,/?%#[]&mKU5uU=";//
    username = [_webSocketJson objectForKey:@"username"];
    NSArray* uris = [_webSocketJson objectForKey:@"uris"];
    
    NSURL *validURL = [NSURL URLWithString: [uris objectAtIndex:0]];
    path = [validURL path];
    
    encodedcredential =(NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                             NULL,
                                                                                             (CFStringRef)credential,
                                                                                             NULL,
                                                                                             //(CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                             (CFStringRef)@"+&",
                                                                                             kCFStringEncodingUTF8 ));
    
    BOOL secure = false;
    // Check if the URL has https
    if([[validURL scheme] isEqual:@"https"])
    {
        secure = true;
    }
    if(!isReconnecting)
        [self onStateChange:SocketConnecting];
    
    NSString *hostURL;
    
    if (stackConfig.doManualDns)
    {
        NSArray *addresses = [self getAddresses:[validURL host]];
        NSLog(@"DNS Result %@", [addresses description]);
        if ([addresses count] > 0)
        {
            for (int i =0; i <[addresses count]; i++)
            {
                if ([[addresses[i] componentsSeparatedByString:@":"] count] > 3) // IPv6 address
                {
                    // Prefer IPv4 if both are present
                    if ([addresses count] > 1)
                    {
                        continue;
                    }
                    else
                    {
                        hostURL = addresses[i];
                    }
                }
                else
                {
                    hostURL = addresses[i];
                }
            }
        }
        else
        {
            hostURL = [validURL host];
        }
    }
    else
    {
        hostURL = [validURL host];
    }
    LogDebug(@"Host name is %@ ", hostURL);
    
    //if(!isReconnecting)
    sh = [[SignalHandler alloc] initWithDefaultValue:hostURL port:[[validURL port] integerValue] secure:secure statscollector:statsCollector];
    
    sh.delegate = self;
    iceservermsg = _iceServerJson;
    [self logToAnalytics:@"SDK_SocketConnectRequest"];
    [sh connectToSignallingServer:username credentials:encodedcredential resource:path];
}

- (void) startSignalingServer:(NSData*) resources;
{
    [self logToAnalytics:@"SDK_GetResourceResponse"];
    [self.delegate onReceiveResources:resources];
    [self parseGetResourceResponse:resources];
    [self connect];
//    [sh connectToSignallingServer:username credentials:credential resource:path];
}

- (NSArray *)getAddresses:(NSString *)url {
        CFHostRef hostRef = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef)url);
        
        BOOL success = CFHostStartInfoResolution(hostRef, kCFHostAddresses, nil);
        if (!success) {
            // something went wrong
            return nil;
        }
        CFArrayRef addressesRef = CFHostGetAddressing(hostRef, nil);
        if (addressesRef == nil) {
            // couldn't found any address
            return nil;
        }
        
        // Convert these addresses into strings.
        char ipAddress[INET6_ADDRSTRLEN];
        NSMutableArray *addresses = [NSMutableArray array];
        CFIndex numAddresses = CFArrayGetCount(addressesRef);
        for (CFIndex currentIndex = 0; currentIndex < numAddresses; currentIndex++) {
            CFDataRef dataRef = (CFDataRef)CFArrayGetValueAtIndex(addressesRef, currentIndex);
            struct sockaddr *address = (struct sockaddr *)CFDataGetBytePtr(dataRef);
            if (address == nil) {
                return nil;
            }
            getnameinfo(address, address->sa_len, ipAddress, INET6_ADDRSTRLEN, nil, 0, NI_NUMERICHOST);
            if (ipAddress == nil) {
                return nil;
            }
            NSString * addressString = [NSString stringWithCString:ipAddress encoding:NSASCIIStringEncoding];
            if ([[addressString componentsSeparatedByString:@":"] count] > 3) // IPv6 address
            {
                addressString = [NSString stringWithFormat:@"[%@]", addressString];
            }
            [addresses addObject:addressString];
        }
        
        return addresses;
}

- (id)initWithDefaultValue:(WebRTCStackConfig*)_stackConfig _appdelegate:(id<WebRTCStackDelegate>)_appdelegate
{
    if((!_stackConfig.serverURL) || (!_stackConfig.portNumber))
       {
           //TODO Need to return object type instead of enum
           //return ERR_INCORRECT_PARAMS;
       }
    
    self = [super init];
    if (self!=nil) {
        stackConfig = _stackConfig;
        wsToken = _stackConfig.wsToken;
	//Stats logging implementation
        NSMutableDictionary* metaData = [self getMetaData];
        LogDebug(@"MetaData is = %@", metaData );
        //NSString* statEndpoint = @"http://st-uestats-fxbo.sys.comcast.net/stats";
        //NSString* statEndpoint = @"http://76.26.116.203";
        //NSString* statEndpoint = @"http://sTAG5ing.rtcwith.me/stats";
        
        statsCollector = [[WebRTCStatsCollector alloc]initWithDefaultValue:metaData _appdelegate:(id<WebRTCStatsCollectorDelegate>)_appdelegate];
        
        // For now while dev is moving fast its nice if call logs are always reported
        // By the client we can eventually turn this off by default and have it turned on only by
        // debug signaling
        //[statsCollector setOmitCallLogInReport:false];
        isChannelAPIEnable = false;;
        //Parse wsToken
        NSError* error;
        NSDictionary* json = [WebRTCJSONSerialization JSONObjectWithData:wsToken options:kNilOptions error:&error];
        NSMutableDictionary *jsonm = [NSMutableDictionary dictionaryWithDictionary:json];
        emailId = [jsonm objectForKey:@"address"];
    
        sh = [[SignalHandler alloc] initWithDefaultValue:stackConfig.serverURL port:stackConfig.portNumber secure:stackConfig.isSecure statscollector:statsCollector];
        sh.delegate = self;
        // Connect to signaling server
        [sh connectToSignallingServer];
        
        self.delegate = (id<WebRTCStackDelegate>)_appdelegate;
        isReconnecting = false;
        _isCapabilityExchangeEnable = false;
        _isVideoBridgeEnable = true;
        isNetworkAvailable = true;
        isNetworkStateUpdated = false;
        _reconnectTimeoutTimer = nil;
        if(_stackConfig.isNwSwitchEnable)
        {
            // Set up Reachability
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(reachabilityChanged:)
                                                         name:kReachabilityChangedNotification object:nil];
            
            reachability = [Reachability reachabilityForInternetConnection];
            [reachability startNotifier];
            oldStatus = [reachability currentReachabilityStatus];
            
            if (reachability.currentReachabilityStatus == ReachableViaWiFi){
                isWifiMode = true;
                isWifiModePrev = false;
            }
            else{
                isWifiMode = false;
                isWifiModePrev = true;
            }
            
        }
    }
    
    LogDebug(@"Stack being initialised with version %s", LIBSDK_VERSION);
    
    return self;
}

- (void) setVideoBridgeEnable: (bool) flag
{
    _isVideoBridgeEnable = flag;
    [XMPPWorker sharedInstance].isVideoBridgeEnable = flag;
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
    
#ifdef LIBSDK_VERSION
    [metadata setValue:@LIBSDK_VERSION forKey:@"sdkVersion"];
#endif
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
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
    return platform;
}


-(NSString*)getNetworkConnectionType
{
    NSArray *subviews = [[[[UIApplication sharedApplication] valueForKey:@"statusBar"] valueForKey:@"foregroundView"]subviews];
    NSNumber *dataNetworkItemView = nil;
    
    for (id subview in subviews) {
        if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
            dataNetworkItemView = subview;
            break;
        }
    }
    NSString* type;
    
    switch ([[dataNetworkItemView valueForKey:@"dataNetworkType"]integerValue]) {
        case 0:
           type=@"No Wifi/Cellular connection";
            _networkType = nonetwork;
            break;
            
        case 1:
            type=@"2G";
            _networkType = cellular2g;
            break;
            
        case 2:
            type=@"3G";
             _networkType = cellular3g;
            break;
            
        case 3:
            type=@"4G";
            _networkType = cellular4g;
            break;
            
        case 4:
            type=@"LTE";
            _networkType =  cellularLTE;
            break;
            
        case 5:
            type=@"Wifi";
            _networkType = wifi;
            break;
            
        default:
            type=@"Not found !!";
            break;
    }
    return type;
}


- (id)createStream:(WebRTCStreamConfig*)_streamConfig _recordingDelegate:(id<WebRTCSessionDelegate>)appDelegate
{
    WebRTCStream *_stream;
    
    if([self isStreamVideoEnable])
        _stream = [[WebRTCStream alloc]initWithDefaultValue:_streamConfig];
    else
    _stream = [[WebRTCStream alloc]init];

    _stream.delegate = self;
    _stream.recordingDelegate = (id<WebRTCAVRecordingDelegate>)appDelegate;
    [_stream start];
    return _stream;
}

- (id)createAudioOnlyStream
{
    WebRTCStream *_stream;
    
    if([self isStreamVideoEnable])
        _stream = [[WebRTCStream alloc]initWithDefaultValue];
    else
        _stream = [[WebRTCStream alloc]init];
    
    _stream.delegate = self;
    [_stream start];
    return _stream;
}

-(void)sendJoinRoomRequest:(WebRTCSessionConfig*)sessionConfig
{
    NSLog(@"WebRTCStack::sendJoinRoomRequest");
    
    NSMutableDictionary* jsonPayload = [[NSMutableDictionary alloc]init];
    
    
    [jsonPayload setObject:sessionConfig.xmppCallType forKey:@"callType"];
    [jsonPayload setObject:sessionConfig.instanceId forKey:@"instanceId"];
    [jsonPayload setObject:sessionConfig.targetID forKey:@"fromUID"];
    
    if(sessionConfig.callType == pstncall)
    {
        [jsonPayload setObject:stackConfig.targetPhoneNum forKey:@"toID"];
    }
    else
    {
        [jsonPayload setObject:stackConfig.userId forKey:@"toID"];
    }
    [jsonPayload setObject:stackConfig.targetRoutingId forKey:@"toRID"];
    [jsonPayload setObject:stackConfig.sourcePhoneNum forKey:@"fromTN"];
    [jsonPayload setObject:stackConfig.targetPhoneNum forKey:@"toTN"];
    [jsonPayload setObject:sessionConfig.deviceType forKey:@"deviceType"];
    [jsonPayload setObject:sessionConfig.topic forKey:@"topic"];
    [jsonPayload setObject:sessionConfig.displayName forKey:@"displayName"];
    [jsonPayload setObject:[NSNumber numberWithBool:sessionConfig.notificationRequired] forKey:@"notificationRequired"];
    [jsonPayload setObject:sessionConfig.sType forKey:@"sType"];
    [jsonPayload setObject:stackConfig.originInstanceId forKey:@"originInstanceID"];
    
    NSLog(@"WebRTCStack::jsonPayload = %@",jsonPayload);
    
    NSMutableDictionary* jsonHeaders = [[NSMutableDictionary alloc]init];
    //[jsonHeaders setObject:stackConfig.custguIdHeader forKey:@"custguid"];
    [jsonHeaders setObject:[[NSUUID UUID] UUIDString] forKey:@"x-tracking-id"];
    NSString *trace = [@"trace-id=" stringByAppendingString:stackConfig.traceIdHeader];
    [jsonHeaders setObject:trace forKey:@"x-trace"];
    [jsonHeaders setObject:stackConfig.serverNameHeader forKey:@"x-server-name"];
    [jsonHeaders setObject:stackConfig.clientNameHeader forKey:@"x-client-name"];
    [jsonHeaders setObject:stackConfig.sourceIdHeader forKey:@"x-source-id"];
    [jsonHeaders setObject:stackConfig.deviceIdHeader forKey:@"Device-Id"];
    
    NSLog(@"WebRTCStack::jsonHeaders = %@",jsonHeaders);
    
    NSString *formattedUrl = [NSString stringWithFormat:@"%@/session/joinroom/roomids/%@", stackConfig.serverURL,sessionConfig.roomId];
    NSLog(@"formattedUrl = %@",formattedUrl);
    httpconn = [[WebRTCHTTP alloc]initWithDefaultValue:formattedUrl _token:stackConfig.wsToken];
    httpconn.delegate = self;
    [self logToAnalytics:@"SDK_JoinRoomRequest"];
  //  [httpconn sendCreateJoinRoomRequest:jsonPayload _requestHeaders:jsonHeaders _requestTimeout:stackConfig.httpRequestTimeout _requestType:@"Join"];
    
     [httpconn sendCreateJoinRoomRequest:jsonPayload _requestHeaders:jsonHeaders _requestTimeout:stackConfig.httpRequestTimeout _requestType:@"Join" _requestretryCount:sessionConfig.joinRoomRequestRetryCount];
}

-(void)sendCreateRoomRequest:(WebRTCSessionConfig*)sessionConfig
{
    NSLog(@"WebRTCStack::sendCreateRoomRequest");
    
    NSMutableDictionary* jsonPayload = [[NSMutableDictionary alloc]init];
    //NSArray* jsonPayload = [[NSArray alloc]init];
    //NSMutableArray* participantsInfo = [[NSMutableArray alloc]init];
    
    //[participantsInfo addObject:@"ngc34@comcast.net"];
    //[participantsInfo addObject:@"24labdemo01@comcast.net"];
    
    //participntInfo changes for PSTN call
//    if([stackConfig.event isEqualToString:@"eventTypePstnCall"])
//    {
//        NSMutableArray *targetPhNum = [[NSMutableArray alloc]init];
//        [targetPhNum setObject:[[XMPPWorker sharedInstance]targetPhoneNumber:stackConfig.targetPhoneNum] atIndexedSubscript:0];
//        [jsonPayload setObject:targetPhNum forKey:@"participantsInfo"];
//          sessionConfig.callType = pstncall;
//    }
//    else
    [jsonPayload setObject:sessionConfig.participantsInfo forKey:@"participantsInfo"];
    
    [jsonPayload setObject:stackConfig.routingId forKey:@"fromRID"];
    [jsonPayload setObject:sessionConfig.xmppCallType forKey:@"callType"];
    [jsonPayload setObject:sessionConfig.instanceId forKey:@"instanceId"];
    [jsonPayload setObject:stackConfig.userId forKey:@"fromUID"];
    [jsonPayload setObject:stackConfig.sourcePhoneNum forKey:@"fromTN"];
    [jsonPayload setObject:stackConfig.targetPhoneNum forKey:@"toTN"];
    [jsonPayload setObject:sessionConfig.deviceType forKey:@"deviceType"];
    [jsonPayload setObject:sessionConfig.displayName forKey:@"displayName"];
    [jsonPayload setObject:sessionConfig.sType forKey:@"sType"];
    
    // If STB id exists, add the same
    if ([sessionConfig.STBID length] > 1)
    {
        [jsonPayload setObject:sessionConfig.STBID forKey:@"STBID"];

    }
    [jsonPayload setObject:sessionConfig.sType forKey:@"sType"];

    [jsonPayload setObject:stackConfig.isOpenSipRequest forKey:@"isOpenSipRequest"];
    
    [jsonPayload setObject:[NSNumber numberWithBool:sessionConfig.notificationRequired] forKey:@"notificationRequired"];
    
    NSLog(@"WebRTCStack::jsonPayload = %@",jsonPayload);
    
    NSMutableDictionary* jsonHeaders = [[NSMutableDictionary alloc]init];
    //[jsonHeaders setObject:stackConfig.custguIdHeader forKey:@"custguid"];
    [jsonHeaders setObject:[[NSUUID UUID] UUIDString] forKey:@"x-tracking-id"];
    NSString *trace = [@"trace-id=" stringByAppendingString:stackConfig.traceIdHeader];
    [jsonHeaders setObject:trace forKey:@"x-trace"];
    [jsonHeaders setObject:stackConfig.serverNameHeader forKey:@"x-server-name"];
    [jsonHeaders setObject:stackConfig.clientNameHeader forKey:@"x-client-name"];
    [jsonHeaders setObject:stackConfig.sourceIdHeader forKey:@"x-source-id"];
    [jsonHeaders setObject:stackConfig.deviceIdHeader forKey:@"Device-Id"];
    
    NSLog(@"WebRTCStack::jsonHeaders = %@",jsonHeaders);
    
    NSString *formattedUrl = [NSString stringWithFormat:@"%@/session/createroom", stackConfig.serverURL];
    NSLog(@"formattedUrl = %@",formattedUrl);
    httpconn = [[WebRTCHTTP alloc]initWithDefaultValue:formattedUrl _token:stackConfig.wsToken];
    httpconn.delegate = self;
    
    [self logToAnalytics:@"SDK_CreateRoomRequest"];
   // [httpconn sendCreateJoinRoomRequest:jsonPayload _requestHeaders:jsonHeaders _requestTimeout:stackConfig.httpRequestTimeout _requestType:@"Create"];
    
    [httpconn sendCreateJoinRoomRequest:jsonPayload _requestHeaders:jsonHeaders _requestTimeout:stackConfig.httpRequestTimeout _requestType:@"Create" _requestretryCount:sessionConfig.joinRoomRequestRetryCount];
}

-(void)sendCloseRoomRequest:(WebRTCSessionConfig*)sessionConfig
{
    NSLog(@"WebRTCStack::sendCloseRoomRequest");
    
    NSMutableDictionary* jsonPayload = [[NSMutableDictionary alloc]init];
    
    
    [jsonPayload setObject:sessionConfig.xmppCallType forKey:@"callType"];
    [jsonPayload setObject:sessionConfig.instanceId forKey:@"instanceId"];
    [jsonPayload setObject:stackConfig.userId forKey:@"fromUID"];
    [jsonPayload setObject:stackConfig.sourcePhoneNum forKey:@"fromTN"];
    [jsonPayload setObject:sessionConfig.deviceType forKey:@"deviceType"];
    [jsonPayload setObject:sessionConfig.displayName forKey:@"displayName"];
     [jsonPayload setObject:stackConfig.routingId forKey:@"RID"];
    
    
    NSLog(@"WebRTCStack::jsonPayload = %@",jsonPayload);
    
    NSMutableDictionary* jsonHeaders = [[NSMutableDictionary alloc]init];
    //[jsonHeaders setObject:stackConfig.custguIdHeader forKey:@"custguid"];
    [jsonHeaders setObject:[[NSUUID UUID] UUIDString] forKey:@"x-tracking-id"];
    NSString *trace = [@"trace-id=" stringByAppendingString:stackConfig.traceIdHeader];
    [jsonHeaders setObject:trace forKey:@"x-trace"];
    [jsonHeaders setObject:stackConfig.serverNameHeader forKey:@"x-server-name"];
    [jsonHeaders setObject:stackConfig.clientNameHeader forKey:@"x-client-name"];
    [jsonHeaders setObject:stackConfig.sourceIdHeader forKey:@"x-source-id"];
    [jsonHeaders setObject:stackConfig.deviceIdHeader forKey:@"Device-Id"];
    
    NSLog(@"WebRTCStack::jsonHeaders = %@",jsonHeaders);
    
    NSString *formattedUrl = [NSString stringWithFormat:@"%@/session/closeroom/roomids/%@", stackConfig.serverURL,sessionConfig.rtcgSessionId];
    NSLog(@"formattedUrl = %@",formattedUrl);
    httpconn = [[WebRTCHTTP alloc]initWithDefaultValue:formattedUrl _token:stackConfig.wsToken];
    httpconn.delegate = self;
    [self logToAnalytics:@"SDK_CloseRoomRequest"];
    [httpconn sendCloseRoomRequest:jsonPayload _requestHeaders:jsonHeaders _requestTimeout:stackConfig.httpRequestTimeout];
}

#pragma mark - XMPP WebSocket Delegate

- (void)onXmppWebSocketConnected
{
    [self logToAnalytics:@"SDK_XMPPServerConnected1"];
    
}

- (void)onXmppWebSocketAuthenticated
{
    [self sendpreferredH264:stackConfig.h264Codec];
    
    
    if(stackConfig.useEventManager)
    {
        [self logToAnalytics:@"SDK_XMPPAuthenticated1"];
        [self.delegate onWebSocketConnectedAndAuthenticated];
    }
    else if(stackConfig.usingRTC20)
    {
        [self logToAnalytics:@"SDK_XMPPAuthenticated"];
        [_session updatingIceServersData:iceservermsg];
        [_session start:iceservermsg];
    }
    else
    {   [self logToAnalytics:@"SDK_SocketConnected"];
        [self.delegate onReady:nil];
    }
}
- (void)onXmppWebSocketError:(NSString*) error
{
    NSLog(@"XMPP Stack : Received an error  :: %@", error);
    [self logToAnalytics:@"SDK_Error"];
    [self logToAnalytics:@"SDK_XMPPAuthenticationFailed"];
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:error forKey:NSLocalizedDescriptionKey];
    NSError *error1 = [NSError errorWithDomain:Socket code:ERR_XMPP_AUTHENTICATION_FAILED userInfo:details];
    [self onStackError:error1.description errorCode:error1.code additionalData:nil];
}

- (void)onXmppWebSocketDisconnected:(NSString*) error
{
    NSLog(@"XMPP Stack : onDisconnect  :: %@", error);
    [self logToAnalytics:@"SDK_XMPPServerDisconnected"];
    [self.delegate onXmppDisconnect: error];
    
}

#pragma mark - Event Manager APIs

- (void)irisXmppRegister
{
    if(eventManagerState != XmppInitialized)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Stack Initialazion is not done yet" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Stack code:ERR_INCORRECT_STATE userInfo:details];
        [self onStackError:error.description errorCode:error.code additionalData:nil];
    }
    
    eventManagerState = XmppRegistering;
    
    NSString *formattedUrl = [NSString stringWithFormat:@"%@/events/xmppregistrationinfo/routingid/%@", stackConfig.xmppRegisterURL,stackConfig.routingId];
    
    [[WebRTCEventManager sharedInstance]setServerURL:formattedUrl];
    [[WebRTCEventManager sharedInstance]setRequestTimeout:stackConfig.httpRequestTimeout];
    [[WebRTCEventManager sharedInstance]setJsonWebToken:stackConfig.jsonWebToken];
    [[WebRTCEventManager sharedInstance]setDelegate:self];
    
    [[WebRTCEventManager sharedInstance]getXmppRegisterInfo];
    

}

- (void)irisXmppWebSockConnect
{
    if((stackConfig.xmppToken == nil) || (stackConfig.xmppTokenExpiryTime == nil) ||
        (stackConfig.xmppRTCServer == nil))
    {
        if(eventManagerState != XmppInitialized)
        {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Incorrect requied parameters xmppToken/xmppTokenExpiryTime/xmppRTCServer" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:Stack code:ERR_INCORRECT_PARAMS userInfo:details];
            [self onStackError:error.description errorCode:error.code additionalData:nil];
        }
    }
    
    [self createWebSockAndXMPPConnection:@"" _timestamp:stackConfig.xmppTokenExpiryTime _xmppToken:stackConfig.xmppToken _xmppServer:stackConfig.xmppRTCServer];
}

-(void)irisXmppUnregister
{
    [[XMPPWorker sharedInstance]disconnectWebSocket];
}

-(void)sendCreateXmppRootEventRequestWithRoomName:(WebRTCSessionConfig*)sessionConfig
{
    NSLog(@"WebRTCStack::sendCreateRoomRequest");
    
    NSMutableDictionary* jsonPayload = [[NSMutableDictionary alloc]init];

    [jsonPayload setObject:sessionConfig.roomName forKey:@"room_name"];
    
    [jsonPayload setObject:sessionConfig.xmppCallType forKey:@"event_type"];
    [jsonPayload setObject:[NSNumber numberWithInteger:sessionConfig.timePosted] forKey:@"time_posted"];
    
    [jsonPayload setObject:stackConfig.routingId forKey:@"from"];
    
    
    if([sessionConfig.userData count] > 0)
    {
        NSError* err;
        NSData * requestData = [NSJSONSerialization  dataWithJSONObject:sessionConfig.userData options:0 error:&err];
        NSString *jsonString = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
        [jsonPayload setObject:jsonString forKey:@"userdata"];
    }

    
    
    NSLog(@"WebRTCStack::jsonPayload = %@",jsonPayload);
    
    NSMutableDictionary* jsonHeaders = [[NSMutableDictionary alloc]init];
    
    NSLog(@"WebRTCStack::jsonHeaders = %@",jsonHeaders);
    
    NSString *formattedUrl = [NSString stringWithFormat:@"%@/events/createrootevent", stackConfig.serverURL];
    NSLog(@"formattedUrl = %@",formattedUrl);
    //eventManager = [[WebRTCEventManager alloc]initWithDefaultValue:formattedUrl _token:stackConfig.jsonWebToken];
    //eventManager.delegate = self;
    
    [[WebRTCEventManager sharedInstance]setServerURL:formattedUrl];
    
    [[WebRTCEventManager sharedInstance]setRequestHeader:jsonHeaders];
    [[WebRTCEventManager sharedInstance]setRequestPayload:jsonPayload];
    [[WebRTCEventManager sharedInstance]createXmppRootEventWithRoomName];
    [self logToAnalytics:@"SDK_CreateRoomRequest"];
    
}

-(void)sendCreateXmppRootEventRequest:(WebRTCSessionConfig*)sessionConfig
{
    NSLog(@"WebRTCStack::sendCreateRoomRequest");
    
    NSMutableDictionary* jsonPayload = [[NSMutableDictionary alloc]init];
    
    [jsonPayload setObject:stackConfig.targetRoutingId forKey:@"to"];
    
    [jsonPayload setObject:sessionConfig.xmppCallType forKey:@"event_type"];
    [jsonPayload setObject:[NSNumber numberWithInteger:sessionConfig.timePosted] forKey:@"time_posted"];
    
    [jsonPayload setObject:stackConfig.routingId forKey:@"from"];
    
    
    if([sessionConfig.userData count] > 0)
    {
        NSError* err;
        NSData * requestData = [NSJSONSerialization  dataWithJSONObject:sessionConfig.userData options:0 error:&err];
        NSString *jsonString = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
        [jsonPayload setObject:jsonString forKey:@"userdata"];
    }
    
    
    
    NSLog(@"WebRTCStack::jsonPayload = %@",jsonPayload);
    
    NSMutableDictionary* jsonHeaders = [[NSMutableDictionary alloc]init];
    
    NSLog(@"WebRTCStack::jsonHeaders = %@",jsonHeaders);
    
    NSString *formattedUrl = [NSString stringWithFormat:@"%@/events/createrootevent", stackConfig.xmppRegisterURL];
    NSLog(@"formattedUrl = %@",formattedUrl);
    //eventManager = [[WebRTCEventManager alloc]initWithDefaultValue:formattedUrl _token:stackConfig.jsonWebToken];
    //eventManager.delegate = self;
    
    [[WebRTCEventManager sharedInstance]setServerURL:formattedUrl];
    
    [[WebRTCEventManager sharedInstance]setRequestHeader:jsonHeaders];
    [[WebRTCEventManager sharedInstance]setRequestPayload:jsonPayload];
    [[WebRTCEventManager sharedInstance]createXmppRootEventWithRoomName];
    [self logToAnalytics:@"SDK_CreateRoomRequest"];
    
}
#pragma mark - Event Manager Delegate

- (void) onXmppRegisterInfoSuccess:(NSString*)rtcServer _xmppToken:(NSString*)token _tokenExpiryTime:(NSString*)expiryTime
{
    
    if(eventManagerState != XmppRegistering)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Stack Initialazion is not done yet" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Stack code:ERR_INCORRECT_STATE userInfo:details];
        [self onStackError:error.description errorCode:error.code additionalData:nil];
    }
    
    stackConfig.xmppRTCServer = rtcServer;
    stackConfig.xmppToken = token;
    stackConfig.xmppTokenExpiryTime = expiryTime;
    
    [self irisXmppWebSockConnect];
    NSLog(@"onIRISRegisterInfo rtcServer = %@, token = %@, expiryTime = %@",rtcServer,token,expiryTime);
    //Creating WS connection
    //[self createWebSockAndXMPPConnection:@"" _timestamp:expiryTime _xmppToken:token _xmppServer:rtcServer];
}


- (void) onCreateRootEventSuccess:(NSString*)rootNodeId _childNodeId:(NSString*)childNodeId _eventData:(NSDictionary*)eventData
{
    NSLog(@"WebRTCStack::rootNodeId = %@",rootNodeId);
    NSLog(@"WebRTCStack::childNodeId = %@",childNodeId);
    NSLog(@"WebRTCStack::eventData = %@",eventData);
    
    [[XMPPWorker sharedInstance] setNodeId:rootNodeId];
    [[XMPPWorker sharedInstance] setCnodeId:childNodeId];
    //[[XMPPWorker sharedInstance] setUnodeId:stackConfig.unodeid];
    
    
    NSString* roomId = [eventData objectForKey:@"Room_id"];
    [[XMPPWorker sharedInstance]setMucId:roomId];

    [_session setRoomId:roomId];
    [_session updatingIceServersData:iceservermsg];
    [_session start:iceservermsg];
    
}
- (id)createPSTNSession:(WebRTCStream *)_stream
           _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate
           _configParam:(WebRTCSessionConfig *)_sessionConfig
{
    _isIncomingCall = false;
    _isPSTNVoiceSession = false;
    if (clientSessionId == NULL) {
        clientSessionId = [[NSUUID UUID] UUIDString];
    }
    
    
    LogDebug(@"ClientSessionId befor session start:: %@",clientSessionId);
    __sessionConfig = _sessionConfig;
    
        [self setVideoBridgeEnable:_sessionConfig.videoBridge];
    
        _sessionConfig.targetPhoneNum = stackConfig.targetPhoneNum;
        _sessionConfig.callType = pstncall;// comment when participant info is enabled
        
        _session = [[WebRTCSession alloc] initWithXMPPValue:self  _configParam:_sessionConfig _stream:_stream _appdelegate:_appdelegate _statcollector:statsCollector];
        sessions = @{clientSessionId: _session};
        if(stackConfig.useEventManager)
        {
            [self sendCreateXmppRootEventRequest:_sessionConfig];
        }
        else
        {
            [self sendCreateRoomRequest:_sessionConfig];
        }
        // [self createXMPPConnection:@"27ba3f70-10f8-11e6-952e-05ba3d7a5b9d" _timestamp:@"30" _xmppToken:@"aaaa" _requestType:@"Create"];
    
    //For Incoming Call
    if (offerMsg != NULL) {
        [_session onSignalingMessage:offerMsg];
    }
    
    // Write alias
    //[statsCollector writeMeta:@"alias" _values:_sessionConfig.callerID];
    return _session;

}
- (WebRTCSession *)createSession:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate _configParam:(WebRTCSessionConfig *)_sessionConfig
{
    _isIncomingCall = false;
    _isPSTNVoiceSession = false;
    if (clientSessionId == NULL) {
        clientSessionId = [[NSUUID UUID] UUIDString];
    }
    

    LogDebug(@"ClientSessionId befor session start:: %@",clientSessionId);
    __sessionConfig = _sessionConfig;
    if(isChannelAPIEnable)
    {
        _session = [[WebRTCSession alloc] initRTCGSessionWithDefaultValue:self arClientSessionId:clientSessionId  _configParam:_sessionConfig  _stream:_stream _appdelegate:_appdelegate  _statcollector:statsCollector _serverURL:stackConfig.serverURL];
        sessions = @{clientSessionId: _session};
        [self logToAnalytics:@"SDK_StartingSession"];
        [_session start:iceservermsg];
    }
     else if(stackConfig.usingRTC20)
    {
        [self setVideoBridgeEnable:_sessionConfig.videoBridge];
        
        if ([stackConfig.event isEqualToString:@"eventTypePstnCall"]) {
            _sessionConfig.targetPhoneNum = stackConfig.targetPhoneNum;
            _sessionConfig.callType = pstncall;// comment when participant info is enabled
        }

        _session = [[WebRTCSession alloc] initWithXMPPValue:self  _configParam:_sessionConfig _stream:_stream _appdelegate:_appdelegate _statcollector:statsCollector];
        sessions = @{clientSessionId: _session};
        if(stackConfig.useEventManager)
        {
            [self sendCreateXmppRootEventRequestWithRoomName:_sessionConfig];
        }
        else
        {
            [self sendCreateRoomRequest:_sessionConfig];
        }
        // [self createXMPPConnection:@"27ba3f70-10f8-11e6-952e-05ba3d7a5b9d" _timestamp:@"30" _xmppToken:@"aaaa" _requestType:@"Create"];
        
    }
    else
    {
        _session = [[WebRTCSession alloc] initWithDefaultValue:self arClientSessionId:clientSessionId _configParam:_sessionConfig _stream:_stream _appdelegate:_appdelegate _statcollector:statsCollector];
        sessions = @{clientSessionId: _session};
        [_session start];
    }
    
    //For Incoming Call
    if (offerMsg != NULL) {
        [_session onSignalingMessage:offerMsg];
    }
    
    // Write alias
    //[statsCollector writeMeta:@"alias" _values:_sessionConfig.callerID];
    return _session;
}

- (id)createIncomingSession:(WebRTCStream *)_stream _appdelegate:(id<WebRTCSessionDelegate>)_appdelegate _configParam:(WebRTCSessionConfig *)_sessionConfig
{
    NSLog(@"Webrtc:Session:: ClientSessionId befor session start:: %@  %@",clientSessionId,[sessions objectForKey:clientSessionId]);
    if (clientSessionId == NULL) {
        clientSessionId = [[NSUUID UUID] UUIDString];
    }
    _isPSTNVoiceSession = false;
    
    if(isXMPPEnable){
        
        _isIncomingCall = true;
        if(_stream == nil)
        {
            WebRTCStreamConfig *streamConfig = [[WebRTCStreamConfig alloc]init];
            streamConfig.isDummyStream = true;
        
            _stream = [self createStream:streamConfig _recordingDelegate:nil];
        }
    }

    _session = [[WebRTCSession alloc] initWithIncomingSession:self arClientSessionId:clientSessionId  _stream:_stream _appdelegate:_appdelegate channelapi:isChannelAPIEnable _statcollector:statsCollector _configParam:_sessionConfig];
    sessions = @{clientSessionId: _session};
    
    __sessionConfig = _sessionConfig;
    if(isChannelAPIEnable)
    {
        [self logToAnalytics:@"SDK_StartingIncomingSession"];
        [_session start:iceservermsg];
    }
    else if(isXMPPEnable)
    {
        [_session setXMPPEnable:true];
        
        //if(_sessionConfig.callType == dataincoming)
           [self setVideoBridgeEnable:false];
        
        if ([stackConfig.event isEqualToString:@"eventTypePstnCall"]) {
            [self setVideoBridgeEnable:true];
            _sessionConfig.targetPhoneNum = stackConfig.targetPhoneNum;
            _sessionConfig.callType = pstncall;// comment when participant info is enabled
        }
            
        if(stackConfig.useEventManager)
        {
            [self sendCreateXmppRootEventRequestWithRoomName:_sessionConfig];
        }
        else
        {
            [self sendJoinRoomRequest:_sessionConfig];
        }

        //[self createXMPPConnection:@"27ba3f70-10f8-11e6-952e-05ba3d7a5b9d" _timestamp:@"30" _xmppToken:@"aaaa" _requestType:@"Join"];
    }
    else
    {
        [_session start];
    }
    
    return _session;
}

- (WebRTCSession *)createDataSession:(id<WebRTCSessionDelegate>)_appdelegate _configParam:(WebRTCSessionConfig *)_sessionConfig
{
    
    WebRTCSession* session = nil;
    if (clientSessionId == NULL) {
        clientSessionId = [[NSUUID UUID] UUIDString];
    }
    
    _dataFlag = true;
    LogDebug(@"ClientSessionId befor session start:: %@",clientSessionId);
    
    __sessionConfig = _sessionConfig;
    
    if(isChannelAPIEnable)
    {
        session = [[WebRTCSession alloc] initRTCGSessionWithDefaultValue:self arClientSessionId:clientSessionId  _configParam:_sessionConfig  _stream:nil _appdelegate:_appdelegate  _statcollector:statsCollector _serverURL:stackConfig.serverURL];
        sessions = @{clientSessionId: session};
        [session setDTLSFlag:true];
        [session dataFlagEnabled:_dataFlag];
        [session start:iceservermsg];
    }
    else if (stackConfig.usingRTC20)
    {
        // For data channel set video bridge false
        [self setVideoBridgeEnable:_sessionConfig.videoBridge];
        
        _session = [[WebRTCSession alloc] initWithXMPPValue:self  _configParam:_sessionConfig _stream:nil _appdelegate:_appdelegate _statcollector:statsCollector];
        sessions = @{clientSessionId: _session};
        [_session setDTLSFlag:true];
        [_session dataFlagEnabled:_dataFlag];
        //[self logToAnalytics:@"SDK_CreateDataSession"];
        if(stackConfig.useEventManager)
        {
            [self sendCreateXmppRootEventRequestWithRoomName:_sessionConfig];
        }
        else
        {
            [self sendCreateRoomRequest:_sessionConfig];
        }
        //[self createXMPPConnection:@"1234abc" _timestamp:@"30" _xmppToken:@"aaaa"];
        
    }
    else
    {
        session = [[WebRTCSession alloc] initWithDefaultValue:self arClientSessionId:clientSessionId _configParam:_sessionConfig _stream:nil _appdelegate:_appdelegate _statcollector:statsCollector];
        sessions = @{clientSessionId: session};
        [session setDTLSFlag:true];
        [session start];
    }
    
    //For Incoming Call
    if (offerMsg != NULL) {
        [session onSignalingMessage:offerMsg];
    }
    
    // Write alias
    //[statsCollector writeMeta:@"alias" _values:_sessionConfig.callerID];
    if (stackConfig.usingRTC20) {
        
        return _session;
    }
    else
    {
        return session;

    }
  }

-(void)createWebSockAndXMPPConnection:(NSString*)roomId _timestamp:(NSString*)timestamp _xmppToken:(NSString*)xmppToken _xmppServer:(NSString*)xmppServer
{
    __sessionConfig.rtcgSessionId = roomId;
    
    
    //NSString* user = [stackConfig.userId componentsSeparatedByString: @"@"][0];
    //websocketURL = @"ma-xmpp-as-a-001.rtc.sys.comcast.net";
    //websocketURL = @"st-xmpp-cmce-002.poc.sys.comcast.net";
    //websocketURL = @"st-xmpp-cmce-002.poc.sys.comcast.net";
    //NSString* xmppUserName = [NSString stringWithFormat:@"%@@%@",user,websocketURL];
                              
    NSLog(@"WebRTCStack::websocketURL = %@",xmppServer);
    
    //websocketURL = @"st-xmpp-wbrn-001.rtc.sys.comcast.net";
    //websocketURL = @"ma-xmpp-as-a-001.rtc.sys.comcast.net";
    if(!stackConfig.useEventManager)
    {
        //Initializing room id
        [_session setRoomId:roomId];
        
        [[XMPPWorker sharedInstance] startEngine];
        [[XMPPWorker sharedInstance] setXMPPDelegate:self];
        [[XMPPWorker sharedInstance] setWebSocketDelegate:self];
        //[XMPPWorker sharedInstance].signalingDelegate = self;
        [[XMPPWorker sharedInstance] setNodeId:stackConfig.nodeid];
        [[XMPPWorker sharedInstance] setCnodeId:stackConfig.cnodeid];
        [[XMPPWorker sharedInstance] setUnodeId:stackConfig.unodeid];
        
    }

    [[XMPPWorker sharedInstance] setHostName:xmppServer];
    //[[XMPPWorker sharedInstance] setActualHostName:websocketURL];
    [[XMPPWorker sharedInstance] setHostPort:stackConfig.portNumber];
    //[[XMPPWorker sharedInstance] setUserName:stackConfig.userName];
    //[[XMPPWorker sharedInstance] setUserName:xmppUserName];
    [[XMPPWorker sharedInstance] setUserName:stackConfig.routingId];
    [[XMPPWorker sharedInstance] setToken:xmppToken];
    [[XMPPWorker sharedInstance] setMucId:roomId];
    [[XMPPWorker sharedInstance] setTimestamp:timestamp];
    //[[XMPPWorker sharedInstance] setRoutingId:stackConfig.userId];
    [[XMPPWorker sharedInstance] setRoutingId:stackConfig.routingId];
    //[[XMPPWorker sharedInstance] setUserName:@"test1@st-xmpp-wbrn-001.rtc.sys.comcast.net"];
    [[XMPPWorker sharedInstance] setUserPwd:@""];
    [[XMPPWorker sharedInstance] setTraceId:stackConfig.traceIdHeader];
    [[XMPPWorker sharedInstance] setEvent:stackConfig.event];

    if(_isIncomingCall)
    [[XMPPWorker sharedInstance] setIsXMPPRoomCreater:false];
    else
     [[XMPPWorker sharedInstance] setIsXMPPRoomCreater:true];
        [[XMPPWorker sharedInstance] setMaxParticipants: [NSString stringWithFormat:@"%d", (int)__sessionConfig.maxParticipants]];
        [self logToAnalytics:@"SDK_XMPPServerConnectRequest"];

    [[XMPPWorker sharedInstance] connect];
    //[[XMPPWorker sharedInstance] fetchedResultsController_roster];
    NSLog(@"XMPP, setting the credentials hostname %@ port %ld username %@",
          stackConfig.serverURL,
          (long)stackConfig.portNumber,
          stackConfig.routingId);
    
    NSArray *lines1 = [stackConfig.serverURL componentsSeparatedByString: @"/"];
    NSString* serviceId = lines1[lines1.count - 1];
    [_session serverUrl:xmppServer routingId:stackConfig.routingId serviceId:serviceId];
}

- (void) createXMPPConnection:(NSString*)mucid _timestamp:(NSString*)timestamp _xmppToken:(NSString*)xmppToken _requestType:(NSString *)requestType
{
    NSLog(@"WebRTCStack::mucid = %@",mucid);
    NSLog(@"WebRTCStack::timestamp = %@",timestamp);
    NSLog(@"WebRTCStack::xmppToken = %@",[xmppToken lowercaseString]);
    
    if ([requestType isEqualToString:@"Create"])
    {
        [self logToAnalytics:@"SDK_CreateRoomResponse"];
    }
    else
    {
        [self logToAnalytics:@"SDK_JoinRoomResponse"];
    }
    _isSMRoomCreated = true;
    
    NSArray *lines = [mucid componentsSeparatedByString: @"@"];
    NSString* roomID = lines[0];
   // __sessionConfig.rtcgSessionId = roomID;
    //Initializing room id
    //[_session setRoomId:roomID];
    NSString* websocketURL = lines[1];
    
    //NSString* user = [stackConfig.userId componentsSeparatedByString: @"@"][0];
    //websocketURL = @"ma-xmpp-as-a-001.rtc.sys.comcast.net";
    //websocketURL = @"st-xmpp-cmce-002.poc.sys.comcast.net";
    //websocketURL = @"st-xmpp-cmce-002.poc.sys.comcast.net";
    //NSString* xmppUserName = [NSString stringWithFormat:@"%@@%@",user,websocketURL];
    
    [self createWebSockAndXMPPConnection:roomID _timestamp:timestamp _xmppToken:xmppToken _xmppServer:websocketURL];
    
    
}- (void)onCloseRoom
{
    LogDebug(@" SessionManager closed room successfully");
    //[self.delegate onSMCloseRoomReqSuccess];
    [self logToAnalytics:@"SDK_CloseRoomSuccess"];

    httpconn.delegate= nil;
}

- (void)onRTCServerMessage:(NSString*)msg
{
    LogDebug(@" onRTCServerMessage");
    
    NSString *type=NULL;
    NSString *clientSessionIdTmp;
    //Parse into JSON object
    NSError *error = nil;
    NSDictionary *messageJSON = [WebRTCJSONSerialization
                                 JSONObjectWithData:[msg dataUsingEncoding:NSUTF8StringEncoding]
                                 options:0 error:&error];
    
    // Check for errors
    NSAssert(!error, @"%@", [NSString stringWithFormat:@"Error handling message: %@", error.description]);
    
    NSAssert([messageJSON count] > 0, @"Invalid JSON object");
  
    
    // Get message type

   if ([messageJSON objectForKey:@"args"]) {
       
       NSArray * args = [messageJSON objectForKey:@"args"];
       NSDictionary * objects = args[0];
       NSString * objects1 = args[0];
       LogInfo(@"Args %@",objects1 );
       if (objects1 == [NSNull null])
             return;
       
       NSData* jsonData = [WebRTCJSONSerialization dataWithJSONObject:objects
                                                          options:0 error:nil];
       NSString *JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
       [statsCollector storeCallLogMessage:objects1 _msgType:@"serverRTC"];
       
       type = [objects objectForKey:@"type"];
       clientSessionIdTmp = [objects objectForKey:@"clientSessionId"];
       from = [objects objectForKey:@"to"];
       to = [objects objectForKey:@"from"];
       LogDebug(@"clientSessionId:: %@",clientSessionId);
       
       if(isChannelAPIEnable)
       {
           if ((type != nil) && (![type compare:@"channelCreated"]))
           {
                LogDebug(@"Received channelCreated message... must be in registered mode");
           }
           else if ([sessions objectForKey:clientSessionId])
           {
               LogDebug(@"Webrtc:Session:: RTC server message has clientsessionId");
               WebRTCSession *session = (WebRTCSession*) [sessions objectForKey:clientSessionId];
               [session onSignalingMessage:objects];
           }
           else
           {
               LogDebug(@"Got message for a session that does not exist");
           }
       }
       else
       {
           if ([sessions objectForKey:clientSessionIdTmp])
           {
               LogDebug(@"Webrtc:Session:: RTC server message has clientsessionId");
               WebRTCSession *session = (WebRTCSession*) [sessions objectForKey:clientSessionIdTmp];
               [session onSignalingMessage:objects];
           }
           else if (![type compare:@"offer"])
           {
               LogDebug(@"Webrtc:Session:: RTC message is of type OFFER");
               clientSessionId = clientSessionIdTmp;
               offerMsg = objects;
               
               [self.delegate onOffer:from to:to];
               //[sessions setValue:session forKey:clientSessionId]; //does not work need to fix for incoming call
               //[session onSignalingMessage:msg];
           }
           else
           {
               [self logToAnalytics:@"SDK_Error"];
               LogDebug(@"Webrtc:Session:: Unknown client SessionId dropping message");
               NSError *error = [NSError errorWithDomain:Stack
                                                    code:ERR_UNKNOWN_CLIENT
                                                userInfo:nil];
               [self onStackError:error.description errorCode:error.code additionalData:nil];
           }
       }

    }
    
}


- (void)onRegMessage:(NSString*)msg
{
    LogDebug(@"Webrtc:Session:: onRegMessage");
    [statsCollector storeCallLogMessage:msg _msgType:@"serverReg"];
    
    NSString *type;
    //Parse into JSON object
    NSError *error = nil;
    NSDictionary *messageJSON = [WebRTCJSONSerialization
                                 JSONObjectWithData:[msg dataUsingEncoding:NSUTF8StringEncoding]
                                 options:0 error:&error];
    
    // Check for errors
    NSAssert(!error, @"%@", [NSString stringWithFormat:@"Error handling message: %@", error.description]);
    
    NSAssert([messageJSON count] > 0, @"Invalid JSON object");
    
    
    // Get message type
    NSArray * args = [messageJSON objectForKey:@"args"];
    NSDictionary * objects = args[0];
    type = [objects objectForKey:@"type"];
    
    if(![type compare:@"regfailure"])
    {
        [self logToAnalytics:@"SDK_Error"];
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Registration Failed !!!" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Session code:ERR_REG_FAILURE userInfo:details];
        [self onStackError:error.description errorCode:error.code additionalData:nil];
    }
    else
    {
        [self.delegate onRegister];
    }
    
}

- (void)onAuthMessage:(NSString*)msg
{
    LogDebug(@"Webrtc:Session:: onAuthMessage");
    [statsCollector storeCallLogMessage:msg _msgType:@"serverAuth"];
}

- (void)sendRTCMessage:(id)msg
{
    LogDebug(@"Webrtc:Session:: sendRTCMessage");
   //  LogDebug(@"type == %@", [msg valueForKey:@"type"]);
    NSData* jsonData = [WebRTCJSONSerialization dataWithJSONObject:msg
                                                       options:0 error:nil];
    NSString *JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];

    //[statsCollector storeCallLogMessage:JSONString _msgType:@"clientRTC"];
    [statsCollector storeCallLogMessage:msg _msgType:@"clientRTC"];
    [sh sendClientRTCMessage:msg];
}

- (void)disconnect
{
    LogDebug(@"WebRTCStack->disconnect");
    sh.delegate = nil;
    
    //Stat collector reporting
    // LogDebug(@"%@",[statsCollector toPrettyString]);
    //[statsCollector reportStats];
    // Teardown XMPP
    [[XMPPWorker sharedInstance] stopEngine];
    
    [sh disconnect];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
   
    //Closing Session Manager
    if(_isSMRoomCreated && !_isIncomingCall){
        
        [self sendCloseRoomRequest:__sessionConfig];
    }
    else
    {
        httpconn.delegate = nil;

    }
    
}

- (void)rejectCall
{
    NSData *data = [@"{\"type\" : \"bye\"}" dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    NSDictionary* json =[WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
    NSMutableDictionary* jsonm = [NSMutableDictionary dictionaryWithDictionary:json];
    
    [jsonm setValue:to forKey:@"target"];
    [jsonm setValue:from forKey:@"from"];
    [jsonm setValue:@"PBA" forKey:@"appId"];
    [jsonm setValue:from forKey:@"uid"];
    [jsonm setValue:@"default" forKey:@"applicationContext"];
    [jsonm setValue:clientSessionId forKey:@"clientSessionId"];
    
    [self sendRTCMessage:jsonm];
    
    
}
- (void)logToAnalytics:(NSString*)event
{
    [self.delegate onLogToAnalytics:event];
}
- (void)sendRegMessage:(id)msg
{
    LogDebug(@"Webrtc:Session:: sendRegMessage");
    [statsCollector storeCallLogMessage:msg _msgType:@"clientReg"];
    [sh sendClientRegMessage:msg];
}

- (void)registerOnServer
{
    LogDebug(@"registerOnServer");
    NSDictionary *tempMsg = @{ @"uid" : emailId, @"address" : emailId, @"Authorization" : @"Bearer ExampleKey"};
    NSError *jsonError = nil;
    NSData *msg = [WebRTCJSONSerialization dataWithJSONObject:tempMsg options:0 error:&jsonError];
    
    NSError* error;
    NSDictionary* json =[WebRTCJSONSerialization JSONObjectWithData:msg options:kNilOptions error:&error];
    
    NSMutableDictionary* jsonm = [NSMutableDictionary dictionaryWithDictionary:json];
    
    
    // Sending registration request
    LogDebug(@"Webrtc:Session:: Sending registration message");
    [self sendRegMessage:jsonm];
    
    NSTimer *_regtimer;
    _regtimer = [NSTimer scheduledTimerWithTimeInterval:ICE_SERVER_TIMEOUT
                                                 target:self
                                               selector:@selector(_timerCallback:)
                                               userInfo:nil
                                                repeats:NO
                 ];
    
    
}

- (void)_timerCallback:(NSTimer *)timer{
    
    LogDebug(@" _timerCallback");
    
    NSDictionary *tempMsg = @{ @"uid" : emailId, @"address" : emailId, @"Authorization" : @"Bearer ExampleKey"};
    NSError *jsonError = nil;
    NSData *msg = [WebRTCJSONSerialization dataWithJSONObject:tempMsg options:0 error:&jsonError];
    
    NSError* error;
    NSDictionary* json =[WebRTCJSONSerialization JSONObjectWithData:msg options:kNilOptions error:&error];
    
    NSMutableDictionary* jsonm = [NSMutableDictionary dictionaryWithDictionary:json];
    
    
    // Sending registration request
    LogDebug(@"Webrtc:Session:: Sending registration message");
    [self sendRegMessage:jsonm];
    
}

#pragma mark - Sample SignalHandlerDelegate delegate
- (void)onSignallingMessage:(NSString*) event msg:(NSString *)msg
{
    LogDebug(@"Webrtc:Session:: Got a signaling message with type:: %@",event );
    if (![event compare:@"rtc_server_message"])
    {
        [self onRTCServerMessage:msg];
    }
    else if (![event compare:@"reg_server_message"]){
        [self onRegMessage:msg];
    }
    else if (![event compare:@"auth_server_message"]){
        [self onAuthMessage:msg];
    }
    else
    {
        LogDebug(@"Webrtc:Session:: unknown message");
    }
}

- (void)_reconnectCallback
{    
    if(isChannelAPIEnable && !isReconnecting && (nwState == SocketDisconnect))
    {
        isReconnecting = true;
        [self onStateChange:SocketReconnecting];
        LogDebug(@" Socket got disconnect, Trying Reconnnecting....");
        [sh disconnectForce];
        
        NSMutableDictionary* jsonHeaders = [[NSMutableDictionary alloc]init];
        [jsonHeaders setObject:[[NSUUID UUID] UUIDString] forKey:@"x-tracking-id"];
        [jsonHeaders setObject:stackConfig.serverNameHeader forKey:@"x-server-name"];
        [jsonHeaders setObject:stackConfig.clientNameHeader forKey:@"x-client-name"];
        [jsonHeaders setObject:stackConfig.sourceIdHeader forKey:@"x-source-id"];
        [jsonHeaders setObject:stackConfig.deviceIdHeader forKey:@"Device-Id"];
        
        [httpconn sendResourceRequest:jsonHeaders _usingRTC20:false _requestTimeout:stackConfig.httpRequestTimeout];
        //[sh connectToSignallingServer:username credentials:encodedcredential resource:path];
    }
}
    
- (void)onConnected
{
     LogDebug(@"Webrtc:Session:: Signaling stack on ready for signaling>>");
    
    if(isReconnecting)
    {
        [self onStateChange:SocketReconnected];
        isReconnecting = false;
        WebRTCSession *session = (WebRTCSession*) [sessions objectForKey:clientSessionId];
        [session reconnectSession];
        if((isWifiModePrev == true) && (isWifiMode == true))
            [session networkReconnected];
    }
    else
    {
        NSArray* alias = [[NSArray alloc] init];
        [self logToAnalytics:@"SDK_SocketConnected"];
        [self onStateChange:SocketConnected];
        [self.delegate onReady:alias];
    }
}

- (void)onDisconnected:(NSString*) error
{
    LogDebug(@"Inside WebRTCStack::onDisconnected");
    [self logToAnalytics:@"SDK_SocketDisconnected"];

    [self onStateChange:Disconnected];
    
    //[self.delegate onDisconnect:@"Disconnected from Signaling server"];
}
- (void)onSignalHandlerError:(NSString*) error Errorcode:(NSInteger)code
{
    LogError(@"onSignalHandlerError");
        
    if(!stackConfig.isNwSwitchEnable || isReconnecting)
        [self onStackError:error errorCode:code additionalData:nil];
    else
    {
        [self onStateChange:SocketDisconnect];
        if(isNetworkAvailable && isNetworkStateUpdated)
        {
            isNetworkStateUpdated = false;
            [self initiateReconnect];
        }
        else
        {
            LogDebug(@"WebRTCStack::onDisconnected:  Socket disconnected");
        }
    }    
}

-(void) onStateChange:(NetworkState)state
{
    nwState = state;
    [self.delegate onNetworkStateChange:state];
}

#pragma mark - Sample WebRTCStreamDelegate delegate
- (void)OnLocalStream:(RTCVideoTrack *)videoTrack;
{
    LogDebug(@"OnLocalStream");
    [self.delegate onLocalPreview:videoTrack];
}

- (void) onStreamError:(NSString *)error errorCode:(NSInteger)code
{
    LogError(@"On Error from stream");
    [self onStackError:error errorCode:code additionalData:nil];
}

-(BOOL)isStreamVideoEnable
{
   return true;
}

- (void) onIceServer:(NSDictionary*) msg
{
    //TODO
}

- (void) onHTTPError:(NSString*)error errorCode:(NSInteger)code additionalData:(NSDictionary *)additionalData

{
   [self onStackError:error errorCode:code additionalData:additionalData];
}

-(void)onStackError:(NSString*)error errorCode:(NSInteger)code additionalData:(NSDictionary *)additionalData
{
    switch (code) {
        case ERR_NO_WEBSOCKET_SUPPORT:
            [statsCollector storeError:@"unable to connect"];
            break;
            
        case ERR_WEBSOCKET_DISCONNECT:
            [statsCollector storeError:@"Server Disconnected"];
            break;
        
        case ERR_INCORRECT_STATE:
            [statsCollector storeError:@"Incorrect State"];
            break;
            
        case ERR_INVALID_CONSTRAINTS:
            [statsCollector storeError:@"Invalid Constraints Given"];
            break;
            
        case ERR_CAMERA_NOT_FOUND:
            [statsCollector storeError:@"Camera Error"];
            break;
            
        default:
            [statsCollector storeError:@"Unknown Error"];
            break;
    }
    [self logToAnalytics:@"SDK_Error"];
    [self.delegate onStackError:error errorCode:code additionalData:additionalData];
}

- (int) getMachineID
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *device = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    LogDebug(@"getMachineID = %@",device);
    
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

- (void)reconnectTimeout
{
    if (nwState == SocketDisconnect)
    {
        LogInfo(@"Network Reconnect Wait Time is Over !!!!");
        [self logToAnalytics:@"SDK_Error"];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"websocket connection has been closed by the gateway/server" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:Socket code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        [self onStackError:error.description errorCode:error.code additionalData:nil];
        [self onStateChange:Disconnected];
        isReconnecting = false;
    }
}

- (void)reachabilityChanged:(NSNotification*)notification
{
    
    if(reachability.currentReachabilityStatus == NotReachable && oldStatus !=  reachability.currentReachabilityStatus)
    {
        LogInfo(@"Internet off");
        isNetworkAvailable = false;
        isNetworkStateUpdated = true;
        oldStatus = reachability.currentReachabilityStatus;
        
        _reconnectTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:RECONNET_TRY_TIMEOUT
                                                       target:self
                                                     selector:@selector(reconnectTimeout)
                                                     userInfo:nil
                                                      repeats:NO
                       ];

    }
    else if(oldStatus != reachability.currentReachabilityStatus)
    {
        LogInfo(@"Internet on");
        isNetworkAvailable = true;
        isNetworkStateUpdated = true;
        oldStatus = reachability.currentReachabilityStatus;
        
        isWifiModePrev = isWifiMode;
        if (reachability.currentReachabilityStatus == ReachableViaWiFi){
            isWifiMode = true;
        }
        else{
            isWifiMode = false;
        }
        [self initiateReconnect];
    }
}

- (void) initiateReconnect
{
    if (_reconnectTimeoutTimer != nil) {
        [_reconnectTimeoutTimer invalidate];
    }
    
    [self _reconnectCallback];
}

-(void)sendpreferredH264:(BOOL)preferH264{
#ifdef __IPHONE_8_0
    //[RTCPeerConnectionFactory OnSetH264:preferH264];
#else
    NSLog(@"Call on iOS version less than iOS 8 will run on VP8 only !!!");
#endif
}

-(void) setRecordingState:(NSString*)state
{
    [[XMPPWorker sharedInstance] record:state];
}

-(void)enableIPV6:(BOOL)value{

    //[RTCPeerConnectionFactory OnSetIPV6:value];
}

-(void) createVoiceSession:(id<WebRTCSessionDelegate>)_appdelegate _configParam:(WebRTCSessionConfig *)_sessionConfig
{
    _isPSTNVoiceSession = true;
    _session = [[WebRTCSession alloc]initWithPSTNSession:self _appdelegate:_appdelegate _configParam:stackConfig];
    [self sendCreateRoomRequest:_sessionConfig];
}

-(void) endVoiceSession
{
    [_session endPSTNSession];
}

-(void)onXmppServerConnected
{
    [self logToAnalytics:@"SDK_XMPPServerConnected"];

    [self.delegate onWebSocketConnectedAndAuthenticated];
}

- (NSString*)getTraceId
{
    return stackConfig.traceIdHeader;
}

-(int) switchSpeaker: (BOOL)builtin
{
    NSError* theError = nil;
    BOOL result = YES;
    
    AVAudioSession* outAudioSession = [AVAudioSession sharedInstance];
    
    result = [outAudioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&theError];
    if (!result)
    {
        NSLog(@"switchSpeaker::setCategory failed");
    }
    
    result = [outAudioSession setActive:YES error:&theError];
    if (!result)
    {
        NSLog(@"switchSpeaker::setActive failed");
    }
    
    if(builtin)
    {
        result = [outAudioSession  overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&theError];
        if(!result)
        {
            NSLog(@"overrideOutputAudioPort to speaker failed");
        }
        
    }
    else
    {
        result = [outAudioSession  overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&theError];
        if(!result)
        {
            NSLog(@"overrideOutputAudioPort to headset failed");
        }
    }
    
    return 1;
}@end
#endif
