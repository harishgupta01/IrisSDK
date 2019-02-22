//
//  WebRTCStatReport.m
//  IrisRtcSdk
//
//  Created by Girish on 14/03/18.
//  Copyright © 2018 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
//
//  WebRTCStatReport.m
//  xfinity-webrtc-sdk
//
//  Created by Pankaj on 17/07/14.
//  Copyright (c) 2014 Comcast. All rights reserved.
//

#import "WebRTCStatReport.h"
#import "WebRTC/WebRTC.h"

int timeCounter11 = 10;


@interface WebRTCStatReport ()
@property(nonatomic ) NSString* txVideoID;
@property(nonatomic ) NSString* rxVideoID;
@property(nonatomic ) NSString* txAudioID;
@property(nonatomic ) NSString* rxAudioID;
@property(nonatomic ) NSString* txAudioCodecName;
@property(nonatomic ) NSString* txVideoCodecName;
@property(nonatomic ) NSString* rxAudioCodecName;
@property(nonatomic ) NSString* rxVideoCodecName;
@property(nonatomic ) BOOL isInitDone;
@property(nonatomic ) NSMutableArray* streamStatsArray;
@property(nonatomic ) NSMutableArray* receiveBandwidthArray ;
@property(nonatomic ) NSMutableArray* sendBandwidthArray;
@property(nonatomic ) NSMutableArray* transmitBitrate;
@property(nonatomic ) NSMutableArray* timeStamp;//Added
@property(nonatomic ) NSMutableArray* googActualEncBitrate;
@property(nonatomic ) NSMutableArray* googRetransmitBitrate;

@property(nonatomic ) NSMutableArray* rxVideoBytesReceived;//
@property(nonatomic ) NSMutableArray* rxVideoCurrentDelayMs;
@property(nonatomic ) NSMutableArray* rxVideoFrameHeightReceived;
@property(nonatomic ) NSMutableArray* rxVideoFrameRateReceived;
@property(nonatomic ) NSMutableArray* rxVideoFrameWidthReceived;
@property(nonatomic ) NSMutableArray* rxVideoPacketsLost;
@property(nonatomic ) NSMutableArray* rxVideoPacketsReceived;// Added
@property(nonatomic ) NSMutableArray* rxVideogoogCaptureStartNtpTimeMs;
@property(nonatomic ) NSMutableArray* rxVideogoogDecodeMs;
@property(nonatomic ) NSMutableArray* rxVideogoogFirsSent ;
@property(nonatomic ) NSMutableArray* rxVideogoogFrameRateDecoded;
@property(nonatomic ) NSMutableArray* rxVideogoogFrameRateOutput;
@property(nonatomic ) NSMutableArray* rxVideogoogJitterBufferMs;
@property(nonatomic ) NSMutableArray* rxVideogoogMaxDecodeMs;
@property(nonatomic ) NSMutableArray* rxVideogoogMinPlayoutDelayMs;
@property(nonatomic ) NSMutableArray* rxVideogoogNacksSent;
@property(nonatomic ) NSMutableArray* rxVideogoogPlisSent;
@property(nonatomic ) NSMutableArray* rxVideogoogRenderDelayMs;
@property(nonatomic ) NSMutableArray* rxVideogoogTargetDelayMs;

@property(nonatomic ) NSMutableArray* rxAudioOutputLevel;//
@property(nonatomic ) NSMutableArray* rxAudioBytesReceived;
@property(nonatomic ) NSMutableArray* rxAudioPacketsLost;
@property(nonatomic ) NSMutableArray* rxAudioPacketsReceived;//Added
@property(nonatomic ) NSMutableArray* rxAudiogoogCaptureStartNtpTimeMs;
@property(nonatomic ) NSMutableArray* rxAudiogoogCurrentDelayMs;
@property(nonatomic ) NSMutableArray* rxAudiogoogDecodingCNG;
@property(nonatomic ) NSMutableArray* rxAudiogoogDecodingCTN;
@property(nonatomic ) NSMutableArray* rxAudiogoogDecodingCTSG;
@property(nonatomic ) NSMutableArray* rxAudiogoogDecodingNormal;
@property(nonatomic ) NSMutableArray* rxAudiogoogDecodingPLC;
@property(nonatomic ) NSMutableArray* rxAudiogoogDecodingPLCCNG;
@property(nonatomic ) NSMutableArray* rxAudiogoogExpandRate;
@property(nonatomic ) NSMutableArray* rxAudiogoogJitterBufferMs;
@property(nonatomic ) NSMutableArray* rxAudiogoogJitterReceived;
@property(nonatomic ) NSMutableArray* rxAudiogoogPreferredJitterBufferMs;
//@property(nonatomic ) NSMutableArray* rxAudiogoogAccelerateRate;
//@property(nonatomic ) NSMutableArray* rxAudiogoogPreemptiveExpandRate;
//@property(nonatomic ) NSMutableArray* rxAudiogoogSecondaryDecodedRate;
//@property(nonatomic ) NSMutableArray* rxAudiogoogSpeechExpandRate;

@property(nonatomic ) NSMutableArray* txVideoBytesSent;//
@property(nonatomic ) NSMutableArray* txVideoEncodeUsagePercent;
@property(nonatomic ) NSMutableArray* txVideoFrameHeightSent;
@property(nonatomic ) NSMutableArray* txVideoFrameRateSent;
@property(nonatomic ) NSMutableArray* txVideoFrameWidthSent;
@property(nonatomic ) NSMutableArray* txVideoRtt;
@property(nonatomic ) NSMutableArray* txVideoPacketsLost;
@property(nonatomic ) NSMutableArray* txVideoPacketsSent;//Added
@property(nonatomic ) NSMutableArray* txVideogoogAdaptationChanges;
@property(nonatomic ) NSMutableArray* txVideogoogAvgEncodeMs;
@property(nonatomic ) NSMutableArray* txVideogoogFirsReceived;
@property(nonatomic ) NSMutableArray* txVideogoogFrameHeightInput;
@property(nonatomic ) NSMutableArray* txVideogoogFrameRateInput;
@property(nonatomic ) NSMutableArray* txVideogoogFrameWidthInput;
@property(nonatomic ) NSMutableArray* txVideogoogNacksReceived;
@property(nonatomic ) NSMutableArray* txVideogoogPlisReceived;

@property(nonatomic ) NSMutableArray* txAudioInputLevel;//
@property(nonatomic ) NSMutableArray* txAudioBytesSent;
@property(nonatomic ) NSMutableArray* txAudioPacketsLost;
@property(nonatomic ) NSMutableArray* txAudioPacketsSent; //Added
@property(nonatomic ) NSMutableArray* txAudiogoogEchoCancellationQualityMin;
@property(nonatomic ) NSMutableArray* txAudiogoogEchoCancellationEchoDelayMedian;
@property(nonatomic ) NSMutableArray* txAudiogoogEchoCancellationEchoDelayStdDev;
@property(nonatomic ) NSMutableArray* txAudiogoogEchoCancellationReturnLoss;
@property(nonatomic ) NSMutableArray* txAudiogoogEchoCancellationReturnLossEnhancement;
@property(nonatomic ) NSMutableArray* txAudiogoogJitterReceived;
@property(nonatomic ) NSMutableArray* txAudiogoogRtt;

@property(nonatomic ) BOOL istxAudioPacketsLost;
@property(nonatomic ) BOOL istxAudiogoogJitterReceived;
@property(nonatomic ) BOOL istxAudiogoogRtt;
@property(nonatomic ) BOOL isrxAudiogoogCaptureStartNtpTimeMs;



@property(nonatomic ) NSInteger arrayIndex;

@end

static BOOL isTurnIPAvailable;

@implementation WebRTCStatReport
@synthesize bytesSent;
@synthesize sendFrameRate;
@synthesize sendWidth;
@synthesize sendHeight;
@synthesize sendBandwidth;
@synthesize recvBandwidth;
@synthesize timesstamp;
@synthesize rtt;
@synthesize packetLossSent;
@synthesize totalPacketSent;
@synthesize packetLossRecv;
@synthesize totalPacketRecv;
@synthesize  turnServerIP;
@synthesize generalFlag;
@synthesize rxAudioFlag;
@synthesize rxVideoFlag;
@synthesize txAudioFlag;
@synthesize txVideoFlag;
@synthesize dateFormatter,isoDateFormatter;
@synthesize istxAudioPacketsLost;
@synthesize istxAudiogoogJitterReceived;
@synthesize istxAudiogoogRtt;
@synthesize isrxAudiogoogCaptureStartNtpTimeMs;
@synthesize isBytesReceived;
@synthesize isWSStats;


