//
//  IrisRtcAudioSession.h : Objective C code used to create and manage the audio session.
//
// Copyright 2016 Comcast Cable Communications Management, LLC
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

#ifndef IrisRtcAudioSession_h
#define IrisRtcAudioSession_h
#import "IrisRtcJingleSession.h"
#import "IrisRtcStream.h"

/**
 * Input for DTMF tone during audio call.
 */
typedef NS_ENUM(NSUInteger, IrisDTMFInputType){
    kNumber1,
    kNumber2,
    kNumber3,
    kNumber4,
    kNumber5,
    kNumber6,
    kNumber7,
    kNumber8,
    kNumber9,
    kNumber0,
    kStar,
    kHash,
    kLetterA,
    kLetterB,
    kLetterC,
    kLetterD
};

/** These are the different Iris RTC SIP call status
 *
 */
typedef NS_ENUM(NSUInteger, IrisSIPStatus) {
        
    /** When the call is initializing
     *
     */
    kInitializing ,
    /** When the call is connecting
     *
     */
    kConnecting ,
    /** When the call is ringing
     *
     */
    //kRinging ,
    /** When the call is connected
     *
     */
    kConnected,
    
    /** When the call is disconnected
     *
     */
    kDisconnected,
    /** When the call is hold
     *
     */
    kHold  
};

/** These are the different Iris RTC  call quality status
 *
 */
typedef NS_ENUM(NSUInteger, IrisStreamQuality) {
    
    /** When the call is not hd
     *
     */
    kNonHD ,
    /** When the call is hd
     *
     */
    kHD,
    /** Default
     *
     */
    kNONE
};


/**
 * The `IrisRtcAudioSessionDelegate` protocol defines the optional methods implemented by
 * delegates of the IrisRtcAudioSession class.
 */
@protocol IrisRtcAudioSessionDelegate <IrisRtcJingleSessionDelegate>

/**
 * This method is called when merging of active session with the held session for PSTN call.
 *
 * @param roomId room id recieved from Iris backend.
 * @param traceId trace id.
 */
-(void)onSessionMerged:(NSString*)roomId traceId:(NSString *)traceId;
/**
 * This method is called when we recieves status of ongoing PSTN call.
 *
 * @param status status of ongoing call.
 * @param roomId room id recieved from Iris backend.
 * @param traceId trace id.
 */
-(void)onSessionSIPStatus:(IrisSIPStatus )status roomId:(NSString*)roomId traceId:(NSString *)traceId;

/**
 * This method is called when session is about to start
 *
 * @param roomId room id recieved from Iris backend.
 * @param traceId trace id.
 */
-(void)onSessionEarlyMedia:(NSString *)roomId traceId:(NSString *)traceId;

/**
 * This method is called to indicate the audio stream quality in the call.
 *
 * @param status status of ongoing call.
 * @param roomId room id recieved from Iris backend.
 * @param traceId trace id.
 */
@optional
-(void)onStreamQualityIndicator:(IrisStreamQuality )quality roomId:(NSString*)roomId traceId:(NSString *)traceId;



@end

/**
 * The `IrisRtcAudioSession` is a class used to create and manage the audio session ie pstn call.
 *
 * This class provides the following apis
 *
 * 1) creating the pstn session : api createWithRoomId:participantId:sourceTelephoneNum:targetTelephoneNumber:notificationData:stream:delegate:error:  can be used for creating session.creating session  involves in getting the room Id from Iris backend by REST API call
 *                           and creates session using room id.
 *
 * 2) joining the pstn session : api  joinWithSessionId:roomToken:roomTokenExpiryTime:stream:delegate:error:  can be used for joining session.Joining session  involves in joining the room using room id which is recieved in notification.
 *
 * 3) api hold will be used to holde the call
 *
 * 4) api unhold will be used to unhold the call
 *
 * 5) api mergeSession: will be used in merging the active session with session on hold
 *
 * 6) api close used to close session
 */

@interface IrisRtcAudioSession : IrisRtcJingleSession

/**
 * private variable used to set the Audio codec preference.
 * Default will be set to OPUS.
 */
@property(nonatomic) IrisRtcSdkAudioCodecType preferedCodecType;

/**
 * private variable
 * set isVideoBridgeEnable as true  to make calls using videobridge.
 */
