//
//  IrisRtcChatSession.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 3/9/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IrisRtcChatSession.h"
#import "IrisRtcJingleSession.h"
#import "IrisRtcUtils.h"
#import "IrisRtcStream.h"
#import "IrisRtcConnection.h"
#import "WebRTCError.h"
#import "XMPPWorker.h"
#import "IrisLogging.h"

NSString* const ChatSession     = @"IrisRtcChatSession";
@class IrisRtcJingleSession;
@interface IrisRtcJingleSession()


-(id)initWithSessionType:(IrisRtcSessionType)sessionType;
-(void)createSessionWithRoomId:(NSString*)roomId notificationData:(NSString*)notificationData stream:(IrisRtcStream*)stream delegate:(id)delegate;
-(void)joinSession:(IrisRootEventInfo*)rootEventInfo stream:(IrisRtcStream*)stream  delegate:(id)delegate;
- (void) setVideoBridgeEnable: (bool) flag;
- (void) setStatsWS: (bool) flag;
-(id)creatSession;
-(void)joinSession;
-(void)sendChatMessage:(IrisChatMessage*)message;
-(void)close;

@end

@implementation IrisRtcChatSession

- (id)init
{
    //Generating random target  id.
    
    self = [super initWithSessionType:kSessionTypeChat];
   
    return self;
}

-(BOOL)createWithRoomId:(NSString* )roomId notificationData:(NSString*)notificationData delegate:(id<IrisRtcChatSessionDelegate>)delegate error:(NSError**)outError
{
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:ChatSession code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        return NO;
    }
    
    if(roomId == nil || ([roomId length] ==0))
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Room Id is empty" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:ChatSession code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
    }
    
    if(_isVideoBridgeEnable){
        [super setVideoBridgeEnable:true];
    }
    else
    {
        [super setVideoBridgeEnable:false];
    }
    
    if([self.traceId length] == 0){
        self.traceId = [[NSUUID UUID] UUIDString];
    }
    
    [super createSessionWithRoomId:roomId notificationData:notificationData stream:nil delegate:delegate];
    return YES;
}

-(BOOL)joinWithSessionId:(NSString*)sessionId roomToken:(NSString*)roomToken roomTokenExpiryTime:(NSInteger)roomTokenExpiry rtcServer:(NSString*)rtcServer delegate:(id<IrisRtcChatSessionDelegate>)delegate error:(NSError **)outError;

{
    IRISLogInfo(@"IrisRtcChatSession::objectId %p", self);
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:ChatSession code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        return NO;
    }
    
    if(sessionId == nil)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Session Id is null" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:ChatSession code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
    }
    
    if(_isVideoBridgeEnable){
        [super setVideoBridgeEnable:true];
    }
    else
    {
        [super setVideoBridgeEnable:false];
    }
    
    if([self.traceId length] == 0){
        self.traceId = [[NSUUID UUID] UUIDString];
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

-(BOOL)sendChatMessage:(IrisChatMessage*)message error:(NSError**)outError
{
    if ([[message data] length] == 0)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Message body is null or empty" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:ChatSession code:ERR_INCORRECT_PARAMS userInfo:details];
        
        return NO;
        
    }
    
        [super sendChatMessage:message];
        return YES;
    
}

@end
