//
//  IrisRtcSession.h : Objective C code used to create and manage the video and chat session.
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

#ifndef IrisRtcSession_h
#define IrisRtcSession_h
#import "IrisRtcStream.h"
#import "IrisRtcJingleSession.h"
#import "IrisChatMessage.h"
#import "IrisChatAck.h"
#import "IrisChatState.h"
#import "IrisRtcJingleSession.h"

@class IrisRtcSession;



/**
 * The `IrisRtcSessionDelegate` protocol defines the optional methods implemented by
 * delegates of the IrisRtcSession class.
 *
 * The delegates should be used to monitor the events like when a remote stream is added or removed.
 * Delegate onAddRemoteStream:mediaTrack: will be called when we got remote stream
 * and onRemoveRemoteStream:mediaTrack: will be called when remote stream is removed.
 */
@protocol IrisRtcSessionDelegate <IrisRtcJingleSessionDelegate>

/**
 * This method is called when the remote stream is added to peerconnection.
 *
 * @param track pointer to the IrisRtcMediaTrack containing remote track.
 * @param participantId Participant Id.
 * @param roomId Room Id.
 * @param traceId trace Id.
 */
-(void)onAddRemoteStream:(IrisRtcMediaTrack *)track participantId:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId;

/**
 * This method is called when the remote stream is removed from the peerconnection.
 *
 * @param track pointer to the IrisRtcMediaTrack containing remote track.
 * @param participantId Participant Id.
 * @param roomId Room Id.
 * @param traceId trace Id.
 */
-(void)onRemoveRemoteStream:(IrisRtcMediaTrack *)track participantId:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId;

/**
 * This method is called when the remote stream is added to peerconnection.
 *
 * @param message Chat message string
 * @param participantId Participant Id sending the chat message
 * @param roomId Room Identifier for the allocated  chat room for the participants
 * @param traceId trace Id.
 */

-(void)onSessionParticipantMessage:(IrisChatMessage *)message participantId:(NSString*)participantId roomId:(NSString*)roomId traceId:(NSString *)traceId;
/**
 * This method is called as an  acknowledggment of  chat message sent to participant.
 *
 *
 * @param message ChatAck message string
 * @param roomId Room Identifier for the allocated  chat room for the participants
 * @param traceId trace Id.
 */
-(void)onChatMessageSuccess:(IrisChatMessage*)message roomId:(NSString*)roomId traceId:(NSString *)traceId;

/**
 * This method is called as when  chat message is not sent to participant.
 *
 *
 * @param messageId messageid of chat message
 * @param info additional info about error.
 * @param roomId Room Identifier for the allocated  chat room for the participants
 * @param traceId trace Id.
 */
-(void)onChatMessageError:(NSString*)messageId withAdditionalInfo:(NSDictionary *)info roomId:(NSString*)roomId traceId:(NSString *)traceId;

/**
 * This method is used for seding chat message state .
 *
 * @param state chat state
 * @param participantId Participant Id sending the chat message
 * @param roomId Room Identifier for the allocated  chat room for the participants
 * @param traceId trace Id.
 */
-(void)onChatMessageState:(IrisChatState)state participantId:(NSString*)participantId roomId:(NSString*)roomId traceId:(NSString *)traceId;


@end

