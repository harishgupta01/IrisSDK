//
//  IrisRtcStreamUtils.h
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 9/27/16.
//  Copyright © 2016 Gupta, Harish (Contractor). All rights reserved.
//

#ifndef IrisRtcStreamUtils_h
#define IrisRtcStreamUtils_h

#define DEFAULT_MINBLOCKS_RESOLUTION 6758400
#define DEFAULT_MAXBLOCKS_RESOLUTION 62208000

#define DEFAULT_VIDEO_MAXBITRATE 4096
#define DEFAULT_VIDEO_INITIALBITRATE 1500
#define DEFAULT_AUDIO_PREFERBITRATE 60
#define DEFAULT_VIDEO_PREFERBITRATE 4096

#define DEFAULT_MIN_FRAMERATE 22
#define DEFAULT_MAX_FRAMERATE 30

#define DEFAULT_DATACHUNKSIZE 16

#define ICE_CONNECTION_TIMEOUT 15
#define PING_INTERVAL 1


typedef NS_ENUM(NSInteger, IrisRtcSessionType) {
    kSessionTypeVideo,
    kSessionTypeAudio,
    kSessionTypeBroadcast,
    kSessionTypeData,
    kSessionTypePSTN,
    kSessionTypeChat,
    kSessionTypeVideoUpgrade
};


typedef NS_ENUM(NSInteger, ConferenceIQType) {
    kAllocate,
    kDeallocate,
    kNormal
};


typedef enum
{
    SessionNetworkQualityIndicator
    
} SessionEventType;

@interface IrisRtcUtils : NSObject

+(NSString*)sessionTypetoString:(IrisRtcSessionType)sessionType;
+(IrisRtcSessionType)sessionTypeFromString:(NSString *)evenType;

@end


#endif /* IrisRtcStreamUtils_h */
