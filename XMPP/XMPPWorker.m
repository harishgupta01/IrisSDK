//
//  XMPPWorker.m
//  AppRTCDemo
//
//  Created by zhang zhiyu on 14-2-25.
//  Copyright (c) 2014年 YK-Unit. All rights reserved.
//

#import "XMPPWorker.h"
#import "XMPPMessage+Signaling.h"
#import "IrisDataElement.h"
// Manish
#import "XMPPJingle.h"
#import "XMPPPresence+Iris.h"
//Vamsi
#import "XMPPRayo.h"
#import "IrisLogging.h"
#import "IrisRtcJingleSession+Internal.h"
//Jahnavi
@import CocoaLumberjack;

//#import "DDLog.h"
//#import "DDTTYLogger.h"
#define DEFAULT_PING_TIMEINTERVAL 15
#define DEFAULT_PING_TIMEOUT_INTERVAL 3
static NSString *const pingID = @"c2s";

#import <CFNetwork/CFNetwork.h>

static const int ddLogLevel = DDLogLevelVerbose;



@interface XMPPWorker(){
    NSTimeInterval presenceCheckTimeInterval;
    BOOL isPingReceived;
    NSDate* lastPongreceived;
    NSInteger pingSentWithoutPong;
}
//- (void)setupStream;
- (void)teardownStream;

- (void)goOnline;
- (void)goOffline;

- (NSManagedObjectContext *)managedObjectContext_roster;
- (NSManagedObjectContext *)managedObjectContext_capabilities;

// Manish
@property (nonatomic, strong) XMPPRoomHybridStorage* xmppRoomStorage;
@property (nonatomic, strong) XMPPRoom* xmppRoom;
@property (nonatomic, strong) XMPPJingle* xmppJingle;
@property (nonatomic, strong) XMPPJID *targetjid;

@property (nonatomic, strong) NSString* participantJID;
@property (nonatomic, strong) NSString* moderatorJID;
@property (nonatomic, strong) NSString* senderJID;


@property (nonatomic, strong) NSTimer *_aliveIQTimer;
@property (nonatomic, strong) NSTimer *_aliveIQTimeoutTimer;
@property (nonatomic, assign) NSTimeInterval pingTimeInterval;
@property (nonatomic, assign) NSTimeInterval pingTimeoutInterval;
@property (nonatomic, strong) NSTimer *_pingTimer;

@property  BOOL isparticipantjoined;

@property  BOOL isAlive;

@end

@implementation XMPPWorker
@synthesize hostPort,timestamp,token,routingId,IsXMPPRoomCreater,isRoomJoined,actualHostName,streamCount,pingPongTimeInterval;
@synthesize event,nodeId,cnodeId,unodeId,maxParticipants;
@synthesize allowSelfSignedCertificates,allowSSLHostNameMismatch;
@synthesize userName,userPwd;
@synthesize isXmppConnected,isEngineRunning;
@synthesize signalingDelegate;
@synthesize webSocketDelegate;
@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize xmppRoster;
@synthesize xmppRosterStorage;
@synthesize xmppvCardTempModule;
@synthesize xmppvCardAvatarModule;
@synthesize xmppCapabilities;
@synthesize xmppCapabilitiesStorage;
@synthesize fetchedResultsController_roster;
@synthesize isVideoBridgeEnable;
@synthesize resourceId;
@synthesize sourceTelNum,targetTelNum;
@synthesize isAttemmptingReconnect;


+ (XMPPWorker *)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static XMPPWorker *_sharedXMPPWorker = nil;
    dispatch_once(&pred, ^{
        _sharedXMPPWorker = [[self alloc] init];
    });
    return _sharedXMPPWorker;
}

- (id)init
{
    self = [super init];
    if (self) {
        hostPort = 0;
        timestamp = NULL;
        token = NULL;
        routingId = NULL;        // You may need to alter these settings depending on the server you're connecting to
        event = NULL;
        nodeId = NULL;
        cnodeId = NULL;
        unodeId = NULL;
        maxParticipants = NULL;
        actualHostName = NULL;
        allowSelfSignedCertificates = NO;
        allowSSLHostNameMismatch = NO;
        _isAlive = false;
        isXmppConnected = NO;
        isEngineRunning = NO;        
        isVideoBridgeEnable = false;
        isRoomJoined = NO;
        isPingReceived = false;
        IsXMPPRoomCreater = true;
        _pingTimeInterval = DEFAULT_PING_TIMEINTERVAL;
        _pingTimeoutInterval = DEFAULT_PING_TIMEOUT_INTERVAL;
        streamCount = -1;
        pingPongTimeInterval = 5;
        pingSentWithoutPong = 0;
        _activeSessions = [[NSMutableDictionary alloc]init];
        _isHitlessUpgrade = false;
        _isSocketReconnected = false;
        
    }
    return self;
}

