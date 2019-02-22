//
// IrisRtcStream.h : Objective C code for managing stream interface used by this SDK
//
// Copyright 2015 Comcast Cable Communications Management, LLC
//
// Permission to use, copy, modify, and/or distribute this software for any purpose
// with or without fee is hereby granted, provided that the above copyright notice
// and this permission notice appear in all copies.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO
// THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
// DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
// AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION
// WITH THE USE OR PERFORMANCE OF THIS SOFTWARE
//

#ifndef IrisRtcStream_h
#define IrisRtcStream_h
#import <UIKit/UIKit.h>
#import "IrisRtcRenderer.h"

/** These constants indicate the type of stream that can be created using the
 * stream API.
 */
typedef NS_ENUM(NSUInteger, IrisRtcSdkStreamType) {
    /** Indicates that both audio (microphone) and video (camera) will be used by
     *  the stream as an input.
     */
    kStreamTypeVideo,
    /** Indicates that only audio (microphone) will be used by
     *  the stream as an input.
     */
    kStreamTypeAudio,
    /** Indicates that only video (camera) will be used by
     *  the stream as an input.
     */
    kStreamTypeVideoOnly
};

/** These constants indicate the type of video resolution that will be used when opening
 * the camera using the stream API.
 */
typedef NS_ENUM(NSUInteger, IrisRtcSdkStreamQuality) {
    /** Indicates that a video resolution of 1920 by 1080 will be used while
     *  opening the camera.
     */
    kStreamQualityFullHD,
    /** Indicates that a video resolution of 1280 by 720 will be used while
     *  opening the camera.
     */
    kStreamQualityHD,
    /** Indicates that a video resolution of 640 by 368 will be used while
     *  opening the camera.
     */
    kStreamQualityVGA,
    /** Indicates that a video resolution of 320 by 240 will be used while
     *  opening the camera.
     */
    kStreamQualityQCIF
};

/** These constants indicate the which camera will be used by
 * stream API.
 */typedef NS_ENUM(NSUInteger, IrisRtcCameraType) {
     /** Indicates that a front camera will be used while
      *  opening the camera.
      */
     kCameraTypeFront,
     /** Indicates that a back camera will be used while
      *  opening the camera.
      */
     kCameraTypeBack,
};

@class IrisRtcStream;

/** The `IrisRtcMediaTrack` class manages the video tracks which are created
 * during the stream creation. When the stream API creates a stream i.e.
 * when it opens the camera, the local preview will be associated with a media
 * track.
 *
 * This media track will be passed to the application via a callback
 * onLocalStream(). When the application receives this callback, it can create
 * IrisRtcRenderer and add the renderer to this track.
 *
 * @warning A renderer is a CPU intensive class and creating multiple renderers
 * can cause significant drain in battery. In case of multiple participants,
 * the renderer functionality should be used on need basis. for e.g show a limited
 * number of renderers or participants on main screen.
 */
@interface IrisRtcMediaTrack : NSObject

/**-----------------------------------------------------------------------------
 * @name Adding a renderer
 * -----------------------------------------------------------------------------
 */

/** Add a renderer to the media track.
 *
 * @param renderer The renderer object created using IrisRtcRenderer API.
 * @param delegate The delegate object for the track. The delegate will
 * receive delegate messages during execution of the operation when output is
 * generated and upon completion or failure of the operation.
 */
-(void)addRenderer:(IrisRtcRenderer*)renderer delegate:(id<IrisRtcRendererDelegate>)delegate;

/**-----------------------------------------------------------------------------
 * @name Removing a renderer
 * -----------------------------------------------------------------------------
 */

/** Removes a renderer from the media track.
 *
 * @param renderer The renderer object created using IrisRtcRenderer API.
 */-(void)removeRenderer:(IrisRtcRenderer*)renderer;

@end

/** The `IrisRtcStreamDelegate` protocol defines the optional methods implemented by
 *delegates of the IrisRtcStream class.
 *
 *IrisRtcStream class when it creates a camera instance and starts the capture,
 *calls the delegate method onLocalStream:mediaTrack: with the media tracks.
 *
 *The application can then use mediatrack APIs to add a renderer to it to start
 *the local preview.
 *
 *In case the IrisRtcStream class has errors while opening the camera or during
 *camera capture process, it will call the onStreamError:error:withAdditionalInfo:
 *delegate method. The additional info will have additional details on the errors.
 *While the error will be according to Iris Error Codes. The most common error codes
 *will happen if the camera instance was not found (due to system level error) or
 *if the camera doesnt support the the video quality setting or the hardware does
 *not have the correct camera type.
 *
 */
@protocol IrisRtcStreamDelegate <NSObject>

