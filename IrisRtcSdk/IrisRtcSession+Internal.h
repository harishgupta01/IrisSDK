//
//  IrisRtcSession+Internal.h
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 10/7/16.
//  Copyright © 2016 Gupta, Harish (Contractor). All rights reserved.
//

#ifndef IrisRtcSession_Internal_h
#define IrisRtcSession_Internal_h
#import "WebRTCStatsCollector.h"
#import "WebRTC/WebRTC.h"
@protocol IrisRtcSdkSesionStatsDelegate <NSObject>

- (void)IrisRtcSession:(IrisRtcSession *)sdkStats onSdkStatsDuringActiveSession:(NSDictionary *)sessionStats;

- (void)IrisRtcSession:(IrisRtcSession *)sdkStats onCompleteSessionStatsWithTimeseries:(NSDictionary*)sessionTimeseries streamInfo:(NSDictionary*)streamInfo eventInfo:(NSMutableArray *)eventinfo;

@end

@interface IrisRtcSession (Internal)

@property(nonatomic, weak) id<IrisRtcSdkSesionStatsDelegate> delegate;

-(void)setStatsCollector:(WebRTCStatsCollector*)statsCollector;


@end

#endif /* IrisRtcSession_Internal_h */
