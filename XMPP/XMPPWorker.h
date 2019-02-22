//
//  XMPPWorker.h
//  AppRTCDemo
//
//  Created by zhang zhiyu on 14-2-25.
//  Copyright (c) 2014年 YK-Unit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@import XMPPFramework;
#import "IrisXMPPCapabilities.h"
#import "XMPPJingle.h"
#import "WebRTCError.h"
#import "IrisChatMessage.h"
#import "IrisDataElement.h"
#import "IrisXMPPStream.h"
@protocol XMPPWorkerSignalingDelegate;
@protocol XMPPWorkerWebSocketDelegate;

@protocol XMPPFileTransferDelegate <NSObject>
- (void) onReady:(NSArray*) alias;
- (void) onError:(NSString*) error;
- (void) onDisconnect:(NSString*) error;

@end


@interface XMPPWorker : NSObject
<IrisXMPPStreamDelegate,XMPPRosterDelegate,XMPPOutgoingFileTransferDelegate,XMPPIncomingFileTransferDelegate>
{
    
    UInt16 hostPort;
    BOOL allowSelfSignedCertificates;
	BOOL allowSSLHostNameMismatch;
    
    NSString *userName;
    NSString *userPwd;
    
    BOOL isXmppConnected;
    BOOL isEngineRunning;
    
    __weak id<XMPPWorkerSignalingDelegate> signalingDelegate;
    __weak id<XMPPWorkerWebSocketDelegate> webSocketDelegate;
    __weak id<XMPPFileTransferDelegate> xmppDelegate;
    
    IrisXMPPStream *xmppStream;
	XMPPReconnect *xmppReconnect;
    XMPPRoster *xmppRoster;
	XMPPRosterCoreDataStorage *xmppRosterStorage;
    XMPPvCardCoreDataStorage *xmppvCardStorage;
	XMPPvCardTempModule *xmppvCardTempModule;
	XMPPvCardAvatarModule *xmppvCardAvatarModule;
	IrisXMPPCapabilities *xmppCapabilities;
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


@property (nonatomic,copy) NSString *eventManagerUrl;
@property (nonatomic,copy) NSString *jwToken;

@property (nonatomic,copy) NSDictionary *turnServers;
@property (nonatomic,copy) NSString *actualHostName;
@property (nonatomic,assign) UInt16 hostPort;
@property (nonatomic,assign) BOOL allowSelfSignedCertificates;
@property (nonatomic,assign) BOOL allowSSLHostNameMismatch;
@property (nonatomic,copy) NSString *userName;
@property (nonatomic,copy) NSString *userPwd;
@property (nonatomic,assign) BOOL isXmppConnected;
@property (nonatomic,assign) BOOL isEngineRunning;
@property (nonatomic,weak) id<XMPPWorkerSignalingDelegate> signalingDelegate;
@property (nonatomic,weak) id<XMPPWorkerWebSocketDelegate> webSocketDelegate;
@property (nonatomic,weak) id<XMPPFileTransferDelegate> xmppDelegate;
@property(nonatomic) BOOL isVideoBridgeEnable;
@property(nonatomic) BOOL isRoomJoined;
@property (nonatomic, assign) NSTimeInterval pingPongTimeInterval;
@property (nonatomic,copy) NSString *timestamp;
@property (nonatomic,copy) NSString *token;
@property (nonatomic,copy) NSString *routingId;
@property (nonatomic,copy) NSString *event;
@property (nonatomic,copy) NSString *cnodeId;
@property (nonatomic,copy) NSString *nodeId;
@property (nonatomic,copy) NSString *unodeId;
@property (nonatomic,copy) NSString *maxParticipants;
@property (nonatomic) BOOL IsXMPPRoomCreater;
@property (nonatomic) int streamCount;
@property (nonatomic, strong, readonly) IrisXMPPStream *xmppStream;
@property (nonatomic, strong, readonly) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong, readonly) XMPPRoster *xmppRoster;
@property (nonatomic, strong, readonly) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, strong, readonly) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong, readonly) IrisXMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong, readonly) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController_roster;

