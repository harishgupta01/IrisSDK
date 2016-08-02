//
//  XMPPWorker.h
//  AppRTCDemo
//
//  Created by zhang zhiyu on 14-2-25.
//  Copyright (c) 2014年 YK-Unit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "XMPPFramework.h"
#import "XMPPRoom.h"
#import "XMPPJingle.h"
#import "XMPPOutgoingFileTransfer.h"
#import "XMPPIncomingFileTransfer.h"
#import "WebRTCError.h"

@protocol XMPPWorkerSignalingDelegate;

@protocol XMPPFileTransferDelegate <NSObject>
- (void) onReady:(NSArray*) alias;
- (void) onError:(NSString*) error;
- (void) onDisconnect:(NSString*) error;

@end


@interface XMPPWorker : NSObject
<XMPPStreamDelegate,XMPPRosterDelegate,XMPPOutgoingFileTransferDelegate,XMPPIncomingFileTransferDelegate>
{
    NSString *hostName;
    UInt16 hostPort;
    BOOL allowSelfSignedCertificates;
	BOOL allowSSLHostNameMismatch;
    
    NSString *userName;
    NSString *userPwd;
    
    BOOL isXmppConnected;
    BOOL isEngineRunning;
    
    __weak id<XMPPWorkerSignalingDelegate> signalingDelegate;
    __weak id<XMPPFileTransferDelegate> xmppDelegate;
    
    XMPPStream *xmppStream;
	XMPPReconnect *xmppReconnect;
    XMPPRoster *xmppRoster;
	XMPPRosterCoreDataStorage *xmppRosterStorage;
    XMPPvCardCoreDataStorage *xmppvCardStorage;
	XMPPvCardTempModule *xmppvCardTempModule;
	XMPPvCardAvatarModule *xmppvCardAvatarModule;
	XMPPCapabilities *xmppCapabilities;
	XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
    
    BOOL customCertEvaluation;
    
    
    NSFetchedResultsController *fetchedResultsController_roster;
    NSString *currentRoom;
    NSString *password;
    
    NSString *focusUserjid;
    NSString *room;
    NSXMLElement *elemPres;
    NSString *jireconRid;
}
@property (nonatomic,copy) NSString *hostName;
//@property (nonatomic,copy) NSString *actualHostName;
@property (nonatomic,assign) UInt16 hostPort;
@property (nonatomic,assign) BOOL allowSelfSignedCertificates;
@property (nonatomic,assign) BOOL allowSSLHostNameMismatch;
@property (nonatomic,copy) NSString *userName;
@property (nonatomic,copy) NSString *userPwd;
@property (nonatomic,assign) BOOL isXmppConnected;
@property (nonatomic,assign) BOOL isEngineRunning;
@property (nonatomic,weak) id<XMPPWorkerSignalingDelegate> signalingDelegate;
@property (nonatomic,weak) id<XMPPFileTransferDelegate> xmppDelegate;
@property(nonatomic) BOOL isVideoBridgeEnable;

@property (nonatomic,copy) NSString *mucId;
@property (nonatomic,copy) NSString *timestamp;
@property (nonatomic,copy) NSString *token;
@property (nonatomic,copy) NSString *routingId;
@property (nonatomic,copy) NSString *traceId;
@property (nonatomic,copy) NSString *event;
@property (nonatomic,copy) NSString *cnodeId;
@property (nonatomic,copy) NSString *nodeId;
@property (nonatomic,copy) NSString *unodeId;
@property (nonatomic,copy) NSString *maxParticipants;
@property (nonatomic) BOOL IsXMPPRoomCreater;
@property (nonatomic, strong, readonly) XMPPStream *xmppStream;
@property (nonatomic, strong, readonly) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong, readonly) XMPPRoster *xmppRoster;
@property (nonatomic, strong, readonly) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, strong, readonly) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong, readonly) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong, readonly) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController_roster;

@property (nonatomic,copy) NSString *resourceId;


+ (XMPPWorker *)sharedInstance;

/*
best to run it IN THIS ORDER
startEngine ➝ [connect ⇄ disconnect] ➝ stopEngine
 */
- (void)startEngine;
- (void)setupStream;
- (void)stopEngine;
- (BOOL)connect;
- (void)disconnect;
- (void)setXMPPDelegate:del;
- (void)joinRoom: (NSString *)roomName appDelegate:(id<XMPPRoomDelegate>)appDelegate;
- (void)leaveRoom;
- (void)activateJingle: (id<XMPPJingleDelegate>)appDelegate;
- (void)deactivateJingle;
- (void)allocateConferenceFocus:roomName;

- (void)sendSignalingMessage:(NSString *)message toUser:(NSString *)jidStr;
- (void)sendJingleMessage:(NSString*)type data:(NSDictionary*)data target:(XMPPJID *)target;
- (void)sendVideoInfo:(NSString*)type data:(NSDictionary*)data target:(XMPPJID *)target;
- (void)sendPresenceAlive;
- (void)sendMediaPresence:(NSDictionary*)msg target:(XMPPJID *)target;
- (void)dial:(NSString*)toNumber from:(NSString*)fromNumber target:(XMPPJID*)targetJid;
- (void)hangup;
- (void)merge;
- (void)hold:(NSString*)to from:(NSString*)from;
- (void)unHold:(NSString*)to from:(NSString*)from;
- (NSString*)targetPhoneNumber:(NSString*)to;
- (void)share:(NSData*)data;
- (void)record:(NSString*)state;

//Recording
- (XMPPIQ*)setRecordingJirecon:(NSString*)state tok:(NSString*)token target:(NSString*)target;
- (XMPPIQ*)setRecordingColibri:(NSString*)state tok:(NSString*)token target:(NSString*)target;


@end


@protocol XMPPWorkerSignalingDelegate <NSObject>
@optional
// Called when receive a signaling message.
- (void)xmppWorker:(XMPPWorker *)sender didReceiveSignalingMessage:(XMPPMessage *)message;
- (void)xmppWorker:(XMPPWorker *)sender didReceiveSessionInitiate:(NSString *)to  sid:(NSString*)sid;
- (void)xmppWorker:(XMPPWorker *)sender didReceiveSetRemoteDescription:(NSXMLElement*)jingle type:(NSString*)type;
- (void)xmppWorker:(XMPPWorker *)sender didReceiveAddIceCandidates:(NSXMLElement*)jingleContent;
- (void)xmppWorker:(XMPPWorker *)sender didJoinRoom:(NSString*)roomName;

//TODO: Need to correct the delegate flow
// as signaling delegate should be implemented by Stack

- (void) FilePath:(NSString*)filePath;
- (void)xmppWorker:(XMPPIncomingFileTransfer *)sender didReceiveFileWithPath:(NSString*)filePath;
- (void)xmppWorker:(XMPPIncomingFileTransfer *)sender didFailWithError:(NSError*)error;
- (void)xmppError:(NSString *)error errorCode:(NSInteger)code;
- (void)onXmppServerConnected;

@end
