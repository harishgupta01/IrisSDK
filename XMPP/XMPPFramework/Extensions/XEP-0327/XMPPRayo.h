//
//  XMPPRayo.h
//  xfinity-webrtc-sdk
//
//  Created by Vamsi on 4/22/15.
//  Copyright (c) 2015 Comcast. All rights reserved.
//

#ifndef xfinity_webrtc_sdk_XMPPRayo_h
#define xfinity_webrtc_sdk_XMPPRayo_h

#import <Foundation/Foundation.h>

#import "XMPP.h"
#import "XMPPFramework.h"

#define RAYO_XMLNS @"urn:xmpp:rayo:1"

@interface XMPPRayo : NSObject

+ (XMPPIQ *)dial:(NSString*)to from:(NSString*)from roomName:(NSString*)roomName roomPass:(NSString*)roomPass target:(NSString*)target;
+ (XMPPIQ *)hangup;
+ (XMPPIQ *)merge:(NSString*)target;
+ (XMPPIQ *)hold:(NSString*)to from:(NSString*)from roomName:(NSString*)roomName roomPass:(NSString*)roomPass target:(NSString*)target;
+ (XMPPIQ *)unHold:(NSString*)to from:(NSString*)from roomName:(NSString*)roomName roomPass:(NSString*)roomPass target:(NSString*)target;

+(void) test;

@end

#endif