- (void)deallocWorker
{
    if (isEngineRunning) {
        [self stopEngine];
    }
    
    if (fetchedResultsController_roster) {
        fetchedResultsController_roster.delegate = Nil;
    }
    
   // self.signalingDelegate = Nil;
    self.webSocketDelegate = Nil;
    
}

#pragma mark - private methods
- (void)setupStream
{
    //Changes done for multiple connection test cases
	//NSAssert(xmppStream == nil, @"Method setupStream invoked multiple times");
	
	// Setup xmpp stream
	//
	// The XMPPStream is the base class for all activity.
	// Everything else plugs into the xmppStream, such as modules/extensions and delegates.
    
	xmppStream = [[IrisXMPPStream alloc] init];
	
#if !TARGET_IPHONE_SIMULATOR
	{
		// Want xmpp to run in the background?
		//
		// P.S. - The simulator doesn't support backgrounding yet.
		//        When you try to set the associated property on the simulator, it simply fails.
		//        And when you background an app on the simulator,
		//        it just queues network traffic til the app is foregrounded again.
		//        We are patiently waiting for a fix from Apple.
		//        If you do enableBackgroundingOnSocket on the simulator,
		//        you will simply see an error message from the xmpp stack when it fails to set the property.
		
		xmppStream.enableBackgroundingOnSocket = YES;
	}
#endif
	
	// Setup reconnect
	//
	// The XMPPReconnect module monitors for "accidental disconnections" and
	// automatically reconnects the stream for you.
	// There's a bunch more information in the XMPPReconnect header file.
	
	xmppReconnect = [[XMPPReconnect alloc] init];
	
	// Setup roster
	//
	// The XMPPRoster handles the xmpp protocol stuff related to the roster.
	// The storage for the roster is abstracted.
	// So you can use any storage mechanism you want.
	// You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
	// or setup your own using raw SQLite, or create your own storage mechanism.
	// You can do it however you like! It's your application.
	// But you do need to provide the roster with some storage facility.
	
	xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    //	xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
	
	xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
	
	xmppRoster.autoFetchRoster = YES;
	xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
	
	// Setup vCard support
	//
	// The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
	// The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
	
	xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
	xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:xmppvCardStorage];
	
	xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:xmppvCardTempModule];
	
	// Setup capabilities
	//
	// The XMPPCapabilities module handles all the complex hashing of the caps protocol (XEP-0115).
	// Basically, when other clients broadcast their presence on the network
	// they include information about what capabilities their client supports (audio, video, file transfer, etc).
	// But as you can imagine, this list starts to get pretty big.
	// This is where the hashing stuff comes into play.
	// Most people running the same version of the same client are going to have the same list of capabilities.
	// So the protocol defines a standardized way to hash the list of capabilities.
	// Clients then broadcast the tiny hash instead of the big list.
	// The XMPPCapabilities protocol automatically handles figuring out what these hashes mean,
	// and also persistently storing the hashes so lookups aren't needed in the future.
	//
	// Similarly to the roster, the storage of the module is abstracted.
	// You are strongly encouraged to persist caps information across sessions.
	//
	// The XMPPCapabilitiesCoreDataStorage is an ideal solution.
	// It can also be shared amongst multiple streams to further reduce hash lookups.
	
    
    /*  Manish: this was the original code
     
     xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
     xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:xmppCapabilitiesStorage];
     
     xmppCapabilities.autoFetchHashedCapabilities = YES;
     xmppCapabilities.autoFetchNonHashedCapabilities = NO;
     
     // Activate xmpp modules
     
     [xmppReconnect         activate:xmppStream];
     [xmppRoster            activate:xmppStream];
     [xmppvCardTempModule   activate:xmppStream];
     [xmppvCardAvatarModule activate:xmppStream];
     [xmppCapabilities      activate:xmppStream];

    */
    
	xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
    xmppCapabilities = [[IrisXMPPCapabilities alloc] initWithCapabilitiesStorage:xmppCapabilitiesStorage];
    
    xmppCapabilities.autoFetchHashedCapabilities = NO;
    xmppCapabilities.autoFetchNonHashedCapabilities = NO;
    xmppCapabilities.autoFetchMyServerCapabilities = YES;

	// Activate xmpp modules
    
	[xmppReconnect         activate:xmppStream];
    
    // Manish: we need however 0030 and 0045
    // 0030 is based on 0115 so lets use that and set properties to use 0030
    [xmppCapabilities      activate:xmppStream];
    
    /* Join room
    // MUC
    self.xmppRoomStorage = [XMPPRoomHybridStorage sharedInstance];
    self.xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:self.xmppRoomStorage jid:xmppStream.myJID];
    
    [self.xmppRoom addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [self.xmppRoom activate:self.xmppStream];
     */
	  
    // Manish: We dont need XEP 0115 or 0153 or 154 or 144
    //[xmppRoster            activate:xmppStream];
    //[xmppvCardTempModule   activate:xmppStream];
    //[xmppvCardAvatarModule activate:xmppStream];
    //[xmppCapabilities      activate:xmppStream];
    
	// Add ourself as a delegate to anything we may be interested in
    
    
	[xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
	[xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    
    
     /*XMPPIncomingFileTransfer *xmppIncomingFileTransfer;
     xmppIncomingFileTransfer = [[XMPPIncomingFileTransfer alloc] init];
     xmppIncomingFileTransfer.disableIBB = NO;
     xmppIncomingFileTransfer.disableSOCKS5 = YES;
     xmppIncomingFileTransfer.disableDirectTransfers = YES;
     [xmppIncomingFileTransfer   activate:xmppStream];
     
     [xmppIncomingFileTransfer addDelegate:self delegateQueue:dispatch_get_main_queue()];*/

    
	// Optional:
	//
	// Replace me with the proper domain and port.
	// The example below is setup for a typical google talk account.
	//
	// If you don't supply a hostName, then it will be automatically resolved using the JID (below).
	// For example, if you supply a JID like 'user@quack.com/rsrc'
	// then the xmpp framework will follow the xmpp specification, and do a SRV lookup for quack.com.
	//
	// If you don't specify a hostPort, then the default (5222) will be used.
	
    //	[xmppStream setHostName:@"talk.google.com"];
    //	[xmppStream setHostPort:5222];
    
    //Vamsi
    //[xmppStream setHostName:@"10.0.0.22"];
    //[xmppStream setHostPort:80];
    
    // You may need to alter these settings depending on the server you're connecting to
    customCertEvaluation = YES;
    
    //Jingle ... Need to check this
    /*allowSelfSignedCertificates = NO;
    allowSSLHostNameMismatch = NO;
    allAudioCodecs = [xmppJingle emptyAudioPayload];
    NSArray * codecs = [[phono papi] codecArray];
    for (int i=0; i< [codecs count]; i++){
        NSDictionary *codec = [codecs objectAtIndex:i];
        [xmppJingle addCodecToPayload:allAudioCodecs name:[codec objectForKey:@"name"] rate:[codec objectForKey:@"rate"] ptype:[codec objectForKey:@"ptype"]];
    }*/

}

- (void)teardownStream
{
	[xmppStream removeDelegate:self];
	[xmppRoster removeDelegate:self];
	
	[xmppReconnect         deactivate];
	[xmppRoster            deactivate];
	[xmppvCardTempModule   deactivate];
	[xmppvCardAvatarModule deactivate];
	[xmppCapabilities      deactivate];
    DDLogVerbose(@"XMPPStream disconnect call from XMPPWorker teardownStream");

	[xmppStream disconnect];
	
	xmppStream = nil;
	xmppReconnect = nil;
    xmppRoster = nil;
	xmppRosterStorage = nil;
	xmppvCardStorage = nil;
    xmppvCardTempModule = nil;
	xmppvCardAvatarModule = nil;
	xmppCapabilities = nil;
	xmppCapabilitiesStorage = nil;
    resourceId = nil;
}

- (void)goOnline
{
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
    
    //NSString *domain = [xmppStream.myJID domain];
    //NSString *domain = hostName;
    
    //Google set their presence priority to 24, so we do the same to be compatible.
    
    /*if([domain isEqualToString:@"gmail.com"]
       || [domain isEqualToString:@"gtalk.com"]
       || [domain isEqualToString:@"talk.google.com"])
    {
        NSXMLElement *priority = [NSXMLElement elementWithName:@"priority" stringValue:@"24"];
        [presence addChild:priority];
    }*/
	
	[[self xmppStream] sendElement:presence];
}




// Manish: Start doing jingle





-(void)sendMediaPresence:(NSDictionary *)msg target:(XMPPJID *)target
{
    NSString *item;
    
    if([[msg objectForKey:@"media"] isEqualToString:@"audio"]){
        item= @"audiomuted";
    }else if([[msg objectForKey:@"media"] isEqualToString:@"video"]){
        item= @"videomuted";
    }
    
    NSArray *targetJID = [[target full] componentsSeparatedByString: @"/"];
    XMPPJID *toJID = [XMPPJID jidWithString:targetJID[0]];
    XMPPPresence *presence = [XMPPPresence presenceWithType:nil to:toJID];
    NSXMLElement *recElement = [NSXMLElement elementWithName:item];
    [recElement addAttributeWithName:@"xmlns" stringValue:@"http://jitsi.org/jitmeet/audio"];
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];    
    [message setStringValue:[msg objectForKey:@"reason"]];
    
    [presence addChild:recElement];
    [presence addChild:message];
    [[self xmppStream] sendElement:presence];
    
}


