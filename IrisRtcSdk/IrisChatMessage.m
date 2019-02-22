//
//  IrisChatMessage.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 4/7/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IrisChatMessage.h"
#import "IrisChatMessage+Internal.h"



@implementation IrisChatMessage



-(id)initWithMessage:(NSString*)message messageId:(NSString*)messageId
{
    self = [super init];
    if (self!=nil) {
    _data = message;
    _messageId = messageId;
    }
    return self;
}


-(id)initWithMessage:(NSString*)message
{
    self = [super init];
    if (self!=nil) {
    _data = message;
    _messageId = [[NSUUID UUID] UUIDString];
  
    }
    return self;
}


@end

@implementation IrisChatMessage (Internal)
-(id)initWithMessage:message messageId:(NSString*)messageId rootNodeId:(NSString*)rootNodeId childNodeId:(NSString*)childNodeId timeReceived:(NSString*)timeReceived{
    
    self = [super init];
    if (self!=nil) {
        _messageId = messageId;
        _rootNodeId = rootNodeId;
        _childNodeId = childNodeId;
        _timeReceived = timeReceived;
        _data = message;
    }
    return self;
}


@end
