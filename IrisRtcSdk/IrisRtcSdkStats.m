//
//  IrisRtcSdkStats.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 10/7/16.
//  Copyright © 2016 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import "IrisRtcSdkStats.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "Reachability.h"

#import "WebRTCStatsCollector.h"
#import "WebRTCLogger.h"
#import "IrisRtcJingleSession.h"
#import "WebRTCUtil.h"
#import "XMPPWorker.h"
#import "IrisXMPPRoom.h"
#define DEFAULT_STATS_TIMEINTERVAL 5
#import "IrisLogging.h"
#import "WebRTCStatReport.h"

@interface IrisRtcSdkStats()<WebRTCStatsCollectorDelegate>

@property(nonatomic) NetworkTypes networkType;
@property(nonatomic, weak) id<IrisRtcSdkStatsDelegate> delegate;

@property(nonatomic, weak) IrisRtcJingleSession* session;
@property(nonatomic) WebRTCStatsCollector* statsCollector;
@property(nonatomic) WebRTCLogger* statsLogging;

@end

@interface IrisRtcJingleSession()


-(void)startMonitoringStats:(id)delegate;
-(void)onSessionParticipantConnected;

-(NSMutableArray *)getStats;

@end

@implementation IrisRtcSdkStats {
    BOOL postedStatsToServer;
    NSTimer *_statsTimer;
    WebRTCStatReport* lastSr;
    NSString* turnIPToStat;
    BOOL turnUsedToStat;
    BOOL isParticipantStreamReceived;
    RTCPeerConnection* peerConnection;
    IrisXMPPRoom* xmppRoom;
    NSString* roomName;
    NSMutableArray *sessionstats;
    NSDictionary *callSummaryDict;
    NSString* xmppServer;
    NSString* serviceId;
    NSString *rtcgid;
  //NSMutableArray *eventsArray;
    NSInteger eventArrayindex;
    NSInteger statstimerInterval;
    NSInteger statstimerCounter;
    BOOL resetStatsTimer;
    BOOL isLoggerCreated;
    //BOOL sendStatsIq;
    long metaId;
   
}
@synthesize IrisRtcSdkMetaData,eventsArray,sendStatsIq;


static NSString* kstatsServerURL = @"https://webrtcstats.g.comcast.net/iris-reference-client-logs";
static NSString* kstatsServerPassword = @"7wupre5pupa8r8nefebe8umbs5trura32q";

-(id)initWithSession:(IrisRtcJingleSession*)session  delegate:(id)delegate
{
    self = [super init];
    if (self!=nil) {
        self.delegate = delegate;
        self.session = session;
        isLoggerCreated = false;
        postedStatsToServer = false;
        lastSr = [[WebRTCStatReport alloc]init];
        eventsArray = [[NSMutableArray alloc]init];
        sessionstats = [[NSMutableArray alloc]init];
        eventArrayindex = 0;
        statstimerCounter = 1;
        resetStatsTimer = false;
        sendStatsIq = true;
        metaId = 1;
    }
    IRISLogInfo(@"IrisRtcSdkStats::initWithSession = %@",self);
    return self;
}

-(void)startMonitoringUsingInterval:(NSInteger)interval
{
    if(!sendStatsIq && !isLoggerCreated){
        isLoggerCreated = true;
        _statsLogging = [[WebRTCLogger alloc]initWithDefaultValue:kstatsServerURL _password:kstatsServerPassword _alias:[XMPPWorker sharedInstance].routingId];
        
        _statsLogging.isCallLogEnable = true;
        
    }
    IRISLogInfo(@"IrisRtcSdkStats::startMonitoringUsingInterval");
    statstimerInterval = interval;
    [self starttimer:10];
    [_session startMonitoringStats:self];
}

-(void)getStats{
    IRISLogInfo(@"IrisRtcSdkStats::getStats");
    if(!resetStatsTimer){
        if(statstimerCounter == DEFAULT_STATS_TIMEINTERVAL)
        {
            resetStatsTimer = true;
            [self starttimer:statstimerInterval];
        }else{
            statstimerCounter++;
       }
     }

    [self getStreamStatsTimer];
}



