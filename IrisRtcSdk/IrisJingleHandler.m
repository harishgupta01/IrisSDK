//
//  IrisJingleHandler.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 7/28/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IrisJingleHandler.h"
#import "IrisLogging.h"

@interface IrisJingleHandler(){
    NSXMLElement *elemPres;
}

@property (nonatomic, strong) XMPPJingle* xmppJingle;
@property (nonatomic, strong) XMPPStream* xmppStream;
@property (nonatomic, strong) IrisDataElement* dataElement;
@property (nonatomic, strong) NSString* roomId;

@end

@implementation IrisJingleHandler

-(id)initWithDataElement:(IrisDataElement*)dataElement roomId:(NSString*)roomId{
    self = [super init];
    _xmppStream = [[XMPPWorker sharedInstance] xmppStream];
    _dataElement = dataElement;
    _roomId = roomId;
    return self;
}

- (void)activateJingle: (id<XMPPJingleDelegate>)appDelegate
{
    IRISLogInfo(@"XMPP Worker Activating Jingle " );
    self.xmppJingle = [[XMPPJingle alloc] init];
    [self.xmppJingle SetDelegate:appDelegate];
    [self.xmppJingle setRoomId:_roomId];
    [self.xmppJingle setDataElement:_dataElement];
    [self.xmppJingle activate:self.xmppStream];
}

- (void)deactivateJingle
{
    IRISLogInfo(@"XMPP Worker Deactivating Jingle " );
    [self.xmppJingle SetDelegate:nil];
    [self.xmppJingle deactivate];

    //[_xmppStream removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    //[_xmppStream disconnectAllExtensions];
    //[_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    _dataElement = nil;
    self.xmppJingle = nil;
}

- (void)sendJingleMessage:(NSString*)type data:(NSDictionary*)data target:(XMPPJID *)target
{
    if ([type hasPrefix:@"session"])
    {
        [self.xmppJingle sendSessionMsg:type data:data target:target];
    }
    else if ([type hasPrefix:@"transport"])
    {
        [self.xmppJingle sendTransportMsg:type data:data target:target];
        
    }
    else if ([type hasPrefix:@"source"])
    {
    }
}

- (void)sendVideoInfo:(NSString*)type data:(NSDictionary*)data target:(XMPPJID *)target
{
    elemPres = [self.xmppJingle getVideoContent:type data:data target:target];
    [self sendPresenceWithVideoInfo];
    
    [NSTimer scheduledTimerWithTimeInterval:10
                                     target:self
                                   selector:@selector(sendPresenceWithVideoInfo)
                                   userInfo:nil
                                    repeats:YES
     ];
}


- (void)sendPresenceWithVideoInfo
{
    XMPPPresence *presence = [XMPPPresence presenceWithType:nil to:[XMPPJID jidWithString:@""]];
    [presence addChild:[elemPres copy]];
    
    //[_xmppStream sendElement:presence];
}

-(NSString*)routingId:(NSString*)streamId{
    
    return [_xmppJingle routingId:streamId];
}
@end
