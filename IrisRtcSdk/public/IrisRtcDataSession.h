//
//  IrisRtcDataSession.h : Objective C code used to create and manage the data session.
//  IrisRtcSdk
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


#ifndef IrisRtcDataSession_h
#define IrisRtcDataSession_h

#import "IrisRtcJingleSession.h"
#import "IrisRtcStream.h"

/**
 * The `IrisRtcDataSessionDelegate` protocol defines the optional methods implemented by
 * delegates of the IrisRtcDataSession class.
 */
@protocol IrisRtcDataSessionDelegate <IrisRtcJingleSessionDelegate>

/**
 * This method is called when data session is established with remote end.
 *
 * @param roomId     room id recieved from Iris backend.
 */
- (void)onDataSessionConnected:(NSString *)roomId;

/**
 * This method is called when complete image data available from remote end, 
    which is saved to a file in storage.
 *
 * @param filePath   the url of the image saved in storage.
 * @param roomId     room id recieved from Iris backend.
 */
- (void)onSessionDataWithImage:(NSString *)filePath roomId:(NSString *)roomId;

@end

/**
 * The `IrisRtcDataSession` is a class used to create and manage the data session using data channel.
 *
 * This class provides the following apis
 *
 * 1) creating the data session : the session is created which involves getting the room Id from Iris backend by REST API call,
 *                               creating room by using room id and creating the data channel to send text/image to remote participant.
 *
 * 2) joining the data session : the session is joined which involves joining the room using room id which is recieved in notification
 *                               and creating the data channel to send text/image to remote participant
 *
 * 3) sending the image data
 *
 * 4) sending the raw data. Data can be compressed using different algorithm and can be sent.
 *
 * 5) sending the text messages
 *
 * 6) closing the session
 *
 *
 */
@interface IrisRtcDataSession : IrisRtcJingleSession

/**
 * private variable
 */
@property(nonatomic) NSString* useAnonymousRoom;



/**
 * This method is called to join data session which involves starting a session and joining the room with room id which is received in notification to establish datachannel connection
 *
 * @param sessionId room name that needs to be joined which is recieved in notification
 * @param delegate  IrisRtcDataSession object for IrisRtcAudioSession,used to receive the callbacks.
 */
-(void)joinWithSessionId:(NSString*)sessionId delegate:(id<IrisRtcDataSessionDelegate>)delegate;


/**
 * This method is called to send image data
 *
 * @param filePath image file path present on device.
 */
-(void)sendImage:(NSString*)filePath;

/**
 * This method is called to send raw data.
 * Data can be compressed using different algorithm and can be sent using this API.
 *
 * @param imgData Raw compressed data
 */
-(void)sendCompressedImage:(NSData*)imgData;

/**
 * This method is called to send text messages
 *
 * @param textMsg text message string
 */
-(void)sendText:(NSString*)textMsg;

/**
 * This method is called to close the session
 */
-(void)close;

@end

#endif /* IrisRtcDataSession_h */