- (void)goOffline
{
   
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	
	[[self xmppStream] sendElement:presence];
}

#pragma mark - public methods
- (void)startEngine
{
    [self setupStream];
    isEngineRunning = YES;
}

- (void)stopEngine
{
    [self teardownStream];
    isEngineRunning = NO;
}

-(BOOL)hasActiveAudioorVideoSession{

    for(NSString* key in _activeSessions.keyEnumerator){
        
        if(![[[_activeSessions objectForKey:key]getSessionType]    isEqual: @"groupchat"]){
            return true;
        }
    }    
   
    return false;
    
}

- (BOOL)connect
{
    if (![xmppStream isDisconnected]) {
        return YES;
    }
   
    if (!self.userName || !self.userPwd) {
        return NO;
    }
    
     //userName should be name@domain
    [xmppStream setMyJID:[XMPPJID jidWithString:self.userName]];
    password = self.userPwd;

    NSError *error = nil;
    if (![xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error])
	{
		//EASYLogError(@"Error connecting: %@", error);
        DDLogVerbose(@"Error due to connect failue");
       [self.webSocketDelegate onXmppWebSocketError:error.description errorCode:ERR_XMPP_CONNECTION_FAILED];
        
		return NO;
	}
    return YES;
}

- (void)disconnect
{
    //if(__presenceAliveTimer != nil)
    //    [__presenceAliveTimer invalidate];
    [self goOffline];
    DDLogVerbose(@"Cocalumberjack::XMPPStream disconnect call from XMPPWorker disconnect");
	//[xmppStream disconnect];
    //[self deallocWorker];
}

