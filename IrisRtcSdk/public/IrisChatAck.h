//
//  IrisChatAck.h :  Chat structure which includes root/child node id,status code along with chat id.
//
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

#ifndef IrisChatAck_h
#define IrisChatAck_h

/**
 * The `IrisChatAck` is a class used to construct chat message using rootNodeId,childNodeId,responsecode and messageId.
 *
 */

@interface IrisChatAck : NSObject

/**
 * Set message Id for the message.
 *
 */
@property (nonatomic) NSString* evmResponseCode;
/**
 * Set root node Id for the message.
 *
 */
@property (nonatomic) NSString* rootNodeId;

/**
 * Set child node Id for the message.
 */
@property (nonatomic) NSString* childNodeId;

/**
 * messageId string need to send
 */
@property (nonatomic) NSString* messageId;


/**
 * Initialize chat message class with message,messageId.
 *
 * @param messageId        messgeId.
 * @param rootNodeId       rootNodeId.
 * @param childNodeId      childNodeId.
 * @param evmResponseCode  responseCode.
 */
-(id)initWithMessage:messageId rootNodeId:(NSString*)rootNodeId childNodeId:(NSString*)childNodeId evmResponseCode:(NSString*)evmResponseCode;



@end

#endif /* IrisChatAck_h */

