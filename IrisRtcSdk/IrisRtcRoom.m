//
//  IrisRtcRoom.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 7/28/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IrisRtcRoom.h"
#import "XMPPRayo.h"
#import "IrisChatState.h"
#import "XMPPPresence+Iris.h"
#import "IrisLogging.h"

@interface IrisRtcRoom()<XMPPStreamDelegate>{
    
}

@property (nonatomic, strong) XMPPRoom* xmppRoom;
@property (nonatomic, strong) XMPPRoomHybridStorage* xmppRoomStorage;
@property (nonatomic, strong) XMPPStream* xmppStream;
@property (nonatomic, strong) IrisDataElement* dataElement;
@property (nonatomic, strong) NSString* roomName;
@property (nonatomic, strong) NSString* resourceId;
@property (nonatomic, strong) NSString* fullRoomName;

@property (nonatomic,weak) id<XMPPRoomDelegate> roomDelegate;
@property (nonatomic, strong) NSTimer *_periodicPresenceTimer;
@end


@implementation IrisRtcRoom : NSObject 

@synthesize delegate,participant;


-(id)initWithDataElement:(IrisDataElement*)dataElement _roomName:(NSString*)roomName appDelegate:(id<XMPPRoomDelegate>)roomDelegate{
    _dataElement = dataElement;
    _xmppStream = [[XMPPWorker sharedInstance] xmppStream];
    _roomDelegate = roomDelegate;
    _roomName = roomName;
   // _streamCount = -1;
    _fullRoomName =  [NSString stringWithFormat:@"%@@%@", _roomName, [_dataElement rtcServer]];
    _fullRoomName = [_fullRoomName stringByReplacingOccurrencesOfString:@"xmpp" withString:@"conference"];
    _xmppRoomStorage = [XMPPRoomHybridStorage sharedInstance];
    
    self.xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:_xmppRoomStorage jid:[XMPPJID jidWithString:_fullRoomName]];
    
    [self.xmppRoom addDelegate:_roomDelegate delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [self.xmppRoom activate:_xmppStream];
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    _isAudioMute = false;
    _isVideoMute = false;
    
    return self;
}

- (void)joinRoom
{
    IRISLogInfo(@"XMPP Worker Joining room %@", _roomName );
    
    IRISLogInfo(@"XMPP Worker _xmppStream.myJID %@", _xmppStream.myJID );
    
    
    //Fix for multiNick
    NSString *Jid= [NSString stringWithFormat:@"%@",_xmppStream.myJID];
    
    if(![self.xmppRoom isJoined]){
        IRISLogVerbose(@"Joining room");
        
        
        //@@@@@@@@@@@@@@
        //Commenting this line for now but can add presence in XMPPStream
        /*[_xmppRoom setDataElement:_dataElement];
        if(participant != nil)
            [_xmppRoom setParticipant:participant];*/
        [self.xmppRoom joinRoomUsingNickname:Jid history:nil];
    }
    else{
        IRISLogInfo(@"Room has already joined. Sending presence for upgrade/downgrade session");
        [self sendPresence];
    }

    //[self.xmppRoom joinRoomUsingNickname:[xmppStream.myJID user] history:nil];
    
}