- (void)disconnectWebSocket
{
   dispatch_async(dispatch_get_main_queue(), ^{
       if(__aliveIQTimer != nil)
           [__aliveIQTimer invalidate];
       
   });
    
    [self stopPingPongTimer];
    
    //[self goOffline];
    IRISLogInfo(@"Cocalumberjack::XMPPStream disconnect call from XMPPWorker disconnectWebSocket");
    [xmppStream setDataElement:nil];
    [xmppStream disconnect];
    //[self deallocWorker];
}

-(void)stopAliveIQTimer {
    
    if(__aliveIQTimer != nil)
         [__aliveIQTimer invalidate];
    
}

-(void)stopPingPongTimer{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(__pingTimer != nil)
            [__pingTimer invalidate];
    });
}

- (void)startAliveIQTimer{
    
   
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __aliveIQTimer = [NSTimer scheduledTimerWithTimeInterval:_pingTimeInterval
                                                          target:self
                                                        selector:@selector(sendAliveIQ)
                                                        userInfo:nil
                                                         repeats:YES
                          ];
    });
    
}

- (void)startPingPongTimer{
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __pingTimer = [NSTimer scheduledTimerWithTimeInterval:pingPongTimeInterval
                                                          target:self
                                                        selector:@selector(sendPing)
                                                        userInfo:nil
                                                         repeats:YES
                          ];
    });
    
}

-(void)sendPing {
    
    //long timeSinceLastPong = [[NSDate date]timeIntervalSinceDate:lastPongreceived];
    //if(_isAlive == false){
    if( pingSentWithoutPong == 5 ){
        pingSentWithoutPong = 0;
        DDLogVerbose(@"Error due to ping/pong failue");
        [self.webSocketDelegate onXmppWebSocketPingPongFailure];
        return;
        
    }
    _isAlive = false;
    DDLogVerbose(@"Sending wesocket ping .....");
    [xmppStream sendPing:NULL];
    pingSentWithoutPong++;
    
}

//Girish:: method to set presencetimeinterval and presencechecktimeinterval
- (void)setPingTimeInterval:(NSTimeInterval)timeinterval
{
    //_pingTimeInterval = timeinterval;
    pingPongTimeInterval = timeinterval;
}

- (void)setPingTimoutInterval:(NSTimeInterval)timeinterval{
    
    if(timeinterval > 0){
        
        _pingTimeoutInterval = timeinterval;
    }
}