@property (nonatomic,copy) NSString *resourceId;
@property (nonatomic,copy) NSMutableDictionary *activeSessions;
@property (nonatomic) BOOL isHitlessUpgrade;
@property (nonatomic,copy) NSString *sourceTelNum;
@property (nonatomic,copy) NSString *targetTelNum;
@property (nonatomic,copy) NSString *oldjid;
@property (nonatomic) BOOL isSocketReconnected;
@property (nonatomic, strong) XMPPJID *userJid;
@property (nonatomic) BOOL isAttemmptingReconnect;




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
- (void)disconnectWebSocket;
- (void)setXMPPDelegate:del;

- (void)sendSignalingMessage:(NSString *)message toUser:(NSString *)jidStr;
- (void)sendVideoInfo:(NSString*)type data:(NSDictionary*)data target:(XMPPJID *)target;
- (void)setPingTimeInterval:(NSTimeInterval)timeinterval;
- (void)setPingTimoutInterval:(NSTimeInterval)timeinterval;
- (void)sendMediaPresence:(NSDictionary*)msg target:(XMPPJID *)target;
- (void)share:(NSData*)data;
- (void)record:(NSString*)state;
-(void)sendUserProfilePresence:(NSString*)name avatarUrl:(NSString*)url;
-(void)stopAliveIQTimer;
- (void)startAliveIQTimer;
- (void)startPingPongTimer;
- (void)stopPingPongTimer;
-(BOOL)hasActiveAudioorVideoSession;

//Recording
- (XMPPIQ*)setRecordingJirecon:(NSString*)state tok:(NSString*)token target:(NSString*)target;
- (XMPPIQ*)setRecordingColibri:(NSString*)state tok:(NSString*)token target:(NSString*)target;
-(void)sendPrivateMessage:(NSString *)msg target:(XMPPJID *)target dataElement:(IrisDataElement*)dataElement;;
@end


@protocol XMPPWorkerSignalingDelegate <NSObject>
@optional
// Called when receive a signaling message.
- (void)xmppWorker:(XMPPWorker *)sender didReceiveSignalingMessage:(XMPPMessage *)message;
- (void)xmppWorker:(XMPPWorker *)sender didReceiveSessionInitiate:(NSString *)to  sid:(NSString*)sid;
- (void)xmppWorker:(XMPPWorker *)sender didReceiveSetRemoteDescription:(NSXMLElement*)jingle type:(NSString*)type;
- (void)xmppWorker:(XMPPWorker *)sender didReceiveAddIceCandidates:(NSXMLElement*)jingleContent;
- (void)xmppWorker:(XMPPWorker *)sender didJoinRoom:(NSString*)roomName;
- (void)xmppWorker:(XMPPWorker *)sender didParticipantUnavailable:(NSString*)roomName participantName:(NSString*)name;

//TODO: Need to correct the delegate flow
// as signaling delegate should be implemented by Stack

- (void) FilePath:(NSString*)filePath;
- (void)xmppWorker:(XMPPIncomingFileTransfer *)sender didReceiveFileWithPath:(NSString*)filePath;
- (void)xmppWorker:(XMPPIncomingFileTransfer *)sender didFailWithError:(NSError*)error;
- (void)xmppError:(NSString *)error errorCode:(NSInteger)code;
- (void)onXmppServerConnected;

@end

@protocol XMPPWorkerWebSocketDelegate <NSObject>

- (void)onXmppWebSocketConnected;
- (void)onXmppWebSocketAuthenticated;
- (void)onXmppWebSocketReconnect;
- (void)onXmppWebSocketError:(NSString *)error errorCode:(NSInteger)code;
- (void)onXmppWebSocketDisconnected:(NSString*) error;
- (void)onXmppWebSocketNotification:(NSDictionary*) data;
- (void)onXmppWebSocketPingPongFailure;

@end
