//
//  IrisRtcVideoSession.h : Objective C code used to create and manage the video session.
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

#ifndef IrisRtcVideoSession_h
#define IrisRtcVideoSession_h
#import "IrisRtcStream.h"
#import "IrisRtcJingleSession.h"


@class IrisRtcVideoSession;




/**
 * The `IrisRtcVideoSessionDelegate` protocol defines the optional methods implemented by
 * delegates of the IrisRtcSession class.
 *
 * The delegates should be used to monitor the events like when a remote stream is added or removed.
 * Delegate onAddRemoteStream:mediaTrack: will be called when we got remote stream
 * and onRemoveRemoteStream:mediaTrack: will be called when remote stream is removed.
 */
@protocol IrisRtcVideoSessionDelegate <IrisRtcJingleSessionDelegate>

/**
 * This method is called when the remote stream is added to peerconnection.
 *
 * @param track pointer to the IrisRtcMediaTrack containing remote track.
 * @param participantId Participant Id.
 * @param roomId Room Id.
 * @param traceId trace Id.
 */
-(void)onAddRemoteStream:(IrisRtcMediaTrack *)track participantId:(NSString*)participantId roomId:(NSString*)roomId traceId:(NSString *)traceId;

/**
 * This method is called when the remote stream is removed from the peerconnection.
 *
 * @param track pointer to the IrisRtcMediaTrack containing remote track.
 * @param participantId Participant Id.
 * @param roomId Room Id.
 * @param traceId trace Id.
 */
-(void)onRemoveRemoteStream:(IrisRtcMediaTrack *)track participantId:(NSString*)participantId roomId:(NSString*)roomId traceId:(NSString *)traceId;

@end

/**
 * The `IrisRtcVideoSession` is a class used to create and manage the video session.
 *
 * This class provides the below apis
 *
 * 1) Creating the session : api's createWithRoomId:notificationData:delegate:error: and createWithRoomId:notificationData:stream:delegate:error: can be used for creating session.creating session  involves in getting the room Id from Iris backend by REST API call
 *                           and creates session using room id.
 *
 * 2) Joining the session  : api's joinWithSessionId:delegate:error: and joinWithSessionId:stream:delegate:error: can be used for joining session.Joining session  involves in joining the room using room id which is recieved in notification.
 *
 * 3) muteVideo api will be used to mute the remote video
 *
 * 4) unmuteVideo api will be used to unmute the remote video
 *
 * 5) close api will be used to close the session
 */
@interface IrisRtcVideoSession : IrisRtcJingleSession



/**
 * private variable .
 * For anonymous room, set 'useAnonymousRoom' with room name and
 * pass nil as participants while creating session.
 */
//@property(nonatomic) NSString* useAnonymousRoom;



/**
 * private variable used to set the Video codec preference.
 * Default will be set to VP8.
 */
@property(nonatomic) IrisRtcSdkVideoCodecType preferredVideoCodecType;
/**
 * private variable used to set the Audio codec preference.
 * Default will be set to OPUS.
 */
@property(nonatomic) IrisRtcSdkAudioCodecType preferredAudioCodecType;


/**
 * private variable
 * set isVideoBridgeEnable as true  to make calls using videobridge.
 */
@property BOOL isVideoBridgeEnable;
/**
 * Creating and starting a video session using the anonymous room name.
 *
 * @param roomName anonymous room name.
 * @param sessionConfig     IrisRtcSessionConfig object for setting additional optional session configuaration parameters.
 * @param stream       local stream.
 * @param delegate     The delegate object for IrisRtcVideoSession used to receive the callbacks.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)createWithRoomName:(NSString* )roomName sessionConfig:(IrisRtcSessionConfig *)sessionConfig stream:(IrisRtcStream*)stream delegate:(id<IrisRtcVideoSessionDelegate>)delegate error:(NSError**)outError;

/**
 * Creating and starting a video session using the room id for the room which has been already allocated for the invloved participants.
 *
 * @param roomId Room Id of the room allocated for the participants invalved.
 * @param notificationData     notification data.
 * @param delegate     The delegate object for IrisRtcVideoSession used to receive the callbacks.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)createWithRoomId:(NSString* )roomId notificationData:(NSString*)notificationData delegate:(id<IrisRtcVideoSessionDelegate>)delegate error:(NSError**)outError;

/**
 * Creating and starting a video session using the room id for the room which has been already allocated for the invloved participants.
 *
 * @param roomId Room Id of the room allocated for the participants invalved.
 * @param notificationData     notification data.
 * @param delegate     The delegate object for IrisRtcVideoSession used to receive the callbacks.
 * @param sessionConfig     IrisRtcSessionConfig object for setting additional optional session configuaration parameters.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)createWithRoomId:(NSString* )roomId notificationData:(NSString*)notificationData  sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id<IrisRtcVideoSessionDelegate>)delegate error:(NSError**)outError;

/**
 * Creating and starting a video session using the room id for the room which has been already allocated for the invloved participants.
 *
 * @param roomId Room Id of the room allocated for the participants invalved.
 * @param notificationData     notification data.
 * @param stream       local stream.
 * @param sessionConfig     IrisRtcSessionConfig object for setting additional optional session configuaration parameters.
 * @param delegate     delegate to receive the callbacks.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)createWithRoomId:(NSString* )roomId notificationData:(NSString*)notificationData stream:(IrisRtcStream*)stream  sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id<IrisRtcVideoSessionDelegate>)delegate error:(NSError**)outError;
/**
 * Creating and starting a video session using the room id for the room which has been already allocated for the invloved participants.
 *
 * @param roomId Room Id of the room allocated for the participants invalved.
 * @param notificationData     notification data.
 * @param stream       local stream.
 * @param delegate     delegate to receive the callbacks.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 
 */
