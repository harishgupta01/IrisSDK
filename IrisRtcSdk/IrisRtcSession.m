//
//  IrisRtcSession.m
//  IrisRtcSdk
//
//  Created by Girish on 05/05/17.
//  Copyright © 2016 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IrisRtcSession.h"
#import "IrisRtcUtils.h"
#import "WebRTCError.h"
#import "IrisRtcConnection.h"
#import "XMPPWorker.h"
#import "IrisLogging.h"

NSString* const Session     = @"IrisRtcSession";

@interface IrisRtcSession()

@property(nonatomic) IrisRtcSdkStreamType streamType;
@property(nonatomic) IrisRtcSdkStreamQuality streamQuality;

@end

@interface IrisRtcJingleSession()

-(id)initWithSessionType:(IrisRtcSessionType)sessionType;
-(void)createSessionWithRoomId:(NSString*)roomId notificationData:(NSString*)notificationData stream:(IrisRtcStream*)stream delegate:(id)delegate;
-(void)sendChatMessage:(IrisChatMessage*)message;
-(void)joinSession:(IrisRootEventInfo*)rootEventInfo stream:(IrisRtcStream*)stream  delegate:(id)delegate;
-(void)joinSession:(NSString*)roomId delegate:(id)delegate;
- (void)preferCodec:(BOOL)value;
- (void) setVideoBridgeEnable: (bool) flag;
- (void) setStatsWS: (bool) flag;
- (void) setAnonymousRoomflag:(BOOL)useAnonymousRoom;
- (void) setStatsCollectorInterval:(NSInteger)interval;
- (void) setMaximumStream: (int) streamcount;
- (void) setSessionType:(IrisRtcSessionType)type;
-(id)creatSession;
-(void)joinSession;
-(void)muteRemoteVideo:(NSString*)participantId;
-(void)unmuteRemoteVideo:(NSString*)participantId;
-(void) setPreferredVideoCodecType:(IrisRtcSdkVideoCodecType)type;
-(void) setPreferredAudioCodecType:(IrisRtcSdkAudioCodecType)type;

-(void)close;

@end

@implementation IrisRtcSession

- (id)init
{
    //Generating random target  id.
    
    self = [super initWithSessionType:kSessionTypeChat];
    
    return self;
}

- (id)initWithTargetId:(NSString*)targetId serverUrl:(NSString *)serverUrl stream:(IrisRtcStream *)stream delegate:(id)delegate
{
    return self;
}

-(BOOL)createWithRoomName:(NSString* )roomName sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id<IrisRtcSessionDelegate>)delegate error:(NSError**)outError{
    
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:Session code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        return NO;
    }
    
    if(roomName == nil || ([roomName length] ==0))
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Room name is empty" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:Session code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
    }
    
    if(_isVideoBridgeEnable){
        [super setVideoBridgeEnable:true];
    }
    else
    {
        [super setVideoBridgeEnable:false];
    }
    
    if(sessionConfig.maxStreamCount){
        [super setMaximumStream:sessionConfig.maxStreamCount];
    }
    
    [super setAnonymousRoomflag:true];    
   
    [super createSessionWithRoomId:roomName notificationData:nil stream:nil delegate:delegate];
    
    return YES;
    
}

-(BOOL)createWithRoomId:(NSString* )roomId  delegate:(id<IrisRtcSessionDelegate>)delegate error:(NSError**)outError
{
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:Session code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        return NO;
    }
    
    if(roomId == nil || ([roomId length] ==0))
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Room Id is empty" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:Session code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
    }
    
    if(_isVideoBridgeEnable){
        [super setVideoBridgeEnable:true];
    }
    else
    {
        [super setVideoBridgeEnable:false];
    }
    
    [super createSessionWithRoomId:roomId notificationData:nil stream:nil delegate:delegate];
    return YES;
}

-(BOOL)createWithRoomId:(NSString* )roomId sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id<IrisRtcSessionDelegate>)delegate error:(NSError**)outError{
    
    IRISLogInfo(@"IrisRtcSession::createWithRoomId");
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        if(outError!= nil)
        *outError = [NSError errorWithDomain:Session code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        return NO;
    }
    
    if(roomId == nil || ([roomId length] ==0))
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Room Id is empty" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        if(outError!= nil)
        *outError = [NSError errorWithDomain:Session code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
    }
    
    if(_isVideoBridgeEnable){
        [super setVideoBridgeEnable:true];
    }
    else
    {
        [super setVideoBridgeEnable:false];
    }
    
    
    if(sessionConfig.statsCollectorInterval){
        [super setStatsCollectorInterval:sessionConfig.statsCollectorInterval];
    }
    
    if(sessionConfig.maxStreamCount){
        [super setMaximumStream:sessionConfig.maxStreamCount];
    }
   
    
    [super createSessionWithRoomId:roomId notificationData:nil stream:nil delegate:delegate];
    return YES;
}