@property BOOL isVideoBridgeEnable;


/**
 * This method is called to create and start pstn/audio session which involves getting the room id from server and creating the room using the room id.
 *
 * @param roomId          Room Id of the already created room for the participants involved
 * @param participantId   Participant Id
 * @param sourceTN        Contains source 10 digit telephone number.
 * @param targetTN        Contains target 10 digit telephone number.
 * @param notificationData notificationData
 * @param stream          local audio stream.
 * @param sessionConfig    IrisRtcSessionConfig object for setting additional optional session configuaration parameters.
 * @param delegate        delegate object for IrisRtcAudioSession,used to receive the callbacks.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)createWithRoomId:(NSString*)roomId participantId:(NSString*)participantId _sourceTelephoneNum:(NSString*)sourceTN _targetTelephoneNumber:(NSString*)targetTN  notificationData:(NSString*)notificationData stream:(IrisRtcStream*)stream sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id<IrisRtcAudioSessionDelegate>)delegate error:(NSError**)outError;

/**
 * This method is called to create and start pstn/audio session which involves in creating the room using the target and source phone number
 *
 * @param targetTN        Contains target 10 digit telephone number.
 * @param sourceTN        Contains source 10 digit telephone number.
 * @param notificationData notificationData
 * @param stream          local audio stream.
 * @param sessionConfig    IrisRtcSessionConfig object for setting additional optional session configuaration parameters.
 * @param delegate        delegate object for IrisRtcAudioSession,used to receive the callbacks.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)createWithTN:(NSString*)targetTN _sourceTelephoneNum:(NSString*)sourceTN notificationData:(NSString*)notificationData stream:(IrisRtcStream*)stream sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id<IrisRtcAudioSessionDelegate>)delegate error:(NSError**)outError;


/**
 * This method is called to join pstn/audio session which involves joining the room using the room id recieved in notification.
 *
 * @param sessionId    room name that needs to be joined which is recieved in notification.
 * @param roomToken         rooomtoken  which is received in notification.
 * @param roomTokenExpiryTime   rommtokenexpiry which is received in notification.
 * @param stream       local audio stream.
 * @param rtcServer     rtcServerURL.
 * @param sessionConfig    IrisRtcSessionConfig object for setting additional optional session configuaration parameters.
 * @param delegate     delegate object for IrisRtcAudioSession,used to receive the callbacks
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)joinWithSessionId:(NSString*)sessionId roomToken:(NSString*)roomToken roomTokenExpiryTime:(NSInteger)roomTokenExpiry stream:(IrisRtcStream*)stream rtcServer:(NSString*)rtcServer sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id<IrisRtcAudioSessionDelegate>)delegate error:(NSError**)outError;
/**
 * setting up user profile information.
 *
 * @param userProfile userprofile information.
 */
-(void)setUserProfile:(IrisRtcUserProfile*)userProfile;

/**
 * This method is called to hold the pstn session
 */
-(void)hold;

/**
 * This method is called to unhold the pstn session
 */
-(void)unhold;

/**
 * This method is called to activate audio while using callkit. Need to call this API in provider(_:didActivate:) delegate.
 */
+(void)activateAudio;

/**
 * This method is called to deactivate audio while using callkit. Need to call this API in provider(_:didDeactivate:) delegate.
 */
+(void)deactivateAudio;

/**
 * This method is called to get stream quality
 *
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
-(void)getStreamQuality:(NSError**)outError;

/**
 * This method is called to merge the active session with the held session for PSTN call.
 *
 * @param heldSession   session which is on hold.
 */
-(BOOL)mergeSession:(IrisRtcAudioSession*) heldSession;

/**
 * This method is used for sending dtmf tones.
 */
-(void)insertDTMFtone:(IrisDTMFInputType)tone ;
/**
 * This method is called to close the session
 */
-(void)close;
/**
 * This method is called to reject call
 *
 * @param roomId        Room Id of the already created room
 * @param toId          Taget routing Id
 * @param traceId       Trace Id.
 * @param server        RTC server URL.
 * @param outError      Provides error code and basic error description when any exception occured in api call.
 */
+(BOOL)reject:(NSString *) roomId toId:(NSString *) toId traceId:(NSString *) traceId server:(NSString *) server error:(NSError**)outError;
@end


#endif /* IrisRtcAudioSession_h */

