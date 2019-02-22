/*
 *  Copyright 2015 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "ARDSDPUtils.h"

#import "WebRTC/WebRTC.h"
#import "IrisLogging.h"

@implementation ARDSDPUtils

+ (RTCSessionDescription *)
    descriptionForDescription:(RTCSessionDescription *)description
          preferredVideoCodec:(NSString *)codec {
    
  NSString *sdpString = description.description;
    //IRISLogInfo(@"preferredVideoCodec at start = %@",sdpString);
  NSString *lineSeparator = @"\n";
  NSString *mLineSeparator = @" ";
    NSString *mangledSdpString;
  // Copied from PeerConnectionClient.java.
  // TODO(tkchin): Move this to a shared C++ file.
  NSMutableArray *lines =
      [NSMutableArray arrayWithArray:
          [sdpString componentsSeparatedByString:lineSeparator]];

  NSInteger mLineIndex = -1;
  NSString *codecRtpMap = nil;
  // a=rtpmap:<payload type> <encoding name>/<clock rate>
  // [/<encoding parameters>]
  NSString *pattern =
      [NSString stringWithFormat:@"^a=rtpmap:(\\d+) %@(/\\d+)+[\r]?$", codec];
    

 
  NSRegularExpression *regex =
      [NSRegularExpression regularExpressionWithPattern:pattern
                                                options:0
                                                  error:nil];
  for (NSInteger i = 0; (i < lines.count) && (mLineIndex == -1 || !codecRtpMap);
       ++i) {
    NSString *line = lines[i];
    if ([line hasPrefix:@"m=video"]) {
      mLineIndex = i;
      continue;
    }
    NSTextCheckingResult *codecMatches =
        [regex firstMatchInString:line
                          options:0
                            range:NSMakeRange(0, line.length)];
    if (codecMatches) {
        
      codecRtpMap =
          [line substringWithRange:[codecMatches rangeAtIndex:1]];


      continue;
    }
  }
  if (mLineIndex == -1) {
    IRISLogInfo(@"No m=video line, so can't prefer %@", codec);
    return description;
  }
  if (!codecRtpMap) {
    IRISLogInfo(@"No rtpmap for %@", codec);
    return description;
  }
  NSArray *origMLineParts =
      [lines[mLineIndex] componentsSeparatedByString:mLineSeparator];
  if (origMLineParts.count > 3) {
    NSMutableArray *newMLineParts =
        [NSMutableArray arrayWithCapacity:origMLineParts.count];
    NSInteger origPartIndex = 0;
    // Format is: m=<media> <port> <proto> <fmt> ...
    [newMLineParts addObject:origMLineParts[origPartIndex++]];
    [newMLineParts addObject:origMLineParts[origPartIndex++]];
    [newMLineParts addObject:origMLineParts[origPartIndex++]];
    [newMLineParts addObject:codecRtpMap];
    for (; origPartIndex < origMLineParts.count; ++origPartIndex) {
        
      if (![codecRtpMap isEqualToString:origMLineParts[origPartIndex]]) {
        [newMLineParts addObject:origMLineParts[origPartIndex]];
      }
    }
    NSString *newMLine =
        [newMLineParts componentsJoinedByString:mLineSeparator];
    [lines replaceObjectAtIndex:mLineIndex
                     withObject:newMLine];

  } else {
    IRISLogError(@"Wrong SDP media description format: %@", lines[mLineIndex]);
  }
 
    
   if([codec containsString:@"H264"]){
      
       BOOL video=NO;
       int insertIndex=0;
       BOOL h264=NO;
       for (int j=0; j<lines.count; j++)
       {
           NSString *line = lines[j];
           if (!video)
           {
               if ([line containsString:@"a=mid:video"])
                   video=YES;
           }
           else
           {
               if (insertIndex==0)
               {
                   if ([line containsString:@"a=rtpmap"])
                       insertIndex=j;
               }
               else
               {
                   if (!h264)
                   {
                       if ([line containsString:@"H264"])
                       {
                           h264=YES;
                           [lines insertObject:line atIndex:insertIndex];
                           [lines removeObjectAtIndex:j+1];
                           insertIndex++;
                       }
                   }
                   else
                   {
                       if ([line containsString:@"a=rtcp"])
                       {
                           [lines insertObject:line atIndex:insertIndex];
                           [lines removeObjectAtIndex:j+1];
                           insertIndex++;
                       }
                       else
                       {
                           break;
                       }
                   }
                   
               }
               
           }
       }
      
       mangledSdpString = [lines componentsJoinedByString:lineSeparator];

    }
    else{
        mangledSdpString = [lines componentsJoinedByString:lineSeparator];
    }
    //IRISLogInfo(@"preferredVideoCodec = %@",mangledSdpString);
    return [[RTCSessionDescription alloc] initWithType:description.type
                                                 sdp:mangledSdpString];
}


+ (NSString *)
descriptionForDescriptionString:(NSString *)description
preferredVideoCodec:(NSString *)codec {
    
    NSString *sdpString = description;
    //IRISLogInfo(@"preferredVideoCodec at start = %@",sdpString);
    NSString *lineSeparator = @"\n";
    NSString *mLineSeparator = @" ";
    NSString *mangledSdpString;
    // Copied from PeerConnectionClient.java.
    // TODO(tkchin): Move this to a shared C++ file.
    NSMutableArray *lines =
    [NSMutableArray arrayWithArray:
     [sdpString componentsSeparatedByString:lineSeparator]];
    
    NSInteger mLineIndex = -1;
    NSString *codecRtpMap = nil;
    // a=rtpmap:<payload type> <encoding name>/<clock rate>
    // [/<encoding parameters>]
    NSString *pattern =
    [NSString stringWithFormat:@"^a=rtpmap:(\\d+) %@(/\\d+)+[\r]?$", codec];
    
    
    
    NSRegularExpression *regex =
    [NSRegularExpression regularExpressionWithPattern:pattern
                                              options:0
                                                error:nil];
    for (NSInteger i = 0; (i < lines.count) && (mLineIndex == -1 || !codecRtpMap);
         ++i) {
        NSString *line = lines[i];
   
        if ([line hasPrefix:@"m=video"]) {
            mLineIndex = i;
            continue;
        }
        NSTextCheckingResult *codecMatches =
        [regex firstMatchInString:line
                          options:0
                            range:NSMakeRange(0, line.length)];
        if (codecMatches) {
            
            codecRtpMap =
            [line substringWithRange:[codecMatches rangeAtIndex:1]];
            
            
            continue;
        }
    }
    if (mLineIndex == -1) {
        IRISLogInfo(@"No m=video line, so can't prefer %@", codec);
        return description;
    }
    if (!codecRtpMap) {
        IRISLogInfo(@"No rtpmap for %@", codec);
        return description;
    }
    NSArray *origMLineParts =
    [lines[mLineIndex] componentsSeparatedByString:mLineSeparator];
    if (origMLineParts.count > 3) {
        NSMutableArray *newMLineParts =
        [NSMutableArray arrayWithCapacity:origMLineParts.count];
        NSInteger origPartIndex = 0;
        // Format is: m=<media> <port> <proto> <fmt> ...
        [newMLineParts addObject:origMLineParts[origPartIndex++]];
        [newMLineParts addObject:origMLineParts[origPartIndex++]];
        [newMLineParts addObject:origMLineParts[origPartIndex++]];
        [newMLineParts addObject:codecRtpMap];
        for (; origPartIndex < origMLineParts.count; ++origPartIndex) {
            
            if (![codecRtpMap isEqualToString:origMLineParts[origPartIndex]]) {
                [newMLineParts addObject:origMLineParts[origPartIndex]];
            }
        }
        NSString *newMLine =
        [newMLineParts componentsJoinedByString:mLineSeparator];
        [lines replaceObjectAtIndex:mLineIndex
                         withObject:newMLine];
        
    } else {
        IRISLogInfo(@"Wrong SDP media description format: %@", lines[mLineIndex]);
    }
    
    
    if([codec containsString:@"H264"]){
        
        BOOL video=NO;
        int insertIndex=0;
        BOOL h264=NO;
        for (int j=0; j<lines.count; j++)
        {
            NSString *line = lines[j];
            if (!video)
            {
                if ([line containsString:@"a=mid:video"])
                video=YES;
            }
            else
            {
                if (insertIndex==0)
                {
                    if ([line containsString:@"a=rtpmap"])
                    insertIndex=j;
                }
                else
                {
                    if (!h264)
                    {
                        if ([line containsString:@"H264"])
                        {
                            h264=YES;
                            [lines insertObject:line atIndex:insertIndex];
                            [lines removeObjectAtIndex:j+1];
                            insertIndex++;
                        }
                    }
                    else
                    {
                        if ([line containsString:@"a=rtcp"])
                        {
                            [lines insertObject:line atIndex:insertIndex];
                            [lines removeObjectAtIndex:j+1];
                            insertIndex++;
                        }
                        else
                        {
                            break;
                        }
                    }
                    
                }
                
            }
        }
        
        mangledSdpString = [lines componentsJoinedByString:lineSeparator];
        
    }
    else{
        mangledSdpString = [lines componentsJoinedByString:lineSeparator];
    }
    //IRISLogInfo(@"preferredVideoCodec = %@",mangledSdpString);
    return mangledSdpString;
}
    
+(NSString *)descriptionForDescriptionString:(NSString *)description
                            preferredAudioCodec:(NSString *)codec {
    
  
    NSString *sdpString = description;
    NSString *lineSeparator = @"\n";
    NSString *mLineSeparator = @" ";
    NSString* isac16kRtpMap = nil;
    NSInteger mLineIndex = -1;
    NSString *mangledSdpString;
    
    BOOL audio=NO;
    int insertIndex=0;
    BOOL isac =NO;

    NSMutableArray *lines =
    [NSMutableArray arrayWithArray:
     [sdpString componentsSeparatedByString:lineSeparator]];
    
    
    NSString *pattern =
    [NSString stringWithFormat:@"^a=rtpmap:(\\d+) %@[\r]?$", codec];
  
    NSRegularExpression* isac16kRegex = [NSRegularExpression
                                             regularExpressionWithPattern:pattern
                                             options:0
                                             error:nil];
        
    
    for (int i = 0; (i < [lines count]) && (mLineIndex == -1 || isac16kRtpMap == nil); ++i) {
            
            NSString* line = [lines objectAtIndex:i];
            
   
            if ([line hasPrefix:@"m=audio"]) {
               
                mLineIndex = i;
                continue;
            }
            
            
            NSTextCheckingResult* result = [isac16kRegex firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
            if (!result)
            isac16kRtpMap = nil;
            else
            isac16kRtpMap =  [line substringWithRange:[result rangeAtIndex:1]];
        }
        
        if (mLineIndex == -1) {
            IRISLogInfo(@" No m=audio line, so can't prefer iSAC");
            return description;
        }
        if (isac16kRtpMap == nil) {
            IRISLogInfo(@" No ISAC/16000 line, so can't prefer iSAC");
            return description;
        }
    
    
        NSArray* origMLineParts =
        [[lines objectAtIndex:mLineIndex] componentsSeparatedByString:@" "];
        NSMutableArray* newMLine =
        [NSMutableArray arrayWithCapacity:[origMLineParts count]];
        int origPartIndex = 0;
        // Format is: m=<media> <port> <proto> <fmt> ...
        [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
        [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
        [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
        [newMLine addObject:isac16kRtpMap];
        for (; origPartIndex < [origMLineParts count]; ++origPartIndex) {
            if ([isac16kRtpMap compare:[origMLineParts objectAtIndex:origPartIndex]]
                != NSOrderedSame) {
                [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex]];
            }
        }
    
    NSString *newLine =
    [newMLine componentsJoinedByString:mLineSeparator];
    [lines replaceObjectAtIndex:mLineIndex
                     withObject:newLine];
    
    for (int j=0; j<lines.count; j++)
        {
            NSString *line = lines[j];
            if (!audio)
            {
                if ([line containsString:@"a=mid:audio"])
                audio=YES;
            }
            else
            {
                if (insertIndex==0)
                {
                    if ([line containsString:@"a=rtpmap"])
                    insertIndex=j;
                }
                else
                {
                    
                    if ([line containsString:codec])
                    {
                       isac=YES;
                       [lines insertObject:line atIndex:insertIndex];
                       [lines removeObjectAtIndex:j+1];
                       insertIndex++;
                     }
 
                  }
                
            }
        }
        
    mangledSdpString = [lines componentsJoinedByString:lineSeparator];
        
    return mangledSdpString;
}
    
    
    
    

@end
