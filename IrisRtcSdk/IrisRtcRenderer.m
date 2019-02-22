//
//  IrisRtcRenderer.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 10/4/16.
//  Copyright © 2016 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IrisRtcStream.h"
#import "WebRTC/WebRTC.h"
#import "IrisRtcRenderer.h"
#import "IrisLogging.h"

//@class RTCEAGLVideoView;

@interface IrisRtcRenderer()<RTCEAGLVideoViewDelegate>


@property(nonatomic, weak) id<IrisRtcRendererDelegate> delegate;
@property(nonatomic) RTCEAGLVideoView*  videoView;
@end
@implementation IrisRtcRenderer

@synthesize frame;
@synthesize transform;

-(id)initWithView:(CGRect)frameSize delegate:(id)delegate
{
    self = [super init];
    self.delegate = delegate;
    _videoView = [[RTCEAGLVideoView alloc]initWithFrame:frameSize];
    _videoView.delegate = self;
    return self;
}

-(void)setFrame:(CGRect)frameSize
{
    IRISLogVerbose(@"IrisRtcRenderer::setFrame");
    _videoView.frame = frameSize;
    
}

-(void)setTransform:(CGAffineTransform)transformSize
{
    _videoView.transform = transformSize;
}

- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size
{
    [self.delegate onVideoSizeChange:self size:size];
}
@end