/**
 * The `IrisRtcSession` is a class used to create and manage the video and chat session.
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
@interface IrisRtcSession : IrisRtcJingleSession
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
 * @param delegate     The delegate object for IrisRtcVideoSession used to receive the callbacks.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)createWithRoomName:(NSString* )roomName sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id<IrisRtcSessionDelegate>)delegate error:(NSError**)outError;

/**
 * Creating and starting a video session using the room id for the room which has been already allocated for the invloved participants.
 *
 * @param roomId Room Id of the room allocated for the participants invalved.
 * @param delegate     The delegate object for IrisRtcVideoSession used to receive the callbacks.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)createWithRoomId:(NSString* )roomId delegate:(id<IrisRtcSessionDelegate>)delegate error:(NSError**)outError;


/**
 * Creating and starting a video session using the room id for the room which has been already allocated for the invloved participants.
 *
 * @param roomId Room Id of the room allocated for the participants invalved.
 * @param sessionConfig  IrisRtcSessionConfig object for setting additional optional session configuaration parameters.
 * @param delegate     The delegate object for IrisRtcVideoSession used to receive the callbacks.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)createWithRoomId:(NSString* )roomId  sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id<IrisRtcSessionDelegate>)delegate error:(NSError**)outError;


/**
 * Creating and starting a video session using the room id for the room which has been already allocated for the invloved participants.
 *
 * @param roomId Room Id of the room allocated for the participants invalved.
 * @param notificationData     notification data.
 * @param stream       local stream.
 * @param sessionConfig  IrisRtcSessionConfig object for setting additional optional session configuaration parameters.
 * @param delegate     delegate to receive the callbacks.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)createWithRoomId:(NSString* )roomId notificationData:(NSString*)notificationData stream:(IrisRtcStream*)stream    sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id<IrisRtcSessionDelegate>)delegate error:(NSError**)outError;


/**
 * Joining a video session which involves starting a session and joining the room with room id which is received in notification
 *
 * @param sessionId room id
 * @param roomToken         rooomtoken  which is received in notification.
 * @param roomTokenExpiryTime   rommtokenexpiry which is received in notification.
 * @param rtcServer     rtcServerURL.
 * @param delegate  The delegate object for IrisRtcVideoSession,used to receive the callbacks.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)joinWithSessionId:(NSString*)sessionId roomToken:(NSString*)roomToken roomTokenExpiryTime:(NSInteger)roomTokenExpiry rtcServer:(NSString*)rtcServer delegate:(id<IrisRtcSessionDelegate>)delegate error:(NSError **)outError;

/**
 * Joining a video session which involves starting a session and joining the room with room id which is received in notification
 *
 * @param sessionId room id
 * @param delegate  The delegate object for IrisRtcVideoSession,used to receive the callbacks.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)joinWithSessionId:(NSString*)sessionId delegate:(id<IrisRtcSessionDelegate>)delegate error:(NSError **)outError;

/**
 * Joining a video session which involves starting a session and joining the room with room id which is received in notification
 *
 * @param sessionId room id
 * @param roomToken         rooomtoken  which is received in notification.
 * @param roomTokenExpiryTime   rommtokenexpiry which is received in notification.
 * @param stream    local stream
 * @param rtcServer     rtcServerURL.
 * @param sessionConfig  IrisRtcSessionConfig object for setting additional optional session configuaration parameters.
 * @param delegate  The delegate object for IrisRtcVideoSession,used to receive the callbacks.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)joinWithSessionId:(NSString*)sessionId roomToken:(NSString*)roomToken roomTokenExpiryTime:(NSInteger)roomTokenExpiry stream:(IrisRtcStream*)stream rtcServer:(NSString*)rtcServer sessionConfig:(IrisRtcSessionConfig *)sessionConfig delegate:(id<IrisRtcSessionDelegate>)delegate error:(NSError **)outError;
/**
 * setting up user profile information.
 *
 * @param userProfile userprofile information.
 */
-(void)setUserProfile:(IrisRtcUserProfile*)userProfile;
/**-----------------------------------------------------------------------------
 * @name Mute remote video
 * -----------------------------------------------------------------------------
 */
/**
 * This method is used for Muting remote video.
 *
 * @param participantId participantId which needs to be muted
 */
-(void)muteVideo:(NSString*)participantId;

/**-----------------------------------------------------------------------------
 * @name Unmute remote video
 * -----------------------------------------------------------------------------
 */
/**
 * This method is used for unmuting remote video.
 *
 * @param participantId participantId which needs to be unmuted
 */
-(void)unmuteVideo:(NSString*)participantId;
/**-----------------------------------------------------------------------------
 * @name upgradeToVideo
 * -----------------------------------------------------------------------------
 */
/**
 * This method is used to upgrade to video sesssion from chat session.
 *
 * @param stream                Stream object
 * @param notificationData      Notification data
 */
-(void)upgradeToVideo:(IrisRtcStream*)stream notificationData:(NSString*)notificationData;
/**-----------------------------------------------------------------------------
 * @name downgradeToChat
 * -----------------------------------------------------------------------------
 */
/**
 * This method is used to downgrade from chat sesssion to video session.
 */
-(void)downgradeToChat;

/**-----------------------------------------------------------------------------
 * @name Sending chat messages
 * -----------------------------------------------------------------------------
 */
/**
 * This method is used for sending chat message.
 *
 * @param message   Chat message that need to be send.
 * @param outError  Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)sendChatMessage:(IrisChatMessage*)message error:(NSError**)outError;
/**-----------------------------------------------------------------------------
 * @name Sending chat state
 * -----------------------------------------------------------------------------
 */
/**
 * This method is used for sending chat state.
 *
 * @param state   Chat state
 */
-(void)sendChatState:(IrisChatState)state;

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
 */
-(NSArray *)getstats;

@end

#endif /* IrisRtcVideoSession_h */

