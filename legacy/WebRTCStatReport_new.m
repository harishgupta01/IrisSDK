//
//  WebRTCStatReport_new.m
//  xfinity-webrtc-sdk
//
//  Created by Pankaj on 17/07/14.
//  Copyright (c) 2014 Comcast. All rights reserved.
//

#import "WebRTCStatReport_new.h"
#import "WebRTC/WebRTC.h"

int timeCounter1 = 10;


@interface WebRTCStatReport_new ()
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
@property(nonatomic ) NSInteger receiveBandwidthVal ;
@property(nonatomic ) NSInteger sendBandwidthVal;
@property(nonatomic ) NSInteger transmitBitrateVal;
@property(nonatomic ) NSMutableString* timeStampVal;
@property(nonatomic ) NSInteger googActualEncBitrateVal;
@property(nonatomic ) NSInteger googRetransmitBitrateVal;

@property(nonatomic ) NSInteger rxVideoBytesReceived;//
@property(nonatomic ) NSInteger rxVideoCurrentDelayMs;
@property(nonatomic ) NSInteger rxVideoFrameHeightReceived;
@property(nonatomic ) NSInteger rxVideoFrameRateReceived;
@property(nonatomic ) NSInteger rxVideoFrameWidthReceived;
@property(nonatomic ) NSInteger rxVideoPacketsLost;
@property(nonatomic ) NSInteger rxVideoPacketsReceived;// Added
@property(nonatomic ) NSInteger rxVideogoogCaptureStartNtpTimeMs;
@property(nonatomic ) NSInteger rxVideogoogDecodeMs;
@property(nonatomic ) NSInteger rxVideogoogFirsSent ;
@property(nonatomic ) NSInteger rxVideogoogFrameRateDecoded;
@property(nonatomic ) NSInteger rxVideogoogFrameRateOutput;
@property(nonatomic ) NSInteger rxVideogoogJitterBufferMs;
@property(nonatomic ) NSInteger rxVideogoogMaxDecodeMs;
@property(nonatomic ) NSInteger rxVideogoogMinPlayoutDelayMs;
@property(nonatomic ) NSInteger rxVideogoogNacksSent;
@property(nonatomic ) NSInteger rxVideogoogPlisSent;
@property(nonatomic ) NSInteger rxVideogoogRenderDelayMs;
@property(nonatomic ) NSInteger rxVideogoogTargetDelayMs;

@property(nonatomic ) NSInteger rxAudioOutputLevel;//
@property(nonatomic ) NSInteger rxAudioBytesReceived;
@property(nonatomic ) NSInteger rxAudioPacketsLost;
@property(nonatomic ) NSInteger rxAudioPacketsReceived;//Added
@property(nonatomic ) NSInteger rxAudiogoogCaptureStartNtpTimeMs;
@property(nonatomic ) NSInteger rxAudiogoogCurrentDelayMs;
@property(nonatomic ) NSInteger rxAudiogoogDecodingCNG;
@property(nonatomic ) NSInteger rxAudiogoogDecodingCTN;
@property(nonatomic ) NSInteger rxAudiogoogDecodingCTSG;
@property(nonatomic ) NSInteger rxAudiogoogDecodingNormal;
@property(nonatomic ) NSInteger rxAudiogoogDecodingPLC;
@property(nonatomic ) NSInteger rxAudiogoogDecodingPLCCNG;
@property(nonatomic ) NSInteger rxAudiogoogExpandRate;
@property(nonatomic ) NSInteger rxAudiogoogJitterBufferMs;
@property(nonatomic ) NSInteger rxAudiogoogJitterReceived;
@property(nonatomic ) NSInteger rxAudiogoogPreferredJitterBufferMs;
//@property(nonatomic ) NSMutableArray* rxAudiogoogAccelerateRate;
//@property(nonatomic ) NSMutableArray* rxAudiogoogPreemptiveExpandRate;
//@property(nonatomic ) NSMutableArray* rxAudiogoogSecondaryDecodedRate;
//@property(nonatomic ) NSMutableArray* rxAudiogoogSpeechExpandRate;

@property(nonatomic ) NSInteger txVideoBytesSent;//
@property(nonatomic ) NSInteger txVideoEncodeUsagePercent;
@property(nonatomic ) NSInteger txVideoFrameHeightSent;
@property(nonatomic ) NSInteger txVideoFrameRateSent;
@property(nonatomic ) NSInteger txVideoFrameWidthSent;
@property(nonatomic ) NSInteger txVideoRtt;
@property(nonatomic ) NSInteger txVideoPacketsLost;
@property(nonatomic ) NSInteger txVideoPacketsSent;//Added
@property(nonatomic ) NSInteger txVideogoogAdaptationChanges;
@property(nonatomic ) NSInteger txVideogoogAvgEncodeMs;
@property(nonatomic ) NSInteger txVideogoogFirsReceived;
@property(nonatomic ) NSInteger txVideogoogFrameHeightInput;
@property(nonatomic ) NSInteger txVideogoogFrameRateInput;
@property(nonatomic ) NSInteger txVideogoogFrameWidthInput;
@property(nonatomic ) NSInteger txVideogoogNacksReceived;
@property(nonatomic ) NSInteger txVideogoogPlisReceived;