- (void)sendSignalingMessage:(NSString *)message toUser:(NSString *)jidStr
{
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:message];
    
    XMPPJID *toJID = [XMPPJID jidWithString:jidStr];
    
    XMPPMessage *xmppMessage = [XMPPMessage signalingMessageTo:toJID elementID:Nil child:body];
    [xmppStream sendElement:xmppMessage];
}

-(void)setActualHostName:(NSString *)name
{
    if (name) {
        actualHostName = Nil;
        actualHostName = [name copy];
        
        if (xmppStream) {
            [xmppStream setActualHostName:name];
        }
    }
}

- (void)setHostPort:(UInt16)port
{
    if (port) {
        hostPort = port;
        if (hostPort) {
            [xmppStream setHostPort:port];
        }
    }
}

- (void)setTimestamp:(NSString *)timeStamp
{
    if (timeStamp) {
        timestamp = Nil;
        timestamp = [timeStamp copy];
        
        if (xmppStream) {
            [xmppStream setTimestamp:timestamp];
        }
    }
}

- (void)setToken:(NSString *)secureToken
{
    if (secureToken) {
        token = Nil;
        token = [secureToken copy];
        
        if (xmppStream) {
            [xmppStream setToken:token];
        }
    }
}

- (void)setRoutingId:(NSString *)Id
{
    if (Id) {
        routingId = Nil;
        routingId = [Id copy];
        
        if (xmppStream) {
            [xmppStream setRoutingId:routingId];
        }
    }
}

- (void)setEvent:(NSString *)callType
{
    if (callType) {
        event = Nil;
        event = [callType copy];
        
        if (xmppStream) {
            [xmppStream setCallType:callType];
        }
    }
}

- (void)setNodeId:(NSString *)Id
{
    if (Id) {
        nodeId = Nil;
        nodeId = [Id copy];
        
        if (xmppStream) {
            [xmppStream setNodeId:nodeId];
        }
    }
}

- (void)setCnodeId:(NSString *)Id
{
    if (Id) {
        cnodeId = Nil;
        cnodeId = [Id copy];
        
        if (xmppStream) {
            [xmppStream setCnodeId:cnodeId];
        }
    }
}

- (void)setUnodeId:(NSString *)Id
{
    if (Id) {
        unodeId = Nil;
        unodeId = [Id copy];
        
        if (xmppStream) {
            [xmppStream setUnodeId:unodeId];
        }
    }
}
- (void)setMaxParticipants:(NSString *)participants
{
    if (participants) {
        maxParticipants = Nil;
        maxParticipants = [participants copy];
        
        if (xmppStream) {
            [xmppStream setMaxParticipants:maxParticipants];
        }
    }
}
- (void)setIsXMPPRoomCreater:(BOOL)IsInitiator
{
    IsXMPPRoomCreater = IsInitiator;
        if (xmppStream) {
            [xmppStream setIsXMPPRoomCreator:IsXMPPRoomCreater];
        }
    
}

- (void)setStreamCount:(int)StreamCount
{
    streamCount = StreamCount;

}
#pragma mark - Core Data
- (NSManagedObjectContext *)managedObjectContext_roster
{
	return [xmppRosterStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext_capabilities
{
	return [xmppCapabilitiesStorage mainThreadManagedObjectContext];
}

- (void)setXMPPDelegate:del
{
    _xmppDelegate = (id< XMPPFileTransferDelegate >) del;
}

#pragma mark - fetchedResultsController_roster
- (NSFetchedResultsController *)fetchedResultsController_roster
{
    if (fetchedResultsController_roster == Nil) {
        NSManagedObjectContext *moc = [self managedObjectContext_roster];
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
            inManagedObjectContext:moc];
		
		NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
		NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
		
		NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, sd2, nil];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setSortDescriptors:sortDescriptors];
		[fetchRequest setFetchBatchSize:10];
		
		fetchedResultsController_roster = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
            managedObjectContext:moc
            sectionNameKeyPath:@"sectionNum"
            cacheName:nil];
		
		NSError *error = nil;
		if (![fetchedResultsController_roster performFetch:&error])
		{
			//EASYLogError(@"Error performing fetch: %@", error);
		}
        
    }
    
    return fetchedResultsController_roster;
}

#pragma mark - XMPPStreamDelegate

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (allowSelfSignedCertificates)
	{
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	}
	
	if (allowSSLHostNameMismatch)
	{
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
	}
	else
	{
		//NSString *expectedCertName = [xmppStream.myJID domain];
        NSString *expectedCertName = actualHostName;
        
		if (expectedCertName)
		{
			[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
		}
	}
}

