//
//  IrisChatMessage.h :  Chat structure which includes root/child node id along with chat message.
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

#ifndef IrisChatMessage_h
#define IrisChatMessage_h

/**
 * The `IrisChatMessage` is a class used to construct chat message using rootNodeId,childNodeId and data.
 *
 */

@interface IrisChatMessage : NSObject

/**
 * Set root node Id for the message.
 *
 */
@property (nonatomic,readonly) NSString* rootNodeId;

/**
 * Set child node Id for the message.
 */
@property (nonatomic,readonly) NSString* childNodeId;

/**
 * Set child node Id for the message.
 */
@property (nonatomic,readonly) NSString* timeReceived;

/**
 * Set message Id for the message.
 *
 */
@property (nonatomic) NSString* messageId;

/**
 * Message string need to send
 */
@property (nonatomic) NSString* data;

/**
 * Initialize chat message class with message,messageId.
 *
 * @param message chat message.
 * @param messageId     messgeId.
 *
 */
-(id)initWithMessage:(NSString*)message messageId:(NSString*)messageId;

/**
 * Initialize chat message class with message.
 *
 * @param message chat message.
 */
-(id)initWithMessage:(NSString*)message;


@end

#endif /* IrisChatMessage_h */
