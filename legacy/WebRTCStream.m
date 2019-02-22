//
//  WebRTCStream.m
//  XfinityVideoShare
//
//  Created by Ganvir, Manish (Contractor) on 5/29/14.
//  Copyright (c) 2014 Infosys. All rights reserved.
//
#ifdef ENABLE_LEGACY_CODE

#import "WebRTCStream.h"
#import "WebRTCFactory.h"
#import "WebRTC/WebRTC.h"

#import "WebRTCError.h"
#import "WebRTCLogHandler.h"
#import "WebRTCLogging.h"

NSString* const Stream= @"Stream";

NSString * const WebRTCRecordEventKey = @"WebRTCRecordEventKey";
NSString * const WebRTCRecordEventDetailKey = @"WebRTCRecordEventDetailKey";

#ifdef ENABLE_RECORDING
@interface WebRTCStream () <RTCMediaStreamRecordingDelegate>
    @property (nonatomic) BOOL isRecordingEnabled;
    @property (nonatomic) NSMutableDictionary* recordState;
    @property (nonatomic) BOOL isRecordingStarted;
#else
@interface WebRTCStream ()
#endif

@end


@implementation WebRTCStream

NSString* const TAG6 = @"WebRTCStream";

- (id)initWithDefaultValue:(WebRTCStreamConfig*)_streamConfig;
{
    // Initialize self
    self = [super init];
    
    // Check whether we are initialized
    if (self!=nil)
    {
        streamConfig = _streamConfig;
        camType = streamConfig.camType;
        isStarted = false;
        localAudioTrack = nil;
        localVideoTrack = nil;
        
#ifdef ENABLE_RECORDING
        _recordState = [[NSMutableDictionary alloc]init];
        _isRecordingStarted = false;
        _isRecordingEnabled = false;
#endif
        // Get capture device
        cameraID = nil;

    
        // If the camera type is auto, first try back camera and then try front camera
        if ((camType == CAM_TYPE_AUTO) || (camType == CAM_TYPE_BACK))
            requiredPos = AVCaptureDevicePositionBack;
        else
            requiredPos = AVCaptureDevicePositionFront;
        
            cameraID = [self getCameraId:requiredPos];
        
        // Try front camera for auto mode
        if (cameraID == nil)
        {
            // Try front camera
            requiredPos = AVCaptureDevicePositionFront;
            cameraID = [self getCameraId:requiredPos];
            
        }
        
        // If camera not found throw an error
        if (cameraID == nil)
        {
            return NULL;
        }
    }
    return self;
}


-(NSString*)getCameraId:(NSInteger)position
{
    NSString* camID;
    AVCaptureDevice *captureDevice;
    for (captureDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
    {
        if (captureDevice.position == position) {
            camID = [captureDevice localizedName];
            
            
            break;
        }
    }
    captureDevice = nil;
    return camID;
}
- (id)initWithDefaultValue
{
    self = [super init];
    if (self!=nil) {
        camType = CAM_TYPE_NONE;
        isStarted = false;
    }
    
    localAudioTrack = nil;
    localVideoTrack = nil;
    
    return self;
    
}

-(void)CreateLocalTracks
{
    LogDebug( @" localTrack******");
    
    if(!(streamConfig.videoOnlyFlag))
    {
        localAudioTrack = [pcfactory audioTrackWithTrackId:@"ARDAMSa0"];
    }
    
    if (camType != CAM_TYPE_NONE)
    {
        BOOL IsVideoCall = [self.delegate isStreamVideoEnable];
        if(IsVideoCall)
        {
            LogDebug(@" CreateLocalTracks called ");
            
            NSDictionary *constraintPairs = @{
                                              kRTCMediaConstraintsMinHeight: [NSString stringWithFormat: @"%d", (int)streamConfig.vMinResolution],
                                              kRTCMediaConstraintsMaxHeight: [NSString stringWithFormat: @"%d", (int)streamConfig.vMaxResolution],
                                              kRTCMediaConstraintsMinWidth: [NSString stringWithFormat: @"%d", (int)streamConfig.hMinResolution],
                                              kRTCMediaConstraintsMaxWidth: [NSString stringWithFormat: @"%d", (int)streamConfig.hMaxResolution],
                                              kRTCMediaConstraintsMinFrameRate: [NSString stringWithFormat: @"%d", (int)streamConfig.minFrameRate],
                                              kRTCMediaConstraintsMaxFrameRate: [NSString stringWithFormat: @"%d", (int)streamConfig.maxFrameRate]
                                              };

            RTCMediaConstraints *localMediaConstrains = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:constraintPairs optionalConstraints:nil];
            
            // Enable 4:3 video aspect ratio
            [self setAspectRatio43:streamConfig.aspectRatio43];
            
            //Setting start bandwidth value
            // [RTCPeerConnectionFactory setkStartBandwidthBps:400000];
            
            // Create Video source
            RTCAVFoundationVideoSource *source =
            [pcfactory avFoundationVideoSourceWithConstraints:localMediaConstrains];
            
            // Create a video track
            localVideoTrack =
            [pcfactory videoTrackWithSource:source
                                    trackId:@"ARDAMSv0"];
            
            if(!source)
            {
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                [details setValue:@"Unable to apply the constraints" forKey:NSLocalizedDescriptionKey];
                
                NSError *error = [NSError errorWithDomain:Stream code:ERR_INVALID_CONSTRAINTS userInfo:details];
                
                [self.delegate onStreamError:error.description errorCode:error.code];
            }
            
            else
            {
                //Add video track to media stream
                if (localVideoTrack) {
                    LogDebug(@"Calling localvideo track");
                    [self.delegate OnLocalStream:localVideoTrack];
#ifdef ENABLE_RECORDING
                    _isRecordingEnabled = true;
#endif
                }
                else
                {
                    NSError *error = [NSError errorWithDomain:Stream
                                                     code:ERR_LOCAL_TRACK
                                                 userInfo:nil];
                    [self.delegate onStreamError:error.description errorCode:error.code];
                }
            }

        }
    }
    isStarted = true;
}

