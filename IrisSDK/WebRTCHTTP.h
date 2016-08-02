//
//  WebRTCHTTP.h
//  xfinity-webrtc-sdk
//
//  Created by Pankaj on 05/08/14.
//  Copyright (c) 2014 Comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WebRTCHTTPDelegate <NSObject>

- (void) onIceServer:(NSDictionary*) msg;
- (void) onHTTPError:(NSString*)error errorCode:(NSInteger)code additionalData:(NSDictionary *)additionalData;
//- (void) startSignalingServer:(NSDictionary*) websocketdata iceserverdata:(NSDictionary*)iceserverdata;
- (void) startSignalingServer:(NSData*)resources;
//xmpp create room
- (void) createXMPPConnection:(NSString*)mucid _timestamp:(NSString*)timestamp _xmppToken:(NSString*)xmppToken _requestType:(NSString *)requestType;
- (void) onCloseRoom;
@end

@interface WebRTCHTTP : NSObject <NSURLConnectionDelegate>
@property (nonatomic) id<WebRTCHTTPDelegate> delegate;
@property (nonatomic) NSString* url;
@property (nonatomic) NSString* tokenStr;

-(id)initWithDefaultValue:(NSString*)endPointURL _token:(NSData *)token;
-(void)sendResourceRequest:(NSDictionary*)requestHeaders _usingRTC20:(BOOL)usingRTC20 _requestTimeout:(NSTimeInterval)requestTimeoutInterval;
-(void)sendCreateJoinRoomRequest:(NSDictionary*)requestPayload _requestHeaders:(NSDictionary*)requestHeaders _requestTimeout:(NSTimeInterval) requestTimeoutInterval _requestType:(NSString *)requestType _requestretryCount:(NSInteger)requestRetryCount;
-(void)sendCloseRoomRequest:(NSDictionary*)requestPayload _requestHeaders:(NSDictionary*)requestHeaders _requestTimeout:(NSTimeInterval) requestTimeoutInterval ;
-(void)End;

@end