-(BOOL)createWithRoomId:(NSString* )roomId notificationData:(NSString*)notificationData stream:(IrisRtcStream*)stream delegate:(id<IrisRtcVideoSessionDelegate>)delegate error:(NSError**)outError;


/**
 * Joining a video session which involves starting a session and joining the room with room id which is received in notification
 *
 * @param sessionId room id
 * @param roomToken         rooomtoken  which is received in notification.
 * @param roomTokenExpiry   rommtokenexpiry which is received in notification.
 * @param rtcServer         rtcServerURL.
 * @param delegate          The delegate object for IrisRtcVideoSession,used to receive the callbacks.
 * @param outError          Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)joinWithSessionId:(NSString*)sessionId roomToken:(NSString*)roomToken roomTokenExpiryTime:(NSInteger)roomTokenExpiry rtcServer:(NSString*)rtcServer delegate:(id<IrisRtcVideoSessionDelegate>)delegate error:(NSError **)outError;


/**
 * Joining a video session which involves starting a session and joining the room with room id which is received in notification
 *
 * @param sessionId         room id
 * @param roomToken         rooomtoken  which is received in notification.
 * @param roomTokenExpiry   rommtokenexpiry which is received in notification.
 * @param stream            local stream
 * @param rtcServer         rtcServerURL.
 * @param sessionConfig     IrisRtcSessionConfig object for setting additional optional session configuaration parameters.
 * @param delegate          The delegate object for IrisRtcVideoSession,used to receive the callbacks.
 * @param outError          Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)joinWithSessionId:(NSString*)sessionId roomToken:(NSString*)roomToken roomTokenExpiryTime:(NSInteger)roomTokenExpiry stream:(IrisRtcStream*)stream rtcServer:(NSString*)rtcServer sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id<IrisRtcVideoSessionDelegate>)delegate error:(NSError **)outError;

/**
 * setting up user profile information.
 *
 * @param userProfile userprofile information.
 */
-(void)setUserProfile:(IrisRtcUserProfile*)userProfile;
/**
 * setting up maximum number of streams for session.
 *
 * @param value maximum number of streams to be viewed in session.
 */
-(void)setMaxNumberOfRemoteStream:(int)value;
/**
 * This method is used to select stream from a particular participant in case we have
 * restricted max number of streams to receive. This API needs be called only after 'onSessionConnected' callback.
 *
 * @param participantId Id for a participant received in onSessionParticipantJoined callback.
 */
-(BOOL)activateRemoteStream:(NSString * _Nonnull)participantId;

/**
 * This method is used for Muting remote video.
 *
 * @param participantId participantId which needs to be muted
 */
-(void)muteVideo:(NSString * _Nonnull)participantId;

/**-----------------------------------------------------------------------------
 * @name Unmute remote video
 * -----------------------------------------------------------------------------
 */
/**
 * This method is used for unmuting remote video.
 *
 * @param participantId participantId which needs to be unmuted
 */
-(void)unmuteVideo:(NSString * _Nonnull)participantId;

/**-----------------------------------------------------------------------------
 * @name Closing the Session
 * -----------------------------------------------------------------------------
 */
/**
 * This method is used for Closing the session.
 */
-(void)close;

/**
 * This api is used to collect stats of session.
 *
 *
 */
-(NSArray *)getstats;

@end

#endif /* IrisRtcVideoSession_h */
