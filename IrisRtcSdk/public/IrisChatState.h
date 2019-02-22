//
//  IrisChatState.h :  Chat states
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

#ifndef IrisChatState_h
#define IrisChatState_h

/**
 * These are Iris Chat states
 * <li>ACTIVE</li>
 * <li>COMPOSING</li>
 * <li>PAUSED</li>
 * <li>INACTIVE</li>
 * <li>GONE</li>
 */
typedef NS_ENUM(NSUInteger, IrisChatState) {
    
    /**
     * User is actively participating in the chat session.
     */
    ACTIVE,
    /**
     * User is composing a message.
     */
    COMPOSING,
    /**
     * User had been composing but now has stopped.
     */
    PAUSED,
    /**
     * User has not been actively participating in the chat session.
     */
    INACTIVE,
    /**
     * User has effectively ended their participation in the chat session.
     */
    GONE
    
};
#endif /* IrisChatState_h */