- (void)allocateConferenceFocus:(ConferenceIQType)type
{
       
    XMPPIQ *xmpp;
    
    NSXMLElement *confElement = [NSXMLElement elementWithName:@"conference"];
    [confElement addAttributeWithName:@"xmlns" stringValue:@"http://jitsi.org/protocol/focus"];
    
    // New DNS related changes
    //NSString *fullRoomName = [NSString stringWithFormat:@"%@.%@", roomName, [xmppStream.myJID domain]];
    //NSString *fullRoomName = [NSString stringWithFormat:@"%@%@", roomName, [xmppStream.myJID domain]];
    
    
    
    
    [confElement addAttributeWithName:@"room" stringValue:_fullRoomName];
    
    NSXMLElement *bridgeElement = [NSXMLElement elementWithName:@"property"];
    [bridgeElement addAttributeWithName:@"name" stringValue:@"bridge"];
    
    NSMutableString *fullvideobridge = [[NSMutableString alloc]init];
    [fullvideobridge appendString:@"jitsi-videobridge."];
    //[fullvideobridge appendString:[xmppStream.myJID domain]];
    [fullvideobridge appendString:[_dataElement rtcServer]];
    [bridgeElement addAttributeWithName:@"value" stringValue:fullvideobridge];
    //[bridgeElement addAttributeWithName:@"value" stringValue:@"jitsi-videobridge..xrtc.me"];
    //[bridgeElement addAttributeWithName:@"value" stringValue:@"jitsi-videobridge..xrtc.me"];
    
    [confElement addChild:bridgeElement];
    
    NSXMLElement *ccElement = [NSXMLElement elementWithName:@"property"];
    [ccElement addAttributeWithName:@"name" stringValue:@"call_control"];
    //NSString *dom = [xmppStream.myJID domain];
    NSString *dom = [_dataElement rtcServer];
    NSString *cc = [dom stringByReplacingOccurrencesOfString:@"xmpp" withString:@"callcontrol"];
    [ccElement addAttributeWithName:@"value" stringValue:cc];
    [confElement addChild:ccElement];
    
    NSXMLElement *chanElement = [NSXMLElement elementWithName:@"property"];
    [chanElement addAttributeWithName:@"name" stringValue:@"channelLastN"];
    [chanElement addAttributeWithName:@"value" intValue:(int)_streamCount];
    
    [confElement addChild:chanElement];
    
    NSXMLElement *adapElement = [NSXMLElement elementWithName:@"property"];
    [adapElement addAttributeWithName:@"name" stringValue:@"adaptiveLastN"];
    [adapElement addAttributeWithName:@"value" stringValue:@"false"];
    
    [confElement addChild:adapElement];
    
    NSXMLElement *simuElement = [NSXMLElement elementWithName:@"property"];
    [simuElement addAttributeWithName:@"name" stringValue:@"adaptiveSimulcast"];
    [simuElement addAttributeWithName:@"value" stringValue:@"false"];
    
    [confElement addChild:simuElement];
    
    NSXMLElement *osctpElement = [NSXMLElement elementWithName:@"property"];
    [osctpElement addAttributeWithName:@"name" stringValue:@"openSctp"];
    [osctpElement addAttributeWithName:@"value" stringValue:@"true"];
    
    [confElement addChild:osctpElement];
    
    //  NSXMLElement *firefoxElement = [NSXMLElement elementWithName:@"property"];
    // [firefoxElement addAttributeWithName:@"name" stringValue:@"enableFirefoxHacks"];
    //  [firefoxElement addAttributeWithName:@"value" stringValue:@"false"];
    NSXMLElement *firefoxElement = [NSXMLElement elementWithName:@"property"];
    [firefoxElement addAttributeWithName:@"name" stringValue:@"simulcastMode"];
    [firefoxElement addAttributeWithName:@"value" stringValue:@"rewriting"];
    
    [confElement addChild:firefoxElement];
    
    // New DNS related changes
    
    //NSMutableString *fullTargetJid = [[NSMutableString alloc]init];
    //[fullTargetJid appendString:@"focus."];
    //[fullTargetJid appendString:[xmppStream.myJID domain]];
    
    //NSString *fullTargetJid = [xmppStream.myJID domain];
    NSString *fullTargetJid = [_dataElement rtcServer];
    fullTargetJid = [fullTargetJid stringByReplacingOccurrencesOfString:@"xmpp" withString:@"focus"];
    
    XMPPJID *targetJid = [XMPPJID jidWithString:fullTargetJid];
    
    xmpp  = [[XMPPIQ alloc]initWithType:@"set" to:targetJid elementID:nil child:[confElement copy]];
    if(type == kAllocate){
        [xmpp addChild:[_dataElement allocate]];
    }
    else
    if(type == kDeallocate){
        [xmpp addChild:[_dataElement deallocate]];
    }
    else
    {
        [xmpp addChild:[_dataElement full]];
    }
    
    [_xmppStream sendElement:xmpp];
    
    
}


- (void)leaveRoom
{
    [_xmppStream removeDelegate:self];
    [_xmppStream removeDelegate:_roomDelegate];
    [self.xmppRoom removeDelegate:_roomDelegate];
    [self.xmppRoom leaveRoom];
}

