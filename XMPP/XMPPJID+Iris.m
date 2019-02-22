//
//  XMPPJID+Iris.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 11/21/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPJID+Iris.h"


@implementation XMPPJID (Iris)

- (NSString *)routingId
{
    if (resource)
    {
        return [resource componentsSeparatedByString:@"/"][0];
    }
    else
    {
        return user;
    }
}
@end