- (void)xmppStream:(XMPPStream *)sender didReceiveTrust:(SecTrustRef)trust
 completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler
{
    //DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    // The delegate method should likely have code similar to this,
    // but will presumably perform some extra security code stuff.
    // For example, allowing a specific self-signed certificate that is known to the app.
    
    dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(bgQueue, ^{
        
        SecTrustResultType result = kSecTrustResultDeny;
        OSStatus status = SecTrustEvaluate(trust, &result);
        
        if (status == noErr && (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified)) {
            completionHandler(YES);
        }
        else {
            completionHandler(NO);
        }
    });
}


- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	isXmppConnected = YES;
    
    NSError *error = nil;
	
	if (![[self xmppStream] authenticateWithPassword:password error:&error])
	{
		DDLogVerbose(@"Error authenticating: %@", error);
        return;
	}
    
    // muc changes
    /*[NSTimer scheduledTimerWithTimeInterval:30
                                     target:self
                                   selector:@selector(sendAlive)
                                   userInfo:nil
                                    repeats:YES
     ];*/

}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
 
	//[self goOnline];
    //NSArray* alias = [[NSArray alloc] init];

    //[self.xmppDelegate onReady:alias];
    _isAlive = true;
    _userJid = [xmppStream myJID];
    [self.webSocketDelegate onXmppWebSocketAuthenticated];
    [self startPingPongTimer];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    //[self.xmppDelegate onError:@"XMPP Server didNotAuthenticate"];
    IRISLogError(@"Error due to authentication failue");
    [self.webSocketDelegate onXmppWebSocketError:@"XMPP Server didNotAuthenticate" errorCode:ERR_WEBSOCKET_DISCONNECT];

}

-(void)xmppStream:(XMPPStream *)sender onPongMessage:(DDXMLElement *)error{
     IRISLogInfo(@"Receiving wesocket pong ...");
    _isAlive = true;
    //lastPongreceived = [NSDate date];
    pingSentWithoutPong = 0;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[message from] xmppStream:xmppStream managedObjectContext:[self managedObjectContext_roster]];
    NSString *body = [[message elementForName:@"body"] stringValue];
    NSString *jidStr = [user jidStr];
    DDLogVerbose(@"ReceiveMessage:\n%@\nfrom:%@",body,jidStr);
    IRISLogInfo(@" *---* ReceiveMessage:\n%@\nfrom:%@",body,jidStr);
    
    if ([message isSignalingMessageWithBody]) {
        /*if (self.signalingDelegate && [self.signalingDelegate respondsToSelector:@selector(xmppWorker:didReceiveSignalingMessage:)]) {*/
            //[self.signalingDelegate xmppWorker:self didReceiveSignalingMessage:message];
        //}
    }
}
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq;
{
    // Check if it is a jingle message
    NSString *type = [iq type];
    
    
    if ([type isEqualToString:@"result"] && ([[iq elementID] isEqualToString:pingID]))
    {
        isPingReceived = true;
    
    }
    
    NSArray *privateIqElements = [iq elementsForXmlns:@"jabber:iq:private"];
    
    // We are only looking for jingle related messages
    if (privateIqElements == nil || ([privateIqElements count] == 0))
        return NO;
    
    // Iterate through elements
    for (NSXMLElement *element in privateIqElements)
    {
        NSXMLElement *data = [element elementForName:@"data"];
        if (data)
        {
            NSString *type = [[data attributeForName:@"type"] stringValue];           
            if([type isEqualToString:@"disconnect"]){
                 [self.webSocketDelegate onXmppWebSocketReconnect];
                return  YES;
            }
            else if([type isEqualToString:@"leave room"]){
                return  NO;
            }
            
            NSMutableDictionary * dict = [data attributesAsDictionary];
            IRISLogInfo(@" XMPPWorker :: Received the private iq %@", [dict description]);
            [self.webSocketDelegate onXmppWebSocketNotification:dict];
        }
    }

    return YES;
}


-(void)sendAliveIQ{
    
        XMPPIQ *sendAliveIQ = [XMPPIQ iqWithType:@"get"  elementID:pingID];
        [sendAliveIQ addAttributeWithName:@"to" stringValue:actualHostName];
        [sendAliveIQ addAttributeWithName:@"from" stringValue:routingId];
        [sendAliveIQ addAttributeWithName:@"xmlns" stringValue:@"jabber:client"];
        NSXMLElement *ping = [NSXMLElement elementWithName:@"ping" xmlns:@"urn:xmpp:ping"];
        [sendAliveIQ addChild:ping];
        
        [[self xmppStream] sendElement:sendAliveIQ];
        //[self startPingTimeoutTimer];
    
    
}

