//
//  IrisRtcUtils.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 12/13/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IrisRtcUtils.h"

@implementation IrisRtcUtils


+(NSString*)sessionTypetoString:(IrisRtcSessionType)sessionType {
    NSString *result = nil;
    
    switch(sessionType) {
        case kSessionTypeVideo:
            result = @"videocall";
            break;
        case kSessionTypeAudio:
            result = @"audiocall";
            break;
        case kSessionTypePSTN:
            result = @"pstncall";
            break;
        case kSessionTypeChat:
            result = @"groupchat";
            break;
        case kSessionTypeVideoUpgrade:
            result = @"videocall";
            break;
        default:
            [NSException raise:NSGenericException format:@"Unexpected FormatType."];
    }
    
    return result;
}

+(IrisRtcSessionType)sessionTypeFromString:(NSString *)evenType
{
    
    if([evenType isEqualToString:@"videocall"]){
        return kSessionTypeVideo;
    }
    else
        if([evenType isEqualToString:@"audiocall"]){
            return kSessionTypeAudio;
        }
        else
            if([evenType isEqualToString:@"groupchat"]){
                return kSessionTypeChat;
            }
            else
                if([evenType isEqualToString:@"pstncall"]){
                    return kSessionTypePSTN;
                }
                else
                {
                    return kSessionTypeChat;
                }
}
@end