@property(nonatomic ) NSInteger txAudioInputLevel;//
@property(nonatomic ) NSInteger txAudioBytesSent;
@property(nonatomic ) NSInteger txAudioPacketsLost;
@property(nonatomic ) NSInteger txAudioPacketsSent; //Added
@property(nonatomic ) NSInteger txAudiogoogEchoCancellationQualityMin;
@property(nonatomic ) NSInteger txAudiogoogEchoCancellationEchoDelayMedian;
@property(nonatomic ) NSInteger txAudiogoogEchoCancellationEchoDelayStdDev;
@property(nonatomic ) NSInteger txAudiogoogEchoCancellationReturnLoss;
@property(nonatomic ) NSInteger txAudiogoogEchoCancellationReturnLossEnhancement;
@property(nonatomic ) NSInteger txAudiogoogJitterReceived;
@property(nonatomic ) NSInteger txAudiogoogRtt;

@property(nonatomic ) BOOL istxAudioPacketsLost;
@property(nonatomic ) BOOL istxAudiogoogJitterReceived;
@property(nonatomic ) BOOL istxAudiogoogRtt;
@property(nonatomic ) BOOL isrxAudiogoogCaptureStartNtpTimeMs;



@property(nonatomic ) NSInteger arrayIndex;

@end

static BOOL isTurnIPAvailable;

@implementation WebRTCStatReport_new
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
        isrxAudiogoogCaptureStartNtpTimeMs = false;
        _streamStatsArray = [[NSMutableArray alloc]init];
        
        _receiveBandwidthVal  = 0;
        _sendBandwidthVal = 0;
        _transmitBitrateVal = 0;
        _timeStampVal = [[NSMutableString alloc]init];
        _googActualEncBitrateVal = 0;
        _googRetransmitBitrateVal = 0;
      
        _rxVideoBytesReceived   = 0;
        _rxVideoCurrentDelayMs  = 0;
        _rxVideoFrameHeightReceived = 0;
        _rxVideoFrameRateReceived   = 0;
        _rxVideoFrameWidthReceived  = 0;
        _rxVideoPacketsLost         = 0;
        _rxVideoPacketsReceived     = 0;//Added
        _rxVideogoogCaptureStartNtpTimeMs  = 0;
        
        _rxVideogoogDecodeMs  = 0;
        _rxVideogoogFirsSent   = 0;
        
        _rxVideogoogFrameRateDecoded  = 0;
        _rxVideogoogFrameRateOutput  = 0;
        
        
        _rxVideogoogJitterBufferMs  = 0;
        _rxVideogoogMaxDecodeMs  = 0;
        _rxVideogoogMinPlayoutDelayMs  = 0;
        _rxVideogoogNacksSent  = 0;
        _rxVideogoogPlisSent  = 0;
        _rxVideogoogRenderDelayMs  = 0;
        _rxVideogoogTargetDelayMs  = 0;
        
        _rxAudioOutputLevel         = 0;//
        _rxAudioBytesReceived      = 0;
        _rxAudioPacketsLost         = 0;
        _rxAudioPacketsReceived     = 0;//Added
 
        _rxAudiogoogPreferredJitterBufferMs = 0;
        _rxAudiogoogCaptureStartNtpTimeMs = 0;
        _rxAudiogoogCurrentDelayMs = 0;
        _rxAudiogoogDecodingCNG = 0;
        _rxAudiogoogDecodingCTN = 0;
        _rxAudiogoogDecodingCTSG = 0;
        _rxAudiogoogDecodingNormal = 0;
        _rxAudiogoogDecodingPLC = 0;
        _rxAudiogoogDecodingPLCCNG = 0;
        _rxAudiogoogExpandRate = 0;
        _rxAudiogoogJitterBufferMs = 0;
        _rxAudiogoogJitterReceived = 0;
