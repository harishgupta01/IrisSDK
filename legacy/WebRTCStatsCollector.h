//
//  WebRTCStats.h
//  xfinity-webrtc-sdk
//
//  Created by Pankaj on 16/07/14.
//  Copyright (c) 2014 Comcast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IrisRtcSession.h"
#import "WebRTCStatGroup.h"

@class IrisRtcSession,WebRTCStatGroup;

@protocol WebRTCStatsCollectorDelegate <NSObject>

-(void) onUpdateStats:(NSString*) statKey _statValue:(id)statsValue;
-(void) onAppendStats:(NSString*) statKey _statValue:(id)statsValue;
@end

@interface WebRTCStatsCollector : NSObject
{
    NSMutableDictionary* sessions;
    WebRTCStatGroup *setup;
}

@property(nonatomic,weak) id<WebRTCStatsCollectorDelegate> delegate;

@property (nonatomic) NSDateFormatter* dateFormatter;
@property (nonatomic) NSMutableDictionary* metaData;
@property (nonatomic) NSMutableDictionary *errorLog;
@property (nonatomic) NSMutableArray *callLog;
@property (nonatomic) BOOL omitCallLogInReport;


-(id)initWithDefaultValue:(NSMutableDictionary*)metaData _appdelegate:(id<WebRTCStatsCollectorDelegate>)_appdelegate;
-(void)startMetric:(NSString*)statName;
-(void)stopMetric:(NSString*)statName;
-(void)storeReaccuring:(NSString*)metaData _values:(NSDictionary*)values;
-(void)writeMeta:(NSString*)metaKey _values:(NSString*)value;
-(void)startMetric:(NSString *)sessionId _statName:(NSString*)statName ;
-(void)stopMetric:(NSString *)sessionId _statName:(NSString*)statName ;
-(void)storeReaccuring:(NSString *)sessionId _statName:(NSString*)statName _values:(NSDictionary*)values;
-(NSMutableDictionary*)streamInfo;


-(void)storeError:(NSString*)reason;
-(void)storeCallLogMessage:(NSString*)msg _msgType:(NSString*)msgType;

-(NSString*)toPrettyString;
//-(NSDictionary*)toJSON;
-(NSDictionary*)toJSON:(BOOL)omitLog;
-(WebRTCStatGroup*)getSessionStats:(NSString *)sessionId;
-(void)saveStats:(NSString *)sessionId _stats:(WebRTCStatGroup*)stats;
//-(void)reportStats;

@end
