//
//  Header.h
//  xfinity-webrtc-sdk
//
//  Created by Gupta, Harish (Contractor) on 7/14/16.
//  Copyright © 2016 Comcast. All rights reserved.
//

#ifndef WebRTCEventManager_h
#define WebRTCEventManager_h
#endif /* WebRTCEventManager_h */
#import <Foundation/Foundation.h>

@protocol WebRTCEventManagerDelegate <NSObject>

- (void) onIceServer:(NSDictionary*) msg;
- (void) onEventManagerFailure:(NSString*)error errorCode:(NSInteger)code additionalData:(NSDictionary *)additionalData;
//- (void) startSignalingServer:(NSDictionary*) websocketdata iceserverdata:(NSDictionary*)iceserverdata;
//- (void) startSignalingServer:(NSData*)resources;
- (void) onXmppRegisterInfoSuccess:(NSString*)rtcServer _xmppToken:(NSString*)token _tokenExpiryTime:(NSString*)expiryTime;
- (void) onCreateRootEventSuccess:(NSString*)rootNodeId _childNodeId:(NSString*)childNodeId _eventData:(NSDictionary*)eventData;
- (void) onCloseRoom;
@end


@interface WebRTCEventManager : NSObject <NSURLConnectionDelegate>
@property (nonatomic) id<WebRTCEventManagerDelegate> delegate;
@property (nonatomic) NSString* serverURL;
@property (nonatomic) NSString* jsonWebToken;
@property (nonatomic) NSTimeInterval requestTimeout;
@property (nonatomic) NSDictionary* requestPayload;
@property (nonatomic) NSDictionary* requestHeader;

+ (WebRTCEventManager *)sharedInstance;

//-(id)initWithDefaultValue:(NSString*)endPointURL _token:(NSString *)token;

//Event Manager APIs
//-(void)createXmppRootEventRequest:(NSDictionary*)requestPayload _requestHeaders:(NSDictionary*)requestHeaders _requestTimeout:(NSTimeInterval) requestTimeoutInterval _requestType:(NSString *)requestType _requestretryCount:(NSInteger)requestRetryCount; ;

-(void)createXmppRootEventWithRoomName;

-(void)getXmppRegisterInfo;

//-(void)End;
@end



