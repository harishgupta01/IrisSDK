//
//  IrisRoomManager.m
//  IrisRtcSdk
//
//  Created by Girish on 08/08/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IrisRtcParticipant.h"

@implementation IrisRtcParticipant : NSObject

-(id)initWithParticipant:participantId timeElapse:(NSDate*)timeElapse{
    self = [super init];
    if (self!=nil) {
        _participantId = participantId;
        _timeElapse = timeElapse;
    }
    return self;
}

@end