-(void)starttimer:(NSInteger)interval
{
       dispatch_async(dispatch_get_main_queue(), ^{
         IRISLogInfo(@"IrisRtcSdkStats::starttimer");
        if(_statsTimer != nil){
            [_statsTimer invalidate];
        }
        
           
        _statsTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                       target:self
                                                     selector:@selector(getStats)
                                                     userInfo:nil
                                                      repeats:YES
                       ];
    });
    
}


-(void)getStreamStatsTimer
{
    [peerConnection statsForTrack:nil statsOutputLevel:RTCStatsOutputLevelDebug
                completionHandler:^(NSArray<RTCStatsReport *> *stats)  {
                    if(stats != nil)
                        [lastSr parseReport:stats];
                    NSDictionary *turnInfo = @{ @"turnIP" :[lastSr turnServerIP]};
                    [_statsCollector storeReaccuring:roomName _statName:@"turnIP" _values:turnInfo];
                    turnInfo = @{ @"turnUsed" :[NSNumber numberWithBool:[WebRTCStatReport isTurnIPAvailable]]};
                    [_statsCollector storeReaccuring:roomName _statName:@"turnUsed" _values:turnInfo];
                    turnIPToStat = [lastSr turnServerIP];
                    turnUsedToStat = [WebRTCStatReport isTurnIPAvailable];        
                 
                  
                    [self.delegate onStats:[lastSr toJSON]];
                    
                    [sessionstats addObject: [lastSr toJSON]];
                  
                    if(sendStatsIq)
                    [self postStats];
                    
                    //To check  if first frame of  remote stream is received
                    if(lastSr.isBytesReceived && !isParticipantStreamReceived){
                        
                        isParticipantStreamReceived = true;
          
                   //     [_session onSessionParticipantConnected];
                    //    [self starttimer:statstimerinterval];
                        
                    }
                    
                    [_statsCollector storeReaccuring:@"streamInfo" _values:[lastSr toJSON]];
            
                    [lastSr streamStatArrayAlloc];
                    [lastSr resetParams];
           
                    
                } ];
}


-(void)stopMonitoring{

    IRISLogInfo(@"IrisRtcSdkStats::stopMonitoring");
    if(_statsTimer != nil)
        [_statsTimer invalidate];
    _statsTimer = nil;
   
    
    [self postFinalStats];
    

}

-(void)postStats{
   
    NSMutableDictionary* metadata = [[NSMutableDictionary alloc]init];
    [metadata setValue:SDK_VERSION forKey:@"sdkVersion"];
    [metadata setValue:@"iOS" forKey:@"sdkType"];
    [metadata setValue:[NSString stringWithFormat:@"%ld", metaId++] forKey:@"metaId"];
    NSMutableDictionary* streamInfo = [[NSMutableDictionary alloc]init];
   
    if(roomName != nil)[streamInfo setObject:roomName forKey:@"roomId"];
    if([XMPPWorker sharedInstance].routingId != nil)[streamInfo setObject:[XMPPWorker sharedInstance].routingId forKey:@"routingId"];
    if(serviceId !=nil)[streamInfo setObject:serviceId forKey:@"serviceId"];
    if(xmppServer != nil)[streamInfo setObject:xmppServer forKey:@"XMPPServer"];
    if(rtcgid != nil)[streamInfo setObject:rtcgid forKey:@"rtcgSessionId"];
   
    if(xmppRoom){
         [xmppRoom sendStats:metadata streamInfo:streamInfo eventsInfo:eventsArray timeSeries:[lastSr statsWS] callSummary:nil];
    }
    
}

