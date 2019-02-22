//
//IrisRtcConnection.h : Objective C code for managing the connection with
//IRIS backend. It also involves making the necessary REST API
//calls with event manager and other components to get the
//resources as required for the connection.
//
// Copyright 2015 Comcast Cable Communications Management, LLC
//
// Permission to use, copy, modify, and/or distribute this software for any purpose
// with or without fee is hereby granted, provided that the above copyright notice
// and this permission notice appear in all copies.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO
// THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
// DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
// AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION
// WITH THE USE OR PERFORMANCE OF THIS SOFTWARE
//



#ifndef IrisRtcConnection_h
#define IrisRtcConnection_h

/** These are the different Iris RTC connection states
 *
 */
typedef NS_ENUM(NSUInteger, IrisRtcConnectionState) {
    /** When the connection is in progress
     *
     */
    kConnectionStateConnecting,
    /** When the connection with IRIS backend is successful
     *
     */
    kConnectionStateConnected,
    /** When the connection is reconnecting with backend
     *
     */
    kConnectionStateReconnecting,
    /** When the connection is authenticated with backend
     *
     */
    kConnectionStateAuthenticated,
    /** When the connection is disconnected.
     *
     */
    kConnectionStateDisconnected
};

NS_ASSUME_NONNULL_BEGIN

/** The `IrisNotificationPayload` class is used to provide the notification payload
 * to Iris SDK
 *
 * The important part of the notification payload includes XMPP server name
 * Credentials to access the 
 * <li>XMPP servers</li>
 * <li>Room name</li>
 * <li>Timestamp</li>
 *
 */
@interface IrisNotificationPayload : NSObject

/** private variable
 */
@property (strong) NSString *rtcServerUrl;
/** private variable
 */
@property (strong) NSString *xmppToken;
/** private variable
 */
@property (strong) NSString *timestamp;
@end

@class IrisRtcConnection;

/** The `IrisRtcConnectionDelegate` protocol defines the optional methods implemented by
 * delegates of the IrisRtcConnection class.
 *
 * The delegate onConnected will be called when connection is established with IRIS backend and delegate onDisconnected
 * will be called  when connection is disconnected with IRIS backend.
 *
 * The delegate onError:withAdditionalInfo: will be called whenever  any error occured in IrisRtcConnection class.It
 * contains error code and additionalinfo about error.
 */

@protocol IrisRtcConnectionDelegate <NSObject>

/** This method is called when the connection is established
 *
 */
- (void)onConnected;
/** This method is called when the connection is reconnecting
 */
- (void)onReconnecting;

/** This method is called when the connection is disconnected
 *
 */
- (void)onDisconnected;

/** This method is called when there is an error
 *
 * @param error The basic error code details
 * @param info Additional details for debugging.
 */
- (void)onError:(NSError *)error withAdditionalInfo:(nullable NSDictionary *)info;

/** This method is called when there is an notification via xmpp
 *
 * @param data The dictionary containing notification payload
 */
- (void)onNotification:(NSDictionary *)data;

@end

/** The `IrisRtcConnection` class used to manage the connection with
 * IRIS backend. It also involves making the necessary REST API
 * calls with event manager and other components to get the
 * resources as required for the connection.
 *
 * The idea of this class is to keep a persistent connection with
 * IRIS backend and hence it is a good practice to create the
 * connection when app goes to foreground and disconnect when the app
 * goes in background.
 */

@interface IrisRtcConnection : NSObject

/** 
 * private variable used to acces the different IrisRtcConnectionStates.
 */
@property (readonly) IrisRtcConnectionState state;
/**
 * private variable used to acces the different IrisRtcConnectionStates.
 */
@property BOOL enableReconnect;

/**
 * private variable used to set pingtimeInterval.
 *
 */
@property(nonatomic) NSTimeInterval pingTimeInterval;

/**
 * private variable used to set pingtimeoutInterval.
 *
 */
@property(nonatomic) NSTimeInterval pingTimeoutInterval;

/**
 * private variable used to set pingtimeoutInterval.
 *
 */
@property(nonatomic) BOOL isAnonymousRoom;


/** This method is used to get current instance of IrisRtcConnection object. The use of this method is to 
 * avoid creating multiple IriRtcConnection objects.
 */

+(IrisRtcConnection *)sharedInstance;

/**-----------------------------------------------------------------------------
 * @name Connect to IRIS backend
 * -----------------------------------------------------------------------------
 */

/**This API is used to establish a connection with the IRIS backend.
 *
 * @param serverUrl The event manager URL.
 * @param irisToken A valid IRIS token details.
 * @param routingId Self(or)Source routing ID.
 * @param delegate The delegate object for IrisRtcConnection. The delegate will
 * receive delegate messages during execution of the operation when output is
 * generated and upon completion or failure of the operation.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 *
 * @warning Please use this api for outgoing calls. Please use
 * connectUsingServer:irisToken:routingId:notificationPayload:delegate api for incoming calls.This api shoule be called
 * only after Retrieving the IRIS token using auth manager,Routing Id through ID manager.
 */
-(BOOL)connectUsingServer:(NSString* )serverUrl irisToken:(NSString*)irisToken routingId:(NSString*)routingId delegate:(id _Nullable)delegate error:(NSError* _Nullable *)outError;

/**This API is used to establish a connection with the IRIS backend.
 *
 * @param serverUrl The event manager URL.
 * @param irisToken A valid IRIS token details.
 * @param routingId Self routing ID.
 * @param notificationPayload This contains details like timestamp, xmpptoken, rtcServerURL.
 * @param delegate The delegate object for IrisRtcConnection. The delegate will
 * receive delegate messages during execution of the operation when output is
 * generated and upon completion or failure of the operation.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 *
 * @warning Please use this api for incoming calls. Please use
 * connectUsingServer:irisToken:routingId:delegate api for outgoing calls.This api shoule be called
 * only after Retrieving the IRIS token using auth manager,Routing Id through ID manager.
 */
//-(BOOL)connectUsingServer:(NSString*)serverUrl irisToken:(NSString*)irisToken routingId:(NSString*)routingId notificationPayload:(IrisNotificationPayload*)notificationPayload delegate:(id _Nullable)delegate error:(NSError* _Nullable *)outError;


/**-----------------------------------------------------------------------------
 * @name Disconnect
 * -----------------------------------------------------------------------------
 */
/**
 * This method is called to disconnect from IRIS backend.
 * @return Nothing
 */
-(void)disconnect;


/**-----------------------------------------------------------------------------
 * @name Reset JWT token
 * -----------------------------------------------------------------------------
 */
/**
 * This method is called to renew the JWT token.
 *
 * @param token     JWT token.
 * @param outError  Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)setIrisToken:(nonnull NSString *)token error:(NSError* _Nullable *)outError;

NS_ASSUME_NONNULL_END

@end

#endif /* IrisRtcConnection_h */