-(void)sendUserProfilePresence:(NSString*)name avatarUrl:(NSString*)url{
    
    if((name != nil) && (url != nil)){
        XMPPPresence *presence = [XMPPPresence presenceWithType:nil to:[XMPPJID jidWithString:room resource:[[xmppStream myJID]full]] id:@"c2p1"];
        NSXMLElement *userProfile = [NSXMLElement elementWithName:@"nick" xmlns:@"http://jabber.org/protocol/nick"];
        [userProfile addAttributeWithName:@"name" stringValue:name];
        [userProfile addAttributeWithName:@"avatar" stringValue:url];
        
        [presence addChild:userProfile];
        
        [[self xmppStream] sendElement:presence];
        

    }
    
}


- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSXMLElement *errorElement = (NSXMLElement *)error;
    IRISLogError(@"xmppStream :didReceiveError %@", [errorElement description]);

    //[self.signalingDelegate xmppError:[errorElement description] errorCode:ERR_XMPP_ERROR];
}

- (void)xmppStream:(XMPPStream *)sender onError:(NSError *)error
{
    
   //[self.signalingDelegate xmppError:[error localizedDescription] errorCode:ERR_XMPP_CONNECTION_FAILED];
    IRISLogError(@"Error due to socket failue");
    _oldjid = [[xmppStream myJID] full];
    [self.webSocketDelegate onXmppWebSocketError:[error localizedDescription] errorCode:ERR_XMPP_CONNECTION_FAILED];
}

- (void) onXmppServerConnected
{
    //[self.signalingDelegate onXmppServerConnected];
    [self.webSocketDelegate onXmppWebSocketConnected];
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (!isXmppConnected)
	{
		//EASYLogError(@"Unable to connect to server. Check xmppStream.hostName");
	}
    isXmppConnected = NO;
    
    //[self.xmppDelegate onDisconnect:[error localizedDescription]];
    IRISLogWarn(@"xmppStreamDidDisconnect::Disconnecting");
    [self.webSocketDelegate onXmppWebSocketDisconnected:[error localizedDescription]];
}

#pragma mark - XMPPRosterDelegate
- (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    IRISLogVerbose(@"xmppRoster :sender:didReceiveBuddyRequest");
	
	XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[presence from]
	                                                         xmppStream:xmppStream
	                                               managedObjectContext:[self managedObjectContext_roster]];
	
	NSString *displayName = [user displayName];
	NSString *jidStrBare = [presence fromStr];
	NSString *body = nil;
	
	if (![displayName isEqualToString:jidStrBare])
	{
		body = [NSString stringWithFormat:@"Buddy request from %@ <%@>", displayName, jidStrBare];
	}
	else
	{
		body = [NSString stringWithFormat:@"Buddy request from %@", displayName];
	}
	
	
	if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:displayName
		                                                    message:body
		                                                   delegate:nil
		                                          cancelButtonTitle:@"Not implemented"
		                                          otherButtonTitles:nil];
		[alertView show];
	}
	else
	{
		// We are not active, so use a local notification instead
		UILocalNotification *localNotification = [[UILocalNotification alloc] init];
		localNotification.alertAction = @"Not implemented";
		localNotification.alertBody = body;
		
		[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
	}
	
}



//PSTN dialing





//Sharecast

- (void)share:(NSData*)data 
{
    XMPPOutgoingFileTransfer *_fileTransfer ;
    

    if (!_fileTransfer) {
        _fileTransfer = [[XMPPOutgoingFileTransfer alloc]
                         initWithDispatchQueue:dispatch_get_main_queue()];
        
        [_fileTransfer activate:[self xmppStream]] ;
        _fileTransfer.disableIBB = NO;
        _fileTransfer.disableSOCKS5 = YES;
        _fileTransfer.disableDirectTransfers = YES;
        //[_fileTransfer addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        
    }
     NSError *err;
    
    XMPPJID *targetJid;
    
   if ([self.senderJID isEqualToString:self.moderatorJID] ) {
        
        targetJid = [XMPPJID jidWithString:self.participantJID resource:[[XMPPJID jidWithString:self.participantJID]resource]];
    }
    else
    {
    
        targetJid = [XMPPJID jidWithString:self.moderatorJID resource:[[XMPPJID jidWithString:self.moderatorJID]resource]];
    
    }
    
    
    if (![_fileTransfer sendData:data
                           named:nil
                     toRecipient:targetJid
                     description:nil
                           error:&err]) {
        
        IRISLogWarn(@"Something was messed");
    }
    
    
}


