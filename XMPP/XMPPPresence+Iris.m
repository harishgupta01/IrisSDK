//
//  XMPPPresence+Iris.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 11/21/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#import "XMPPPresence+Iris.h"
@import XMPPFramework;
@implementation XMPPPresence (Iris)

- (NSString*)sessionType{
    //for (NSXMLElement *element in privateIqElements)
    //     {
    NSXMLElement *data = [self elementForName:@"data"];
    if (data)
    {
        NSMutableDictionary * dict = [data attributesAsDictionary];
        return [dict objectForKey:@"event"];
    }
    //       }
    
    return nil;
}

+ (XMPPPresence *)presenceWithType:(NSString *)type to:(XMPPJID *)to id:(NSString *)id
{
    return [[XMPPPresence alloc] initWithType:type to:to id:id];
}

- (id)initWithType:(NSString *)type to:(XMPPJID *)to id:(NSString *)id
{
    if ((self = [super initWithName:@"presence"]))
    {
        if (type)
            [self addAttributeWithName:@"type" stringValue:type];
        
        if (to)
            [self addAttributeWithName:@"to" stringValue:[to full]];
        
        if (id)
            [self addAttributeWithName:@"id" stringValue:id];
    }
    return self;
}

@end