//        _rxAudiogoogAccelerateRate = [NSMutableArray array];
//        _rxAudiogoogPreemptiveExpandRate = [NSMutableArray array];
//        _rxAudiogoogSecondaryDecodedRate = [NSMutableArray array];
//        _rxAudiogoogSpeechExpandRate = [NSMutableArray array];
        
        _txVideoBytesSent           = 0;//
        _txVideoEncodeUsagePercent  = 0;
        _txVideoFrameHeightSent     = 0;
        _txVideoFrameRateSent       = 0;
        _txVideoFrameWidthSent      = 0;
        _txVideoRtt                 = 0;
        _txVideoPacketsLost         = 0;
        _txVideoPacketsSent         = 0;//Added
        _txVideogoogAdaptationChanges = 0;
        _txVideogoogAvgEncodeMs = 0;
        _txVideogoogFirsReceived = 0;
        _txVideogoogFrameHeightInput = 0;
        _txVideogoogFrameRateInput = 0;
        _txVideogoogFrameWidthInput = 0;
        _txVideogoogNacksReceived = 0;
        _txVideogoogPlisReceived = 0;
        
        _txAudioInputLevel          = 0;//
        _txAudioBytesSent           = 0;
        _txAudioPacketsSent        = 0;
        _txAudioPacketsLost         = 0;//Added
        _txAudiogoogEchoCancellationQualityMin  = 0;
        _txAudiogoogEchoCancellationEchoDelayMedian =  0;
        _txAudiogoogEchoCancellationEchoDelayStdDev =  0;
        _txAudiogoogEchoCancellationReturnLoss = 0;
        _txAudiogoogEchoCancellationReturnLossEnhancement = 0;
        _txAudiogoogJitterReceived = 0;
        _txAudiogoogRtt = 0;
        
        _arrayIndex = 0;
        
       // [_txAudiogoogJitterReceived removeAllObjects];
      //  [_txAudiogoogRtt removeAllObjects];
      //  [_txAudioPacketsLost removeAllObjects];
        
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
                
            //    NSString* type = [pairs objectForKey:key];
                
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
            _txAudioBytesSent = [aWrappedInt integerValue];
        }
        else if(![type compare:@"audioInputLevel"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"audioInputLevel"];
             _txAudioInputLevel = [aWrappedInt integerValue];
        }
        else if(![type compare:@"packetsSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsSent"];
             _txAudioPacketsSent = [aWrappedInt integerValue];
        }
        else if(![type compare:@"packetsLost"])
        {
            
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsLost"];
             _txAudioPacketsLost = [aWrappedInt integerValue];
        }
        else if(![type compare:@"googEchoCancellationQualityMin"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationQualityMin"];
             _txAudiogoogEchoCancellationQualityMin = [aWrappedInt integerValue];
        }
        else if(![type compare:@"googEchoCancellationEchoDelayMedian"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationEchoDelayMedian"];
             _txAudiogoogEchoCancellationEchoDelayMedian = [aWrappedInt integerValue];
        }
        else if(![type compare:@"googEchoCancellationEchoDelayStdDev"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationEchoDelayStdDev"];
             _txAudiogoogEchoCancellationEchoDelayStdDev = [aWrappedInt integerValue];
        }
        else if(![type compare:@"googEchoCancellationReturnLoss"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationReturnLoss"];
            _txAudiogoogEchoCancellationReturnLoss = [aWrappedInt integerValue];
        }
        else if(![type compare:@"googEchoCancellationReturnLossEnhancement"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googEchoCancellationReturnLossEnhancement"];
             _txAudiogoogEchoCancellationReturnLossEnhancement = [aWrappedInt integerValue];
        }
        else if(![type compare:@"googJitterReceived"])
        {
           
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googJitterReceived"];
            _txAudiogoogJitterReceived = [aWrappedInt integerValue];       

           
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
            _txAudiogoogRtt =[aWrappedInt integerValue];
//            if (( _txAudiogoogRtt.count == 0 && _arrayIndex == 0 )|| istxAudiogoogRtt)
//            {
//                [_txAudiogoogRtt setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
//                istxAudiogoogRtt = YES;
//
//            }
//            else{
//
//
//            if(_txAudiogoogRtt.count == _arrayIndex){
//                [_txAudiogoogRtt setObject:aWrappedInt atIndexedSubscript:(_arrayIndex-1)];
//            }else{
//                [_txAudiogoogRtt setObject:aWrappedInt atIndexedSubscript:_txAudiogoogRtt.count];
//            }
//            }
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
          //  [_txVideoBytesSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
            _txVideoBytesSent =[aWrappedInt integerValue];
        }
        else if(![type compare:@"packetsSent"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsSent"];
          //  [_txVideoPacketsSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _txVideoPacketsSent =[aWrappedInt integerValue];
        }
        else if(![type compare:@"googFrameHeightSent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameHeightSent"];
        //     [_txVideoFrameHeightSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
              _txVideoFrameHeightSent =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googFrameWidthSent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameWidthSent"];
         //    [_txVideoFrameWidthSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
              _txVideoFrameWidthSent =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googFrameRateSent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameRateSent"];
         //    [_txVideoFrameRateSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
              _txVideoFrameRateSent =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googEncodeUsagePercent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googEncodeUsagePercent"];
        //     [_txVideoEncodeUsagePercent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
              _txVideoEncodeUsagePercent =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googRtt"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             rtt = [aWrappedInt integerValue];
             if(rtt < 0)
                 rtt = 0;
             //rtt = aWrappedInt;
             [obj setValue:aWrappedInt forKey:@"googRtt"];
         //    [_txVideoRtt setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
              _txVideoRtt =[aWrappedInt integerValue];
         }
         else if(![type compare:@"packetsLost"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             packetLossSent = [aWrappedInt integerValue];
             if(packetLossSent < 0)
                 packetLossSent = 0;
             [obj setValue:aWrappedInt forKey:@"packetsLost"];
          //  [_txVideoPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
              _txVideoPacketsLost =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googAdaptationChanges"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googAdaptationChanges"];
          //   [_txVideogoogAdaptationChanges setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
              _txVideogoogAdaptationChanges =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googAvgEncodeMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googAvgEncodeMs"];
          //   [_txVideogoogAvgEncodeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
              _txVideogoogAvgEncodeMs =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googFirsReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googFirsReceived"];
        //     [_txVideogoogFirsReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
              _txVideogoogFirsReceived =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googFrameHeightInput"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameHeightInput"];
           //  [_txVideogoogFrameHeightInput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _txVideogoogFrameHeightInput =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googFrameRateInput"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameRateInput"];
          //   [_txVideogoogFrameRateInput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _txVideogoogFrameRateInput =[aWrappedInt integerValue];
              _txVideoBytesSent =[aWrappedInt integerValue];
         }
        
         else if(![type compare:@"googFrameWidthInput"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameWidthInput"];
          //   [_txVideogoogFrameWidthInput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _txVideogoogFrameWidthInput =[aWrappedInt integerValue];
             _txVideogoogFirsReceived =[aWrappedInt integerValue];
              _txVideoBytesSent =[aWrappedInt integerValue];
         }
        
         else if(![type compare:@"googNacksReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googNacksReceived"];
          //   [_txVideogoogNacksReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _txVideogoogNacksReceived = [aWrappedInt integerValue];
              _txVideoBytesSent =[aWrappedInt integerValue];
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
         //    [_txVideogoogPlisReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _txVideogoogPlisReceived =[aWrappedInt integerValue];
              _txVideoBytesSent =[aWrappedInt integerValue];
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
          //  [_rxAudioBytesReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
            _rxAudioBytesReceived =[aWrappedInt integerValue];
        }
        else if(![type compare:@"audioOutputLevel"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"audioOutputLevel"];
         //    [_rxAudioOutputLevel setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _rxAudioOutputLevel =[aWrappedInt integerValue];
         }
         else if(![type compare:@"packetsReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"packetsReceived"];
        //     [_rxAudioPacketsReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _rxAudioPacketsReceived =[aWrappedInt integerValue];
             _txVideoBytesSent =[aWrappedInt integerValue];
         }
         else if(![type compare:@"packetsLost"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"packetsLost"];
          //   [_rxAudioPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _rxAudioPacketsLost =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googCaptureStartNtpTimeMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googCaptureStartNtpTimeMs"];
             _rxAudiogoogCaptureStartNtpTimeMs =[aWrappedInt integerValue];
          //   [_rxAudiogoogCaptureStartNtpTimeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             
//             if (( _rxAudiogoogCaptureStartNtpTimeMs.count == 0 && _arrayIndex == 0 )|| isrxAudiogoogCaptureStartNtpTimeMs)
//             {
//                 [_rxAudiogoogCaptureStartNtpTimeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
//
//                 isrxAudiogoogCaptureStartNtpTimeMs = YES;
//
//             }
//             else{
//                 if(_rxAudiogoogCaptureStartNtpTimeMs.count == _arrayIndex){
//                     [_rxAudiogoogCaptureStartNtpTimeMs setObject:aWrappedInt atIndexedSubscript:(_arrayIndex-1)];
//                     _txVideoBytesSent =[aWrappedInt integerValue];
//                 }else{
//                     [_rxAudiogoogCaptureStartNtpTimeMs setObject:aWrappedInt atIndexedSubscript:_rxAudiogoogCaptureStartNtpTimeMs.count];
//                 }
//             }
             
         }
         else if(![type compare:@"googCurrentDelayMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googCurrentDelayMs"];
           //  [_rxAudiogoogCurrentDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _rxAudiogoogCurrentDelayMs =[aWrappedInt integerValue];
             _txVideoBytesSent =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googDecodingCNG"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodingCNG"];
          //   [_rxAudiogoogDecodingCNG setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _rxAudiogoogDecodingCNG =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googDecodingCTN"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodingCTN"];
          //   [_rxAudiogoogDecodingCTN setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _rxAudiogoogDecodingCTN =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googDecodingCTSG"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodingCTSG"];
           //  [_rxAudiogoogDecodingCTSG setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _rxAudiogoogDecodingCTSG =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googDecodingNormal"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodingNormal"];
           //  [_rxAudiogoogDecodingNormal setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _rxAudiogoogDecodingNormal =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googDecodingPLC"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodingPLC"];
         //    [_rxAudiogoogDecodingPLC setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _rxAudiogoogDecodingPLC =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googDecodingPLCCNG"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodingPLCCNG"];
           //  [_rxAudiogoogDecodingPLCCNG setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _rxAudiogoogDecodingPLCCNG =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googExpandRate"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googExpandRate"];
          //   [_rxAudiogoogExpandRate setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _rxAudiogoogExpandRate =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googJitterBufferMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googJitterBufferMs"];
          //   [_rxAudiogoogJitterBufferMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _rxAudiogoogJitterBufferMs =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googJitterReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googJitterReceived"];
          //   [_rxAudiogoogJitterReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _rxAudiogoogJitterReceived =[aWrappedInt integerValue];
         }
         else if(![type compare:@"googPreferredJitterBufferMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googPreferredJitterBufferMs"];
       //      [_rxAudiogoogPreferredJitterBufferMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
             _rxAudiogoogPreferredJitterBufferMs =[aWrappedInt integerValue];
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
            _rxVideoBytesReceived = [aWrappedInt integerValue];
          //  [_rxVideoBytesReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
            
        }
        else if(![type compare:@"packetsReceived"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsReceived"];
             _rxVideoPacketsReceived = [aWrappedInt integerValue];
          //  [_rxVideoPacketsReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
        }
        else if(![type compare:@"googFrameHeightReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameHeightReceived"];
              _rxVideoFrameHeightReceived = [aWrappedInt integerValue];
          //   [_rxVideoFrameHeightReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFrameWidthReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameWidthReceived"];
              _rxVideoFrameWidthReceived = [aWrappedInt integerValue];
           //  [_rxVideoFrameWidthReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFrameRateReceived"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameRateReceived"];
              _rxVideoFrameRateReceived = [aWrappedInt integerValue];
          //   [_rxVideoFrameRateReceived setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googCurrentDelayMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googCurrentDelayMs"];
              _rxVideoCurrentDelayMs = [aWrappedInt integerValue];
           //  [_rxVideoCurrentDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"packetsLost"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             packetLossRecv = [aWrappedInt integerValue];
             if(packetLossRecv < 0)
                 packetLossRecv = 0;
             [obj setValue:aWrappedInt forKey:@"packetsLost"];
              _rxVideoPacketsLost = [aWrappedInt integerValue];
          //   [_rxVideoPacketsLost setObject:aWrappedInt atIndexedSubscript:_arrayIndex];

         }
         else if(![type compare:@"googCaptureStartNtpTimeMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googCaptureStartNtpTimeMs"];
              _rxVideogoogCaptureStartNtpTimeMs = [aWrappedInt integerValue];
            // [_rxVideogoogCaptureStartNtpTimeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googDecodeMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googDecodeMs"];
              _rxVideogoogDecodeMs = [aWrappedInt integerValue];
          //   [_rxVideogoogDecodeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFirsSent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googFirsSent"];
              _rxVideogoogFirsSent = [aWrappedInt integerValue];
           //  [_rxVideogoogFirsSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFrameRateDecoded"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameRateDecoded"];
              _rxVideogoogFrameRateDecoded = [aWrappedInt integerValue];
            // [_rxVideogoogFrameRateDecoded setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googFrameRateOutput"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googFrameRateOutput"];
              _rxVideogoogFrameRateOutput = [aWrappedInt integerValue];
         //    [_rxVideogoogFrameRateOutput setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googJitterBufferMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googJitterBufferMs"];
              _rxVideogoogJitterBufferMs = [aWrappedInt integerValue];
          //   [_rxVideogoogJitterBufferMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googMaxDecodeMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googMaxDecodeMs"];
              _rxVideogoogMaxDecodeMs = [aWrappedInt integerValue];
          //   [_rxVideogoogMaxDecodeMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googMinPlayoutDelayMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googMinPlayoutDelayMs"];
              _rxVideogoogMinPlayoutDelayMs = [aWrappedInt integerValue];
          //   [_rxVideogoogMinPlayoutDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googNacksSent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googNacksSent"];
              _rxVideogoogNacksSent = [aWrappedInt integerValue];
           //  [_rxVideogoogNacksSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googPlisSent"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googPlisSent"];
              _rxVideogoogPlisSent = [aWrappedInt integerValue];
           //  [_rxVideogoogPlisSent setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
         }
         else if(![type compare:@"googRenderDelayMs"])
         {
             aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
             [obj setValue:aWrappedInt forKey:@"googRenderDelayMs"];
              _rxVideogoogRenderDelayMs = [aWrappedInt integerValue];
          //   [_rxVideogoogRenderDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
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
             _rxVideogoogTargetDelayMs = [aWrappedInt integerValue];
           //  [_rxVideogoogTargetDelayMs setObject:aWrappedInt atIndexedSubscript:_arrayIndex];
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
           
            _sendBandwidthVal = sendBandwidth ;
        }
        else if(![type compare:@"googTransmitBitrate"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googTransmitBitrate"];
          
            _transmitBitrateVal = [aWrappedInt integerValue];
        }
        else if(![type compare:@"googAvailableReceiveBandwidth"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            recvBandwidth = [aWrappedInt integerValue];
            [obj setValue:aWrappedInt forKey:@"googAvailableReceiveBandwidth"];
            _receiveBandwidthVal = [aWrappedInt integerValue];
        }
        else if(![type compare:@"packetsLost"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"packetsLost"];
        }
        else if(![type compare:@"googActualEncBitrate"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googActualEncBitrate"];
            _googActualEncBitrateVal = [aWrappedInt integerValue];
        }
        else if(![type compare:@"googRetransmitBitrate"])
        {
            aWrappedInt = [NSNumber numberWithInteger:[[pairs objectForKey:key] intValue]];
            [obj setValue:aWrappedInt forKey:@"googRetransmitBitrate"];
            _googRetransmitBitrateVal = [aWrappedInt integerValue];
        }
    }
    
    return obj;

}

-(NSString*)getTurnServerIP:(NSDictionary *)pairs
{
    NSString * serverIP = @"";
    BOOL isActive = false;
    BOOL isRelay = false;        
  //  NSString* remoteCandidateType = @"relay";
    
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
     
        _timeStampVal = [timestamp mutableCopy];

        
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
            NSDictionary* pairs = report.values;
            turnServerIP = [self getTurnServerIP:pairs];
        }
        if(streamStats != nil)
        [_streamStatsArray addObject:streamStats];
    }

    if (!rxVideoFlag) {
        
         _rxVideoBytesReceived = [aWrappedInt integerValue];
         _rxVideoPacketsReceived = [aWrappedInt integerValue];
         _rxVideoFrameHeightReceived = [aWrappedInt integerValue];
         _rxVideoFrameWidthReceived = [aWrappedInt integerValue];
         _rxVideoFrameRateReceived = [aWrappedInt integerValue];
         _rxVideoCurrentDelayMs = [aWrappedInt integerValue];
         _rxVideoPacketsLost = [aWrappedInt integerValue];
         _rxVideogoogCaptureStartNtpTimeMs = [aWrappedInt integerValue];
         _rxVideogoogDecodeMs = [aWrappedInt integerValue];
         _rxVideogoogFirsSent = [aWrappedInt integerValue];
         _rxVideogoogFrameRateDecoded = [aWrappedInt integerValue];
         _rxVideogoogFrameRateOutput = [aWrappedInt integerValue];
        _rxVideogoogJitterBufferMs = [aWrappedInt integerValue];
        _rxVideogoogMaxDecodeMs = [aWrappedInt integerValue];
        _rxVideogoogMinPlayoutDelayMs = [aWrappedInt integerValue];
        _rxVideogoogNacksSent = [aWrappedInt integerValue];
        _rxVideogoogPlisSent = [aWrappedInt integerValue];
        _rxVideogoogNacksSent = [aWrappedInt integerValue];
        _rxVideogoogRenderDelayMs = [aWrappedInt integerValue];
        _rxVideogoogTargetDelayMs = [aWrappedInt integerValue];
        
        rxVideoFlag = false;
    }
    
    if (!txVideoFlag) {
     
        _txVideoBytesSent = [aWrappedInt integerValue];
        _txVideoEncodeUsagePercent = [aWrappedInt integerValue];
        _txVideoFrameHeightSent = [aWrappedInt integerValue];
        _txVideoFrameRateSent = [aWrappedInt integerValue];
        _txVideoFrameWidthSent = [aWrappedInt integerValue];
        _txVideoRtt = [aWrappedInt integerValue];
        _txVideoPacketsLost = [aWrappedInt integerValue];
        _txVideoPacketsSent = [aWrappedInt integerValue];
        _txVideogoogAdaptationChanges = [aWrappedInt integerValue];
        _txVideogoogAvgEncodeMs = [aWrappedInt integerValue];
        _txVideogoogFirsReceived = [aWrappedInt integerValue];
        _txVideogoogFrameHeightInput = [aWrappedInt integerValue];
        _txVideogoogFrameRateInput = [aWrappedInt integerValue];
        _txVideogoogFrameWidthInput = [aWrappedInt integerValue];
        _txVideogoogNacksReceived = [aWrappedInt integerValue];
        _txVideogoogPlisReceived = [aWrappedInt integerValue];
     
        
        txVideoFlag = false ;
        
    }
    
    if (!rxAudioFlag) {
        
        _rxAudioOutputLevel = [aWrappedInt integerValue];
        _rxAudioBytesReceived = [aWrappedInt integerValue];
        _rxAudioPacketsLost = [aWrappedInt integerValue];
        _rxAudioPacketsReceived = [aWrappedInt integerValue];
        _rxAudiogoogPreferredJitterBufferMs = [aWrappedInt integerValue];
        _rxAudiogoogCaptureStartNtpTimeMs = [aWrappedInt integerValue];
        _rxAudiogoogCurrentDelayMs = [aWrappedInt integerValue];
        _rxAudiogoogDecodingCNG = [aWrappedInt integerValue];
        _rxAudiogoogDecodingCTN = [aWrappedInt integerValue];
        _rxAudiogoogDecodingCTSG = [aWrappedInt integerValue];
        _rxAudiogoogDecodingNormal = [aWrappedInt integerValue];
        _rxAudiogoogDecodingPLC = [aWrappedInt integerValue];
        _rxAudiogoogDecodingPLCCNG = [aWrappedInt integerValue];
        _rxAudiogoogExpandRate = [aWrappedInt integerValue];
        _rxAudiogoogJitterBufferMs = [aWrappedInt integerValue];
        _rxAudiogoogJitterReceived = [aWrappedInt integerValue];
        rxAudioFlag = false;

    }
    
    if (!txAudioFlag) {

        _txAudioInputLevel = [aWrappedInt integerValue];
        _txAudioBytesSent = [aWrappedInt integerValue];
        _txAudioPacketsLost = [aWrappedInt integerValue];
        _txAudioPacketsSent = [aWrappedInt integerValue];
        _txAudiogoogEchoCancellationQualityMin = [aWrappedInt integerValue];
        _txAudiogoogEchoCancellationEchoDelayMedian = [aWrappedInt integerValue];
        _txAudiogoogEchoCancellationEchoDelayStdDev = [aWrappedInt integerValue];
        _txAudiogoogEchoCancellationReturnLoss = [aWrappedInt integerValue];
        _txAudiogoogEchoCancellationReturnLossEnhancement = [aWrappedInt integerValue];
        _txAudiogoogJitterReceived = [aWrappedInt integerValue];
        _txAudiogoogRtt = [aWrappedInt integerValue];
         txAudioFlag = false;
    }
    
    if (!generalFlag) {        
        _sendBandwidthVal = [aWrappedInt integerValue];
        _receiveBandwidthVal = [aWrappedInt integerValue];
        _transmitBitrateVal = [aWrappedInt integerValue];
        _googActualEncBitrateVal = [aWrappedInt integerValue];
        _googRetransmitBitrateVal = [aWrappedInt integerValue];
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

//-(int)useLastReportToCalcCurrentBandwidth:(WebRTCStatReport_new*)lastReport
//{
//
//    /*
//    double d = (bytesSent - (lastReport.bytesSent))/((timesstamp - (lastReport.timesstamp))/10);
//
//    NSLog(@"Time difference is = %f",d);
//    sendBandwidth = d;*/
//    return sendBandwidth;
//}


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
    
    [general setObject:[NSNumber numberWithInteger:_receiveBandwidthVal] forKey:@"googAvailableReceiveBandwidth"];
    
    [general setObject:[NSNumber numberWithInteger:_sendBandwidthVal] forKey:@"googAvailableSendBandwidth"];
    
    [general setObject:[NSNumber numberWithInteger:_transmitBitrateVal] forKey:@"googTransmitBitrate"];
    
    [general setObject:_timeStampVal forKey:@"timestamp"];
    
    [general setObject:[NSNumber numberWithInteger:_googRetransmitBitrateVal] forKey:@"googActualEncBitrate"];
    
    [general setObject:[NSNumber numberWithInteger:_googRetransmitBitrateVal] forKey:@"googRetransmitBitrate"];
    
    ///////////////////////////////////////////////////////////////////
    
    
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideoBytesReceived] forKey:@"bytesReceived"];
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideoCurrentDelayMs] forKey:@"googCurrentDelayMs"];
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideoFrameHeightReceived] forKey:@"googFrameHeightReceived"];
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideoFrameRateReceived] forKey:@"googFrameRateReceived"];
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideoFrameWidthReceived] forKey:@"googFrameWidthReceived"];
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideoPacketsLost] forKey:@"packetsLost"];
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideoPacketsReceived] forKey:@"packetsReceived"];
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideogoogCaptureStartNtpTimeMs] forKey:@"googCaptureStartNtpTimeMs"];
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideogoogDecodeMs] forKey:@"googDecodeMs"];
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideogoogFirsSent] forKey:@"googFirsSent"];
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideogoogFrameRateDecoded] forKey:@"googFrameRateDecoded"];
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideogoogFrameRateOutput] forKey:@"googFrameRateOutput"];
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideogoogJitterBufferMs] forKey:@"googJitterBufferMs"];
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideogoogMaxDecodeMs] forKey:@"googMaxDecodeMs"];
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideogoogMinPlayoutDelayMs] forKey:@"googMinPlayoutDelayMs"];
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideogoogNacksSent] forKey:@"googNacksSent"];
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideogoogPlisSent] forKey:@"googPlisSent"];
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideogoogRenderDelayMs] forKey:@"googRenderDelayMs"];
    
    [rxVideo setObject:[NSNumber numberWithInteger:_rxVideogoogTargetDelayMs] forKey:@"googTargetDelayMs"];
    
    if(_rxVideoCodecName != nil)[rxVideo setObject:_rxVideoCodecName forKey:@"googCodecName"];
    
    ///////////////////////////////////////////////////////////////////
    
    [rxAudio setObject:[NSNumber numberWithInteger:_rxAudioOutputLevel] forKey:@"audioOutputLevel"];
    
    [rxAudio setObject:[NSNumber numberWithInteger:_rxAudioBytesReceived] forKey:@"bytesReceived"];
    
    [rxAudio setObject:[NSNumber numberWithInteger:_rxAudioPacketsLost] forKey:@"packetsLost"];
    
    [rxAudio setObject:[NSNumber numberWithInteger:_rxAudioPacketsReceived] forKey:@"packetsReceived"];
    
    [rxAudio setObject:[NSNumber numberWithInteger:_rxAudiogoogCaptureStartNtpTimeMs] forKey:@"googCaptureStartNtpTimeMs"];
    
    [rxAudio setObject:[NSNumber numberWithInteger:_rxAudiogoogCurrentDelayMs] forKey:@"googCurrentDelayMs"];
    
    [rxAudio setObject:[NSNumber numberWithInteger:_rxAudiogoogDecodingCNG] forKey:@"googDecodingCNG"];
    
    [rxAudio setObject:[NSNumber numberWithInteger:_rxAudiogoogDecodingCTN] forKey:@"googDecodingCTN"];
    
    [rxAudio setObject:[NSNumber numberWithInteger:_rxAudiogoogDecodingCTSG] forKey:@"googDecodingCTSG"];
    
    [rxAudio setObject:[NSNumber numberWithInteger:_rxAudiogoogDecodingNormal] forKey:@"googDecodingNormal"];
    
    [rxAudio setObject:[NSNumber numberWithInteger:_rxAudiogoogDecodingPLC] forKey:@"googDecodingPLC"];
    
    [rxAudio setObject:[NSNumber numberWithInteger:_rxAudiogoogDecodingPLCCNG] forKey:@"googDecodingPLCCNG"];
    
    [rxAudio setObject:[NSNumber numberWithInteger:_rxAudiogoogExpandRate] forKey:@"googExpandRate"];
    
    [rxAudio setObject:[NSNumber numberWithInteger:_rxAudiogoogJitterBufferMs] forKey:@"googJitterBufferMs"];
    
    [rxAudio setObject:[NSNumber numberWithInteger:_rxAudiogoogJitterReceived] forKey:@"googJitterReceived"];
    
    [rxAudio setObject:[NSNumber numberWithInteger:_rxAudiogoogPreferredJitterBufferMs] forKey:@"googPreferredJitterBufferMs"];
    
    if(_rxAudioCodecName != nil)[rxAudio setObject:_rxAudioCodecName forKey:@"googCodecName"];
    
