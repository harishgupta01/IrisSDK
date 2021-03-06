//
//  IrisXMPPAnonymousAuthentication.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 11/21/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#import "IrisXMPPAnonymousAuthentication.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int xmppLogLevel = XMPP_LOG_LEVEL_INFO; // | XMPP_LOG_FLAG_TRACE;
#else
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

/**
 * Seeing a return statements within an inner block
 * can sometimes be mistaken for a return point of the enclosing method.
 * This makes inline blocks a bit easier to read.
 **/
#define return_from_block  return

NSString* gRoutingId, *gTraceId;
@implementation IrisXMPPAnonymousAuthentication
{
#if __has_feature(objc_arc_weak)
    __weak XMPPStream *xmppStream;
#else
    __unsafe_unretained XMPPStream *xmppStream;
#endif
}

+ (NSString *)mechanismName
{
    return @"NOAUTH";
}

- (id)initWithStream:(XMPPStream *)stream
{
    if ((self = [super init]))
    {
        xmppStream = stream;
    }
    return self;
}

- (id)initWithStream:(XMPPStream *)stream password:(NSString *)password
{
    return [self initWithStream:stream];
}

- (id)initWithStream:(XMPPStream *)stream password:(NSString *)password routingID:(NSString*)routingId traceID:(NSString*)traceId
{
    //return [self initWithStream:stream];
    if ((self = [super init]))
    {
        xmppStream = stream;
        gRoutingId = routingId;
        gTraceId = traceId;
    }
    return self;
}

- (BOOL)start:(NSError **)errPtr
{
    // <auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="ANONYMOUS" />
    
    NSXMLElement *auth = [NSXMLElement elementWithName:@"auth" xmlns:@"urn:ietf:params:xml:ns:xmpp-sasl"];
    [auth addAttributeWithName:@"mechanism" stringValue:@"NOAUTH"];
    [auth addAttributeWithName:@"routingid" stringValue:gRoutingId];
    [auth addAttributeWithName:@"traceid" stringValue:gTraceId];
    //[auth addAttributeWithName:@"resourceid" stringValue:[[NSUUID UUID] UUIDString]];
    [xmppStream sendAuthElement:auth];
    
    return YES;
}

- (XMPPHandleAuthResponse)handleAuth:(NSXMLElement *)authResponse
{
    // We're expecting a success response.
    // If we get anything else we can safely assume it's the equivalent of a failure response.
    
    if ([[authResponse name] isEqualToString:@"success"])
    {
        return XMPP_AUTH_SUCCESS;
    }
    else
    {
        return XMPP_AUTH_FAIL;
    }
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation XMPPStream (IrisXMPPAnonymousAuthentication)

- (BOOL)supportsAnonymousAuthentication
{
    return [self supportsAuthenticationMechanism:[IrisXMPPAnonymousAuthentication mechanismName]];
}

- (BOOL)authenticateAnonymously:(NSError **)errPtr
{
    XMPPLogTrace();
    
    __block BOOL result = YES;
    __block NSError *err = nil;
    
    dispatch_block_t block = ^{ @autoreleasepool {
        
        if ([self supportsAnonymousAuthentication])
        {
            IrisXMPPAnonymousAuthentication *anonymousAuth = [[IrisXMPPAnonymousAuthentication alloc] initWithStream:self];
            
            result = [self authenticate:anonymousAuth error:&err];
        }
        else
        {
            NSString *errMsg = @"The server does not support anonymous authentication.";
            NSDictionary *info = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
            
            err = [NSError errorWithDomain:XMPPStreamErrorDomain code:XMPPStreamUnsupportedAction userInfo:info];
            
            result = NO;
        }
    }};
    
    if (dispatch_get_specific(self.xmppQueueTag))
        block();
    else
        dispatch_sync(self.xmppQueue, block);
    
    if (errPtr)
        *errPtr = err;
    
    return result;
}

@end