-(BOOL)createWithRoomId:(NSString* )roomId notificationData:(NSString*)notificationData stream:(IrisRtcStream*)stream  sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id<IrisRtcSessionDelegate>)delegate error:(NSError**)outError
{
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:Session code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        return NO;
    }
    
    if(roomId == nil || ([roomId length] ==0))
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Room Id is empty" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:Session code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
    }
    
    if(sessionConfig.statsCollectorInterval){
        [super setStatsCollectorInterval:sessionConfig.statsCollectorInterval];
    }
    
    if(sessionConfig.maxStreamCount){
        [super setMaximumStream:sessionConfig.maxStreamCount];
    }
    
    
    if(_isVideoBridgeEnable){
        [super setVideoBridgeEnable:true];
    }
    else
    {
        [super setVideoBridgeEnable:false];
    }
    
    [super createSessionWithRoomId:roomId notificationData:notificationData stream:stream delegate:delegate];
    
    return YES;
}

-(BOOL)joinWithSessionId:(NSString*)sessionId delegate:(id<IrisRtcSessionDelegate>)delegate error:(NSError **)outError
{
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:Session code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        return NO;
    }
    
    if(sessionId == nil)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Session Id is null" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:Session code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
    }
    if(_isVideoBridgeEnable){
        [super setVideoBridgeEnable:true];
    }
    else
    {
        [super setVideoBridgeEnable:false];
    }
    
    [super joinSession:sessionId delegate:delegate];
    
    return YES;
}


-(BOOL)joinWithSessionId:(NSString*)sessionId roomToken:(NSString*)roomToken roomTokenExpiryTime:(NSInteger)roomTokenExpiry rtcServer:(NSString*)rtcServer delegate:(id<IrisRtcSessionDelegate>)delegate error:(NSError* _Nullable *)outError
{
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:Session code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        return NO;
    }
    
    if(sessionId == nil)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Session Id is null" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:Session code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
    }
    
    if(_isVideoBridgeEnable){
        [super setVideoBridgeEnable:true];
    }
    else
    {
        [super setVideoBridgeEnable:false];
    }

    //[self setSessionType:kSessionTypeVideoUpgrade];
    IRISLogInfo(@"joinWithSessionId roomToken = %@",roomToken);
    IRISLogInfo(@"joinWithSessionId roomTokenExpiry = %ld",(long)roomTokenExpiry);
    
    IrisRootEventInfo* rootEventInfo = [[IrisRootEventInfo alloc]init];
    
    [rootEventInfo setRtcServer:rtcServer];
    [rootEventInfo setRoomId:sessionId];
    
    if([roomToken length] == 0){
        [rootEventInfo setRoomToken:@""];
        [rootEventInfo setRoomExpiryTime:0];
    }
    else{
        [rootEventInfo setRoomToken:roomToken];
        [rootEventInfo setRoomExpiryTime:[NSString stringWithFormat:@"%li", (long)roomTokenExpiry]];
    }
    
    [super joinSession:rootEventInfo stream:nil delegate:delegate];
    
    return YES;
}

-(BOOL)joinWithSessionId:(NSString*)sessionId roomToken:(NSString*)roomToken roomTokenExpiryTime:(NSInteger)roomTokenExpiry stream:(IrisRtcStream*)stream rtcServer:(NSString*)rtcServer sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id)delegate error:(NSError* _Nullable *)outError
{
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:Session code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        return NO;
    }
    
    if(_isVideoBridgeEnable){
        [super setVideoBridgeEnable:true];
    }
    else
    {
        [super setVideoBridgeEnable:false];
    }
    
    
    if(sessionConfig.statsCollectorInterval){
        [super setStatsCollectorInterval:sessionConfig.statsCollectorInterval];
    }
    
    [self setSessionType:kSessionTypeVideoUpgrade];
    IRISLogInfo(@"joinWithSessionId roomToken>> = %@",roomToken);
    IRISLogInfo(@"joinWithSessionId roomTokenExpiry>> = %ld",(long)roomTokenExpiry);
    
    IrisRootEventInfo* rootEventInfo = [[IrisRootEventInfo alloc]init];
    
    [rootEventInfo setRtcServer:rtcServer];
    [rootEventInfo setRoomId:sessionId];
    
    if([roomToken length] == 0){
        [rootEventInfo setRoomToken:@""];
        [rootEventInfo setRoomExpiryTime:0];
    }
    else{
        [rootEventInfo setRoomToken:roomToken];
        [rootEventInfo setRoomExpiryTime:[NSString stringWithFormat:@"%li", (long)roomTokenExpiry]];
    }

    if(sessionId == nil)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Session Id is null" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:Session code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
    }
    else{
        [super joinSession:rootEventInfo stream:stream delegate:delegate];
    }
    
    return YES;
}

-(void)muteVideo:(NSString*)participantId
{
     IRISLogInfo(@"IrisRtcSession::muteRemoteVideo = %@",participantId);
    [super muteRemoteVideo:participantId];
}

-(void)unmuteVideo:(NSString*)participantId
{
    [super unmuteRemoteVideo:participantId];
}

-(void)close
{
    [super close];
}


-(void) setPreferredVideoCodecType:(IrisRtcSdkVideoCodecType)type
{
    [super setPreferredVideoCodecType:type];
}

-(void) setPreferredAudioCodecType:(IrisRtcSdkAudioCodecType)type
{
    [super setPreferredAudioCodecType:type];
}

-(BOOL)sendChatMessage:(IrisChatMessage*)message error:(NSError**)outError
{
    if ([[message data] length] == 0)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Message body is null or empty" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:Session code:ERR_INCORRECT_PARAMS userInfo:details];
        
        return NO;
        
    }
    
    [super sendChatMessage:message];
    return YES;

}


@end