// Recording

- (void)record:(NSString*)state
{
    XMPPIQ *iq;
    
    iq = [self setRecordingJirecon:state tok:nil target:nil];
    
    // send IQ
    [xmppStream sendElement:iq];    
}

- (XMPPIQ*)setRecordingJirecon:(NSString*)state tok:(NSString*)token target:(NSString*)target
{
    XMPPIQ *xmpp;
    
    NSXMLElement *recElement = [NSXMLElement elementWithName:@"recording"];
    [recElement addAttributeWithName:@"xmlns" stringValue:@"http://jitsi.org/protocol/jirecon"];
    [recElement addAttributeWithName:@"action" stringValue:state];
    [recElement addAttributeWithName:@"mucjid" stringValue:room];
    if ([state isEqual:@"stop"])
    {
        [recElement addAttributeWithName:@"rid" stringValue:jireconRid];
    }
    else
    {
        jireconRid = @"";
    }

    
  
    //NSString *focusmucjid = [xmppStream.myJID domain];
    NSString *focusmucjid = actualHostName;
    focusmucjid = [focusmucjid stringByReplacingOccurrencesOfString:@"xmpp" withString:@"jirecon"];
    
    XMPPJID *targetJid = [XMPPJID jidWithString:focusmucjid];
    
    xmpp  = [[XMPPIQ alloc]initWithType:@"set" to:targetJid elementID:nil child:[recElement copy]];
    
    return xmpp;

}

- (XMPPIQ*)setRecordingColibri:(NSString*)state tok:(NSString*)token target:(NSString*)target
{
    XMPPIQ *xmpp;
    
    NSXMLElement *conElement = [NSXMLElement elementWithName:@"conference"];
    [conElement addAttributeWithName:@"xmlns" stringValue:@"http://jitsi.org/protocol/colibri"];
    
    
    NSXMLElement *recElement = [NSXMLElement elementWithName:@"recording"];
    [recElement addAttributeWithName:@"state" stringValue:state];
    [recElement addAttributeWithName:@"token" stringValue:token];
    
    [conElement addChild:recElement];
    
    NSString *focusmucjid = target;
    focusmucjid = [focusmucjid stringByReplacingOccurrencesOfString:@"xmpp" withString:@"colibri"];
    
    XMPPJID *targetJid = [XMPPJID jidWithString:focusmucjid];
    
    xmpp  = [[XMPPIQ alloc]initWithType:@"set" to:targetJid elementID:nil child:[conElement copy]];
    
    return xmpp; 
}

//XMPP XMPPOutgoingFileTransfer delegate

- (void)xmppOutgoingFileTransfer:(XMPPOutgoingFileTransfer *)sender
                didFailWithError:(NSError *)error
{
    IRISLogError(@"Outgoing file transfer failed with error: %@", error);
}

- (void)xmppOutgoingFileTransferDidSucceed:(XMPPOutgoingFileTransfer *)sender
{
    IRISLogInfo(@"File transfer successful.");
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                    message:@"Your file was sent successfully."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

//XMPP XMPPIncomingFileTransfer

- (void)xmppIncomingFileTransfer:(XMPPIncomingFileTransfer *)sender
                didFailWithError:(NSError *)error
{
    IRISLogError(@"%@: Incoming file transfer failed with error: %@", THIS_FILE, error);
    //[self.signalingDelegate xmppWorker:sender didFailWithError:error];
}

- (void)xmppIncomingFileTransfer:(XMPPIncomingFileTransfer *)sender
               didReceiveSIOffer:(XMPPIQ *)offer
{
    IRISLogInfo(@"%@: Incoming file transfer did receive SI offer. Accepting...", THIS_FILE);
    [sender acceptSIOffer:offer];
}

- (void)xmppIncomingFileTransfer:(XMPPIncomingFileTransfer *)sender
              didSucceedWithData:(NSData *)data
                           named:(NSString *)name
{
    IRISLogInfo(@"%@: Incoming file transfer did succeed.", THIS_FILE);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *fullPath = [[paths lastObject] stringByAppendingPathComponent:name];
    [data writeToFile:fullPath options:0 error:nil];
    
    //[self.xmppDelegate FilePath:fullPath];
    //[self.signalingDelegate xmppWorker:sender didReceiveFileWithPath:fullPath];
    
    /*UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                    message:@"File was received successfully."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];*/
    
    IRISLogInfo(@"%@: Data was written to the path: %@", THIS_FILE, fullPath);
}

@end
