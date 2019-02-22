//
//  IrisRtcStream.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 9/26/16.
//  Copyright © 2016 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IrisRtcStream.h"
#import "WebRTCFactory.h"
#import "WebRTC/WebRTC.h"

#import "WebRTCError.h"
#import "IrisRtcUtils.h"
#import <AVFoundation/AVFoundation.h>
#import "IrisRtcSdk.h"
#import "IrisRtcStream+Internal.h"
#import "IrisRtcMediaTrack+Internal.h"
#import "IrisLogging.h"

#define WEBRTC_ERR_INCORRECT_PARAMETERS -1
#define WEBRTC_ERR_INCORRECT_STATE      -2

NSString* const IrisRtcStreamTag= @"IrisRtcStream";


@interface IrisRtcStream()
{
    bool isStarted;
    NSString * cameraID;
    RTCPeerConnectionFactory *pcfactory;
    
    RTCVideoTrack *localVideoTrack;
    RTCAudioTrack *localAudioTrack;
    RTCAVFoundationVideoSource *videoSource;
    AVCaptureDevicePosition requiredPos;
    BOOL localDummyStream;
    
    
}

@property(nonatomic,weak) id<IrisRtcStreamDelegate> delegate;
@property(nonatomic,weak) id<IrisRtcSdkStreamDelegate> streamdelegate;
@property(nonatomic)RTCMediaStream* lms;
@property(nonatomic) IrisRtcSdkStreamType streamType;
@property(nonatomic) IrisRtcSdkStreamQuality streamQuality;
@property(nonatomic) BOOL isLocalTrackAdded;
@property(nonatomic) BOOL isVideoEnable;
@property(nonatomic)BOOL isAudioMuted;
-(NSString*)getCameraId:(NSInteger)position;

-(void)localTrack;

-(void)addVideoTrack;

-(void)setAspectRatio43:(BOOL)value;

@end

@implementation IrisRtcMediaTrack

-(void)addRenderer:(IrisRtcRenderer*)renderer delegate:(id<IrisRtcRendererDelegate>)delegate
{
    [_videoTrack addRenderer:renderer.videoView];
}

-(void)removeRenderer:(IrisRtcRenderer*)renderer
{
    [_videoTrack removeRenderer:renderer.videoView];
}

@end

@implementation IrisRtcStream


-(id)initWithDelegate:(id<IrisRtcStreamDelegate>)delegate error:(NSError **)outError
{
    //IrisRtcStream* stream =  [[IrisRtcStream alloc]initWithDefaultValue:kStreamTypeVideo streamQuality:kStreamQualityVGA delegate:delegate];
    //[stream start];
    //return stream;
    self = [super init];
    if (self!=nil) {
        
        isStarted = false;
        self.streamType = kStreamTypeVideo;
        self.streamQuality = kStreamQualityHD;
        self.delegate = delegate;
        _isVideoEnable = false;
        _isLocalTrackAdded = false;
        // Get capture device
        cameraID = nil;
        cameraID = [self getCameraId:AVCaptureDevicePositionBack];
        requiredPos = AVCaptureDevicePositionBack;
        // Try front camera for auto mode
        if (cameraID == nil)
        {
            // Try front camera
            requiredPos = AVCaptureDevicePositionFront;
            cameraID = [self getCameraId:AVCaptureDevicePositionFront];
            
        }
        
#if TARGET_IPHONE_SIMULATOR
        
        IRISLogInfo(@"Target is : Simulator");
        //Simulator can't access the camera, so not throwing any exception.
#else
        
        IRISLogInfo(@"Target is : Device");
        // If camera not found throw an error
        if (cameraID == nil)
        {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Unable to open the camera" forKey:NSLocalizedDescriptionKey];
            // populate the error object with the details
            *outError = [NSError errorWithDomain:IrisRtcStreamTag code:ERR_CAMERA_NOT_FOUND userInfo:details];
            return nil;
        }
#endif
        
        
        
    }
    return self;
    
    
}

-(id)initWithType:(IrisRtcSdkStreamType)type quality:(IrisRtcSdkStreamQuality)quality cameraType:(IrisRtcCameraType)cameraType delegate:(id<IrisRtcStreamDelegate>)delegate error:(NSError **)outError
{
    self = [super init];
    if (self!=nil) {
        
        isStarted = false;
        self.streamType = type;
        self.streamQuality = quality;
        self.delegate = delegate;
        _isVideoEnable = false;
        _isLocalTrackAdded = false;
        // Get capture device
        cameraID = nil;
        if(cameraType == kCameraTypeBack)
        {
            cameraID = [self getCameraId:AVCaptureDevicePositionBack];
            requiredPos = AVCaptureDevicePositionBack;
            if (cameraID == nil)
            {
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                [details setValue:@"Unable to open the camera" forKey:NSLocalizedDescriptionKey];
                // populate the error object with the details
                *outError = [NSError errorWithDomain:IrisRtcStreamTag code:ERR_CAMERA_NOT_FOUND userInfo:details];
                return nil;
            }
        }
        else
        {
            cameraID = [self getCameraId:AVCaptureDevicePositionFront];
            requiredPos = AVCaptureDevicePositionFront;
            if (cameraID == nil)
            {
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                [details setValue:@"Unable to open the camera" forKey:NSLocalizedDescriptionKey];
                // populate the error object with the details
                *outError = [NSError errorWithDomain:IrisRtcStreamTag code:ERR_CAMERA_NOT_FOUND userInfo:details];
                return nil;
            }
        }
    }
    return self;
    
}

