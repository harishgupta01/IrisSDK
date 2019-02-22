//
//  WebRTCStatReport_new.h
//  xfinity-webrtc-sdk
//
//  Created by Pankaj on 17/07/14.
//  Copyright (c) 2014 Comcast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebRTC/WebRTC.h"

@interface WebRTCStatReport_new : NSObject

@property(nonatomic ) NSInteger bytesSent;
@property(nonatomic ) NSInteger sendFrameRate;
@property(nonatomic ) NSInteger sendWidth;
@property(nonatomic ) NSInteger sendHeight;
@property(nonatomic ) NSInteger sendBandwidth;
@property(nonatomic ) NSInteger recvBandwidth;
@property(nonatomic ) NSInteger rtt;
@property(nonatomic ) NSInteger packetLossSent;
@property(nonatomic ) NSInteger totalPacketSent;
@property(nonatomic ) NSInteger packetLossRecv;
@property(nonatomic ) NSInteger totalPacketRecv;
@property(nonatomic ) double timesstamp;
@property(nonatomic ) NSString* turnServerIP;
@property(nonatomic ) NSString* reportID;
@property(nonatomic ) BOOL generalFlag;
@property(nonatomic ) BOOL rxAudioFlag;
@property(nonatomic ) BOOL rxVideoFlag;
@property(nonatomic ) BOOL txAudioFlag;
@property(nonatomic ) BOOL txVideoFlag;
@property(nonatomic ) NSDateFormatter* dateFormatter;
@property(nonatomic ) NSDateFormatter* isoDateFormatter;
@property(nonatomic ) BOOL isBytesReceived;

-(id)init;
-(void)parseReport:(NSArray*)reports;
//-(int)useLastReportToCalcCurrentBandwidth:(WebRTCStatReport_new*)lastReport;
-(NSMutableDictionary*)toJSON;
-(NSString*)toString;
-(NSMutableDictionary*)getRxVideoStat:(NSDictionary*)pairs;
-(NSMutableDictionary*)getTxVideoStat:(NSDictionary*)pairs;
-(NSMutableDictionary*)getRxAudioStat:(NSDictionary*)pairs;
-(NSMutableDictionary*)getTxAudioStat:(NSDictionary*)pairs;
-(NSMutableDictionary*)getGeneralStat:(NSDictionary*)pairs;
-(NSString*)getTurnServerIP:(NSArray*)pairs;
-(NSMutableDictionary*)stats;
-(void)streamStatArrayAlloc;
-(void)resetParams;
//-(NSString*)toString:(NSArray*)_array;

/* To check if turn ip available */
+ (BOOL)isTurnIPAvailable;
+ (void)setTurnIPAvailabilityStatus:(BOOL)value;
@end
