//
//  WebRTCStream.h
//  XfinityVideoShare
//
//  Created by Ganvir, Manish (Contractor) on 5/29/14.
//  Copyright (c) 2014 Infosys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "WebRTC/WebRTC.h"

#import "WebRTCStreamConfig.h"
#import "WebRTCAVRecordingDelegate.h"

// Error codes returned by APIs
#define WEBRTC_ERR_INCORRECT_PARAMETERS -1
#define WEBRTC_ERR_INCORRECT_STATE      -2

@protocol WebRTCStreamDelegate <NSObject>

- (void) OnLocalStream:(RTCVideoTrack *)videoTrack;
- (void) onStreamError:(NSString*)error errorCode:(NSInteger)code;
- (BOOL) isStreamVideoEnable;
@end
@interface WebRTCStream : NSObject
{
    bool isStarted;
    WebRTCCamera_type_e camType;
    RTCPeerConnectionFactory *pcfactory;
    NSString * cameraID;
    RTCVideoTrack *localVideoTrack;
    RTCAudioTrack *localAudioTrack;

    WebRTCStreamConfig* streamConfig;
    AVCaptureDevicePosition requiredPos;
    BOOL localDummyStream;

}
@property(nonatomic,weak) id<WebRTCStreamDelegate> delegate;
@property(nonatomic,weak) id<WebRTCAVRecordingDelegate> recordingDelegate;
//@property (nonatomic) WebRTCAVRecording* avRecording;
//Below API's are called from the application for configuring the stream

-(void)applyStreamConfigChange:(WebRTCStreamConfig*)configParam;
- (int)start;
- (int)stop;
- (int)stopVideo;
- (int)startVideo;
- (int)muteAudio;
- (int)unmuteAudio;
#ifdef ENABLE_RECORDING
//Below API's used for start and stop recording
-(int)startRecording;
-(int)stopRecording;
-(NSDictionary*)getRecordingStatus;
#endif
-(void)setAspectRatio43:(BOOL)value;


//Below mentioned API's are for internal purpose only

- (id)initWithDefaultValue:(WebRTCStreamConfig*)_streamConfig;
- (id)initWithDefaultValue;
- (BOOL)isAudioMuted;
- (BOOL)isVideoStarted;
- (bool)IsStarted;
-(NSString*)getCameraId:(NSInteger)position;
- (WebRTCStreamConfig*) getStreamConfig;
-(RTCAudioTrack*)getAudioTrack;
-(RTCVideoTrack*)getVideoTrack;
@end
