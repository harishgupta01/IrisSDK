//
//  IrisRtcVideoSession.m
//  IrisRtcSdk
//
//  Created by VinayakBhat on 04/10/16.
//  Copyright © 2016 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IrisRtcVideoSession.h"
#import "IrisRtcUtils.h"
#import "WebRTCError.h"
#import "IrisRtcConnection.h"
#import "XMPPWorker.h"
#import "IrisLogging.h"

NSString* const VideoSession     = @"IrisRtcVideoSession";

@interface IrisRtcVideoSession()

@property(nonatomic) IrisRtcSdkStreamType streamType;
@property(nonatomic) IrisRtcSdkStreamQuality streamQuality;

@end

@interface IrisRtcJingleSession()

-(id)initWithSessionType:(IrisRtcSessionType)sessionType;

-(void)createSessionWithRoomId:(NSString*)roomId notificationData:(NSString*)notificationData stream:(IrisRtcStream*)stream delegate:(id)delegate;
-(void)joinSession:(IrisRootEventInfo*)rootEventInfo stream:(IrisRtcStream*)stream  delegate:(id)delegate;
- (void)preferCodec:(BOOL)value;
- (void) setVideoBridgeEnable: (bool) flag;
- (void) setStatsWS: (bool) flag;
- (void) setMaximumStream: (int) streamcount;
- (void) setAnonymousRoomflag:(BOOL)useAnonymousRoom;
- (void) setStatsCollectorInterval:(NSInteger)interval;
-(id)creatSession;
-(void)joinSession;
-(void)muteRemoteVideo:(NSString*)participantId;
-(void)unmuteRemoteVideo:(NSString*)participantId;
-(void) setPreferredVideoCodecType:(IrisRtcSdkVideoCodecType)type;
-(void) setPreferredAudioCodecType:(IrisRtcSdkAudioCodecType)type;

-(void)close;

@end

@implementation IrisRtcVideoSession
    
- (id)init
{
    //Generating random target  id.
    
     self = [super initWithSessionType:kSessionTypeVideo];
    
    return self;
}

- (id)initWithTargetId:(NSString*)targetId serverUrl:(NSString *)serverUrl stream:(IrisRtcStream *)stream delegate:(id)delegate
{
    return self;
}

-(BOOL)createWithRoomId:(NSString* )roomId notificationData:(NSString*)notificationData delegate:(id<IrisRtcVideoSessionDelegate>)delegate error:(NSError**)outError
{
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:VideoSession code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        return NO;
    }

    if(roomId == nil || ([roomId length] ==0))
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Room Id is empty" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:VideoSession code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
    }

    if(_isVideoBridgeEnable){
        [super setVideoBridgeEnable:true];
    }
    else
    {
        [super setVideoBridgeEnable:false];
    }
    
    [super createSessionWithRoomId:roomId notificationData:notificationData stream:nil delegate:delegate];
    return YES;
}

-(BOOL)createWithRoomName:(NSString* )roomName sessionConfig:(IrisRtcSessionConfig *)sessionConfig stream:(IrisRtcStream*)stream delegate:(id<IrisRtcVideoSessionDelegate>)delegate error:(NSError**)outError{
    
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:VideoSession code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        return NO;
    }
    
    if(roomName == nil || ([roomName length] ==0))
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"roomName is empty" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:VideoSession code:ERR_INCORRECT_PARAMS userInfo:details];
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
   
    [super createSessionWithRoomId:roomName notificationData:nil stream:stream delegate:delegate];
    
    return YES;
    
}

-(BOOL)createWithRoomId:(NSString* )roomId notificationData:(NSString*)notificationData  sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id<IrisRtcVideoSessionDelegate>)delegate error:(NSError**)outError
{
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:VideoSession code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        return NO;
    }
    
    if(roomId == nil || ([roomId length] ==0))
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Room Id is empty" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:VideoSession code:ERR_INCORRECT_PARAMS userInfo:details];
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
    
    [super createSessionWithRoomId:roomId notificationData:notificationData stream:nil delegate:delegate];
    
    return YES;
}



-(BOOL)createWithRoomId:(NSString* )roomId notificationData:(NSString*)notificationData stream:(IrisRtcStream*)stream  sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id<IrisRtcVideoSessionDelegate>)delegate error:(NSError**)outError
{
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:VideoSession code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        return NO;
    }
    
    if(roomId == nil || ([roomId length] ==0))
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Room Id is empty" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:VideoSession code:ERR_INCORRECT_PARAMS userInfo:details];
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
    
    if(sessionConfig.statsCollectorInterval){
        [super setStatsCollectorInterval:sessionConfig.statsCollectorInterval];
    }
    
    [super createSessionWithRoomId:roomId notificationData:notificationData stream:stream delegate:delegate];

    return YES;
}

-(BOOL)createWithRoomId:(NSString* )roomId notificationData:(NSString*)notificationData  stream:(IrisRtcStream*)stream  delegate:(id<IrisRtcVideoSessionDelegate>)delegate error:(NSError**)outError
{
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:VideoSession code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        return NO;
    }
    
    if(roomId == nil || ([roomId length] ==0))
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Room Id is empty" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:VideoSession code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
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

-(BOOL)joinWithSessionId:(NSString*)sessionId roomToken:(NSString*)roomToken roomTokenExpiryTime:(NSInteger)roomTokenExpiry rtcServer:(NSString*)rtcServer delegate:(id<IrisRtcVideoSessionDelegate>)delegate error:(NSError* _Nullable *)outError
{
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:VideoSession code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        return NO;
    }
    
    if(sessionId == nil)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Session Id is null" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:VideoSession code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
    }
    
    

    if(_isVideoBridgeEnable){
        [super setVideoBridgeEnable:true];
    }
    else
    {
        [super setVideoBridgeEnable:false];
    }

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
        *outError = [NSError errorWithDomain:VideoSession code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
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
   
    if(sessionId == nil)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Session Id is null" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:VideoSession code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
        
    }
    else{
       // [super joinSession:sessionId stream:stream delegate:delegate];
          [super joinSession:rootEventInfo stream:stream delegate:delegate];
    }
    
    
    return YES;
}

-(void)muteVideo:(NSString*)participantId
{
    IRISLogInfo(@"IrisRtcVideoSession::muteRemoteVideo = %@",participantId);
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


@end



