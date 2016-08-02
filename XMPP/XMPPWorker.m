//
//  XMPPWorker.m
//  AppRTCDemo
//
//  Created by zhang zhiyu on 14-2-25.
//  Copyright (c) 2014年 YK-Unit. All rights reserved.
//

#import "XMPPWorker.h"
#import "XMPPMessage+Signaling.h"

#import "GCDAsyncSocket.h"
#import "XMPP.h"
#import "XMPPLogging.h"
#import "XMPPReconnect.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPvCardAvatarModule.h"
#import "XMPPvCardCoreDataStorage.h"

// Manish
#import "XMPPRoom.h"
#import "XMPPRoomHybridStorage.h"
#import "XMPPJingle.h"

//Vamsi
#import "XMPPRayo.h"

//Jahnavi
#import "XMPPOutgoingFileTransfer.h"
#import "XMPPIncomingFileTransfer.h"

#import "DDLog.h"
#import "DDTTYLogger.h"

#import <CFNetwork/CFNetwork.h>

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

@interface XMPPWorker()
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

@property (nonatomic, strong) NSString* participantJID;
@property (nonatomic, strong) NSString* moderatorJID;
@property (nonatomic, strong) NSString* senderJID;

@property (nonatomic, strong) NSTimer *_presenceAliveTimer;


@end

@implementation XMPPWorker
@synthesize hostName,hostPort,mucId,timestamp,token,routingId,traceId,IsXMPPRoomCreater;//actualHostName;
@synthesize event,nodeId,cnodeId,unodeId,maxParticipants;
@synthesize allowSelfSignedCertificates,allowSSLHostNameMismatch;
@synthesize userName,userPwd;
@synthesize isXmppConnected,isEngineRunning;
@synthesize signalingDelegate;
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
        hostName = NULL;
        hostPort = 0;
	timestamp = NULL;
        token = NULL;
        mucId = NULL;
        routingId = NULL;        // You may need to alter these settings depending on the server you're connecting to
        traceId = NULL;
        event = NULL;
        nodeId = NULL;
        cnodeId = NULL;
        unodeId = NULL;
        maxParticipants = NULL;
        //actualHostName = NULL;
        allowSelfSignedCertificates = NO;
        allowSSLHostNameMismatch = NO;
        
        isXmppConnected = NO;
        isEngineRunning = NO;        
        isVideoBridgeEnable = true;
        IsXMPPRoomCreater = false;
    }
    return self;
}

- (void)dealloc
{
    if (isEngineRunning) {
        [self stopEngine];
    }
    
    if (fetchedResultsController_roster) {
        fetchedResultsController_roster.delegate = Nil;
    }
    
    self.signalingDelegate = Nil;
}

#pragma mark - private methods
- (void)setupStream
{
	NSAssert(xmppStream == nil, @"Method setupStream invoked multiple times");
	
	// Setup xmpp stream
	//
	// The XMPPStream is the base class for all activity.
	// Everything else plugs into the xmppStream, such as modules/extensions and delegates.
    
	xmppStream = [[XMPPStream alloc] init];
	
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
    xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:xmppCapabilitiesStorage];
    
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
    NSString *domain = hostName;
    
    //Google set their presence priority to 24, so we do the same to be compatible.
    
    if([domain isEqualToString:@"gmail.com"]
       || [domain isEqualToString:@"gtalk.com"]
       || [domain isEqualToString:@"talk.google.com"])
    {
        NSXMLElement *priority = [NSXMLElement elementWithName:@"priority" stringValue:@"24"];
        [presence addChild:priority];
    }
	
	[[self xmppStream] sendElement:presence];
}

