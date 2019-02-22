//
//  IrisRtcDataSession.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 10/3/16.
//  Copyright © 2016 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IrisRtcDataSession.h"
#import "IrisRtcUtils.h"
#import  "XMPPWorker.h"

@interface IrisRtcJingleSession()
-(id)initWithSessionType:(IrisRtcSessionType)sessionType;
-(void)createSession:(NSArray*)participantIds notificationData:(NSString*)notificationData stream:(IrisRtcStream*)stream delegate:(id)delegate;

-(void)createSessionWithAnonymousRoom:(NSString*)roomName stream:(IrisRtcStream*)stream  delegate:(id)delegate;
-(void)joinSession:(IrisRootEventInfo*)rootEventInfo stream:(IrisRtcStream*)stream  delegate:(id)delegate;
-(void) sendDataWithImage:(NSString*)filePath;
- (instancetype)initIrisRtcSession:(IrisRtcSessionType)sessionType targetId:(NSString*)targetId delegate:(id)delegate;
-(void) sendCompressedImageData:(NSData*)imgData;
-(void) sendDataWithText:(NSString*)_textMsg;
-(void)close;

@end

@implementation IrisRtcDataSession
- (id)init
{   
    self = [super initWithSessionType:kSessionTypeData];
    return self;
}


-(void)createWithParticipants:(NSArray*)participants notificationData:(NSString*)notificationData delegate:(id<IrisRtcDataSessionDelegate>)delegate{
    
    if(participants == nil)
    {
        NSString* targetID = [[NSUUID UUID] UUIDString];
        targetID = [targetID stringByAppendingString:@"@irisvideochat.comcast.com"];
  
         //[super createSessionWithAnonymousRoom:_useAnonymousRoom stream:nil delegate:delegate];
    }
    else
    {
        return [super createSession:participants notificationData:notificationData stream:nil delegate:delegate];
    }
    
    
}

-(void)joinWithSessionId:(NSString*)sessionId delegate:(id<IrisRtcDataSessionDelegate>)delegate{
    
    
    IrisRootEventInfo* rootEventInfo = [[IrisRootEventInfo alloc]init];
    [rootEventInfo setRoomId:sessionId];
    
    [super joinSession:rootEventInfo stream:nil delegate:delegate];

}

-(void)sendImage:(NSString*)filePath
{
    [super sendDataWithImage:filePath];
}

-(void)sendCompressedImage:(NSData*)imgData
{
    [super sendCompressedImageData:imgData];
}

-(void)sendText:(NSString*)textMsg
{
    [super sendDataWithText:textMsg];
}

-(void)close{
    
    [super close];
}

@end