-(void)postFinalStats{
    
    NSMutableDictionary* callSummary = [[NSMutableDictionary alloc]init];
    NSMutableDictionary* streamInfo1 = [[NSMutableDictionary alloc]init];
    NSMutableDictionary* streamInfo = [[NSMutableDictionary alloc]init];
    NSMutableDictionary* eventInfo = [[NSMutableDictionary alloc]init];
    
    streamInfo1 =  [_statsCollector streamInfo];
    
    NSString *startTime = [NSString stringWithFormat:@"%@", [streamInfo1 objectForKey:@"startTime"]];
    NSString *stopTime = [NSString stringWithFormat:@"%@",[streamInfo1 objectForKey:@"stopTime"]];
    NSString *duration = [NSString stringWithFormat:@"%@", [streamInfo1 objectForKey:@"duration"]];
    NSString *callType = [NSString stringWithFormat:@"%@",[callSummaryDict objectForKey:@"CallType"]];
    NSString *callDirection = [NSString stringWithFormat:@"%@",[callSummaryDict objectForKey:@"CallDirection"]];
    if([callSummaryDict objectForKey:@"callStatus"] != nil && [[callSummaryDict objectForKey:@"callStatus"] isEqualToString:@"Failure"]){
        [callSummary setObject:[callSummaryDict objectForKey:@"CallFailureReason"] forKey:@"callFailureReason"];
        [callSummary setObject:[callSummaryDict objectForKey:@"callStatus"] forKey:@"callStatus"];
    }else{
        [callSummary setObject:@"Success" forKey:@"callStatus"];
    }
    if(duration!=nil)[callSummary setObject:duration forKey:@"callDuration"];    
    if(callType!=nil)[streamInfo setObject:callType forKey:@"callType"];
    if(startTime != nil)[streamInfo setObject:startTime forKey:@"startTime"];
    if(stopTime != nil)[streamInfo setObject:stopTime forKey:@"stopTime"];
    if(callDirection!= nil)[streamInfo setObject:callDirection forKey:@"callDirection"];
    if(roomName != nil)[streamInfo setObject:roomName forKey:@"roomId"];
    if([XMPPWorker sharedInstance].routingId != nil)[streamInfo setObject:[XMPPWorker sharedInstance].routingId forKey:@"routingId"];
    if(serviceId !=nil)[streamInfo setObject:serviceId forKey:@"serviceId"];
    if(xmppServer != nil)[streamInfo setObject:xmppServer forKey:@"XMPPServer"];
    if(rtcgid != nil)[streamInfo setObject:rtcgid forKey:@"rtcgSessionId"];
    if(turnIPToStat != nil)[streamInfo setObject:turnIPToStat forKey:@"turnIP"];
    if([streamInfo1 objectForKey:@"duration"] == nil)
    {
        [streamInfo setObject:[NSNumber numberWithBool:YES] forKey:@"turnUsed"];
    }
    else
    {
        [streamInfo setObject:[NSNumber numberWithBool:turnUsedToStat] forKey:@"turnUsed"];
    }
    //stack
    //  if(traceId != nil)[streamInfo setObject:traceId forKey:@"traceId"];
    
    [eventInfo setObject:eventsArray forKey:@"group"];
    
    if(sendStatsIq){
      
        if(xmppRoom){
            [xmppRoom sendStats:[self getMetaData] streamInfo:streamInfo eventsInfo:eventsArray timeSeries:[lastSr statsWS] callSummary:callSummary ];
        }
    }else{
        if(!postedStatsToServer){
            [self.delegate onSummary:[lastSr stats] streamInfo:streamInfo metaData:[self getMetaData]];
            
            IRISLogInfo(@"Posting stats to server");
   
            
            [_statsLogging postStatsToServer:[self getMetaData] timeseries:[lastSr stats] streamInfo:streamInfo events:eventsArray error:@""];
            
            postedStatsToServer = true;
            
        }
    }
    
    IrisRtcSdkMetaData = nil;
    eventsArray = nil ;
    sendStatsIq = nil;
    _delegate = nil;
    _session = nil;
    _statsCollector = nil;
    _statsLogging = nil;
    
}

