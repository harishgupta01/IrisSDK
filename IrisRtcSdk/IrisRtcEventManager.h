//
//  IrisRtcEventManager.h
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 9/26/16.
//  Copyright © 2016 Gupta, Harish (Contractor). All rights reserved.
//

#ifndef IrisRtcEventManager_h
#define IrisRtcEventManager_h
#import "IrisRootEventInfo.h"
#import "IrisRtcUtils.h"

@protocol IrisRtcEventManagerDelegate <NSObject>

- (void) onIceServer:(NSDictionary*) msg;
- (void) onEventManagerFailure:(NSError*)error additionalData:(NSDictionary *)additionalData;
//- (void) startSignalingServer:(NSDictionary*) websocketdata iceserverdata:(NSDictionary*)iceserverdata;
//- (void) startSignalingServer:(NSData*)resources;
- (void) onXmppRegisterInfoSuccess:(NSString*)rtcServer _xmppToken:(NSString*)token _tokenExpiryTime:(NSString*)expiryTime _turnServer:(NSDictionary*)turnServer;
- (void) onCreateRootEventSuccess:(IrisRootEventInfo*)rootEventInfo;
- (void) onRoomTokenRenewd:(NSString*)roomToken _roomTokenExpiry:(NSString*)roomTokenExpiry;
- (void) onRoomInvalid;
- (void) onCloseRoom;

//New Delegate
- (void) onCreateRoomSuccess:(NSString*)roomId;

@end


@interface IrisRtcEventManager : NSObject <NSURLConnectionDelegate>
@property (nonatomic) id<IrisRtcEventManagerDelegate> delegate;
@property (nonatomic) NSTimeInterval requestTimeout;
@property (nonatomic) BOOL isPSTNcallwithTN;
@property (nonatomic) BOOL useAnonymousRoom;

-(id)initWithURL:(NSString*)endPointURL _token:(NSString *)token delegate:(id<IrisRtcEventManagerDelegate>)delegate;

-(id)initWithTraceId:(NSString *)traceId _roomId:(NSString*)roomId delegate:(id<IrisRtcEventManagerDelegate>)eventMngrDelegate;

-(void)createRootEventWithPayload:(NSString*)notificationPayload _sessionType:(IrisRtcSessionType)sessionType;

-(void)getXmppRegisterInfo;

-(void)renewToken:(NSString*)roomId;

-(void)End;

@end

#endif /* IrisRtcEventManager_h */
