//
//  WebRTCStats.h
//  xfinity-webrtc-sdk
//
//  Created by Pankaj on 16/07/14.
//  Copyright (c) 2014 Comcast. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebRTCLogger: NSObject

@property (nonatomic) NSMutableArray* callLog;
@property (nonatomic) NSArray* setup;
@property (nonatomic) NSMutableDictionary *metaData;
@property (nonatomic) NSMutableDictionary *session;
@property (nonatomic) NSMutableDictionary *errorLog;
@property (nonatomic) NSString* alias;
@property (nonatomic) BOOL isCallLogEnable;

-(id)initWithDefaultValue:(NSString*)endpointURL  _password:(NSString*)password _alias:(NSString*)fromID;
-(void)updateStats:(NSString*)statKey _statValue:(id)statValue;
-(void)appendStats:(NSString*)statKey _statValue:(id)statValue;
-(void)postStatsToServer;
-(void)postStatsToServer:(NSMutableDictionary*)metaData timeseries:(NSMutableDictionary *)obj streamInfo:(NSMutableDictionary *)streamInfo events:(NSMutableArray *)events error:(NSString *)errorMsg;

@end