#pragma mark - XMPP Stream delegate for session

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    IRISLogInfo(@"IrisRtcRoom: xmppRoom presence eventType = %@",[presence sessionType]);
    /*if([XMPPStream isPeriodicPresence:presence])
     {
     _isparticipantjoined = YES;
     
     if(__presenceCheckTimer != nil){
     [__presenceCheckTimer invalidate];
     __presenceCheckTimer = nil;
     }
     
     XMPPJID* from = [presence from];
     NSDictionary* fromDict = @{ @"from"     : from};
     __presenceCheckTimer = [NSTimer scheduledTimerWithTimeInterval:presenceCheckTimeInterval
     target:self
     selector:@selector(checkPresence:)
     userInfo:fromDict
     repeats:NO
     ];
     }*/
    
}


- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *
                                                      
                                                      )iq
{

    IRISLogInfo(@"IrisRtcRoom::didReceiveIQ ");
    // muc changes
    //IRISLogInfo(@"xmppStream : didReceiveIQ %@", iq.description);
    
    if (_resourceId == nil)
    {
        NSXMLElement *showStatus = [iq elementForName:@"ref"];
        NSString *uri= [showStatus attributeStringValueForName:@"uri"];
        _resourceId = [uri substringFromIndex:5];
        
    }
    
    
    if ([iq isResultIQ])
    {
        NSXMLElement *elem = [iq elementForName:@"conference" xmlns:@"http://jitsi.org/protocol/focus"];
        
        if (elem != nil)
        {
            NSString *ready = [elem attributeStringValueForName:@"ready"];
            
            if ([ready isEqual:@"true"])
            {
                //parse config options
                
                
                //TODO: check external auth enabled
                //TODO: check sip gateway enabled
                
                NSString* room = [elem attributeStringValueForName:@"room"];
                
                // New DNS related changes
                room = [room stringByReplacingOccurrencesOfString:@"xmpp" withString:@"conference"];
                //Focus Joined
                
               // [self joinRoom];
                
                XMPPIQ *iqResponse = [XMPPIQ iqWithType:@"result" to:[iq from] elementID:[iq elementID]];
                [iqResponse addChild:[_dataElement bare]];
                [_xmppStream sendElement:iqResponse];
                
                return YES;
            }
        }
        
       
        
        NSString *error = [iq attributeStringValueForName:@"type"];
        
        if([error isEqualToString:@"error"])
        {
            NSString *errorDesc = [[iq elementForName:@"error"]stringValue];
            NSString *errMsg;
            
            if([errorDesc containsString:@"item-not-found"])
            {
                errMsg = @"The JID of the specified target entity does not exist";
                [self.delegate onIrisRtcRoomError:errorDesc _errorCode:ERR_XMPP_ERROR];
            }
            else if ([errorDesc containsString:@"not-allowed"])
            {
                errMsg = @"IQ procession not allowed";
                [self.delegate onIrisRtcRoomError:errorDesc _errorCode:ERR_XMPP_ERROR];
            }
            else if ([errorDesc containsString:@"service-unavailable"])
            {
                errMsg = @"The target entity does not support this protocol";
               [self.delegate onIrisRtcRoomError:errorDesc _errorCode:ERR_XMPP_ERROR];
            }
            else
            {
                IRISLogError(@"Error in IQ message");
                [self.delegate onIrisRtcRoomError:errorDesc _errorCode:ERR_XMPP_ERROR];
            }
            
        }
        
        
    }
    
    
    return NO;
}


- (void)startPeriodicPresenceTimer{
    
    [[XMPPWorker sharedInstance]stopAliveIQTimer];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __periodicPresenceTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                          target:self
                                                        selector:@selector(sendPresence)
                                                        userInfo:nil
                                                         repeats:YES
                          ];
    });
    
}

-(void)stopPeriodicPresenceTimer{
    [__periodicPresenceTimer invalidate];
    [[XMPPWorker sharedInstance]startAliveIQTimer];
}

-(void)setIsAudioMute:(BOOL)isAudioMute{
    _isAudioMute = isAudioMute;
    [self sendPresence];
}

-(void)setIsVideoMute:(BOOL)isVideoMute{
    _isVideoMute = isVideoMute;
    [self sendPresence];
}

