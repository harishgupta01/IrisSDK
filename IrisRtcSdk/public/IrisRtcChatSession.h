//
// IrisRtcChatSession.h : code used to create and manage the chat session.
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

#ifndef IrisRtcChatSession_h
#define IrisRtcChatSession_h

#import "IrisRtcJingleSession.h"
#import "IrisChatMessage.h"
#import "IrisChatState.h"


@class IrisRtcChatSession;

/**
 * The `IrisRtcChatSessionDelegate` protocol defines the optional methods implemented by
 * delegates of the IrisRtcSession class.
 *
 * The protocol needs to be conform to get the chat messages from the remote participant */
@protocol IrisRtcChatSessionDelegate <IrisRtcJingleSessionDelegate>

/**
 * This method is called when the remote stream is added to peerconnection.
 *
 * @param message Chat message string
 * @param participantId Participant Id sending the chat message
 * @param roomId Room Identifier for the allocated  chat room for the participants
 * @param traceId trace Id.
 */
-(void)onSessionParticipantMessage:(IrisChatMessage*)message participantId:(NSString*)participantId roomId:(NSString*)roomId traceId:(NSString *)traceId;

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
-(void)onChatMessageError:(NSString*)messageId withAdditionalInfo:(NSDictionary *)info roomId:(NSString *)roomId traceId:(NSString *)traceId;

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
 * The `IrisRtcChatSession` is a class used to create and manage the chat session.
 *
 * This class provides the below apis
 *
 * 1) Creating the session : API's to create chat session between the participant involved.
 *
 * 2) Joining the session  : Joining the chat session.
 *
 * 3) Sending chat message to the remote participant
 *
 * 4) close api will be used to close the session
 */


@interface IrisRtcChatSession : IrisRtcJingleSession



/**
 * private variable
 * set isVideoBridgeEnable as true  to make calls using videobridge.
 */
@property BOOL isVideoBridgeEnable;


/**
 * Creating and starting a chat session using the room id for the room which has been already allocated for the invloved participants.
 *
 * @param roomId Room Id of the room allocated for the participants invalved.
 * @param notificationData     notification data.
 * @param delegate     The delegate object for IrisRtcChatSession used to receive the callbacks.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)createWithRoomId:(NSString* )roomId notificationData:(NSString*)notificationData delegate:(id<IrisRtcChatSessionDelegate>)delegate error:(NSError**)outError;


/**
 * Creating and starting a chat session which involves getting the room id from server and creating the room using the room id.
 *
 * @param participants participants target routing id.
 * @param notificationData     notification data.
 * @param delegate     The delegate object for IrisRtcVideoSession used to receive the callbacks.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)createWithParticipants:(NSArray* )participants notificationData:(NSString*)notificationData delegate:(id<IrisRtcChatSessionDelegate>)delegate error:(NSError**)outError;

/**
 * Joining a chat session which involves starting a session and joining the room with room id which is received in notification
 *
 * @param sessionId room id
 * @param roomToken         rooomtoken  which is received in notification.
 * @param roomTokenExpiryTime   rommtokenexpiry which is received in notification.
 * @param rtcServer     rtcServerURL.
 * @param delegate  The delegate object for IrisRtcVideoSession,used to receive the callbacks.
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
-(BOOL)joinWithSessionId:(NSString*)sessionId roomToken:(NSString*)roomToken roomTokenExpiryTime:(NSInteger)roomTokenExpiry rtcServer:(NSString*)rtcServer delegate:(id<IrisRtcChatSessionDelegate>)delegate error:(NSError **)outError;

/**
 * setting up user profile information.
 *
 * @param userProfile userprofile information.
 */
-(void)setUserProfile:(IrisRtcUserProfile*)userProfile;
/**-----------------------------------------------------------------------------
 * @name Sending chat messages
 * -----------------------------------------------------------------------------
 */
/**
 * This method is used for sending chat message.
 *
 * @param message   Chat message that needs to be sent
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


@end

#endif /* IrisRtcChatSession_h */