-(void)startPreview
{
    if(!_isVideoEnable)
    {
        if(_isLocalTrackAdded)
        {
            [self startVideo];
        }
        else
        {
            [self start];
        }
        
        _isVideoEnable = true;
    }
    
    
}

-(void)stopPreview
{
    if(_isVideoEnable)
    {
        [self stopVideo];
        _isVideoEnable = false;
    }
}

-(void)flip
{
    if (videoSource)
        [videoSource setUseBackCamera:!videoSource.useBackCamera];
}

#pragma mark - Internal methods

- (int)start
{
    // Get the factory to access other PC methods
    pcfactory = [WebRTCFactory getPeerConnectionFactory];
    
    if (pcfactory == nil)
    {
        IRISLogError(@" Error creating peerconnection factory");
        return -1;
    }
    
    [self localTrack];
    
    
    return 0;
}

-(void)close
{
    IRISLogInfo(@"IrisRtcStream close");
    //[WebRTCFactory DestroyPeerConnectionFactory];
    //_isRecordingEnabled = false;
    localVideoTrack = nil;
    isStarted = false;
    cameraID = nil;
    pcfactory = nil;
    _isVideoEnable = false;
    _isLocalTrackAdded = false;
    self.delegate = nil;
    //[WebRTCFactory DestroyPeerConnectionFactory];
    
}

-(void)fakelocalStream
{
    IRISLogInfo( @" fakelocalStream******");
    
    // Create media stream and add audio track
    /*lms = [pcfactory mediaStreamWithLabel:@"ARDAMS"];
    [lms addAudioTrack:[pcfactory audioTrackWithID:@"ARDAMSa0"]];
    [lms addVideoTrack:[pcfactory videoTrackWithID:@"ARDAMSv0" source:nil]];*/
    
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

-(void)localTrack
{
    IRISLogVerbose(@"localTrack******");
    
    if(_streamType == kStreamTypeAudio || _streamType == kStreamTypeVideo)
    {
        NSString *streamID = [NSString stringWithFormat:@"iOSStream%@",[self getRandomId]];
        NSString *trackId = [NSString stringWithFormat:@"iOSAudioTrack%@",[self getRandomId]];
        IRISLogVerbose(@"localTrack****** streamID = %@ and trackId = %@",streamID,trackId);
        _lms = [pcfactory mediaStreamWithStreamId:streamID];
        localAudioTrack = [pcfactory audioTrackWithTrackId:trackId];
        [_lms addAudioTrack:localAudioTrack];
        
        //_lms = [pcfactory mediaStreamWithStreamId:@"ARDAMS"];
    }
    
    if(_streamType != kStreamTypeAudio)
    {
        [self addVideoTrack];
    }
    
    isStarted = true;
}

-(void)addVideoTrack
{
    NSString* minWidth;
    NSString* minHeight;
    NSString* maxWidth;
    NSString* maxHeight;
    
    if(_streamQuality == kStreamQualityFullHD)
    {
        minWidth = @"1920";
        minHeight = @"1080";
        maxWidth = @"1920";
        maxHeight = @"1080";
    }
    else
    if(_streamQuality == kStreamQualityHD)
    {
        minWidth = @"1280";
        minHeight = @"720";
        maxWidth = @"1280";
        maxHeight = @"720";
    }
    else
    if(_streamQuality == kStreamQualityVGA)
    {
        minWidth = @"640";
        minHeight = @"480";
        maxWidth = @"640";
        maxHeight = @"480";
    }
    else
    if(_streamQuality == kStreamQualityQCIF)
    {
        minWidth = @"320";
        minHeight = @"240";
        maxWidth = @"320";
        maxHeight = @"240";
    }
    
    NSDictionary *constraintPairs = @{
                                      kRTCMediaConstraintsMinHeight: minHeight,
                                      kRTCMediaConstraintsMaxHeight: maxHeight,
                                      kRTCMediaConstraintsMinWidth: minWidth,
                                      kRTCMediaConstraintsMaxWidth: maxWidth,
                                      kRTCMediaConstraintsMinFrameRate: [[NSString alloc] initWithFormat:@"%d", DEFAULT_MIN_FRAMERATE],
                                      kRTCMediaConstraintsMaxFrameRate: [[NSString alloc] initWithFormat:@"%d", DEFAULT_MAX_FRAMERATE]
                                      };
    
    RTCMediaConstraints *localMediaConstrains = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:constraintPairs optionalConstraints:nil];
    

    // Set it to true to enable 4:3 video aspect ratio
    [self setAspectRatio43:false];
    
    //Create Video source
    // Create Video source
    videoSource =
    [pcfactory avFoundationVideoSourceWithConstraints:localMediaConstrains];
    if(!videoSource)
    {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Unable to apply the constraints" forKey:NSLocalizedDescriptionKey];
        
        NSError *error = [NSError errorWithDomain:IrisRtcStreamTag code:ERR_INVALID_CONSTRAINTS userInfo:details];
        
        //[self.delegate onIrisRtcStreamError:error.description errorCode:error.code additionalData:nil];
    }
    
    // Create a video track
    NSString *trackId = [NSString stringWithFormat:@"iOSVideoTrack%@",[self getRandomId]];
    localVideoTrack =
    [pcfactory videoTrackWithSource:videoSource
                            trackId:trackId];
    
    [_lms addVideoTrack:localVideoTrack];
    
    //Add video track to media stream
    if (localVideoTrack) {
        IRISLogInfo(@"Calling localvideo track");

        IrisRtcMediaTrack* localStream = [[IrisRtcMediaTrack alloc]init];
        localStream.videoTrack = localVideoTrack;
        _isLocalTrackAdded = true;
        _isVideoEnable = true;
        [self.delegate onLocalStream:self mediaTrack:localStream];
        
        
    }
}