-(id)init
{
    self = [super init];
    if (self!=nil) {
        
        _txVideoID = nil;
        _rxVideoID = nil;
        _txAudioID = nil;
        _rxAudioID = nil;
        _isInitDone = false;
        isTurnIPAvailable = false;
        turnServerIP = @"";
        rtt = 0;
        totalPacketSent = 0;
        packetLossSent = 0;
        generalFlag = false;
        rxAudioFlag = false;
        rxVideoFlag = false;
        txAudioFlag = false;
        txVideoFlag = false ;
        istxAudioPacketsLost      = false;
        istxAudiogoogJitterReceived = false;
        istxAudiogoogRtt = false;
        isBytesReceived = false;
        isWSStats = true;
        isrxAudiogoogCaptureStartNtpTimeMs = false;
        _streamStatsArray = [[NSMutableArray alloc]init];
        _receiveBandwidthArray  = [NSMutableArray array];
        _sendBandwidthArray     = [NSMutableArray array];
        _transmitBitrate        = [NSMutableArray array];
        _timeStamp              = [NSMutableArray array];//Added
        _googActualEncBitrate      = [NSMutableArray array];
        _googRetransmitBitrate      = [NSMutableArray array];
        
        _rxVideoBytesReceived   = [NSMutableArray array];
        _rxVideoCurrentDelayMs  = [NSMutableArray array];
        _rxVideoFrameHeightReceived = [NSMutableArray array];
        _rxVideoFrameRateReceived   = [NSMutableArray array];
        _rxVideoFrameWidthReceived  = [NSMutableArray array];
        _rxVideoPacketsLost         = [NSMutableArray array];
        _rxVideoPacketsReceived     = [NSMutableArray array];//Added
        _rxVideogoogCaptureStartNtpTimeMs  = [NSMutableArray array];
        
        _rxVideogoogDecodeMs  = [NSMutableArray array];
        _rxVideogoogFirsSent   = [NSMutableArray array];
        
        _rxVideogoogFrameRateDecoded  = [NSMutableArray array];
        _rxVideogoogFrameRateOutput  = [NSMutableArray array];
        
        
        _rxVideogoogJitterBufferMs  = [NSMutableArray array];
        _rxVideogoogMaxDecodeMs  = [NSMutableArray array];
        _rxVideogoogMinPlayoutDelayMs  = [NSMutableArray array];
        _rxVideogoogNacksSent  = [NSMutableArray array];
        _rxVideogoogPlisSent  = [NSMutableArray array];
        _rxVideogoogRenderDelayMs  = [NSMutableArray array];
        _rxVideogoogTargetDelayMs  = [NSMutableArray array];
        
        _rxAudioOutputLevel         = [NSMutableArray array];//
        _rxAudioBytesReceived       = [NSMutableArray array];
        _rxAudioPacketsLost         = [NSMutableArray array];
        _rxAudioPacketsReceived     = [NSMutableArray array];//Added
        
        _rxAudiogoogPreferredJitterBufferMs = [NSMutableArray array];
        _rxAudiogoogCaptureStartNtpTimeMs = [NSMutableArray array];
        _rxAudiogoogCurrentDelayMs = [NSMutableArray array];
        _rxAudiogoogDecodingCNG = [NSMutableArray array];
        _rxAudiogoogDecodingCTN = [NSMutableArray array];
        _rxAudiogoogDecodingCTSG = [NSMutableArray array];
        _rxAudiogoogDecodingNormal = [NSMutableArray array];
        _rxAudiogoogDecodingPLC = [NSMutableArray array];
        _rxAudiogoogDecodingPLCCNG = [NSMutableArray array];
        _rxAudiogoogExpandRate = [NSMutableArray array];
        _rxAudiogoogJitterBufferMs = [NSMutableArray array];
        _rxAudiogoogJitterReceived = [NSMutableArray array];
        //        _rxAudiogoogAccelerateRate = [NSMutableArray array];
        //        _rxAudiogoogPreemptiveExpandRate = [NSMutableArray array];
        //        _rxAudiogoogSecondaryDecodedRate = [NSMutableArray array];
        //        _rxAudiogoogSpeechExpandRate = [NSMutableArray array];
        
        _txVideoBytesSent           = [NSMutableArray array];//
        _txVideoEncodeUsagePercent  = [NSMutableArray array];
        _txVideoFrameHeightSent     = [NSMutableArray array];
        _txVideoFrameRateSent       = [NSMutableArray array];
        _txVideoFrameWidthSent      = [NSMutableArray array];
        _txVideoRtt                 = [NSMutableArray array];
        _txVideoPacketsLost         = [NSMutableArray array];
        _txVideoPacketsSent         = [NSMutableArray array];//Added
        _txVideogoogAdaptationChanges = [NSMutableArray array];
        _txVideogoogAvgEncodeMs = [NSMutableArray array];
        _txVideogoogFirsReceived = [NSMutableArray array];
        _txVideogoogFrameHeightInput = [NSMutableArray array];
        _txVideogoogFrameRateInput = [NSMutableArray array];
        _txVideogoogFrameWidthInput = [NSMutableArray array];
        _txVideogoogNacksReceived = [NSMutableArray array];
        _txVideogoogPlisReceived = [NSMutableArray array];
        
        _txAudioInputLevel          = [NSMutableArray array];//
        _txAudioBytesSent           = [NSMutableArray array];
        _txAudioPacketsSent         = [NSMutableArray array];
        _txAudioPacketsLost         = [NSMutableArray array]; //Added
        _txAudiogoogEchoCancellationQualityMin  =[NSMutableArray array];
        _txAudiogoogEchoCancellationEchoDelayMedian =[NSMutableArray array];
        _txAudiogoogEchoCancellationEchoDelayStdDev = [NSMutableArray array];
        _txAudiogoogEchoCancellationReturnLoss =[NSMutableArray array];
        _txAudiogoogEchoCancellationReturnLossEnhancement =[NSMutableArray array];
        _txAudiogoogJitterReceived =[NSMutableArray array];
        _txAudiogoogRtt =[NSMutableArray array];
        
        _arrayIndex = 0;
        
        [_txAudiogoogJitterReceived removeAllObjects];
        [_txAudiogoogRtt removeAllObjects];
        [_txAudioPacketsLost removeAllObjects];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        
        isoDateFormatter = [[NSDateFormatter alloc] init];
        NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        [isoDateFormatter setTimeZone:timeZone];
        [isoDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        
    }
    
    return self;
}

-(void)initIDForSSRC:(NSArray*)reports
{
    
    for(RTCStatsReport* report in reports)
    {
        NSString* type = report.type;
        
        if (![type compare:@"ssrc"])
        {
            NSDictionary* pairs = report.values;
            
            
            for(id key in pairs)
            {
                
                NSString* type = [pairs objectForKey:key];
                
                if(![key compare:@"googFrameRateReceived"])
                {
                    _rxVideoID = report.reportId;
                }
                else if(![key compare:@"googFrameRateSent"])
                {
                    _txVideoID = report.reportId;
                }
                else if(![key compare:@"audioOutputLevel"])
                {
                    _rxAudioID = report.reportId;
                }
                else if(![key compare:@"audioInputLevel"])
                {
                    _txAudioID = report.reportId;
                }
            }
            
        }
    }
    
}


-(NSMutableDictionary*)getTxAudioStat:(NSDictionary*)pairs
{
    NSMutableDictionary* obj = [[NSMutableDictionary alloc]init];
    [obj setValue:@"TxAudio" forKey:@"id"];
    
    for(id key in pairs)
    {
        //obj = [[NSMutableDictionary alloc]init];
        NSNumber *aWrappedInt = nil;
        NSString* type = key;
        
        if(![type compare:@"bytesSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"bytesSent"];
            [_txAudioBytesSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"audioInputLevel"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"audioInputLevel"];
            [_txAudioInputLevel setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"packetsSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsSent"];
            [_txAudioPacketsSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"packetsLost"])
        {
            
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsLost"];
            if ((_txAudiogoogRtt.count == 0 && _arrayIndex == 0) || istxAudioPacketsLost)
            {
                [_txAudioPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
                istxAudioPacketsLost=YES;
            }
            else{
                if(_txAudiogoogRtt.count == _arrayIndex){
                    [_txAudioPacketsLost setObject:aWrappedInt atIndexedSubscript:(_arrayIndex-1)];
                }else{
                    [_txAudioPacketsLost setObject:aWrappedInt atIndexedSubscript:_txAudioPacketsLost.count];
                }
            }
            
        }
        else if(![type compare:@"googEchoCancellationQualityMin"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationQualityMin"];
            [_txAudiogoogEchoCancellationQualityMin  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googEchoCancellationEchoDelayMedian"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationEchoDelayMedian"];
            [_txAudiogoogEchoCancellationEchoDelayMedian  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googEchoCancellationEchoDelayStdDev"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationEchoDelayStdDev"];
            [_txAudiogoogEchoCancellationEchoDelayStdDev  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googEchoCancellationReturnLoss"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationReturnLoss"];
            [_txAudiogoogEchoCancellationReturnLoss  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googEchoCancellationReturnLossEnhancement"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationReturnLossEnhancement"];
            [_txAudiogoogEchoCancellationReturnLossEnhancement  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googJitterReceived"])
        {
            
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googJitterReceived"];
            
            
            if (( _txAudiogoogJitterReceived.count == 0 && _arrayIndex == 0 )|| istxAudiogoogJitterReceived)
            {
                [_txAudiogoogJitterReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
                istxAudiogoogJitterReceived = YES;
                
            }
            else{
                if(_txAudiogoogJitterReceived.count == _arrayIndex){
                    [_txAudiogoogJitterReceived setObject:aWrappedInt atIndexedSubscript:(_arrayIndex-1)];
                }else{
                    [_txAudiogoogJitterReceived setObject:aWrappedInt atIndexedSubscript:_txAudiogoogJitterReceived.count];
                }
            }
            
        }
        else if(![type compare:@"googCodecName"])
        {
            _txAudioCodecName = [pairs objectForKey:key];
            [obj setValue:_txAudioCodecName forKey:@"googCodecType"];
        }
        else if(![type compare:@"googRtt"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googRtt"];
            
            
            if (( _txAudiogoogRtt.count == 0 && _arrayIndex == 0 )|| istxAudiogoogRtt)
            {
                [_txAudiogoogRtt setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
                istxAudiogoogRtt = YES;
                
            }
            else{
                
                
                if(_txAudiogoogRtt.count == _arrayIndex){
                    [_txAudiogoogRtt setObject:aWrappedInt atIndexedSubscript:(_arrayIndex-1)];
                }else{
                    [_txAudiogoogRtt setObject:aWrappedInt atIndexedSubscript:_txAudiogoogRtt.count];
                }
            }
        }
        
    }
    
    return obj;
}

-(NSMutableDictionary*)getTxVideoStat:(NSDictionary*)pairs
{
    
    NSMutableDictionary* obj = [[NSMutableDictionary alloc]init];
    [obj setValue:@"TxVideo" forKey:@"id"];
    
    for(id key in pairs)
    {
        //obj = [[NSMutableDictionary alloc]init];
        NSNumber *aWrappedInt = nil;
        NSString* type = key;
        
        if(![type compare:@"bytesSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"bytesSent"];
            [_txVideoBytesSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"packetsSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsSent"];
            [_txVideoPacketsSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googFrameHeightSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googFrameHeightSent"];
            [_txVideoFrameHeightSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googFrameWidthSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googFrameWidthSent"];
            [_txVideoFrameWidthSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googFrameRateSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googFrameRateSent"];
            [_txVideoFrameRateSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googEncodeUsagePercent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googEncodeUsagePercent"];
            [_txVideoEncodeUsagePercent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googRtt"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            rtt = [aWrappedInt integerValue];
            if(rtt < 0)
                rtt = 0;
            //rtt = aWrappedInt;
            [obj setValue:aWrappedInt forKey:@"googRtt"];
            [_txVideoRtt setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"packetsLost"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            packetLossSent = [aWrappedInt integerValue];
            if(packetLossSent < 0)
                packetLossSent = 0;
            [obj setValue:aWrappedInt forKey:@"packetsLost"];
            [_txVideoPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googAdaptationChanges"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googAdaptationChanges"];
            [_txVideogoogAdaptationChanges setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googAvgEncodeMs"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googAvgEncodeMs"];
            [_txVideogoogAvgEncodeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googFirsReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googFirsReceived"];
            [_txVideogoogFirsReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googFrameHeightInput"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googFrameHeightInput"];
            [_txVideogoogFrameHeightInput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googFrameRateInput"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googFrameRateInput"];
            [_txVideogoogFrameRateInput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        
        else if(![type compare:@"googFrameWidthInput"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googFrameWidthInput"];
            [_txVideogoogFrameWidthInput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        
        else if(![type compare:@"googNacksReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googNacksReceived"];
            [_txVideogoogNacksReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googCodecName"])
        {
            _txVideoCodecName = [pairs objectForKey:key];
            [obj setValue:_txVideoCodecName forKey:@"googCodecType"];
        }
        else if(![type compare:@"googPlisReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googPlisReceived"];
            [_txVideogoogPlisReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
    }
    
    return obj;
    
    
}

-(NSMutableDictionary*)getRxAudioStat:(NSDictionary*)pairs
{
    
    NSMutableDictionary* obj = [[NSMutableDictionary alloc]init];
    [obj setValue:@"RxAudio" forKey:@"id"];
    
    for(id key in pairs)
    {
        //obj = [[NSMutableDictionary alloc]init];
        NSNumber *aWrappedInt = nil;
        NSString* type = key;
        
        if(![type compare:@"bytesReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"bytesReceived"];
            [_rxAudioBytesReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"audioOutputLevel"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"audioOutputLevel"];
            [_rxAudioOutputLevel setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"packetsReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsReceived"];
            [_rxAudioPacketsReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"packetsLost"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsLost"];
            [_rxAudioPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googCaptureStartNtpTimeMs"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googCaptureStartNtpTimeMs"];
            
            if (isWSStats) {
                [_rxAudiogoogCaptureStartNtpTimeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
            }
            else {
            
                if (( _rxAudiogoogCaptureStartNtpTimeMs.count == 0 && _arrayIndex == 0 )|| isrxAudiogoogCaptureStartNtpTimeMs)
                {
                    [_rxAudiogoogCaptureStartNtpTimeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
                    isrxAudiogoogCaptureStartNtpTimeMs = YES;
                 
                }
                else{
                    if(_rxAudiogoogCaptureStartNtpTimeMs.count == _arrayIndex){
                        [_rxAudiogoogCaptureStartNtpTimeMs setObject:aWrappedInt atIndexedSubscript:(_arrayIndex-1)];
                    }else{
                        [_rxAudiogoogCaptureStartNtpTimeMs setObject:aWrappedInt atIndexedSubscript:_rxAudiogoogCaptureStartNtpTimeMs.count];
                    }
                }
            }
            
        }
        else if(![type compare:@"googCurrentDelayMs"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googCurrentDelayMs"];
            [_rxAudiogoogCurrentDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googDecodingCNG"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googDecodingCNG"];
            [_rxAudiogoogDecodingCNG setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googDecodingCTN"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googDecodingCTN"];
            [_rxAudiogoogDecodingCTN setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googDecodingCTSG"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googDecodingCTSG"];
            [_rxAudiogoogDecodingCTSG setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googDecodingNormal"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googDecodingNormal"];
            [_rxAudiogoogDecodingNormal setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googDecodingPLC"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googDecodingPLC"];
            [_rxAudiogoogDecodingPLC setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googDecodingPLCCNG"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googDecodingPLCCNG"];
            [_rxAudiogoogDecodingPLCCNG setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googExpandRate"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googExpandRate"];
            [_rxAudiogoogExpandRate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googJitterBufferMs"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googJitterBufferMs"];
            [_rxAudiogoogJitterBufferMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googJitterReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googJitterReceived"];
            [_rxAudiogoogJitterReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googPreferredJitterBufferMs"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googPreferredJitterBufferMs"];
            [_rxAudiogoogPreferredJitterBufferMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googCodecName"])
        {
            _rxAudioCodecName = [pairs objectForKey:key];
            [obj setValue:_rxAudioCodecName forKey:@"googCodecType"];
        }
        //         else if(![type compare:@"googPreemptiveExpandRate"])
        //         {
        //             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
        //             [obj setValue:aWrappedInt forKey:@"googPreemptiveExpandRate"];
        //             [_rxAudiogoogPreemptiveExpandRate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        //         }
        //         else if(![type compare:@"googSecondaryDecodedRate"])
        //         {
        //             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
        //             [obj setValue:aWrappedInt forKey:@"googSecondaryDecodedRate"];
        //             [_rxAudiogoogSecondaryDecodedRate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        //         }
        //         else if(![type compare:@"googAccelerateRate"])
        //         {
        //             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
        //             [obj setValue:aWrappedInt forKey:@"googAccelerateRate"];
        //             [_rxAudiogoogAccelerateRate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        //         }
        //         else if(![type compare:@"googSpeechExpandRate"])
        //         {
        //             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
        //             [obj setValue:aWrappedInt forKey:@"googSpeechExpandRate"];
        //             [_rxAudiogoogSpeechExpandRate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        //         }
    }
    
    return obj;
    
    
    
}

-(NSMutableDictionary*)getRxVideoStat:(NSDictionary*)pairs
{
    NSMutableDictionary* obj = [[NSMutableDictionary alloc]init];
    [obj setValue:@"RxVideo" forKey:@"id"];
    
    for(id key in pairs)
    {
        //obj = [[NSMutableDictionary alloc]init];
        NSNumber *aWrappedInt = nil;
        NSString* type = key;
        
        if(![type compare:@"bytesReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            if([aWrappedInt intValue] > 0){
                
                isBytesReceived = true;
            }
            
            [obj setValue:aWrappedInt forKey:@"bytesReceived"];
            [_rxVideoBytesReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"packetsReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsReceived"];
            [_rxVideoPacketsReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];        }
        else if(![type compare:@"googFrameHeightReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googFrameHeightReceived"];
            [_rxVideoFrameHeightReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];         }
        else if(![type compare:@"googFrameWidthReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googFrameWidthReceived"];
            [_rxVideoFrameWidthReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googFrameRateReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googFrameRateReceived"];
            [_rxVideoFrameRateReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googCurrentDelayMs"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googCurrentDelayMs"];
            [_rxVideoCurrentDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"packetsLost"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            packetLossRecv = [aWrappedInt integerValue];
            if(packetLossRecv < 0)
                packetLossRecv = 0;
            [obj setValue:aWrappedInt forKey:@"packetsLost"];
            [_rxVideoPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
            
        }
        else if(![type compare:@"googCaptureStartNtpTimeMs"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googCaptureStartNtpTimeMs"];
            [_rxVideogoogCaptureStartNtpTimeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googDecodeMs"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googDecodeMs"];
            [_rxVideogoogDecodeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googFirsSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googFirsSent"];
            [_rxVideogoogFirsSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googFrameRateDecoded"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googFrameRateDecoded"];
            [_rxVideogoogFrameRateDecoded setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googFrameRateOutput"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googFrameRateOutput"];
            [_rxVideogoogFrameRateOutput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googJitterBufferMs"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googJitterBufferMs"];
            [_rxVideogoogJitterBufferMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googMaxDecodeMs"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googMaxDecodeMs"];
            [_rxVideogoogMaxDecodeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googMinPlayoutDelayMs"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googMinPlayoutDelayMs"];
            [_rxVideogoogMinPlayoutDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googNacksSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googNacksSent"];
            [_rxVideogoogNacksSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googPlisSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googPlisSent"];
            [_rxVideogoogPlisSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googRenderDelayMs"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googRenderDelayMs"];
            [_rxVideogoogRenderDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googCodecName"])
        {
            _rxVideoCodecName = [pairs objectForKey:key];
            [obj setValue:_rxVideoCodecName forKey:@"googCodecType"];
        }
        else if(![type compare:@"googTargetDelayMs"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googTargetDelayMs"];
            [_rxVideogoogTargetDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
    }
    
    return obj;
}


-(NSMutableDictionary*)getGeneralStat:(NSDictionary*)pairs
{
    NSMutableDictionary* obj = [[NSMutableDictionary alloc]init];
    [obj setValue:@"General" forKey:@"id"];
    
    for(id key in pairs)
    {
        //obj = [[NSMutableDictionary alloc]init];
        NSNumber *aWrappedInt = nil;
        NSString* type = key;
        
        if(![type compare:@"googAvailableSendBandwidth"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            sendBandwidth = [aWrappedInt integerValue];
            [obj setValue:aWrappedInt forKey:@"googAvailableSendBandwidth"];
            [_sendBandwidthArray setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googTransmitBitrate"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googTransmitBitrate"];
            [_transmitBitrate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googAvailableReceiveBandwidth"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            recvBandwidth = [aWrappedInt integerValue];
            [_receiveBandwidthArray setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
            [obj setValue:aWrappedInt forKey:@"googAvailableReceiveBandwidth"];
        }
        else if(![type compare:@"packetsLost"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsLost"];
        }
        else if(![type compare:@"googActualEncBitrate"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [_googActualEncBitrate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
            [obj setValue:aWrappedInt forKey:@"googActualEncBitrate"];
        }
        else if(![type compare:@"googRetransmitBitrate"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [_googRetransmitBitrate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
            [obj setValue:aWrappedInt forKey:@"googRetransmitBitrate"];
        }
    }
    
    return obj;
    
}

-(NSString*)getTurnServerIP:(NSDictionary *)pairs
{
    NSString * serverIP = @"";
    BOOL isActive = false;
    BOOL isRelay = false;
    NSString* remoteCandidateType = @"relay";
    
    for(id key in pairs)
    {
        //obj = [[NSMutableDictionary alloc]init];
        NSString* type = key;
        
        if(![type compare:@"googActiveConnection"])
        {
            isActive = [[pairs objectForKey:key] boolValue];
        }
        else
            if(![type compare:@"googRemoteCandidateType"])
            {
                if(![[pairs objectForKey:key] compare:@"relay"])
                    isRelay = true;
            }
            else
                if(![type compare:@"googRemoteAddress"])
                {
                    serverIP =[pairs objectForKey:key];
                }
    }
    if(isActive && isRelay)
    {
        isTurnIPAvailable = true;
        return serverIP;
    }
    
    return @"";
}


-(void)parseReport:(NSArray*)reports
{
    NSInteger anInt = 0;
    NSNumber *aWrappedInt = [NSNumber numberWithInteger:anInt];
    if(!_isInitDone)
    {
        [self initIDForSSRC:reports];
        _isInitDone = true;
    }
    for(RTCStatsReport* report in reports)
    {
        NSString* type = report.type;
        timesstamp = report.timestamp;
        //converting to UTC time format
        //        NSDate* date = [dateFormatter dateFromString:[dateFormatter stringFromDate:[NSDate date]]];
        //        NSString *timestamp1 = [NSString stringWithFormat:@"%@",date];
        //        [_timeStamp setObject:timestamp1 atIndexedSubscript:_arrayIndex];
        
        NSDate *now = [NSDate date];
        NSString *timestamp = [isoDateFormatter stringFromDate:now];
        
        [_timeStamp setObject:timestamp atIndexedSubscript:_arrayIndex];
        
        
        NSMutableDictionary* streamStats = nil;
        if (![type compare:@"ssrc"] || ![type compare:@"VideoBwe"])
        {
            
            NSString* reportID = report.reportId;
            NSDictionary* pairs = report.values;
            if(![reportID compare:_rxVideoID])
            {
                
                streamStats = [self getRxVideoStat:pairs];
                NSInteger packetLost = [[streamStats objectForKey:@"packetsLost"]integerValue];
                NSInteger packetRecv = [[streamStats objectForKey:@"packetsReceived"]integerValue];
                //totalPacketSent = packetRecv + packetLost;
                totalPacketRecv = packetRecv + packetLost;
                if(totalPacketRecv <= 0)
                    totalPacketRecv = 1;
                rxVideoFlag = true;
            }
            else
                if(![reportID compare:_txVideoID])
                {
                    streamStats = [self getTxVideoStat:pairs];
                    NSInteger packetLost = [[streamStats objectForKey:@"packetsLost"]integerValue];
                    NSInteger packetSent = [[streamStats objectForKey:@"packetsSent"]integerValue];
                    totalPacketSent = packetSent + packetLost;
                    if(totalPacketSent <= 0)
                        totalPacketSent = 1;
                    txVideoFlag = true;
                }
                else
                    if(![reportID compare:_rxAudioID])
                    {
                        streamStats = [self getRxAudioStat:pairs];
                        rxAudioFlag = true ;
                    }
                    else
                        if(![reportID compare:_txAudioID])
                        {
                            streamStats = [self getTxAudioStat:pairs];
                            txAudioFlag = true ;
                        }
                        else
                            if(![reportID compare:@"bweforvideo"])
                            {
                                streamStats = [self getGeneralStat:pairs];
                                generalFlag = true;
                            }
            
        }
        else
            if (![type compare:@"googCandidatePair"] && !isTurnIPAvailable)
            {
                NSArray* pairs = report.values;
                turnServerIP = [self getTurnServerIP:pairs];
            }
        if(streamStats != nil)
            [_streamStatsArray addObject:streamStats];
    }
    
    if (!rxVideoFlag) {
        
        [_rxVideoBytesReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideoPacketsReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideoFrameHeightReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideoFrameWidthReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideoFrameRateReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideoCurrentDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideoPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideogoogCaptureStartNtpTimeMs  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        
        [_rxVideogoogDecodeMs  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideogoogFirsSent   setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        
        [_rxVideogoogFrameRateDecoded  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideogoogFrameRateOutput  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        
        
        [_rxVideogoogJitterBufferMs  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideogoogMaxDecodeMs  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideogoogMinPlayoutDelayMs  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideogoogNacksSent  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideogoogPlisSent  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideogoogRenderDelayMs  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxVideogoogTargetDelayMs  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        rxVideoFlag = false;
    }
    
    if (!txVideoFlag) {
        
        [_txVideoBytesSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideoEncodeUsagePercent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideoFrameHeightSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideoFrameRateSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideoFrameWidthSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideoRtt setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideoPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideoPacketsSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideogoogAdaptationChanges setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideogoogAvgEncodeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideogoogFirsReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideogoogFrameHeightInput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideogoogFrameRateInput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideogoogFrameWidthInput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideogoogNacksReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txVideogoogPlisReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        
        txVideoFlag = false ;
        
    }
    
    if (!rxAudioFlag) {
        
        [_rxAudioOutputLevel setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudioBytesReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudioPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudioPacketsReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogPreferredJitterBufferMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogCaptureStartNtpTimeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogCurrentDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogDecodingCNG setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogDecodingCTN setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogDecodingCTSG setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogDecodingNormal setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogDecodingPLC setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogDecodingPLCCNG setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogExpandRate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogJitterBufferMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_rxAudiogoogJitterReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        //        [_rxAudiogoogPreemptiveExpandRate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        //        [_rxAudiogoogSecondaryDecodedRate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        //        [_rxAudiogoogSpeechExpandRate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        //        [_rxAudiogoogAccelerateRate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        rxAudioFlag = false;
        
    }
    
    if (!txAudioFlag) {
        
        [_txAudioInputLevel setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudioBytesSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudioPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudioPacketsSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudiogoogEchoCancellationQualityMin setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudiogoogEchoCancellationEchoDelayMedian setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudiogoogEchoCancellationEchoDelayStdDev setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudiogoogEchoCancellationReturnLoss setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudiogoogEchoCancellationReturnLossEnhancement setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudiogoogJitterReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_txAudiogoogRtt setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        txAudioFlag = false;
    }
    
    if (!generalFlag) {
        
        [_sendBandwidthArray setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_receiveBandwidthArray setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_transmitBitrate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_googActualEncBitrate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        [_googRetransmitBitrate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        generalFlag = false;
    }
    
    if (timeCounter11 == 10) {
        if (isWSStats == false) {
            _arrayIndex++;
        }
        timeCounter11 = 0;
    }
    
    timeCounter11++;
    
}

-(void)resetParams
{
    _txVideoID = nil;
    _rxVideoID = nil;
    _txAudioID = nil;
    _rxAudioID = nil;
    _isInitDone = false;
    isTurnIPAvailable = false;
    turnServerIP = @"";
    rtt = 0;
    totalPacketSent = 0;
    packetLossSent = 0;
    
}

-(int)useLastReportToCalcCurrentBandwidth:(WebRTCStatReport*)lastReport
{
    
    /*
     double d = (bytesSent - (lastReport.bytesSent))/((timesstamp - (lastReport.timesstamp))/10);
     
     NSLog(@"Time difference is = %f",d);
     sendBandwidth = d;*/
    return sendBandwidth;
}


-(NSDictionary*)toJSON{
    
    NSMutableDictionary *obj1 = [[NSMutableDictionary alloc]init];
    [obj1 setValue:_streamStatsArray forKey:@"groups"];
    return  obj1;
}

-(NSString*)toString
{
    NSMutableDictionary* data = [self toJSON];
    NSString *string = [NSString stringWithFormat:@"%@",data];
    return string;
}

+ (BOOL)isTurnIPAvailable
{
    return isTurnIPAvailable;
}

-(void)streamStatArrayAlloc
{
    _streamStatsArray = [[NSMutableArray alloc]init];
}

+ (void)setTurnIPAvailabilityStatus:(BOOL)value
{
    isTurnIPAvailable = value;
}

//-(NSString*)toString:(NSArray*)_array{
//
//    NSError *error = nil;
//    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_array options:0 error:&error];
//    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//    NSString *jsonString2 = [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
//    NSString *jsonString3 = [jsonString2 stringByReplacingOccurrencesOfString:@"\"" withString:@""];
//    return jsonString3;
//
//    return [[_array valueForKey:@"description"] componentsJoinedByString:@","];
//
//}

-(NSMutableDictionary*)stats{
    
    //    NSString * result;
    
    NSMutableDictionary* general = [[NSMutableDictionary alloc]init];
    
    NSMutableDictionary* rxVideo = [[NSMutableDictionary alloc]init];
    
    NSMutableDictionary* rxAudio = [[NSMutableDictionary alloc]init];
    
    NSMutableDictionary* txVideo = [[NSMutableDictionary alloc]init];
    
    NSMutableDictionary* txAudio = [[NSMutableDictionary alloc]init];
    
    NSMutableDictionary* timeseries = [[NSMutableDictionary alloc]init];
    
    /////////////////////////////////////////////////////////////////
    
    [general setObject:_receiveBandwidthArray forKey:@"googAvailableReceiveBandwidth"];
    
    [general setObject:_sendBandwidthArray forKey:@"googAvailableSendBandwidth"];
    
    [general setObject:_transmitBitrate forKey:@"googTransmitBitrate"];
    
    [general setObject:_timeStamp forKey:@"timestamp"];
    
    [general setObject:_googActualEncBitrate forKey:@"googActualEncBitrate"];
    
    [general setObject:_googRetransmitBitrate forKey:@"googRetransmitBitrate"];
    
    ///////////////////////////////////////////////////////////////////
    
    if(_rxVideoBytesReceived != nil) [rxVideo setObject:_rxVideoBytesReceived forKey:@"bytesReceived"];
    
    if(_rxVideoCurrentDelayMs != nil)[rxVideo setObject:_rxVideoCurrentDelayMs forKey:@"googCurrentDelayMs"];
    
    if(_rxVideoFrameHeightReceived != nil)[rxVideo setObject:_rxVideoFrameHeightReceived forKey:@"googFrameHeightReceived"];
    
    if(_rxVideoFrameRateReceived != nil)[rxVideo setObject:_rxVideoFrameRateReceived forKey:@"googFrameRateReceived"];
    
    if(_rxVideoFrameWidthReceived != nil)[rxVideo setObject:_rxVideoFrameWidthReceived forKey:@"googFrameWidthReceived"];
    
    if(_rxVideoPacketsLost != nil)[rxVideo setObject:_rxVideoPacketsLost forKey:@"packetsLost"];
    
    if(_rxVideoPacketsReceived != nil)[rxVideo setObject:_rxVideoPacketsReceived forKey:@"packetsReceived"];
    
    if(_rxVideogoogCaptureStartNtpTimeMs != nil)[rxVideo setObject:_rxVideogoogCaptureStartNtpTimeMs forKey:@"googCaptureStartNtpTimeMs"];
    
    if(_rxVideogoogDecodeMs != nil)[rxVideo setObject:_rxVideogoogDecodeMs forKey:@"googDecodeMs"];
    
    if(_rxVideogoogFirsSent != nil)[rxVideo setObject:_rxVideogoogFirsSent forKey:@"googFirsSent"];
    
    if(_rxVideogoogFrameRateDecoded != nil)[rxVideo setObject:_rxVideogoogFrameRateDecoded forKey:@"googFrameRateDecoded"];
    
    if(_rxVideogoogFrameRateOutput != nil)[rxVideo setObject:_rxVideogoogFrameRateOutput forKey:@"googFrameRateOutput"];
    
    if(_rxVideogoogJitterBufferMs != nil)[rxVideo setObject:_rxVideogoogJitterBufferMs forKey:@"googJitterBufferMs"];
    
    if(_rxVideogoogMaxDecodeMs != nil)[rxVideo setObject:_rxVideogoogMaxDecodeMs forKey:@"googMaxDecodeMs"];
    
    if(_rxVideogoogMinPlayoutDelayMs != nil)[rxVideo setObject:_rxVideogoogMinPlayoutDelayMs forKey:@"googMinPlayoutDelayMs"];
    
    if(_rxVideogoogNacksSent != nil)[rxVideo setObject:_rxVideogoogNacksSent forKey:@"googNacksSent"];
    
    if(_rxVideogoogPlisSent != nil)[rxVideo setObject:_rxVideogoogPlisSent forKey:@"googPlisSent"];
    
    if(_rxVideogoogRenderDelayMs != nil)[rxVideo setObject:_rxVideogoogRenderDelayMs forKey:@"googRenderDelayMs"];
    
    if(_rxVideogoogTargetDelayMs != nil)[rxVideo setObject:_rxVideogoogTargetDelayMs forKey:@"googTargetDelayMs"];
    
    if(_rxVideoCodecName != nil)[rxVideo setObject:_rxVideoCodecName forKey:@"googCodecName"];
    
    ///////////////////////////////////////////////////////////////////
    
    if(_rxAudioOutputLevel != nil)[rxAudio setObject:_rxAudioOutputLevel forKey:@"audioOutputLevel"];
    
    if(_rxAudioBytesReceived != nil)[rxAudio setObject:_rxAudioBytesReceived forKey:@"bytesReceived"];
    
    if(_rxAudioPacketsLost != nil)[rxAudio setObject:_rxAudioPacketsLost forKey:@"packetsLost"];
    
    if(_rxAudioPacketsReceived != nil)[rxAudio setObject:_rxAudioPacketsReceived forKey:@"packetsReceived"];
    
    
    
    if(_rxAudiogoogCaptureStartNtpTimeMs != nil)[rxAudio setObject:_rxAudiogoogCaptureStartNtpTimeMs forKey:@"googCaptureStartNtpTimeMs"];
    
    if(_rxAudiogoogCurrentDelayMs != nil)[rxAudio setObject:_rxAudiogoogCurrentDelayMs forKey:@"googCurrentDelayMs"];
    
    if(_rxAudiogoogDecodingCNG != nil)[rxAudio setObject:_rxAudiogoogDecodingCNG forKey:@"googDecodingCNG"];
    
    if(_rxAudiogoogDecodingCTN != nil)[rxAudio setObject:_rxAudiogoogDecodingCTN forKey:@"googDecodingCTN"];
    
    if(_rxAudiogoogDecodingCTSG != nil)[rxAudio setObject:_rxAudiogoogDecodingCTSG forKey:@"googDecodingCTSG"];
    
    if(_rxAudiogoogDecodingNormal != nil)[rxAudio setObject:_rxAudiogoogDecodingNormal forKey:@"googDecodingNormal"];
    
    if(_rxAudiogoogDecodingPLC != nil)[rxAudio setObject:_rxAudiogoogDecodingPLC forKey:@"googDecodingPLC"];
    
    if(_rxAudiogoogDecodingPLCCNG != nil)[rxAudio setObject:_rxAudiogoogDecodingPLCCNG forKey:@"googDecodingPLCCNG"];
    
    if(_rxAudiogoogExpandRate != nil)[rxAudio setObject:_rxAudiogoogExpandRate forKey:@"googExpandRate"];
    
    if(_rxAudiogoogJitterBufferMs != nil)[rxAudio setObject:_rxAudiogoogJitterBufferMs forKey:@"googJitterBufferMs"];
    
    if(_rxAudiogoogJitterReceived != nil)[rxAudio setObject:_rxAudiogoogJitterReceived forKey:@"googJitterReceived"];
    
    if(_rxAudiogoogPreferredJitterBufferMs != nil)[rxAudio setObject:_rxAudiogoogPreferredJitterBufferMs forKey:@"googPreferredJitterBufferMs"];
    
    if(_rxAudioCodecName != nil)[rxAudio setObject:_rxAudioCodecName forKey:@"googCodecName"];
    
    //    if(_rxAudiogoogPreemptiveExpandRate != nil)[rxAudio setObject:_rxAudiogoogPreemptiveExpandRate forKey:@"googPreemptiveExpandRate"];
    
    //    if(_rxAudiogoogAccelerateRate != nil)[rxAudio setObject:_rxAudiogoogAccelerateRate forKey:@"googAccelerateRate"];
    
    //    if(_rxAudiogoogSecondaryDecodedRate != nil)[rxAudio setObject:_rxAudiogoogSecondaryDecodedRate forKey:@"googSecondaryDecodedRate"];
    
    //    if(_rxAudiogoogSpeechExpandRate != nil)[rxAudio setObject:_rxAudiogoogSpeechExpandRate forKey:@"googSpeechExpandRate"];
    
    ///////////////////////////////////////////////////////////////////
    
    if(_txVideoBytesSent != nil)[txVideo setObject:_txVideoBytesSent forKey:@"bytesSent"];
    
    if(_txVideoEncodeUsagePercent != nil)[txVideo setObject:_txVideoEncodeUsagePercent forKey:@"googEncodeUsagePercent"];
    
    if(_txVideoFrameHeightSent != nil)[txVideo setObject:_txVideoFrameHeightSent forKey:@"googFrameHeightSent"];
    
    if(_txVideoFrameRateSent != nil)[txVideo setObject:_txVideoFrameRateSent forKey:@"googFrameRateSent"];
    
    if(_txVideoFrameWidthSent != nil)[txVideo setObject:_txVideoFrameWidthSent forKey:@"googFrameWidthSent"];
    
    if(_txVideoRtt != nil)[txVideo setObject:_txVideoRtt forKey:@"googRtt"];
    
    if(_txVideoPacketsLost != nil)[txVideo setObject:_txVideoPacketsLost forKey:@"packetsLost"];
    
    if(_txVideoPacketsSent != nil)[txVideo setObject:_txVideoPacketsSent forKey:@"packetsSent"];
    
    if(_txVideogoogAdaptationChanges != nil)[txVideo setObject:_txVideogoogAdaptationChanges forKey:@"googAdaptationChanges"];
    
    if(_txVideogoogAvgEncodeMs != nil)[txVideo setObject:_txVideogoogAvgEncodeMs forKey:@"googAvgEncodeMs"];
    
    if(_txVideogoogFirsReceived != nil)[txVideo setObject:_txVideogoogFirsReceived forKey:@"googFirsReceived"];
    
    if(_txVideogoogFrameHeightInput != nil)[txVideo setObject:_txVideogoogFrameHeightInput forKey:@"googFrameHeightInput"];
    
    if(_txVideogoogFrameRateInput != nil)[txVideo setObject:_txVideogoogFrameRateInput forKey:@"googFrameRateInput"];
    
    if(_txVideogoogFrameWidthInput != nil)[txVideo setObject:_txVideogoogFrameWidthInput forKey:@"googFrameWidthInput"];
    
    if(_txVideogoogNacksReceived != nil)[txVideo setObject:_txVideogoogNacksReceived forKey:@"googNacksReceived"];
    
    if(_txVideogoogPlisReceived != nil)[txVideo setObject:_txVideogoogPlisReceived forKey:@"googPlisReceived"];
    
    if(_txVideoCodecName != nil)[txVideo setObject:_txVideoCodecName forKey:@"googCodecName"];
    
    ///////////////////////////////////////////////////////////////////
    
    if(_txAudioInputLevel != nil)[txAudio setObject:_txAudioInputLevel forKey:@"audioInputLevel"];
    
    if(_txAudioBytesSent != nil)[txAudio setObject:_txAudioBytesSent forKey:@"bytesSent"];
    
    if(_txAudioPacketsLost != nil)[txAudio setObject:_txAudioPacketsLost forKey:@"packetsLost"];
    
    if(_txAudioPacketsSent != nil)[txAudio setObject:_txAudioPacketsSent forKey:@"packetsSent"];
    
    if(_txAudiogoogEchoCancellationQualityMin != nil)[txAudio setObject:_txAudiogoogEchoCancellationQualityMin forKey:@"googEchoCancellationQualityMin"];
    
    if(_txAudiogoogEchoCancellationEchoDelayMedian != nil)[txAudio setObject:_txAudiogoogEchoCancellationEchoDelayMedian forKey:@"googEchoCancellationEchoDelayMedian"];
    
    if(_txAudiogoogEchoCancellationEchoDelayStdDev != nil)[txAudio setObject:_txAudiogoogEchoCancellationEchoDelayStdDev forKey:@"googEchoCancellationEchoDelayStdDev"];
    
    if(_txAudiogoogEchoCancellationReturnLoss != nil)[txAudio setObject:_txAudiogoogEchoCancellationReturnLoss forKey:@"googEchoCancellationReturnLoss"];
    
    if(_txAudiogoogEchoCancellationReturnLossEnhancement != nil)[txAudio setObject:_txAudiogoogEchoCancellationReturnLossEnhancement forKey:@"googEchoCancellationReturnLossEnhancement"];
    
    if(_txAudiogoogJitterReceived != nil)[txAudio setObject:_txAudiogoogJitterReceived forKey:@"googJitterReceived"];
    
    if(_txAudiogoogRtt != nil)[txAudio setObject:_txAudiogoogRtt forKey:@"googRtt"];
    
    if(_txAudioCodecName != nil)[txAudio setObject:_txAudioCodecName forKey:@"googCodecName"];
    
    ///////////////////////////////////////////////////////////////////
    
    [timeseries setObject:general forKey:@"General"];
    [timeseries setObject:rxVideo forKey:@"rxVideo"];
    [timeseries setObject:rxAudio forKey:@"rxAudio"];
    [timeseries setObject:txVideo forKey:@"txVideo"];
    [timeseries setObject:txAudio forKey:@"txAudio"];
    
    return timeseries;
    
    
}

-(NSMutableDictionary*)statsWS{
    
    //    NSString * result;
    
    NSMutableDictionary* general = [[NSMutableDictionary alloc]init];
    
    NSMutableDictionary* rxVideo = [[NSMutableDictionary alloc]init];
    
    NSMutableDictionary* rxAudio = [[NSMutableDictionary alloc]init];
    
    NSMutableDictionary* txVideo = [[NSMutableDictionary alloc]init];
    
    NSMutableDictionary* txAudio = [[NSMutableDictionary alloc]init];
    
    NSMutableDictionary* timeseries = [[NSMutableDictionary alloc]init];
    
    /////////////////////////////////////////////////////////////////
    
    if(_receiveBandwidthArray != nil && [_receiveBandwidthArray count] != 0) [general setObject:[_receiveBandwidthArray[0] stringValue] forKey:@"googAvailableReceiveBandwidth"];
    
    if(_sendBandwidthArray != nil && [_sendBandwidthArray count] != 0) [general setObject:[_sendBandwidthArray[0] stringValue] forKey:@"googAvailableSendBandwidth"];
    
    if(_transmitBitrate != nil && [_transmitBitrate count] != 0) [general setObject:[_transmitBitrate[0] stringValue] forKey:@"googTransmitBitrate"];
    
    if(_timeStamp != nil && [_timeStamp count] != 0) [general setObject:_timeStamp[0] forKey:@"timestamp"];
    
    if(_googActualEncBitrate != nil && [_googActualEncBitrate count] != 0) [general setObject:[_googActualEncBitrate[0] stringValue] forKey:@"googActualEncBitrate"];
    
    if(_googRetransmitBitrate != nil && [_googRetransmitBitrate count] != 0) [general setObject:[_googRetransmitBitrate[0] stringValue] forKey:@"googRetransmitBitrate"];
    
    ///////////////////////////////////////////////////////////////////
    
    if(_rxVideoBytesReceived != nil && [_rxVideoBytesReceived count] != 0) [rxVideo setObject:[_rxVideoBytesReceived[0] stringValue] forKey:@"bytesReceived"];
    
    if(_rxVideoCurrentDelayMs != nil && [_rxVideoCurrentDelayMs count] != 0)[rxVideo setObject:[_rxVideoCurrentDelayMs[0] stringValue] forKey:@"googCurrentDelayMs"];
    
    if(_rxVideoFrameHeightReceived != nil && [_rxVideoFrameHeightReceived count] != 0)[rxVideo setObject:[_rxVideoFrameHeightReceived[0] stringValue] forKey:@"googFrameHeightReceived"];
    
    if(_rxVideoFrameRateReceived != nil && [_rxVideoFrameRateReceived count] != 0)[rxVideo setObject:[_rxVideoFrameRateReceived[0] stringValue] forKey:@"googFrameRateReceived"];
    
    if(_rxVideoFrameWidthReceived != nil && [_rxVideoFrameWidthReceived count] != 0)[rxVideo setObject:[_rxVideoFrameWidthReceived[0] stringValue] forKey:@"googFrameWidthReceived"];
    
    if(_rxVideoPacketsLost != nil && [_rxVideoPacketsLost count] != 0)[rxVideo setObject:[_rxVideoPacketsLost[0] stringValue] forKey:@"packetsLost"];
    
    if(_rxVideoPacketsReceived != nil && [_rxVideoPacketsReceived count] != 0)[rxVideo setObject:[_rxVideoPacketsReceived[0] stringValue] forKey:@"packetsReceived"];
    
    if(_rxVideogoogCaptureStartNtpTimeMs != nil && [_rxVideogoogCaptureStartNtpTimeMs count] != 0)[rxVideo setObject:[_rxVideogoogCaptureStartNtpTimeMs[0] stringValue] forKey:@"googCaptureStartNtpTimeMs"];
    
    if(_rxVideogoogDecodeMs != nil && [_rxVideogoogDecodeMs count] != 0)[rxVideo setObject:[_rxVideogoogDecodeMs[0] stringValue] forKey:@"googDecodeMs"];
    
    if(_rxVideogoogFirsSent != nil && [_rxVideogoogFirsSent count] != 0)[rxVideo setObject:[_rxVideogoogFirsSent[0] stringValue] forKey:@"googFirsSent"];
    
    if(_rxVideogoogFrameRateDecoded != nil && [_rxVideogoogFrameRateDecoded count] != 0)[rxVideo setObject:[_rxVideogoogFrameRateDecoded[0] stringValue] forKey:@"googFrameRateDecoded"];
    
    if(_rxVideogoogFrameRateOutput != nil && [_rxVideogoogFrameRateOutput count] != 0)[rxVideo setObject:[_rxVideogoogFrameRateOutput[0] stringValue] forKey:@"googFrameRateOutput"];
    
    if(_rxVideogoogJitterBufferMs != nil && [_rxVideogoogJitterBufferMs count] != 0)[rxVideo setObject:[_rxVideogoogJitterBufferMs[0] stringValue] forKey:@"googJitterBufferMs"];
    
    if(_rxVideogoogMaxDecodeMs != nil && [_rxVideoCurrentDelayMs count] != 0)[rxVideo setObject:[_rxVideogoogMaxDecodeMs[0] stringValue] forKey:@"googMaxDecodeMs"];
    
    if(_rxVideogoogMinPlayoutDelayMs != nil && [_rxVideogoogMaxDecodeMs count] != 0)[rxVideo setObject:[_rxVideogoogMinPlayoutDelayMs[0] stringValue] forKey:@"googMinPlayoutDelayMs"];
    
    if(_rxVideogoogNacksSent != nil && [_rxVideogoogNacksSent count] != 0)[rxVideo setObject:[_rxVideogoogNacksSent[0] stringValue] forKey:@"googNacksSent"];
    
    if(_rxVideogoogPlisSent != nil && [_rxVideogoogPlisSent count] != 0)[rxVideo setObject:[_rxVideogoogPlisSent[0] stringValue] forKey:@"googPlisSent"];
    
    if(_rxVideogoogRenderDelayMs != nil && [_rxVideogoogRenderDelayMs count] != 0)[rxVideo setObject:[_rxVideogoogRenderDelayMs[0] stringValue] forKey:@"googRenderDelayMs"];
    
    if(_rxVideogoogTargetDelayMs != nil && [_rxVideogoogTargetDelayMs count] != 0)[rxVideo setObject:[_rxVideogoogTargetDelayMs[0] stringValue] forKey:@"googTargetDelayMs"];
    
    if(_rxVideoCodecName != nil) [rxVideo setObject:_rxVideoCodecName forKey:@"googCodecName"];
    
    ///////////////////////////////////////////////////////////////////
    
    if(_rxAudioOutputLevel != nil && [_rxAudioOutputLevel count] != 0)[rxAudio setObject:[_rxAudioOutputLevel[0] stringValue] forKey:@"audioOutputLevel"];
    
    if(_rxAudioBytesReceived != nil && [_rxAudioBytesReceived count] != 0)[rxAudio setObject:[_rxAudioBytesReceived[0] stringValue] forKey:@"bytesReceived"];
    
    if(_rxAudioPacketsLost != nil && [_rxAudioPacketsLost count] != 0)[rxAudio setObject:[_rxAudioPacketsLost[0] stringValue] forKey:@"packetsLost"];
    
    if(_rxAudioPacketsReceived != nil && [_rxAudioPacketsReceived count] != 0)[rxAudio setObject:[_rxAudioPacketsReceived[0] stringValue] forKey:@"packetsReceived"];
    
    
    
    if(_rxAudiogoogCaptureStartNtpTimeMs != nil && [_rxAudiogoogCaptureStartNtpTimeMs count] != 0)[rxAudio setObject:[_rxAudiogoogCaptureStartNtpTimeMs[0] stringValue] forKey:@"googCaptureStartNtpTimeMs"];
    
    if(_rxAudiogoogCurrentDelayMs != nil && [_rxAudiogoogCurrentDelayMs count] != 0)[rxAudio setObject:[_rxAudiogoogCurrentDelayMs[0] stringValue] forKey:@"googCurrentDelayMs"];
    
    if(_rxAudiogoogDecodingCNG != nil && [_rxAudiogoogDecodingCNG count] != 0)[rxAudio setObject:[_rxAudiogoogDecodingCNG[0] stringValue] forKey:@"googDecodingCNG"];
    
    if(_rxAudiogoogDecodingCTN != nil && [_rxAudiogoogDecodingCTN count] != 0)[rxAudio setObject:[_rxAudiogoogDecodingCTN[0] stringValue] forKey:@"googDecodingCTN"];
    
    if(_rxAudiogoogDecodingCTSG != nil && [_rxAudiogoogDecodingCTSG count] != 0)[rxAudio setObject:[_rxAudiogoogDecodingCTSG[0] stringValue] forKey:@"googDecodingCTSG"];
    
    if(_rxAudiogoogDecodingNormal != nil && [_rxAudiogoogDecodingNormal count] != 0)[rxAudio setObject:[_rxAudiogoogDecodingNormal[0] stringValue] forKey:@"googDecodingNormal"];
    
    if(_rxAudiogoogDecodingPLC != nil && [_rxAudiogoogDecodingPLC count] != 0)[rxAudio setObject:[_rxAudiogoogDecodingPLC[0] stringValue] forKey:@"googDecodingPLC"];
    
    if(_rxAudiogoogDecodingPLCCNG != nil && [_rxAudiogoogDecodingPLCCNG count] != 0)[rxAudio setObject:[_rxAudiogoogDecodingPLCCNG[0] stringValue] forKey:@"googDecodingPLCCNG"];
    
    if(_rxAudiogoogExpandRate != nil && [_rxAudiogoogExpandRate count] != 0)[rxAudio setObject:[_rxAudiogoogExpandRate[0] stringValue] forKey:@"googExpandRate"];
    
    if(_rxAudiogoogJitterBufferMs != nil && [_rxAudiogoogJitterBufferMs count] != 0)[rxAudio setObject:[_rxAudiogoogJitterBufferMs[0] stringValue] forKey:@"googJitterBufferMs"];
    
    if(_rxAudiogoogJitterReceived != nil && [_rxAudiogoogJitterReceived count] != 0)[rxAudio setObject:[_rxAudiogoogJitterReceived[0] stringValue] forKey:@"googJitterReceived"];
    
    if(_rxAudiogoogPreferredJitterBufferMs != nil && [_rxAudiogoogPreferredJitterBufferMs count] != 0)[rxAudio setObject:[_rxAudiogoogPreferredJitterBufferMs[0] stringValue] forKey:@"googPreferredJitterBufferMs"];
    
    if(_rxAudioCodecName != nil)[rxAudio setObject:_rxAudioCodecName forKey:@"googCodecName"];
    
    //    if(_rxAudiogoogPreemptiveExpandRate != nil)[rxAudio setObject:_rxAudiogoogPreemptiveExpandRate forKey:@"googPreemptiveExpandRate"];
    
    //    if(_rxAudiogoogAccelerateRate != nil)[rxAudio setObject:_rxAudiogoogAccelerateRate forKey:@"googAccelerateRate"];
    
    //    if(_rxAudiogoogSecondaryDecodedRate != nil)[rxAudio setObject:_rxAudiogoogSecondaryDecodedRate forKey:@"googSecondaryDecodedRate"];
    
    //    if(_rxAudiogoogSpeechExpandRate != nil)[rxAudio setObject:_rxAudiogoogSpeechExpandRate forKey:@"googSpeechExpandRate"];
    
    ///////////////////////////////////////////////////////////////////
    
    if(_txVideoBytesSent != nil && [_txVideoBytesSent count] != 0)[txVideo setObject:[_txVideoBytesSent[0] stringValue] forKey:@"bytesSent"];
    
    if(_txVideoEncodeUsagePercent != nil && [_txVideoEncodeUsagePercent count] != 0)[txVideo setObject:[_txVideoEncodeUsagePercent[0] stringValue] forKey:@"googEncodeUsagePercent"];
    
    if(_txVideoFrameHeightSent != nil && [_txVideoFrameHeightSent count] != 0)[txVideo setObject:[_txVideoFrameHeightSent[0] stringValue] forKey:@"googFrameHeightSent"];
    
    if(_txVideoFrameRateSent != nil && [_txVideoFrameRateSent count] != 0)[txVideo setObject:[_txVideoFrameRateSent[0] stringValue] forKey:@"googFrameRateSent"];
    
    if(_txVideoFrameWidthSent != nil && [_txVideoFrameWidthSent count] != 0)[txVideo setObject:[_txVideoFrameWidthSent[0] stringValue] forKey:@"googFrameWidthSent"];
    
    if(_txVideoRtt != nil && [_txVideoRtt count] != 0)[txVideo setObject:[_txVideoRtt[0] stringValue] forKey:@"googRtt"];
    
    if(_txVideoPacketsLost != nil && [_txVideoPacketsLost count] != 0)[txVideo setObject:[_txVideoPacketsLost[0] stringValue] forKey:@"packetsLost"];
    
    if(_txVideoPacketsSent != nil && [_txVideoPacketsSent count] != 0)[txVideo setObject:[_txVideoPacketsSent[0] stringValue] forKey:@"packetsSent"];
    
    if(_txVideogoogAdaptationChanges != nil && [_txVideogoogAdaptationChanges count] != 0)[txVideo setObject:[_txVideogoogAdaptationChanges[0] stringValue] forKey:@"googAdaptationChanges"];
    
    if(_txVideogoogAvgEncodeMs != nil && [_txVideogoogAvgEncodeMs count] != 0)[txVideo setObject:[_txVideogoogAvgEncodeMs[0] stringValue] forKey:@"googAvgEncodeMs"];
    
    if(_txVideogoogFirsReceived != nil && [_txVideogoogFirsReceived count] != 0)[txVideo setObject:[_txVideogoogFirsReceived[0] stringValue] forKey:@"googFirsReceived"];
    
    if(_txVideogoogFrameHeightInput != nil && [_txVideogoogFrameHeightInput count] != 0)[txVideo setObject:_txVideogoogFrameHeightInput[0] forKey:@"googFrameHeightInput"];
    
    if(_txVideogoogFrameRateInput != nil && [_txVideogoogFrameRateInput count] != 0)[txVideo setObject:[_txVideogoogFrameRateInput[0] stringValue] forKey:@"googFrameRateInput"];
    
    if(_txVideogoogFrameWidthInput != nil && [_txVideogoogFrameWidthInput count] != 0)[txVideo setObject:[_txVideogoogFrameWidthInput[0] stringValue] forKey:@"googFrameWidthInput"];
    
    if(_txVideogoogNacksReceived != nil && [_txVideogoogNacksReceived count] != 0)[txVideo setObject:[_txVideogoogNacksReceived[0] stringValue] forKey:@"googNacksReceived"];
    
    if(_txVideogoogPlisReceived != nil && [_txVideogoogPlisReceived count] != 0)[txVideo setObject:[_txVideogoogPlisReceived[0] stringValue] forKey:@"googPlisReceived"];
    
    if(_txVideoCodecName != nil)[txVideo setObject:_txVideoCodecName forKey:@"googCodecName"];
    
    ///////////////////////////////////////////////////////////////////
    
    if(_txAudioInputLevel != nil && [_txAudioInputLevel count] != 0)[txAudio setObject:[_txAudioInputLevel[0] stringValue] forKey:@"audioInputLevel"];
    
    if(_txAudioBytesSent != nil && [_txAudioBytesSent count] != 0)[txAudio setObject:[_txAudioBytesSent[0] stringValue] forKey:@"bytesSent"];
    
    if(_txAudioPacketsLost != nil && [_txAudioPacketsLost count] != 0) [txAudio setObject:[_txAudioPacketsLost[0] stringValue] forKey:@"packetsLost"];
    
    if(_txAudioPacketsSent != nil && [_txAudioPacketsSent count] != 0)[txAudio setObject:[_txAudioPacketsSent[0] stringValue] forKey:@"packetsSent"];
    
    if(_txAudiogoogEchoCancellationQualityMin != nil && [_txAudiogoogEchoCancellationQualityMin count] != 0)[txAudio setObject:[_txAudiogoogEchoCancellationQualityMin[0] stringValue] forKey:@"googEchoCancellationQualityMin"];
    
    if(_txAudiogoogEchoCancellationEchoDelayMedian != nil && [_txAudiogoogEchoCancellationEchoDelayMedian count] != 0)[txAudio setObject:[_txAudiogoogEchoCancellationEchoDelayMedian[0] stringValue] forKey:@"googEchoCancellationEchoDelayMedian"];
    
    if(_txAudiogoogEchoCancellationEchoDelayStdDev != nil && [_txAudiogoogEchoCancellationEchoDelayStdDev count] != 0)[txAudio setObject:[_txAudiogoogEchoCancellationEchoDelayStdDev[0] stringValue] forKey:@"googEchoCancellationEchoDelayStdDev"];
    
    if(_txAudiogoogEchoCancellationReturnLoss != nil && [_txAudiogoogEchoCancellationReturnLoss count] != 0)[txAudio setObject:[_txAudiogoogEchoCancellationReturnLoss[0] stringValue] forKey:@"googEchoCancellationReturnLoss"];
    
    if(_txAudiogoogEchoCancellationReturnLossEnhancement != nil && [_txAudiogoogEchoCancellationReturnLossEnhancement count] != 0)[txAudio setObject:[_txAudiogoogEchoCancellationReturnLossEnhancement[0] stringValue] forKey:@"googEchoCancellationReturnLossEnhancement"];
    
    if(_txAudiogoogJitterReceived != nil && [_txAudiogoogJitterReceived count] != 0)[txAudio setObject:[_txAudiogoogJitterReceived[0] stringValue] forKey:@"googJitterReceived"];
    
    if(_txAudiogoogRtt != nil && [_txAudiogoogRtt count] != 0)[txAudio setObject:[_txAudiogoogRtt[0] stringValue] forKey:@"googRtt"];
    
    if(_txAudioCodecName != nil)[txAudio setObject:_txAudioCodecName forKey:@"googCodecName"];
    
    ///////////////////////////////////////////////////////////////////
    
    [timeseries setObject:general forKey:@"General"];
    [timeseries setObject:rxVideo forKey:@"rxVideo"];
    [timeseries setObject:rxAudio forKey:@"rxAudio"];
    [timeseries setObject:txVideo forKey:@"txVideo"];
    [timeseries setObject:txAudio forKey:@"txAudio"];
    
    return timeseries;
    
    
}




@end