//    if(_rxAudiogoogPreemptiveExpandRate != nil)[rxAudio setObject:_rxAudiogoogPreemptiveExpandRate forKey:@"googPreemptiveExpandRate"];
    
//    if(_rxAudiogoogAccelerateRate != nil)[rxAudio setObject:_rxAudiogoogAccelerateRate forKey:@"googAccelerateRate"];
    
//    if(_rxAudiogoogSecondaryDecodedRate != nil)[rxAudio setObject:_rxAudiogoogSecondaryDecodedRate forKey:@"googSecondaryDecodedRate"];
    
//    if(_rxAudiogoogSpeechExpandRate != nil)[rxAudio setObject:_rxAudiogoogSpeechExpandRate forKey:@"googSpeechExpandRate"];
    
    ///////////////////////////////////////////////////////////////////
    
    [txVideo setObject:[NSNumber numberWithInteger:_txVideoBytesSent] forKey:@"bytesSent"];
    
    [txVideo setObject:[NSNumber numberWithInteger:_txVideoEncodeUsagePercent] forKey:@"googEncodeUsagePercent"];
    
    [txVideo setObject:[NSNumber numberWithInteger:_txVideoFrameHeightSent] forKey:@"googFrameHeightSent"];
    
    [txVideo setObject:[NSNumber numberWithInteger:_txVideoFrameRateSent] forKey:@"googFrameRateSent"];
    
    [txVideo setObject:[NSNumber numberWithInteger:_txVideoFrameWidthSent] forKey:@"googFrameWidthSent"];
    
    [txVideo setObject:[NSNumber numberWithInteger:_txVideoRtt] forKey:@"googRtt"];
    
    [txVideo setObject:[NSNumber numberWithInteger:_txVideoPacketsLost] forKey:@"packetsLost"];
    
    [txVideo setObject:[NSNumber numberWithInteger:_txVideoPacketsSent] forKey:@"packetsSent"];
    
    [txVideo setObject:[NSNumber numberWithInteger:_txVideogoogAdaptationChanges] forKey:@"googAdaptationChanges"];
    
    [txVideo setObject:[NSNumber numberWithInteger:_txVideogoogAvgEncodeMs] forKey:@"googAvgEncodeMs"];
    
    [txVideo setObject:[NSNumber numberWithInteger:_txVideogoogFirsReceived] forKey:@"googFirsReceived"];
    
    [txVideo setObject:[NSNumber numberWithInteger:_txVideogoogFrameHeightInput] forKey:@"googFrameHeightInput"];
    
    [txVideo setObject:[NSNumber numberWithInteger:_txVideogoogFrameRateInput] forKey:@"googFrameRateInput"];
    
    [txVideo setObject:[NSNumber numberWithInteger:_txVideogoogFrameWidthInput] forKey:@"googFrameWidthInput"];
    
    [txVideo setObject:[NSNumber numberWithInteger:_txVideogoogNacksReceived] forKey:@"googNacksReceived"];
    
    [txVideo setObject:[NSNumber numberWithInteger:_txVideogoogPlisReceived] forKey:@"googPlisReceived"];
    
    if(_txVideoCodecName != nil)[txVideo setObject:_txVideoCodecName forKey:@"googCodecName"];
    
    ///////////////////////////////////////////////////////////////////
    
    [txAudio setObject:[NSNumber numberWithInteger:_txAudioInputLevel] forKey:@"audioInputLevel"];
    
    [txAudio setObject:[NSNumber numberWithInteger:_txAudioBytesSent] forKey:@"bytesSent"];
    
    [txAudio setObject:[NSNumber numberWithInteger:_txAudioPacketsLost] forKey:@"packetsLost"];
    
    [txAudio setObject:[NSNumber numberWithInteger:_txAudioPacketsSent] forKey:@"packetsSent"];
    
    [txAudio setObject:[NSNumber numberWithInteger:_txAudiogoogEchoCancellationQualityMin] forKey:@"googEchoCancellationQualityMin"];
    
    [txAudio setObject:[NSNumber numberWithInteger:_txAudiogoogEchoCancellationEchoDelayMedian] forKey:@"googEchoCancellationEchoDelayMedian"];
    
    [txAudio setObject:[NSNumber numberWithInteger:_txAudiogoogEchoCancellationEchoDelayStdDev] forKey:@"googEchoCancellationEchoDelayStdDev"];
    
    [txAudio setObject:[NSNumber numberWithInteger:_txAudiogoogEchoCancellationReturnLoss] forKey:@"googEchoCancellationReturnLoss"];
    
    [txAudio setObject:[NSNumber numberWithInteger:_txAudiogoogEchoCancellationReturnLossEnhancement] forKey:@"googEchoCancellationReturnLossEnhancement"];
    
    [txAudio setObject:[NSNumber numberWithInteger:_txAudiogoogJitterReceived] forKey:@"googJitterReceived"];
    
    [txAudio setObject:[NSNumber numberWithInteger:_txAudiogoogRtt] forKey:@"googRtt"];
    
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
