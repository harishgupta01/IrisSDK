//
//  IrisRootEventInfo.h
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 7/27/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#ifndef IrisRootEventInfo_h
#define IrisRootEventInfo_h

@interface IrisRootEventInfo : NSObject

@property(nonatomic) NSString* rootNodeId;
@property(nonatomic) NSString* childNodeId;
@property(nonatomic) NSString* roomToken;
@property(nonatomic) NSString* roomId;
@property(nonatomic) NSString* roomExpiryTime;
@property(nonatomic) NSString* rtcServer;
@property(nonatomic) NSString* targetRoutingId;
@end

#endif /* IrisRootEventInfo_h */