-(void)fakelocalStream
{
    LogDebug( @" fakelocalStream******");
    
    // Create media stream and add audio track
    /*lms = [pcfactory mediaStreamWithLabel:@"ARDAMS"];
    [lms addAudioTrack:[pcfactory audioTrackWithID:@"ARDAMSa0"]];
    [lms addVideoTrack:[pcfactory videoTrackWithID:@"ARDAMSv0" source:nil]];*/
    
}

- (int)start
{
    // Get the factory to access other PC methods
    pcfactory = [WebRTCFactory getPeerConnectionFactory];
    
    if (pcfactory == nil)
    {
        LogError(@" Error creating peerconnection factory");
        NSError *error = [NSError errorWithDomain:Stream
                                             code:ERR_PC_FACTORY
                                         userInfo:nil];
        [self.delegate onStreamError:error.description errorCode:error.code];
        return -1;
    }
    
    if(streamConfig.isDummyStream)
        [self fakelocalStream];
    else
        [self CreateLocalTracks];
    
    
    return 0;
}
- (int)stop
{
    //[WebRTCFactory DestroyPeerConnectionFactory];
#ifdef ENABLE_RECORDING
    _isRecordingEnabled = false;
#endif
    localVideoTrack = nil;
    localAudioTrack = nil;
    isStarted = false;
    cameraID = nil;
    streamConfig = nil;
    pcfactory = nil;

    return OK_NO_ERROR;
}
- (bool)IsStarted
{
    return isStarted;
}

-(int)StateErrorCheck
{
    // Check if the stream has been initialised
    if (self == nil)
    {
        LogDebug(@" Stream not initialized !!!");
        return WEBRTC_ERR_INCORRECT_STATE;
    }
    // Check if the stream is started
    if (!isStarted)
    {
        LogDebug(@" Stream not started !!!");
        return WEBRTC_ERR_INCORRECT_STATE;
    }
    
    return 0;
}
// API to mute the current running track
- (int)muteAudio
{
    int errCode=0;
    LogDebug(@" muteAudio!!!" );

    // Error check
    errCode = [self StateErrorCheck];
    if (errCode != 0)
        return errCode;
    
    LogDebug(@" go through the tracks !!!");

    localAudioTrack.isEnabled = false;
    
    return 0;
}
- (int)unmuteAudio
{
    int errCode=0;
    
    // Error check
    errCode = [self StateErrorCheck];
    if (errCode != 0)
        return errCode;
    
    localAudioTrack.isEnabled = true;

    return 0;
}
- (int)stopVideo
{
    int errCode=0;
    
    // Error check
    errCode = [self StateErrorCheck];
    if (errCode != 0)
        return errCode;
    if (camType == CAM_TYPE_NONE)
        return WEBRTC_ERR_INCORRECT_STATE;
    
    localVideoTrack.isEnabled = false;

    return 0;
}
- (int)startVideo
{
    int errCode=0;
    
    // Error check
    errCode = [self StateErrorCheck];
    if (errCode != 0)
        return errCode;
    
    if (camType == CAM_TYPE_NONE)
        return WEBRTC_ERR_INCORRECT_STATE;
    
    localVideoTrack.isEnabled = true;

    return WEBRTC_ERR_INCORRECT_STATE;
}
- (BOOL)isAudioMuted
{
    int errCode=0;
    
    // Error check
    errCode = [self StateErrorCheck];
    if (errCode != 0)
        return false;
    
    // Get Camera
    return localAudioTrack.isEnabled;
}
- (BOOL)isVideoStarted
{
    int errCode=0;
    
    
    // Error check
    errCode = [self StateErrorCheck];
    if (errCode != 0)
        return false;
    
    if (camType == CAM_TYPE_NONE)
        return WEBRTC_ERR_INCORRECT_STATE;
    
    return localVideoTrack.isEnabled;
}


