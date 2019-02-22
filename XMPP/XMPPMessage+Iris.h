//
//  XMPPMessage+Iris.h
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 11/22/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

@import XMPPFramework;

@interface XMPPMessage (Iris)

- (NSString*)evmresponseCode;
- (NSString*)rootNodeId;
- (NSString*)childNodeId;
- (NSString*)timeReceived;

@end
