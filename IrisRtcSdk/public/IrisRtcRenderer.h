//
// IrisRtcRenderer.h : Objective C code for managing views which will render local and remote video tracks
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

#ifndef IrisRtcRenderer_h
#define IrisRtcRenderer_h

@class IrisRtcRenderer;

/** The `IrisRtcRendererDelegate` protocol defines the optional methods implemented by
 * delegates of the IrisRtcRenderer class.
 *
 * This method is called when size of local or remote videoview changes.
 * The size of view  alters due to orientation change
 *
 */

@protocol IrisRtcRendererDelegate <NSObject>
/** This method is called when there is change in size coordinates of remote or local video
 *
 * @param renderer Pointer to the renderer object.
 * @param size size coordinates of view.
 */

-(void)onVideoSizeChange:(IrisRtcRenderer *)renderer size:(CGSize)size;

@end

/** The `IrisRtcRenderer` class is mainly used to initialize the RTCEAGLVideoView for rendering local and remote video
 *  tracks.
 *
 *  The api initWithView:delegate: will initialize RTCEAGLVideoView with  view frame coordinates which is passed as
 *  parameter.
 *
 *  size coordiantes of View can altered using variables
 *  <li>frame</li>
 *  <li>transform</li>
 */
@interface IrisRtcRenderer : NSObject

/** private variable
 */
@property(nonatomic,readonly) UIView*  videoView;
/** private variable
 */
@property(nonatomic) CGRect frame;
/** private variable
 */
@property(nonatomic) CGAffineTransform transform;
/** The api initWithView:delegate will initialize RTCEAGLVideoView with  size coordinates which is passed as parameter.
 *  @param frame view frame in which video has to be rendered
 *  @param delegate The delegate object for the Renderer. The delegate will
 *  receive delegate messages during execution of the operation when output is
 *  generated and upon completion or failure of the operation.
 */
-(id)initWithView:(CGRect)frame delegate:(id)delegate;

@end

#endif /* IrisRtcRenderer_h */
