//
//  WebRTCStatReport.m
//  xfinity-webrtc-sdk
//
//  Created by Pankaj on 17/07/14.
//  Copyright (c) 2014 Comcast. All rights reserved.
//

#import "WebRTCStatReport.h"
#import "RTCPair.h"

int timeCounter1 = 10;


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
@synthesize dateFormatter;

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
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        
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
            NSArray* pairs = report.values;
            
            for(RTCPair* pair in pairs)
            {
                NSString* type = pair.key;
                
                if(![type compare:@"googFrameRateReceived"])
                {
                    _rxVideoID = report.reportId;
                }
                else if(![type compare:@"googFrameRateSent"])
                {
                    _txVideoID = report.reportId;
                }
                else if(![type compare:@"audioOutputLevel"])
                {
                    _rxAudioID = report.reportId;
                }
                else if(![type compare:@"audioInputLevel"])
                {
                    _txAudioID = report.reportId;
                }
            }
            
        }
    }
    
}


-(NSMutableDictionary*)getTxAudioStat:(NSArray*)pairs
{
    NSMutableDictionary* obj = [[NSMutableDictionary alloc]init];
    [obj setValue:@"TxAudio" forKey:@"id"];
    
    for(RTCPair* pair in pairs)
    {
        //obj = [[NSMutableDictionary alloc]init];
        NSNumber *aWrappedInt = nil;
        NSString* type = pair.key;
            
        if(![type compare:@"bytesSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"bytesSent"];
            [_txAudioBytesSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"audioInputLevel"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"audioInputLevel"];
            [_txAudioInputLevel setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"packetsSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsSent"];
            [_txAudioPacketsSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"packetsLost"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsLost"];
            [_txAudioPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googEchoCancellationQualityMin"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationQualityMin"];
            [_txAudiogoogEchoCancellationQualityMin  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googEchoCancellationEchoDelayMedian"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationEchoDelayMedian"];
            [_txAudiogoogEchoCancellationEchoDelayMedian  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googEchoCancellationEchoDelayStdDev"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationEchoDelayStdDev"];
            [_txAudiogoogEchoCancellationEchoDelayStdDev  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googEchoCancellationReturnLoss"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationReturnLoss"];
            [_txAudiogoogEchoCancellationReturnLoss  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googEchoCancellationReturnLossEnhancement"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationReturnLossEnhancement"];
            [_txAudiogoogEchoCancellationReturnLossEnhancement  setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googJitterReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"googJitterReceived"];
            [_txAudiogoogJitterReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googCodecName"])
        {
            _txAudioCodecName = pair.value;
            [obj setValue:_txAudioCodecName forKey:@"googCodecType"];
        }
        else if(![type compare:@"googRtt"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"googRtt"];
            [_txAudiogoogRtt setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }

    }
    
    return obj;
}

-(NSMutableDictionary*)getTxVideoStat:(NSArray*)pairs
{
    NSMutableDictionary* obj = [[NSMutableDictionary alloc]init];
    [obj setValue:@"TxVideo" forKey:@"id"];
    
    for(RTCPair* pair in pairs)
    {
        //obj = [[NSMutableDictionary alloc]init];
        NSNumber *aWrappedInt = nil;
        NSString* type = pair.key;
        
        if(![type compare:@"bytesSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"bytesSent"];
            [_txVideoBytesSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"packetsSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsSent"];
            [_txVideoPacketsSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googFrameHeightSent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameHeightSent"];
             [_txVideoFrameHeightSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFrameWidthSent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameWidthSent"];
             [_txVideoFrameWidthSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFrameRateSent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameRateSent"];
             [_txVideoFrameRateSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googEncodeUsagePercent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googEncodeUsagePercent"];
             [_txVideoEncodeUsagePercent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googRtt"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             rtt = [aWrappedInt integerValue];
             if(rtt < 0)
                 rtt = 0;
             //rtt = aWrappedInt;
             [obj setValue:aWrappedInt forKey:@"googRtt"];
             [_txVideoRtt setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"packetsLost"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             packetLossSent = [aWrappedInt integerValue];
             if(packetLossSent < 0)
                 packetLossSent = 0;
             [obj setValue:aWrappedInt forKey:@"packetsLost"];
            [_txVideoPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googAdaptationChanges"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googAdaptationChanges"];
             [_txVideogoogAdaptationChanges setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googAvgEncodeMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googAvgEncodeMs"];
             [_txVideogoogAvgEncodeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFirsReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFirsReceived"];
             [_txVideogoogFirsReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFrameHeightInput"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameHeightInput"];
             [_txVideogoogFrameHeightInput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFrameRateInput"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameRateInput"];
             [_txVideogoogFrameRateInput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
        
         else if(![type compare:@"googFrameWidthInput"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameWidthInput"];
             [_txVideogoogFrameWidthInput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
        
         else if(![type compare:@"googNacksReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googNacksReceived"];
             [_txVideogoogNacksReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googCodecName"])
         {
             _txVideoCodecName = pair.value;
             [obj setValue:_txVideoCodecName forKey:@"googCodecType"];
         }
         else if(![type compare:@"googPlisReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googPlisReceived"];
             [_txVideogoogPlisReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
    }

    
    return obj;
}

-(NSMutableDictionary*)getRxAudioStat:(NSArray*)pairs
{
    NSMutableDictionary* obj = [[NSMutableDictionary alloc]init];
    [obj setValue:@"RxAudio" forKey:@"id"];
    
    for(RTCPair* pair in pairs)
    {
        //obj = [[NSMutableDictionary alloc]init];
        NSNumber *aWrappedInt = nil;
        NSString* type = pair.key;
        
        if(![type compare:@"bytesReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"bytesReceived"];
            [_rxAudioBytesReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"audioOutputLevel"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"audioOutputLevel"];
             [_rxAudioOutputLevel setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"packetsReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"packetsReceived"];
             [_rxAudioPacketsReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"packetsLost"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"packetsLost"];
             [_rxAudioPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googCaptureStartNtpTimeMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googCaptureStartNtpTimeMs"];
             [_rxAudiogoogCaptureStartNtpTimeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googCurrentDelayMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googCurrentDelayMs"];
             [_rxAudiogoogCurrentDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googDecodingCNG"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodingCNG"];
             [_rxAudiogoogDecodingCNG setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googDecodingCTN"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodingCTN"];
             [_rxAudiogoogDecodingCTN setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googDecodingCTSG"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodingCTSG"];
             [_rxAudiogoogDecodingCTSG setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googDecodingNormal"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodingNormal"];
             [_rxAudiogoogDecodingNormal setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googDecodingPLC"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodingPLC"];
             [_rxAudiogoogDecodingPLC setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googDecodingPLCCNG"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodingPLCCNG"];
             [_rxAudiogoogDecodingPLCCNG setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googExpandRate"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googExpandRate"];
             [_rxAudiogoogExpandRate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googJitterBufferMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googJitterBufferMs"];
             [_rxAudiogoogJitterBufferMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googJitterReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googJitterReceived"];
             [_rxAudiogoogJitterReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googPreferredJitterBufferMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googPreferredJitterBufferMs"];
             [_rxAudiogoogPreferredJitterBufferMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googCodecName"])
         {
             _rxAudioCodecName = pair.value;
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

-(NSMutableDictionary*)getRxVideoStat:(NSArray*)pairs
{
    NSMutableDictionary* obj = [[NSMutableDictionary alloc]init];
    [obj setValue:@"RxVideo" forKey:@"id"];
    
    for(RTCPair* pair in pairs)
    {
        //obj = [[NSMutableDictionary alloc]init];
        NSNumber *aWrappedInt = nil;
        NSString* type = pair.key;
        
        if(![type compare:@"bytesReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"bytesReceived"];
            [_rxVideoBytesReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"packetsReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsReceived"];
            [_rxVideoPacketsReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];        }
        else if(![type compare:@"googFrameHeightReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameHeightReceived"];
             [_rxVideoFrameHeightReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];         }
         else if(![type compare:@"googFrameWidthReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameWidthReceived"];
             [_rxVideoFrameWidthReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFrameRateReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameRateReceived"];
             [_rxVideoFrameRateReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googCurrentDelayMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googCurrentDelayMs"];
             [_rxVideoCurrentDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"packetsLost"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             packetLossRecv = [aWrappedInt integerValue];
             if(packetLossRecv < 0)
                 packetLossRecv = 0;
             [obj setValue:aWrappedInt forKey:@"packetsLost"];
             [_rxVideoPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];

         }
         else if(![type compare:@"googCaptureStartNtpTimeMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googCaptureStartNtpTimeMs"];
             [_rxVideogoogCaptureStartNtpTimeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googDecodeMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodeMs"];
             [_rxVideogoogDecodeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFirsSent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFirsSent"];
             [_rxVideogoogFirsSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFrameRateDecoded"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameRateDecoded"];
             [_rxVideogoogFrameRateDecoded setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFrameRateOutput"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameRateOutput"];
             [_rxVideogoogFrameRateOutput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googJitterBufferMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googJitterBufferMs"];
             [_rxVideogoogJitterBufferMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googMaxDecodeMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googMaxDecodeMs"];
             [_rxVideogoogMaxDecodeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googMinPlayoutDelayMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googMinPlayoutDelayMs"];
             [_rxVideogoogMinPlayoutDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googNacksSent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googNacksSent"];
             [_rxVideogoogNacksSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googPlisSent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googPlisSent"];
             [_rxVideogoogPlisSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googRenderDelayMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googRenderDelayMs"];
             [_rxVideogoogRenderDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googCodecName"])
         {
             _rxVideoCodecName = pair.value;
             [obj setValue:_rxVideoCodecName forKey:@"googCodecType"];
         }
         else if(![type compare:@"googTargetDelayMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
             [obj setValue:aWrappedInt forKey:@"googTargetDelayMs"];
             [_rxVideogoogTargetDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
    }

    return obj;
}


-(NSMutableDictionary*)getGeneralStat:(NSArray*)pairs
{
    NSMutableDictionary* obj = [[NSMutableDictionary alloc]init];
    [obj setValue:@"General" forKey:@"id"];
    
    for(RTCPair* pair in pairs)
    {
        //obj = [[NSMutableDictionary alloc]init];
        NSNumber *aWrappedInt = nil;
        NSString* type = pair.key;
        
        if(![type compare:@"googAvailableSendBandwidth"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            sendBandwidth = [aWrappedInt integerValue];
            [obj setValue:aWrappedInt forKey:@"googAvailableSendBandwidth"];
            [_sendBandwidthArray setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googTransmitBitrate"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"googTransmitBitrate"];
            [_transmitBitrate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googAvailableReceiveBandwidth"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            recvBandwidth = [aWrappedInt integerValue];
            [_receiveBandwidthArray setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
            [obj setValue:aWrappedInt forKey:@"googAvailableReceiveBandwidth"];
        }
        else if(![type compare:@"packetsLost"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsLost"];
        }
        else if(![type compare:@"googActualEncBitrate"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [_googActualEncBitrate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
            [obj setValue:aWrappedInt forKey:@"googActualEncBitrate"];
        }
        else if(![type compare:@"googRetransmitBitrate"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[pair.value intValue]];
            [_googRetransmitBitrate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
            [obj setValue:aWrappedInt forKey:@"googRetransmitBitrate"];
        }
    }
    
    return obj;
}

-(NSString*)getTurnServerIP:(NSArray *)pairs
{
    NSString * serverIP = @"";
    BOOL isActive = false;
    BOOL isRelay = false;        
    NSString* remoteCandidateType = @"relay";
    
    for(RTCPair* pair in pairs)
    {
        //obj = [[NSMutableDictionary alloc]init];
        NSString* type = pair.key;
        
        if(![type compare:@"googActiveConnection"])
        {
            isActive = [pair.value boolValue];
        }
        else
        if(![type compare:@"googRemoteCandidateType"])
        {
            if(![pair.value compare:@"relay"])
            isRelay = true;
        }
        else
        if(![type compare:@"googRemoteAddress"])
        {
            serverIP = pair.value;
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
        NSDate* date = [dateFormatter dateFromString:[dateFormatter stringFromDate:[NSDate date]]];
        NSString *timestamp1 = [NSString stringWithFormat:@"%@",date];
        [_timeStamp setObject:timestamp1 atIndexedSubscript:_arrayIndex];
        
        NSMutableDictionary* streamStats = nil;
        if (![type compare:@"ssrc"] || ![type compare:@"VideoBwe"])
        {
            NSString* reportID = report.reportId;
            NSArray* pairs = report.values;
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
    
    if (timeCounter1 == 10) {
        _arrayIndex++;
        timeCounter1 = 0;
    }
    timeCounter1++;

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



@end
