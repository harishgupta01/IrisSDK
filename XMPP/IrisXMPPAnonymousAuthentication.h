//
//  IrisXMPPAnonymousAuthentication.h
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 11/21/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#ifndef IrisXMPPAnonymousAuthentication_h
#define IrisXMPPAnonymousAuthentication_h

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
@import XMPPFramework;


@interface IrisXMPPAnonymousAuthentication : NSObject <XMPPSASLAuthentication>

- (id)initWithStream:(XMPPStream *)stream;

- (id)initWithStream:(XMPPStream *)stream password:(NSString *)password routingID:(NSString*)routingId traceID:(NSString*)traceId;

// This class implements the XMPPSASLAuthentication protocol.
//
// See XMPPSASLAuthentication.h for more information.

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface XMPPStream (IrisXMPPAnonymousAuthentication)

/**
 * Returns whether or not the server support anonymous authentication.
 *
 * This information is available after the stream is connected.
 * In other words, after the delegate has received xmppStreamDidConnect: notification.
 **/
- (BOOL)supportsAnonymousAuthentication;

/**
 * This method attempts to start the anonymous authentication process.
 *
 * This method is asynchronous.
 *
 * If there is something immediately wrong,
 * such as the stream is not connected or doesn't support anonymous authentication,
 * the method will return NO and set the error.
 * Otherwise the delegate callbacks are used to communicate auth success or failure.
 *
 * @see xmppStreamDidAuthenticate:
 * @see xmppStream:didNotAuthenticate:
 **/
- (BOOL)authenticateAnonymously:(NSError **)errPtr;

@end
#endif /* IrisXMPPAnonymousAuthentication_h */