-(NSMutableDictionary*)getCallSummaryStats{
    
    NSMutableDictionary* callStats = [[NSMutableDictionary alloc]init];
    NSMutableDictionary* callSummary = [[NSMutableDictionary alloc]init];
    NSMutableDictionary* streamInfo1 = [[NSMutableDictionary alloc]init];
    NSMutableDictionary* streamInfo = [[NSMutableDictionary alloc]init];
    
    streamInfo1 =  [_statsCollector streamInfo];
    
    NSString *startTime = [NSString stringWithFormat:@"%@", [streamInfo1 objectForKey:@"startTime"]];
    NSString *stopTime = [NSString stringWithFormat:@"%@",[streamInfo1 objectForKey:@"stopTime"]];
    NSString *duration = [NSString stringWithFormat:@"%@", [streamInfo1 objectForKey:@"duration"]];
    NSString *callType = [NSString stringWithFormat:@"%@",[callSummaryDict objectForKey:@"CallType"]];
    NSString *callDirection = [NSString stringWithFormat:@"%@",[callSummaryDict objectForKey:@"CallDirection"]];
    if([callSummaryDict objectForKey:@"callStatus"] != nil && [[callSummaryDict objectForKey:@"callStatus"] isEqualToString:@"Failure"]){
        [callSummary setObject:[callSummaryDict objectForKey:@"CallFailureReason"] forKey:@"callFailureReason"];
        [callSummary setObject:[callSummaryDict objectForKey:@"callStatus"] forKey:@"callStatus"];
    }else{
        [callSummary setObject:@"Success" forKey:@"callStatus"];
    }
    if(duration!=nil)[callSummary setObject:duration forKey:@"callDuration"];
    if(callType!=nil)[streamInfo setObject:callType forKey:@"callType"];
    if(startTime != nil)[streamInfo setObject:startTime forKey:@"startTime"];
    if(stopTime != nil)[streamInfo setObject:stopTime forKey:@"stopTime"];
    if(callDirection!= nil)[streamInfo setObject:callDirection forKey:@"callDirection"];
    if(roomName != nil)[streamInfo setObject:roomName forKey:@"roomId"];
    if([XMPPWorker sharedInstance].routingId != nil)[streamInfo setObject:[XMPPWorker sharedInstance].routingId forKey:@"routingId"];
    if(serviceId !=nil)[streamInfo setObject:serviceId forKey:@"serviceId"];
    if(xmppServer != nil)[streamInfo setObject:xmppServer forKey:@"XMPPServer"];
    if(rtcgid != nil)[streamInfo setObject:rtcgid forKey:@"rtcgSessionId"];

    if(callSummary!=nil)[callStats setObject:callSummary forKey:@"callsummary"];
    if(streamInfo!=nil)[callStats setObject:streamInfo forKey:@"streaminfo"];
    
    return callStats;
}

-(void)setStatsIq:(BOOL)val {
    
    lastSr.isWSStats = val;
    
}

-(NSDictionary*)IrisRtcSdkMetaData
{
    return [self getMetaData];
}

-(NSMutableArray *)getstats{
    
    return sessionstats;
}

-(NSMutableDictionary*)getMetaData
{
    @synchronized(self) {
     IRISLogInfo(@"IrisRtcSdkStats::getMetaData");
    /*NSString* name = [[UIDevice currentDevice] name];
     NSString* systemName =  [[UIDevice currentDevice] systemName];
     NSString* systemVersion = [[UIDevice currentDevice] systemVersion];
     NSString* model =  [[UIDevice currentDevice] model];*/
    NSString* NetConType = [self getNetworkConnectionType ];
    NSMutableDictionary* metadata = [[NSMutableDictionary alloc]init];
    //SString *uniqueIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString* sdkVersion = [UIDevice currentDevice].systemVersion;
    //[metadata setValue:name forKey:@"name"];
    // [metadata setValue:systemName forKey:@"systemName"];
    // [metadata setValue:systemVersion forKey:@"systemVersion"];
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *result = [NSString stringWithCString:systemInfo.machine
                                          encoding:NSUTF8StringEncoding];
    NSString* modelType = nil;
    modelType = [self platformType1:result];
    
    [metadata setValue:SDK_VERSION forKey:@"sdkVersion"];
    [metadata setValue:modelType forKey:@"model"];
    [metadata setValue:@"Apple" forKey:@"manufacturer"];
    [metadata setValue:NetConType forKey:@"NetworkType"];
    [metadata setValue:sdkVersion forKey:@"iOSSDKVersion"];
    [metadata setValue:@"iOS" forKey:@"sdkType"];
    [metadata setValue:[NSString stringWithFormat:@"%ld", metaId++] forKey:@"metaId"];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = [bundle infoDictionary];
    NSString *prodName = [info objectForKey:@"CFBundleDisplayName"];
    [metadata setValue:prodName forKey:@"packageName"];
    //[metadata setValue:prodName forKey:@"alias"];
    return metadata;
    }
    
}