// API to mute the current running track
- (int)mute
{
    int errCode=0;
    IRISLogInfo(@" muteAudio!!!" );
    
    // Error check
    errCode = [self StateErrorCheck];
    if (errCode != 0)
        return errCode;
    
    IRISLogVerbose(@" go through the tracks !!!");
    
    localAudioTrack.isEnabled = false;
    _isMuted = true;
    
    if(_streamdelegate)
    [self.streamdelegate onAudioMute:true];
    
    return 0;
}
- (int)unmute
{
    int errCode=0;
    
    // Error check
    errCode = [self StateErrorCheck];
    if (errCode != 0)
        return errCode;
    
    localAudioTrack.isEnabled = true;
    _isMuted = false;
    
     [self.streamdelegate onAudioMute:false];
    
    return 0;
}
- (int)stopVideo
{
    int errCode=0;
    
    // Error check
    errCode = [self StateErrorCheck];
    if (errCode != 0)
        return errCode;

    localVideoTrack.isEnabled = false;
    
     [self.streamdelegate onVideoMute:true];
    
    return 0;
}
- (int)startVideo
{
    int errCode=0;
    
    // Error check
    errCode = [self StateErrorCheck];
    if (errCode != 0)
        return errCode;
    
    localVideoTrack.isEnabled = true;
    
     [self.streamdelegate onVideoMute:false];
    
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
    
    return localVideoTrack.isEnabled;
}



-(int)StateErrorCheck
{
    // Check if the stream has been initialised
    if (self == nil)
    {
        IRISLogWarn(@" Stream not initialized !!!");
        return WEBRTC_ERR_INCORRECT_STATE;
    }
    // Check if the stream is started
    if (!isStarted)
    {
        IRISLogWarn(@" Stream not started !!!");
        return WEBRTC_ERR_INCORRECT_STATE;
    }

    return 0;
}

// Enable 4:3 video aspect ratio
-(void)setAspectRatio43:(BOOL)value
{
    NSMutableDictionary *aspect = [[NSMutableDictionary alloc]init];
    [aspect setValue:[NSNumber numberWithBool:value]  forKey:@"aspectRatio"];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"AspectRatioChangeNotification" object:nil userInfo:aspect];
}

-(NSString *)getRandomId
{
    NSMutableString *returnString = [NSMutableString stringWithCapacity:5];
    
    NSString *numbers = @"0123456789";

    for (int i = 0; i < 5; i++)
    {
        [returnString appendFormat:@"%C", [numbers characterAtIndex:arc4random() % [numbers length]]];
    }
    
    return returnString;
}


@end


@implementation IrisRtcStream (Internal)

-(IrisRtcSdkStreamType)getStreamType
{
    return _streamType;
}

-(RTCAudioTrack*)getAudioTrack
{
    return localAudioTrack;
}
-(RTCVideoTrack*)getVideoTrack
{
    return localVideoTrack;
}

-(RTCMediaStream*)getMediaStream
{
    return _lms;
}

-(void)setStreamDelegate:(id)delegate{
    self.streamdelegate = delegate;
}




@end