// Manish: Method to join a room
- (void)joinRoom: (NSString *)roomName appDelegate:(id<XMPPRoomDelegate>)appDelegate
{
    NSLog(@"XMPP Worker Joining room %@", roomName );

    self.xmppRoomStorage = [XMPPRoomHybridStorage sharedInstance];
    
    self.xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:self.xmppRoomStorage jid:[XMPPJID jidWithString:roomName]];
    
    [self.xmppRoom addDelegate:appDelegate delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [self.xmppRoom activate:self.xmppStream];
    
    //Fix for multiNick
    NSString *Jid= [NSString stringWithFormat:@"%@",xmppStream.myJID];
    [self.xmppRoom joinRoomUsingNickname:Jid history:nil];
    //[self.xmppRoom joinRoomUsingNickname:[xmppStream.myJID user] history:nil];

}

- (void)leaveRoom
{
    [self.xmppRoom leaveRoom];
}

// Manish: Start doing jingle
- (void)activateJingle: (id<XMPPJingleDelegate>)appDelegate
{
    NSLog(@"XMPP Worker Activating Jingle " );
    self.xmppJingle = [[XMPPJingle alloc] init];
    [self.xmppJingle SetDelegate:appDelegate];
    [self.xmppJingle activate:self.xmppStream];
    [self.xmppJingle setCnodeId:cnodeId];
    [self.xmppJingle setEvent:event];
    [self.xmppJingle setTraceId:traceId];
    [self.xmppJingle setNodeId:nodeId];
    [self.xmppJingle setUnodeId:unodeId];
}

// Manish: Stop doing jingle
- (void)deactivateJingle
{
    NSLog(@"XMPP Worker Deactivating Jingle " );
    [self.xmppJingle SetDelegate:nil];
    [self.xmppJingle deactivate];
    self.xmppJingle = nil;
}

- (void)sendJingleMessage:(NSString*)type data:(NSDictionary*)data target:(XMPPJID *)target
{
    if ([type hasPrefix:@"session"])
    {
        [self.xmppJingle sendSessionMsg:type data:data target:target];
    }
    else if ([type hasPrefix:@"transport"])
    {
        [self.xmppJingle sendTransportMsg:type data:data target:target];
        
    }
    else if ([type hasPrefix:@"source"])
    {
    }
}

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

- (void)sendVideoInfo:(NSString*)type data:(NSDictionary*)data target:(XMPPJID *)target
{
    elemPres = [self.xmppJingle getVideoContent:type data:data target:target];
    [self sendPresenceWithVideoInfo];
    
    [NSTimer scheduledTimerWithTimeInterval:10
                                     target:self
                                   selector:@selector(sendPresenceWithVideoInfo)
                                   userInfo:nil
                                    repeats:YES
     ];
}

- (void)sendPresenceAlive
{
    __presenceAliveTimer = [NSTimer scheduledTimerWithTimeInterval:30
                                     target:self
                                   selector:@selector(sendAlive)
                                   userInfo:nil
                                    repeats:YES
     ];
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
        [self.signalingDelegate xmppError:error.description errorCode:ERR_XMPP_CONNECTION_FAILED];
        
		return NO;
	}
    return YES;
}

- (void)disconnect
{
    if(__presenceAliveTimer != nil)
        [__presenceAliveTimer invalidate];
    [self goOffline];
	[xmppStream disconnect];
}

- (void)sendSignalingMessage:(NSString *)message toUser:(NSString *)jidStr
{
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:message];
    
    XMPPJID *toJID = [XMPPJID jidWithString:jidStr];
    
    XMPPMessage *xmppMessage = [XMPPMessage signalingMessageTo:toJID elementID:Nil child:body];
    [xmppStream sendElement:xmppMessage];
}

- (void)setHostName:(NSString *)name
{
    if (name) {
        hostName = Nil;
        hostName = [name copy];

        if (xmppStream) {
            [xmppStream setHostName:name];
        }
    }
}

/*-(void)setActualHostName:(NSString *)name
{
    if (name) {
        actualHostName = Nil;
        actualHostName = [name copy];
        
        if (xmppStream) {
            [xmppStream setActualHostName:name];
        }
    }
}*/

- (void)setHostPort:(UInt16)port
{
    if (port) {
        hostPort = port;
        if (hostPort) {
            [xmppStream setHostPort:port];
        }
    }
}