- (NSString *) platformType1:(NSString *)platform
{
    
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone 5c (GSM)";
    if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone 5c (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone 5s (GSM)";
    if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone 5s (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([platform isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([platform isEqualToString:@"iPhone8,1"])    return @"iPhone 6S";
    if ([platform isEqualToString:@"iPhone8,2"])    return @"iPhone 6S Plus";
    if ([platform isEqualToString:@"iPhone8,4"])    return @"iPhone SE";
    if ([platform isEqualToString:@"iPhone9,1"])    return @"iPhone 7 (CDMA)";
    if ([platform isEqualToString:@"iPhone9,3"])    return @"iPhone 7 (GSM)";
    if ([platform isEqualToString:@"iPhone9,2"])    return @"iPhone 7 Plus (CDMA)";
    if ([platform isEqualToString:@"iPhone9,4"])    return @"iPhone 7 Plus (GSM)";
    if ([platform isEqualToString:@"iPhone10,1"])    return @"iPhone 8 (CDMA)";
    if ([platform isEqualToString:@"iPhone10,2"])    return @"iPhone 8 Plus (CDMA)";
    if ([platform isEqualToString:@"iPhone10,5"])    return @"iPhone 8 Plus (GSM)";
    if ([platform isEqualToString:@"iPhone10,3"])    return @"iPhone X (CDMA)";
    if ([platform isEqualToString:@"iPhone10,6"])    return @"iPhone X (GSM)";
    if ([platform isEqualToString:@"iPhone11,2"])    return @"iPhone XS";
    if ([platform isEqualToString:@"iPhone11,4"])    return @"iPhone XS Max";
    if ([platform isEqualToString:@"iPhone11,6"])    return @"iPhone XS Max China";
    if ([platform isEqualToString:@"iPhone11,8"])    return @"iPhone XR";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini (GSM)";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3 (GSM)";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4 (GSM)";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad4,1"])      return @"iPad Air (WiFi)";
    if ([platform isEqualToString:@"iPad4,2"])      return @"iPad Air (Cellular)";
    if ([platform isEqualToString:@"iPad4,3"])      return @"iPad Air";
    if ([platform isEqualToString:@"iPad4,4"])      return @"iPad Mini 2G (WiFi)";
    if ([platform isEqualToString:@"iPad4,5"])      return @"iPad Mini 2G (Cellular)";
    if ([platform isEqualToString:@"iPad4,6"])      return @"iPad Mini 2G";
    if ([platform isEqualToString:@"iPad4,7"])      return @"iPad Mini (Wifi)";
    if ([platform isEqualToString:@"iPad6,7"])      return @"iPad Pro (12.9\")";
    if ([platform isEqualToString:@"iPad6,3"])      return @"iPad Pro (9.7\")";
    if ([platform isEqualToString:@"iPad6,4"])      return @"iPad Pro (9.7\")";
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
    return platform;
}


-(NSString*)getNetworkConnectionType
{
 //   NSArray *subviews = [[[[UIApplication sharedApplication] valueForKey:@"UIStatusBar_Modern"] valueForKey:@"foregroundView"]subviews];
//    NSArray *subviews ;
//    NSNumber *dataNetworkItemView = nil;
//
//    if ([[[UIApplication sharedApplication] valueForKeyPath:@"_statusBar"] isKindOfClass:NSClassFromString(@"UIStatusBar_Modern")]) {
//        subviews = [[[[[UIApplication sharedApplication] valueForKeyPath:@"_statusBar"] valueForKeyPath:@"_statusBar"] valueForKeyPath:@"foregroundView"] subviews];
//    } else {
//        subviews = [[[[UIApplication sharedApplication] valueForKeyPath:@"_statusBar"] valueForKeyPath:@"foregroundView"] subviews];
//    }
//
//
//    for (id subview in subviews) {
//        if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
//            dataNetworkItemView = subview;
//            break;
//        }
//    }
//    NSString* type;
//
//    switch ([[dataNetworkItemView valueForKey:@"dataNetworkType"]integerValue]) {
//        case 0:
//            type=@"No Wifi/Cellular connection";
//            _networkType = nonetwork;
//            break;
//
//        case 1:
//            type=@"2G";
//            _networkType = cellular2g;
//            break;
//
//        case 2:
//            type=@"3G";
//            _networkType = cellular3g;
//            break;
//
//        case 3:
//            type=@"4G";
//            _networkType = cellular4g;
//            break;
//
//        case 4:
//            type=@"LTE";
//            _networkType =  cellularLTE;
//            break;
//
//        case 5:
//            type=@"Wifi";
//            _networkType = wifi;
//            break;
//
//        default:
//            type=@"Not found !!";
//            break;
//    }
//    NSLog(@"type %@",type);
//    return type;
    
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [reachability currentReachabilityStatus];
    NSString *type=@"";
    if(status == NotReachable)
    {
        type=@"No Wifi/Cellular connection";
    }
    else if (status == ReachableViaWiFi)
    {
        type=@"Wifi";
    }
    else if (status == ReachableViaWWAN)
    {
        CTTelephonyNetworkInfo *telephonyInfo = [CTTelephonyNetworkInfo new];
        NSString *connectionType = telephonyInfo.currentRadioAccessTechnology;
        if(connectionType != nil){
            if (([connectionType isEqualToString:CTRadioAccessTechnologyGPRS])
                ||([connectionType isEqualToString:CTRadioAccessTechnologyEdge])
                ||([connectionType isEqualToString:CTRadioAccessTechnologyCDMA1x]))
            {
                type=@"2G";
            }
            else if (([connectionType isEqualToString:CTRadioAccessTechnologyWCDMA])
                     ||([connectionType isEqualToString:CTRadioAccessTechnologyHSDPA])
                     ||([connectionType isEqualToString:CTRadioAccessTechnologyHSUPA])
                     ||([connectionType isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0])
                     ||([connectionType isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA])
                     ||([connectionType isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB])
                     ||([connectionType isEqualToString:CTRadioAccessTechnologyeHRPD]))
            {
                type=@"3G";
            }
            else if ([connectionType isEqualToString:CTRadioAccessTechnologyLTE])
            {
                type=@"4G";
            }
        }
    }   
    return type;
}

# pragma mark IrisRtcSdkSesionStatsDelegate delegate methods
- (void)IrisRtcSession:(IrisRtcJingleSession *)sdkStats onSdkStatsDuringActiveSession:(NSDictionary *)sessionStats{
  
    [self.delegate onStats:sessionStats];
    
}



- (void)IrisRtcSession:(IrisRtcJingleSession *)sdkStats onCompleteSessionStatsWithTimeseries:(NSMutableDictionary*)sessionTimeseries streamInfo:(NSMutableDictionary*)streamInfo eventInfo:(NSMutableArray *)eventinfo{
    if(!sendStatsIq){
    if(!postedStatsToServer){
       
        [self.delegate onSummary:sessionTimeseries streamInfo:streamInfo metaData:[self getMetaData]];
        
        IRISLogInfo(@"IrisRtcSession::posting stats to server");
        [_statsLogging postStatsToServer:[self getMetaData] timeseries:sessionTimeseries streamInfo:streamInfo events:eventinfo error:@""];
        
        postedStatsToServer = true;
        
    }
    }
    
}

- (void)onPeerConnection:(RTCPeerConnection*)peerconnection statscollector:(WebRTCStatsCollector*)statscollector roomname:(NSString*)roomname irisRoom:(IrisXMPPRoom *)irisroom{
    
    roomName = roomname;
    peerConnection = peerconnection;
    _statsCollector = statscollector;
    xmppRoom = irisroom;
}


- (void)onLogEvents:(NSDictionary *)event callSummary:(NSDictionary*)callsummary{

    callSummaryDict = callsummary;
    [eventsArray setObject:event atIndexedSubscript:eventArrayindex];
    eventArrayindex++;
}


# pragma mark WebRTCStatsCollectorDelegate delegate methods

-(void) onUpdateStats:(NSString*) statKey _statValue:(id)statsValue{
    
    NSMutableDictionary *stats = [[NSMutableDictionary alloc]init];
    [stats setObject:statsValue forKey:@"value"];
    [stats setObject:statKey forKey:@"key"];
   
    [self.delegate onStats:stats];
}

-(void) onAppendStats:(NSString*) statKey _statValue:(id)statsValue{
    
}


@end


