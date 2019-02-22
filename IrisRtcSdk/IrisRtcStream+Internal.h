//
//  IrisRtcStream+Internal.h
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 10/7/16.
//  Copyright © 2016 Gupta, Harish (Contractor). All rights reserved.
//

#ifndef IrisRtcStream_Internal_h
#define IrisRtcStream_Internal_h


@interface IrisRtcStream (Internal)

-(RTCAudioTrack*)getAudioTrack;
-(RTCVideoTrack*)getVideoTrack;
-(RTCMediaStream*)getMediaStream;
-(IrisRtcSdkStreamType)getStreamType;
-(void)setStreamDelegate:(id)delegate;
@end

@protocol IrisRtcSdkStreamDelegate <NSObject>

- (void)onAudioMute:(BOOL)mute;
- (void)onVideoMute:(BOOL)mute;

@end


#endif /* IrisRtcStream_Internal_h */
