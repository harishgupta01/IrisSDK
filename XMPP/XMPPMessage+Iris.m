//
//  XMPPMessage+Iris.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 11/22/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#import "XMPPMessage+Iris.h"

@implementation XMPPMessage (Iris)

- (NSString*)evmresponseCode{
    return [[[self elementForName:@"data"] attributeForName:@"evmresponsecode"] stringValue];
}

- (NSString *)rootNodeId
{
    //IRISLogInfo(@"data element %@",[[self elementForName:@"data"]stringValue]);
    return [[[self elementForName:@"data"] attributeForName:@"rootnodeid"] stringValue];
}

- (NSString *)childNodeId
{
    return [[[self elementForName:@"data"] attributeForName:@"childnodeid"] stringValue];
}

- (NSString *)timeReceived
{
    return [[[self elementForName:@"data"] attributeForName:@"timereceived"] stringValue];
}

@end