-(void)applyStreamConfigChange:(WebRTCStreamConfig*)configParam
{
    LogDebug(@"Inside applyStreamConfigChange");
    // TBD
}

- (WebRTCStreamConfig*) getStreamConfig
{
    return streamConfig;
}
#ifdef ENABLE_RECORDING

- (int)startRecording
{
    //TODO: Implement startRecording functionality
    if(!_isRecordingEnabled)
    {
        LogDebug(@"WebRTC::startRecording Stream has not started yet!!!" );
        return ERR_INCORRECT_STATE;
    }
    
    // Check if recording has already started
    if (_isRecordingStarted)
    {
        LogDebug(@"WebRTC::startRecording recording has already started!!!" );
        return ERR_INCORRECT_STATE;
    }
    
    // Call media stream recording API
    [lms startRecording:streamConfig.recordedFilePath videoquality:(int)streamConfig.recordingQuality videoHeight:[localVideoTrack getVideoHeight] videoWidth:[localVideoTrack getVideoWidth ]  delegate:self];
    
    _isRecordingStarted = true;
    
    return 0;
}

- (int)stopRecording
{
    // Check if recording has already started
    if (!_isRecordingStarted)
    {
        LogDebug(@"WebRTC::startRecording recording has already stopped!!!" );
        return ERR_INCORRECT_STATE;
    }
    
    _isRecordingStarted = false;
    
    [lms stopRecording];
    
    return 0;
}

- (NSDictionary*)getRecordingStatus
{
    return nil;
}

#pragma mark - RTCMediaStreamRecordingDelegate delegates

// Call back to receive recording events
- (void) onLmsRecordingEvent:(NSDictionary *)state
{
    LogDebug(@"WebRTC::onLmsRecordingEvent state %@", state.description );

    if([self.recordingDelegate conformsToProtocol:@protocol(WebRTCAVRecordingDelegate)] && [self.recordingDelegate respondsToSelector:@selector(onRecordingEvent:)]) {
        
        [_recordState setValuesForKeysWithDictionary:state];
        if ([state[@"Event"] isEqualToString:@"Started"])
        {
            [_recordState setValue:[NSNumber numberWithInteger:WebRTCAVRecordingStarted] forKey:WebRTCRecordEventKey];
        }
        else if ([state[@"Event"] isEqualToString:@"Finished"])
        {
            [_recordState setValue:[NSNumber numberWithInteger:WebRTCAVRecordingEnded] forKey:WebRTCRecordEventKey];
        }
        [self.recordingDelegate onRecordingEvent:_recordState];
    }
}

// Call back to receive recording errors
- (void) onLmsRecordingError:(NSString*)error errorCode:(NSInteger)code
{
    LogDebug(@"WebRTC::onLmsRecordingError error %@", error);

    if([self.recordingDelegate conformsToProtocol:@protocol(WebRTCAVRecordingDelegate)] && [self.recordingDelegate respondsToSelector:@selector(onRecordingError:errorCode:)]) {
        [self.recordingDelegate onRecordingError:error errorCode:code ];
    }
}
#endif
// Enable 4:3 video aspect ratio
-(void)setAspectRatio43:(BOOL)value
{
    NSMutableDictionary *aspect = [[NSMutableDictionary alloc]init];
    [aspect setValue:[NSNumber numberWithBool:value]  forKey:@"aspectRatio"];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"AspectRatioChangeNotification" object:nil userInfo:aspect];
}

-(RTCAudioTrack*)getAudioTrack
{
    return localAudioTrack;
}
-(RTCVideoTrack*)getVideoTrack
{
    return localVideoTrack;
}
@end
#endif
