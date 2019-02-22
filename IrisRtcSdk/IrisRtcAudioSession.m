//
//  IrisRtcAudioSession.m
//  IrisRtcSdk
//
//  Created by VinayakBhat on 07/10/16.
//  Copyright © 2016 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IrisRtcAudioSession.h"
#import "IrisRtcUtils.h"
#import "WebRTCError.h"
#import "IrisRtcConnection.h"
#import "XMPPWorker.h"
#import "IrisXMPPStream.h"
#import "WebRTC/WebRTC.h"
#import "IrisLogging.h"
@import libPhoneNumber_iOS;

NSString* const AudioSession     = @"IrisRtcAudioSession";





@interface IrisRtcJingleSession()


-(id)initWithSessionType:(IrisRtcSessionType)sessionType;

-(void)createAudioSessionWithRoomId:(NSString*)roomId participantId:(NSString*)participantId _sourceTelephoneNum:(NSString*)sourceTN _targetTelephoneNumber:(NSString*)targetTN notificationData:(NSString*)notificationData stream:(IrisRtcStream*)stream delegate:(id)delegate;
-(void)createAudioSessionWithTN:(NSString*)targetTN _sourceTelephoneNum:(NSString*)sourceTN notificationData:(NSString*)notificationData stream:(IrisRtcStream*)stream delegate:(id)delegate;
-(void)joinSession:(IrisRootEventInfo*)rootEventInfo stream:(IrisRtcStream*)stream  delegate:(id)delegate;
- (void) setVideoBridgeEnable: (bool) flag;
- (void) setStatsWS: (bool) flag;
- (void) setStatsCollectorInterval:(NSInteger)interval;
-(void) setToDomain:(NSString*)toDomain;
-(void)hold;
-(void)unHold;
-(BOOL)merge:(IrisRtcAudioSession*)session;
-(void)endPSTNCall;
-(void)insertDTMFtone:(IrisDTMFInputType)tone ;
-(void) setPreferredAudioCodecType:(IrisRtcSdkAudioCodecType)type;


@end

@implementation IrisRtcAudioSession

- (id)init
{
    //Generating random target id.
    self = [super initWithSessionType:kSessionTypePSTN];
    return self;
}


-(BOOL)createWithRoomId:(NSString*)roomId participantId:(NSString*)participantId _sourceTelephoneNum:(NSString*)sourceTN _targetTelephoneNumber:(NSString*)targetTN  notificationData:(NSString*)notificationData stream:(IrisRtcStream*)stream sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id<IrisRtcAudioSessionDelegate>)delegate error:(NSError**)outError;
{
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:AudioSession code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
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
    
    
    [super createAudioSessionWithRoomId:roomId participantId:participantId _sourceTelephoneNum:sourceTN _targetTelephoneNumber:targetTN notificationData:notificationData stream:stream delegate:delegate];
    
    return YES;
}

-(BOOL)createWithTN:(NSString*)targetTN _sourceTelephoneNum:(NSString*)sourceTN notificationData:(NSString*)notificationData stream:(IrisRtcStream*)stream sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id<IrisRtcAudioSessionDelegate>)delegate error:(NSError**)outError{
    
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:AudioSession code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
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
  
    if (sessionConfig.toDomain) {
        [super setToDomain:sessionConfig.toDomain];
    }
 
    BOOL containsLetter = NSNotFound != [targetTN rangeOfCharacterFromSet:NSCharacterSet.letterCharacterSet].location;
    BOOL containsNumber = NSNotFound != [targetTN rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet].location;
    BOOL containsSpecialCharcter = NSNotFound != [targetTN rangeOfString:@"^([*]|[+]|[0-9])\\d*$" options:NSRegularExpressionSearch].location;
    
    if([targetTN length] == 0 || [sourceTN length] == 0){
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Source/Target telephone number is null" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:AudioSession code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
    }else if(containsLetter && containsNumber){
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"AlphaNumbers not supported" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:AudioSession code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
    }
    else if (!containsSpecialCharcter){
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Invalid Number Format" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:AudioSession code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
    }
    
     [super createAudioSessionWithTN:targetTN _sourceTelephoneNum:sourceTN notificationData:notificationData stream:stream delegate:delegate];
    
    return YES;
}

