//
//  IrisRtcSdkCoreData.h
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 10/7/16.
//  Copyright © 2016 Gupta, Harish (Contractor). All rights reserved.
//

#ifndef IrisRtcSdkCoreData_h
#define IrisRtcSdkCoreData_h

@protocol IrisRtcCoreDataDelegate <IrisRtcSessionDelegate>

- (void)IrisRtcSdkCoreData:(IrisRtcSdkCoreData *)sdkCoreData onDataSessionConnected:(NSString *)roomId;

- (void)IrisRtcSdkCoreData:(IrisRtcSdkCoreData *)sdkCoreData onSessionDataWithImage:(NSString*)filePath;

@end


@interface IrisRtcSdkCoreData : NSObject

@property(readonly) IrisRtcSdkVersion;

@end

#endif /* IrisRtcSdkCoreData_h */