/** This method is called when the local preview is available
 *
 * @param stream Pointer to the stream object.
 * @param mediaTrack Media track that is associated with the camera instance.
 */
-(void)onLocalStream:(IrisRtcStream *)stream mediaTrack:(IrisRtcMediaTrack *)mediaTrack;

/** This method is called when there in an error during camera capture processs
 *
 * @param stream Pointer to the stream object.
 * @param error Error code and basic description.
 * @param info Additional details for debugging.
 */
-(void)onStreamError:(IrisRtcStream *)stream error:(NSError*)error withAdditionalInfo:(NSDictionary *)info;

@end


/** The `IrisRtcStream` class manages the audio and video streams that can be created
 * using IRIS stream APIs. When a video or audio session is created, you can associate
 * the session with a stream.
 *
 * The stream class APIs divided in 3 main sections:
 * 1) Creation of streams. This can be done using initWithDelegate:error: and
 *  initWithType:quality:cameraType:delegate:error: API. Use the close api to close the
 *  streams
 *
 * 2) Local preview: The startPreview and stopPreview API can start and stop the preview
 *
 * 3) Management: To mute, unmute or to flip you can use mute, unmute, flip API
 *
 * @warning When using the stream class, it will ask user to allow to use camera while running.
 * Please make sure apppropriate access is allowed in info.plist for the same.
 * When the stream is started, it wont immediately access the microphone, it will use the mic
 * only when the call is connected. Hence the pop-up for mic access will be presented to the user
 * at a later point of time. Also when the call is connected, we change the audio session mode
 * to VIDEO CHAT for a better experience. You can override this behaviour by choosing your own
 * audio session in the application.
 */
@interface IrisRtcStream :NSObject

/** Returns the flag telling whether the video stream is used by the current stream object.
 *
 * @return The flag value of video stream.
 */
@property(readonly) BOOL isVideoEnabled;

/** Returns the flag telling whether the audio stream is muted or not.
 *
 * @return The audio mute status.
 */
@property(readonly) BOOL isMuted;


/**-----------------------------------------------------------------------------
 * @name Creation of the stream
 * -----------------------------------------------------------------------------
 */
/** This method is called to create a stream with default options. It will create stream
 *  with both audio and video. It will choose the video quality as VGA and make use of
 *  back camera.
 *
 * @param delegate The delegate object for the stream. The delegate will
 * receive delegate messages during execution of the operation when output is
 * generated and upon completion or failure of the operation.
 * @param outError      Provides error code and basic error description when any exception occured in api call.
 */
-(id)initWithDelegate:(id<IrisRtcStreamDelegate>)delegate error:(NSError **)outError;

/** This method is called to create a stream with options. It will create stream
 *  based on the options provided.
 *
 * @param type The type of the stream that will be created. You can choose to use 
 * audio or video or both for the stream creation.
 * @param quality The stream video quality you would like to use. You can choose
 * from HD to a lower resolution such as QCIF.
 * @param cameraType A choice between front and back camera of the device.
 * @param delegate The delegate object for the stream. The delegate will
 * receive delegate messages during execution of the operation when output is
 * generated and upon completion or failure of the operation.
 * @param outError      Provides error code and basic error description when any exception occured in api call.
 */
-(id)initWithType:(IrisRtcSdkStreamType)type quality:(IrisRtcSdkStreamQuality)quality
       cameraType:(IrisRtcCameraType)cameraType delegate:(id<IrisRtcStreamDelegate>)delegate error:(NSError **)outError;

/** This method is called to close a stream. The close operation is synchronous and can 
 *  take time while closing the stream. Closing the stream during a session can cause
 *  an error in video or audio sessions. Hence it is advisable to use this API once the 
 *  session is closed.
 */
-(void)close;

/**-----------------------------------------------------------------------------
 * @name Creation of the preview
 * -----------------------------------------------------------------------------
 */
/** This method is called to start a local preview for the chosen camera.
 *  When this API is called after stream creation, it will use the delegate method
 *  onLocalStream:mediaTrack: to send the track to the application. Application can 
 *  create a renderer and add the same to this track.
 */
-(void)startPreview;

/** This method is called to stop a local preview for the chosen camera.
 *  Please remove the renderer from the track before calling this API.
 */
-(void)stopPreview;

/**-----------------------------------------------------------------------------
 * @name Settings
 * -----------------------------------------------------------------------------
 */
/** This method is called to change the camera type. If the current camera type
 *  is "back", it will be changed to front and vice versa.
 */
-(void)flip;

/** This method is called to mute the audio. This API should be called only when 
 * the stream type is VIDEO or AUDIO.
 */
-(void)mute;

/** This method is called to un-mute the audio. This API should be called only when
 * the stream type is VIDEO or AUDIO.
 */
-(void)unmute;

@end

#endif /* IrisRtcStream_h */