-(void)createAudioSession{
  //  [super createSession];
}

-(void)hold{
    [super hold];
}

-(void)unhold{
     [super unHold];
}

-(BOOL)mergeSession:(IrisRtcAudioSession*) heldSession{
    return [super merge:heldSession];
}

-(void)close{
    [super close];
}

-(BOOL)joinWithSessionId:(NSString*)sessionId roomToken:(NSString*)roomToken roomTokenExpiryTime:(NSInteger)roomTokenExpiry stream:(IrisRtcStream*)stream rtcServer:(NSString*)rtcServer sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id<IrisRtcAudioSessionDelegate>)delegate error:(NSError* _Nullable *)outError

{
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:AudioSession code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        return NO;
    }
    
    if(sessionId == nil)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Session Id is null" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:AudioSession code:ERR_INCORRECT_PARAMS userInfo:details];
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
    
   
    [super joinSession:rootEventInfo stream:stream delegate:delegate];
    
 
    return YES;
}

-(void)insertDTMFtone:(IrisDTMFInputType)tone {
    [super insertDTMFtone:tone ];
}

-(void) setPreferredAudioCodecType:(IrisRtcSdkAudioCodecType)type
{
    [super setPreferredAudioCodecType:type];
}

+(BOOL)reject:(NSString *) roomId toId:(NSString *) toId traceId:(NSString *) traceId server:(NSString *) server error:(NSError**)outError
{
    IrisRtcConnectionState state =[[IrisRtcConnection sharedInstance]state];
    if(state != kConnectionStateAuthenticated)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"IrisRtcConnection is not done yet" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:AudioSession code:ERR_WEBSOCKET_DISCONNECT userInfo:details];
        return NO;
    }
    
    if((roomId == nil) || (toId == nil) || (server == nil) || (traceId == nil) || ([roomId length] == 0) || ([toId length] == 0) || ([server length] == 0) || ([traceId length] == 0)){
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Incorrect Parameters" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        *outError = [NSError errorWithDomain:AudioSession code:ERR_INCORRECT_PARAMS userInfo:details];
        return NO;
    }
    
    XMPPJID *targetJid = [XMPPJID jidWithUser:roomId domain:server resource:toId];
    
    XMPPIQ *iq = [[XMPPIQ alloc]initWithType:@"set" to:targetJid elementID:nil];
    [iq addAttributeWithName:@"xmlns" stringValue:@"jabber:client"];
    
    NSXMLElement *jingleElement = [NSXMLElement elementWithName:@"query"];
    [jingleElement addAttributeWithName:@"xmlns" stringValue:@"jabber:iq:private"];
    [jingleElement addAttributeWithName:@"strict" stringValue:@"false"];
    
    NSXMLElement *dataElement = [NSXMLElement elementWithName:@"data" xmlns:@"urn:xmpp:comcast:info"];
    [dataElement addAttributeWithName:@"event" stringValue:[IrisRtcUtils sessionTypetoString:kSessionTypePSTN]];
    [dataElement addAttributeWithName:@"rtcserver" stringValue:server];
    [dataElement addAttributeWithName:@"to" stringValue:[targetJid full]];
    [dataElement addAttributeWithName:@"roomid" stringValue:roomId];
    [dataElement addAttributeWithName:@"traceid" stringValue:traceId];
    [dataElement addAttributeWithName:@"action" stringValue:@"reject"];

    [iq addChild:jingleElement];
    [iq addChild:dataElement];
    
    IrisXMPPStream* xmppStream = [[XMPPWorker sharedInstance] xmppStream];
    // send IQ
    [xmppStream sendElement:iq];
    return  YES;
    
}

+(void)activateAudio{
    RTCAudioSession *session = [RTCAudioSession sharedInstance];
    [session activateAudioUnit];
}

+(void)deactivateAudio{
    RTCAudioSession *session = [RTCAudioSession sharedInstance];
    [session deactivateAudioUnit];
}
@end