- (void)setMucId:(NSString *)Id
{
    if (Id) {
        mucId = Nil;
        mucId = [Id copy];
        
        if (xmppStream) {
            [xmppStream setMucId:mucId];
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
- (void)setTraceId:(NSString *)Id
{
    if (Id) {
        traceId = Nil;
        traceId = [Id copy];
        
        if (xmppStream) {
            [xmppStream setTraceId:traceId];
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
        NSString *expectedCertName = hostName;
        
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
    NSArray* alias = [[NSArray alloc] init];

    [self.xmppDelegate onReady:alias];

}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self.xmppDelegate onError:@"XMPP Server didNotAuthenticate"];

}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *
                                                      
                                                      )iq
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	// muc changes
    NSLog(@"xmppStream : didReceiveIQ %@", iq.description);
    
    if (resourceId == nil)
    {
        NSXMLElement *showStatus = [iq elementForName:@"ref"];
        NSString *uri= [showStatus attributeStringValueForName:@"uri"];
        resourceId = [uri substringFromIndex:5];
 
    }

    
    if ([iq isResultIQ])
    {
       NSXMLElement *elem = [iq elementForName:@"conference" xmlns:@"http://jitsi.org/protocol/focus"];
       
       if (elem != nil)
       {
          NSString *ready = [elem attributeStringValueForName:@"ready"];
           
           if ([ready isEqual:@"true"])
           {
               //parse config options
               focusUserjid = [elem attributeStringValueForName:@"focusjid"];
               
               //TODO: check external auth enabled
               //TODO: check sip gateway enabled
               
               room = [elem attributeStringValueForName:@"room"];
               
               // New DNS related changes               
               room = [room stringByReplacingOccurrencesOfString:@"xmpp" withString:@"conference"];
               
               [self.signalingDelegate xmppWorker:self didJoinRoom:room];
               
               XMPPIQ *iqResponse = [XMPPIQ iqWithType:@"result" to:[iq from] elementID:[iq elementID]];
               [xmppStream sendElement:iqResponse];
               
               return YES;
           }
       }
        
        NSXMLElement *jireconElem = [iq elementForName:@"recording" xmlns:@"http://jitsi.org/protocol/jirecon"];
        
        if (jireconElem != nil)
        {
            jireconRid = [jireconElem attributeStringValueForName:@"rid"];
            
            XMPPIQ *iqResponse = [XMPPIQ iqWithType:@"result" to:[iq from] elementID:[iq elementID]];
            [xmppStream sendElement:iqResponse];
            
            return YES;
        }

        NSString *error = [iq attributeStringValueForName:@"type"];
        
        if([error isEqualToString:@"error"])
        {
            NSString *errorDesc = [[iq elementForName:@"error"]stringValue];
            NSString *errMsg;
            
            if([errorDesc containsString:@"item-not-found"])
            {
                errMsg = @"The JID of the specified target entity does not exist";
                [self.signalingDelegate xmppError:errMsg errorCode:ERR_XMPP_ERROR];
            }
            else if ([errorDesc containsString:@"not-allowed"])
            {
                errMsg = @"IQ procession not allowed";
                [self.signalingDelegate xmppError:errMsg errorCode:ERR_XMPP_ERROR];
            }
            else if ([errorDesc containsString:@"service-unavailable"])
            {
                errMsg = @"The target entity does not support this protocol";
                [self.signalingDelegate xmppError:errMsg errorCode:ERR_XMPP_ERROR];
            }
            else
            {
                NSLog(@"Error in IQ message");
                [self.signalingDelegate xmppError:errorDesc errorCode:ERR_XMPP_ERROR];
            }

        }
            
    
    }

    
	return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[message from] xmppStream:xmppStream managedObjectContext:[self managedObjectContext_roster]];
    NSString *body = [[message elementForName:@"body"] stringValue];
    NSString *jidStr = [user jidStr];
    DDLogVerbose(@"ReceiveMessage:\n%@\nfrom:%@",body,jidStr);
    
    if ([message isSignalingMessageWithBody]) {
        /*if (self.signalingDelegate && [self.signalingDelegate respondsToSelector:@selector(xmppWorker:didReceiveSignalingMessage:)]) {*/
            [self.signalingDelegate xmppWorker:self didReceiveSignalingMessage:message];
        //}
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
    
    NSString *myJID = [[xmppStream myJID] full];
    NSLog(@"rtcTargetJid:%@", myJID);
    

    
    NSXMLElement *x = [presence elementForName:@"x"];
    NSXMLElement *item = [x elementForName:@"item"];
    
    NSString *targetJid = [[item attributeForName:@"jid"]stringValue];
    NSString *role = [[item attributeForName:@"role"]stringValue];
    
    if ([role isEqualToString:@"participant"]) {
        
        self.participantJID = targetJid;
        
    }
    else if ([role isEqualToString:@"moderator"]){
        
        self.moderatorJID = targetJid;
    }
    
    self.senderJID = [[sender myJID] full];

}

- (void)sendAlive
{
    //XMPPPresence *presence = [XMPPPresence presence];//[XMPPPresence presenceWithType:nil to:toJID];
    XMPPPresence *presence = [XMPPPresence presenceWithType:nil to:xmppStream.myJID];
    [[self xmppStream] sendElement:presence];
}

- (void)sendPresenceWithVideoInfo
{
    XMPPPresence *presence = [XMPPPresence presenceWithType:nil to:[XMPPJID jidWithString:room]];
    [presence addChild:[elemPres copy]];
    
    [[self xmppStream] sendElement:presence];
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSXMLElement *errorElement = (NSXMLElement *)error;
    NSLog(@"xmppStream :didReceiveError %@", [errorElement description]);

    [self.signalingDelegate xmppError:[errorElement description] errorCode:ERR_XMPP_ERROR];
}

- (void)xmppStream:(XMPPStream *)sender onError:(NSError *)error
{
   [self.signalingDelegate xmppError:[error localizedDescription] errorCode:ERR_XMPP_CONNECTION_FAILED];
}

- (void) onXmppServerConnected
{
    [self.signalingDelegate onXmppServerConnected];
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (!isXmppConnected)
	{
		//EASYLogError(@"Unable to connect to server. Check xmppStream.hostName");
	}
    isXmppConnected = NO;
    
    [self.xmppDelegate onDisconnect:[error localizedDescription]];
}

#pragma mark - XMPPRosterDelegate
- (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSLog(@"xmppRoster :sender:didReceiveBuddyRequest");
	
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

// Jicofo/Videobridge related
- (void)allocateConferenceFocus:roomName
{
    // Set focue user jid
    focusUserjid = @"";
    
    // Create conference IQ
    XMPPIQ *iq = [self createConferenceIQ:roomName];
    
    NSXMLElement *miscData = [NSXMLElement elementWithName:@"data" xmlns:@"urn:xmpp:comcast:info"];
    [miscData addAttributeWithName:@"event" stringValue:event];
    [miscData addAttributeWithName:@"traceid" stringValue:traceId];
    [miscData addAttributeWithName:@"nodeid" stringValue:nodeId];
    [miscData addAttributeWithName:@"cnodeid" stringValue:cnodeId];
    [miscData addAttributeWithName:@"unodeid" stringValue:unodeId];
    [miscData addAttributeWithName:@"host" stringValue:hostName];
    [miscData addAttributeWithName:@"maxparticipants" stringValue:maxParticipants];
    if(IsXMPPRoomCreater)
        [miscData addAttributeWithName:@"initiator" stringValue:@"true"];
    [iq addChild:miscData];
    
    // send IQ
    [xmppStream sendElement:iq];
}

- (XMPPIQ*) createConferenceIQ:roomName
{
    XMPPIQ *xmpp;
    
    NSXMLElement *confElement = [NSXMLElement elementWithName:@"conference"];
    [confElement addAttributeWithName:@"xmlns" stringValue:@"http://jitsi.org/protocol/focus"];
    
    // New DNS related changes
    //NSString *fullRoomName = [NSString stringWithFormat:@"%@.%@", roomName, [xmppStream.myJID domain]];
    //NSString *fullRoomName = [NSString stringWithFormat:@"%@%@", roomName, [xmppStream.myJID domain]];
    NSString *fullRoomName = [NSString stringWithFormat:@"%@%@", roomName, hostName];
    
    fullRoomName = [fullRoomName stringByReplacingOccurrencesOfString:@"xmpp" withString:@"conference"];
    
    [confElement addAttributeWithName:@"room" stringValue:fullRoomName];
    
    NSXMLElement *bridgeElement = [NSXMLElement elementWithName:@"property"];
    [bridgeElement addAttributeWithName:@"name" stringValue:@"bridge"];
    
    NSMutableString *fullvideobridge = [[NSMutableString alloc]init];
    [fullvideobridge appendString:@"jitsi-videobridge."];
    //[fullvideobridge appendString:[xmppStream.myJID domain]];
    [fullvideobridge appendString:hostName];
    [bridgeElement addAttributeWithName:@"value" stringValue:fullvideobridge];
    //[bridgeElement addAttributeWithName:@"value" stringValue:@"jitsi-videobridge..xrtc.me"];
    //[bridgeElement addAttributeWithName:@"value" stringValue:@"jitsi-videobridge..xrtc.me"];
    
    [confElement addChild:bridgeElement];
    
    NSXMLElement *ccElement = [NSXMLElement elementWithName:@"property"];
    [ccElement addAttributeWithName:@"name" stringValue:@"call_control"];
    //NSString *dom = [xmppStream.myJID domain];
    NSString *dom = hostName;
    NSString *cc = [dom stringByReplacingOccurrencesOfString:@"xmpp" withString:@"callcontrol"];
    [ccElement addAttributeWithName:@"value" stringValue:cc];
    [confElement addChild:ccElement];
    
    NSXMLElement *chanElement = [NSXMLElement elementWithName:@"property"];
    [chanElement addAttributeWithName:@"name" stringValue:@"channelLastN"];
    [chanElement addAttributeWithName:@"value" stringValue:@"-1"];
    
    [confElement addChild:chanElement];
    
    NSXMLElement *adapElement = [NSXMLElement elementWithName:@"property"];
    [adapElement addAttributeWithName:@"name" stringValue:@"adaptiveLastN"];
    [adapElement addAttributeWithName:@"value" stringValue:@"false"];
    
    [confElement addChild:adapElement];
    
    NSXMLElement *simuElement = [NSXMLElement elementWithName:@"property"];
    [simuElement addAttributeWithName:@"name" stringValue:@"adaptiveSimulcast"];
    [simuElement addAttributeWithName:@"value" stringValue:@"false"];
    
    [confElement addChild:simuElement];
    
    NSXMLElement *osctpElement = [NSXMLElement elementWithName:@"property"];
    [osctpElement addAttributeWithName:@"name" stringValue:@"openSctp"];
    [osctpElement addAttributeWithName:@"value" stringValue:@"true"];
    
    [confElement addChild:osctpElement];
    
  //  NSXMLElement *firefoxElement = [NSXMLElement elementWithName:@"property"];
   // [firefoxElement addAttributeWithName:@"name" stringValue:@"enableFirefoxHacks"];
  //  [firefoxElement addAttributeWithName:@"value" stringValue:@"false"];
    NSXMLElement *firefoxElement = [NSXMLElement elementWithName:@"property"];
    [firefoxElement addAttributeWithName:@"name" stringValue:@"simulcastMode"];
    [firefoxElement addAttributeWithName:@"value" stringValue:@"rewriting"];
    
    [confElement addChild:firefoxElement];
    
    // New DNS related changes
    
    //NSMutableString *fullTargetJid = [[NSMutableString alloc]init];
    //[fullTargetJid appendString:@"focus."];
    //[fullTargetJid appendString:[xmppStream.myJID domain]];
    
    //NSString *fullTargetJid = [xmppStream.myJID domain];
    NSString *fullTargetJid = hostName;
    fullTargetJid = [fullTargetJid stringByReplacingOccurrencesOfString:@"xmpp" withString:@"focus"];
    
    XMPPJID *targetJid = [XMPPJID jidWithString:fullTargetJid];
    
    xmpp  = [[XMPPIQ alloc]initWithType:@"set" to:targetJid elementID:nil child:[confElement copy]];
    
    return xmpp;
    
}

//PSTN dialing

- (void) dial:(NSString*)to from:(NSString*)from target:(XMPPJID*)targetJid;
{
    //XMPPIQ *iq = [XMPPRayo dial:to from:from roomName:room roomPass:@"" target:[xmppStream.myJID domain]];
  
    //to = [self targetPhoneNumber:to];
    //from = @"+12674550136";
    XMPPIQ *iq = [XMPPRayo dial:to from:from roomName:room roomPass:@"" target:[targetJid full]];
    
    // send IQ
    [xmppStream sendElement:iq];
  
}

-(NSString*)targetPhoneNumber:(NSString*)to
{
    NSPredicate *digitCountPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"[0-9]{10}"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"(\\+1)[0-9]{10}"];
    
    if ([digitCountPredicate evaluateWithObject:to] == YES)
    {
        NSString* toTN = [NSString stringWithFormat:@"+1%@@tel.comcast.net",to];
        to = toTN;
    }
    else if ([predicate evaluateWithObject:to] == YES)
    {
        NSString* toTN = [NSString stringWithFormat:@"%@@tel.comcast.net",to];
        to = toTN;
    }
    
    return to;
}

- (void)hangup
{
    XMPPIQ *iq = [XMPPRayo hangup];
    
    // send IQ
    [xmppStream sendElement:iq];
}

-(void)merge
{
    XMPPIQ *iq = [XMPPRayo merge:resourceId];
    
    // send IQ
    [xmppStream sendElement:iq];
    
}

-(void)hold:(NSString *)to from:(NSString *)from
{
     NSString *myJID = [[xmppStream myJID] full];
    
    XMPPIQ *iq = [XMPPRayo hold:to from:myJID roomName:room roomPass:@"" target:resourceId];
    
    // send IQ
    [xmppStream sendElement:iq];
    
}

-(void)unHold:(NSString *)to from:(NSString *)from
{
    NSString *myJID = [[xmppStream myJID] full];

    XMPPIQ *iq = [XMPPRayo unHold:to from:myJID roomName:room roomPass:@"" target:resourceId];
    
    // send IQ
    [xmppStream sendElement:iq];
}

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
        [_fileTransfer addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        
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
        
        NSLog(@"Something was messed");
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
    NSString *focusmucjid = hostName;
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
    NSLog(@"Outgoing file transfer failed with error: %@", error);    
}

- (void)xmppOutgoingFileTransferDidSucceed:(XMPPOutgoingFileTransfer *)sender
{
    NSLog(@"File transfer successful.");
    
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
    NSLog(@"%@: Incoming file transfer failed with error: %@", THIS_FILE, error);
    [self.signalingDelegate xmppWorker:sender didFailWithError:error];
}

- (void)xmppIncomingFileTransfer:(XMPPIncomingFileTransfer *)sender
               didReceiveSIOffer:(XMPPIQ *)offer
{
    NSLog(@"%@: Incoming file transfer did receive SI offer. Accepting...", THIS_FILE);
    [sender acceptSIOffer:offer];
}

- (void)xmppIncomingFileTransfer:(XMPPIncomingFileTransfer *)sender
              didSucceedWithData:(NSData *)data
                           named:(NSString *)name
{
    NSLog(@"%@: Incoming file transfer did succeed.", THIS_FILE);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *fullPath = [[paths lastObject] stringByAppendingPathComponent:name];
    [data writeToFile:fullPath options:0 error:nil];
    
    //[self.xmppDelegate FilePath:fullPath];
    [self.signalingDelegate xmppWorker:sender didReceiveFileWithPath:fullPath];
    
    /*UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                    message:@"File was received successfully."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];*/
    
    NSLog(@"%@: Data was written to the path: %@", THIS_FILE, fullPath);
}

@end
