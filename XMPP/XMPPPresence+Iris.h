//
//  XMPPPresence+Iris.h
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 11/21/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#ifndef XMPPPresence_Iris_h
#define XMPPPresence_Iris_h
@import XMPPFramework;

@interface XMPPPresence (Iris)

- (NSString*)sessionType;
+ (XMPPPresence *)presenceWithType:(NSString *)type to:(XMPPJID *)to id:(NSString *)id;
- (id)initWithType:(NSString *)type to:(XMPPJID *)to id:(NSString *)id;

@end

#endif /* XMPPPresence_Iris_h */