-(void)sendPresence{
    
        XMPPPresence *presence = [XMPPPresence presenceWithType:nil to:[XMPPJID jidWithString:_fullRoomName resource:[[_xmppStream myJID] full]] id:@"c2p1"];
    
        [presence addChild:[_dataElement bare]];
 
        NSXMLElement *audioMutedElement = [NSXMLElement elementWithName:@"audiomuted" objectValue:_isAudioMute ? @"true" : @"false"];
        [presence addChild:audioMutedElement];
    
        NSXMLElement *videoMutedElement = [NSXMLElement elementWithName:@"videomuted" objectValue:_isVideoMute ? @"true" : @"false"];
        [presence addChild:videoMutedElement];

        if(participant != nil){
            
            NSXMLElement *userProfile = [NSXMLElement elementWithName:@"nick" xmlns:@"http://jabber.org/protocol/nick"];
            [userProfile addAttributeWithName:@"name" stringValue:participant.name];
            [userProfile addAttributeWithName:@"avatar" stringValue:participant.avatarUrl];
        
            [presence addChild:userProfile];
        }
       
        [[self xmppStream] sendElement:presence];
}


- (void) dial:(NSString*)to from:(NSString*)from target:(XMPPJID*)targetJid toRoutingId:(NSString*)toRoutingId {
    //XMPPIQ *iq = [XMPPRayo dial:to from:from roomName:room roomPass:@"" target:[xmppStream.myJID domain]];
    
    //to = [self targetPhoneNumber:to];
    //from = @"+12674550136";
    XMPPIQ *iq = [XMPPRayo dial:to from:from roomName:_fullRoomName roomPass:@"" target:[targetJid full]];
    [iq addChild:[_dataElement toRoutingId]];
    // send IQ
    [_xmppStream sendElement:iq];
    
}


-(NSString*)targetPhoneNumber:(NSString*)to
{
    NSPredicate *digitCountPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"[0-9]{10}"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"(\\+1)[0-9]{10}"];
    
    if ([digitCountPredicate evaluateWithObject:to] == YES)
    {
        NSString* toTN = [NSString stringWithFormat:@"+1%@@tel.comcast.net",to];
        to = toTN;
    }
    else if ([predicate evaluateWithObject:to] == YES)
    {
        NSString* toTN = [NSString stringWithFormat:@"%@@tel.comcast.net",to];
        to = toTN;
    }
    
    return to;
}

- (void)hangup:(NSString*)toNumber from:(NSString*)fromNumber target:(XMPPJID*)targetJid toRoutingId:(NSString*)toRoutingId
{
    //XMPPIQ *iq = [XMPPRayo dial:to from:from roomName:room roomPass:@"" target:[targetJid full]];
    
    XMPPIQ *iq = [XMPPRayo hangup:toNumber from:fromNumber roomName:_fullRoomName roomPass:@"" target:[self getPSTNParticipantJid:targetJid]];
    [iq addChild:[_dataElement bare]];
    // send IQ
    [_xmppStream sendElement:iq];
}

- (void)merge:(XMPPJID*)targetJid secondParticipantJid:(NSString*)participantJid
{
    XMPPIQ *iq = [XMPPRayo merge:[self getPSTNParticipantJid:targetJid] secondParticipantJid:participantJid];
    [iq addChild:[_dataElement bare]];
    // send IQ
    [_xmppStream sendElement:iq];
    
}

-(void)hold:(NSString *)to from:(NSString *)from targetJid:(XMPPJID*)targetJid {
    NSString *myJID = [[_xmppStream myJID] full];
    XMPPIQ *iq = [XMPPRayo hold:to from:myJID roomName:_fullRoomName roomPass:@"" target:[self getPSTNParticipantJid:targetJid]];
    [iq addChild:[_dataElement bare]];
    // send IQ
    [_xmppStream sendElement:iq];
    
}

-(void)unHold:(NSString *)to from:(NSString *)from targetJid:(XMPPJID*)targetJid {
    NSString *myJID = [[_xmppStream myJID] full];
    XMPPIQ *iq = [XMPPRayo unHold:to from:myJID roomName:_fullRoomName roomPass:@"" target:[self getPSTNParticipantJid:targetJid]];
    [iq addChild:[_dataElement bare]];
    // send IQ
    [_xmppStream sendElement:iq];
}

-(NSString*) getPSTNParticipantJid:(XMPPJID*)targetJid
{
    NSString* roomJid = [[targetJid full] stringByReplacingOccurrencesOfString:@"conference" withString:@"callcontrol"];
   
    return roomJid;
    
}
@end
