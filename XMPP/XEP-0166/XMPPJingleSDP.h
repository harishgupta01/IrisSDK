//
//  XMPPJingleSDP.h
//  xfinity-webrtc-sdk
//
//  Created by Ganvir, Manish (Contractor) on 2/6/15.
//  Copyright (c) 2015 Comcast. All rights reserved.
//

#ifndef xfinity_webrtc_sdk_XMPPJingleSDP_h
#define xfinity_webrtc_sdk_XMPPJingleSDP_h
#import <Foundation/Foundation.h>
@import XMPPFramework;


// Namespace for jingle messages
#define XEP_0166_XMLNS @"urn:xmpp:jingle:1"

@interface XMPPJingleSDPUtil : NSObject
{
    NSMutableArray* session;
    NSMutableArray* media;
    
	NSXMLElement *sdpFprElement;
    NSString *gUfrag;
    NSString *gPwd;
    NSMutableDictionary *mediaContent;
}
- (XMPPIQ *)SDPToXMPP:(NSString *)sdp action:(NSString *)action initiator:(XMPPJID *)initiator target:(XMPPJID *)target UID:(NSString *)UID SID:(NSString *)SID;
- (XMPPIQ *)CandidateToXMPP:(NSDictionary *)dict action:(NSString *)action initiator:(XMPPJID *)initiator target:(XMPPJID *)target UID:(NSString *)UID SID:(NSString *)SID;
- (NSXMLElement *)MediaToXMPP:(NSString *)type  data:(NSDictionary *)data target:(XMPPJID *)target UID:(NSString *)UID SID:(NSString *)SID;
-(NSString*)routingIdFor:(NSString*)streamId;
- (NSString *)XMPPToSDP:(XMPPIQ *)iq;
- (NSString *)modifySDP:(XMPPIQ *)iq;
- (NSString *)modifySourceRemoveSDP:(XMPPIQ *)iq;
- (NSDictionary *)XMPPToCandidate:(XMPPIQ *)iq;

- (NSString*)find_line:(NSString*)haystack  needle:(NSString*)needle;
- (NSArray*)find_lines:(NSString*)haystack  needle:(NSString*)needle;
- (NSArray*) parse_mline:(NSString*)line;

- (void) splitSDP:(NSString*)sdp;

@end

#endif
