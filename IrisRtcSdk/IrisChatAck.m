//
//  IrisChatAck.m
//  IrisRtcSdk
//
//  Created by Girish on 14/06/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IrisChatAck.h"

@implementation IrisChatAck

-(id)initWithMessage:messageId rootNodeId:(NSString*)rootNodeId childNodeId:(NSString*)childNodeId evmResponseCode:(NSString*)evmResponseCode;{
    self = [super init];
    if (self!=nil) {
        _messageId = messageId;
        _rootNodeId = rootNodeId;
        _childNodeId = childNodeId;
        _evmResponseCode = evmResponseCode;
    }
    return self;
    
}

@end
