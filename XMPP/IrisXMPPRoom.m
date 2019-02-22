//
//  IrisXMPPRoom.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 11/21/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IrisXMPPRoom.h"
#import "WebRTCError.h"
#import "XMPPWorker.h"
#import "XMPPPresence+Iris.h"
#import "XMPPRayo.h"
#import "XMPPMessage+Iris.h"
#import "IrisChatMessage+Internal.h"
#import "IrisLogging.h"
#import "XMPPJID+Iris.h"

@interface IrisXMPPRoom()<XMPPStreamDelegate,XMPPRoomDelegate>{
    long iqId;
    BOOL isDialSent;
}

@property (nonatomic, strong) XMPPRoom* xmppRoom;
@property (nonatomic, strong) XMPPRoomHybridStorage* xmppRoomStorage;
@property (nonatomic, strong) IrisXMPPStream* xmppStream;
@property (nonatomic, strong) IrisDataElement* dataElement;
@property (nonatomic, strong) NSString* roomName;
@property (nonatomic, strong) NSString* resourceId;
@property (nonatomic, strong) NSString* fullRoomName;

@property (nonatomic,weak) id<IrisXMPPRoomDelegate> roomDelegate;
@property (nonatomic, strong) NSTimer *_periodicPresenceTimer;
@property (nonatomic, strong) NSTimer *statsQueueTimer;
@property (nonatomic, strong) NSMutableArray *statsQueue;
@end

@implementation IrisXMPPRoom : NSObject

@synthesize participant;


-(id)initWithDataElement:(IrisDataElement*)dataElement _roomName:(NSString*)roomName appDelegate:(id<IrisXMPPRoomDelegate>)roomDelegate{
    _dataElement = dataElement;
    _xmppStream = [[XMPPWorker sharedInstance] xmppStream];
    _roomDelegate = roomDelegate;
    _roomName = roomName;
    isDialSent = false;
    // _streamCount = -1;
    _fullRoomName =  [NSString stringWithFormat:@"%@@%@", _roomName, [_dataElement rtcServer]];
    _fullRoomName = [_fullRoomName stringByReplacingOccurrencesOfString:@"xmpp" withString:@"conference"];
    _xmppRoomStorage = [XMPPRoomHybridStorage sharedInstance];
    
    self.xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:_xmppRoomStorage jid:[XMPPJID jidWithString:_fullRoomName]];
    
    [self.xmppRoom addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [self.xmppRoom activate:_xmppStream];
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    _isAudioMute = false;
    _isVideoMute = false;
    iqId = 1;
    _statsQueue =[[NSMutableArray alloc]init];
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
        [_xmppStream setDataElement:_dataElement];
        [ [[XMPPWorker sharedInstance]xmppCapabilities] setDataElement:_dataElement];
       /* if(participant != nil)
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

-(void)sendPrivateMessage:(NSString *)msg target:(NSString *)target
{
    NSXMLElement *body = [NSXMLElement elementWithName:@"body" stringValue:msg];
    IRISLogInfo(@"sendPrivateMessage::bare jid = %@",[[self.xmppRoom myRoomJID]bare]);
    IRISLogInfo(@"sendPrivateMessage::target = %@",[NSString stringWithFormat:@"%@/%@", [[self.xmppRoom myRoomJID] bare], target]);
    XMPPMessage *message = [XMPPMessage message];
    [message addChild:body];
    [message addAttributeWithName:@"from" stringValue:[[self.xmppRoom myRoomJID]resource]];
    [message addAttributeWithName:@"id" stringValue:[[NSUUID UUID] UUIDString]];
    [message addAttributeWithName:@"to" stringValue:[NSString stringWithFormat:@"%@/%@", [[self.xmppRoom myRoomJID] bare], target]];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    if(_dataElement != nil){
        [message addChild:[_dataElement bare]];
    }
    [_xmppStream sendElement:message];
}

-(void)sendChatMessage:(IrisChatMessage*)irisMessage
{
  //  if ([[irisMessage data] length] == 0) return;
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body" stringValue:[irisMessage data]];
    
    XMPPMessage *message = [XMPPMessage message];
    [message addAttributeWithName:@"id" stringValue:[irisMessage messageId]];
    [message addChild:body];
    //    NSXMLElement *dataElement = [xmppStream createDataElement:[irisMessage rootNodeId] childNodeId:[irisMessage childNodeId]];
    [message addActiveChatState];
    
    if(_dataElement != nil){
        [message addChild:[_dataElement bare]];
    }
    [self.xmppRoom sendMessage:message];
}

- (void)sendIrisChatState:(IrisChatState)chatState{
    
    XMPPMessage *message = [XMPPMessage message];
    
    if(chatState == ACTIVE){
        [message addActiveChatState];
    }else if(chatState == COMPOSING){
        [message addComposingChatState];
    }else if(chatState == INACTIVE){
        [message addInactiveChatState];
    }else if(chatState == PAUSED){
        [message addPausedChatState];
    }else if(chatState == GONE){
        [message addGoneChatState];
    }
    
    if(_dataElement != nil){
        [message addChild:[_dataElement bare]];
    }
    [self.xmppRoom sendMessage:message];
}

- (void)leaveRoom
{
    IRISLogVerbose(@"Leaving Room");
    [self.xmppRoom leaveRoom];
    [_xmppStream removeDelegate:self];
    [self.xmppRoom removeDelegate:self];
    [_xmppStream removeDelegate:_roomDelegate];
    [self.xmppRoom removeDelegate:_roomDelegate];
    self.roomDelegate = nil;
    IRISLogVerbose(@"Leaving Room done");
}

#pragma mark - XMPP Room delegate for session

- (void)xmppRoomDidCreate:(XMPPRoom *)sender{
    if(self.roomDelegate != nil)
    [self.roomDelegate xmppRoomDidCreate];
}

- (void)xmppRoomDidJoin:(XMPPRoom *)sender{
    if(self.roomDelegate != nil)
    [self.roomDelegate xmppRoomDidJoin];
}

- (void)xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence{
    IRISLogVerbose(@"IrisXMPPRoom: occupantDidJoin");
    if(self.roomDelegate != nil)
    [self.roomDelegate occupantDidJoin:occupantJID withPresence:presence];
}


- (void)xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence{
    if(self.roomDelegate != nil)
    [self.roomDelegate occupantDidLeave:occupantJID withPresence:presence];
}

- (void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID{
    
}

#pragma mark - XMPP Stream delegate for session

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    IRISLogInfo(@"IrisXMPPRoom: xmppRoom presence eventType = %@",[presence sessionType]);
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

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    // This method is invoked on the moduleQueue.
    
    XMPPJID *from = [message from];
    if(![[from full] containsString:[[self.xmppRoom roomJID] bare]])
        return;
    
    //    if (![roomJID isEqualToJID:from options:XMPPJIDCompareBare])
    //    {
    //        return; // Stanza isn't for our room
    //    }
    

    
    // Is this a message we need to store (a chat message)?
    //
    // A message to all recipients MUST be of type groupchat.
    // A message to an individual recipient would have a <body/>.
    
    BOOL isChatMessage;
    IrisChatMessage *chatMessage;
    
    if ([from isFull])
        isChatMessage = [message isGroupChatMessageWithBody];
    else
        isChatMessage = [message isMessageWithBody];
    
    if (isChatMessage)
    {
        
        NSXMLElement *dataelement = [message elementForName:@"data"];
        
        if(dataelement!= nil){
            
            chatMessage = [[IrisChatMessage alloc]initWithMessage:[message body] messageId:[message elementID] rootNodeId:[message rootNodeId] childNodeId:[message childNodeId] timeReceived:[message timeReceived]];
        }else{
            
            chatMessage = [[IrisChatMessage alloc]initWithMessage:[message body] messageId:[message elementID]];
        }
        
        
        if(![[[message from] full] containsString:[[message to] full]]){
            if(self.roomDelegate != nil)
            [self.roomDelegate didReceiveIrisMessage:chatMessage fromOccupant:from];
            
        }else{
            if([message evmresponseCode] != nil){
                int responcecode = [[message evmresponseCode]intValue];
                if(self.roomDelegate != nil)
                [self.roomDelegate didReceiveIrisAckMessage:chatMessage responseCode:responcecode];
            }
            
        }
    }
    else if(![message isMessageWithBody] && ![[[message from] full] containsString:[[message to] full]] && [message hasChatState])
    {
        IrisChatState state;
        
        if([message hasActiveChatState]){
            state = ACTIVE;
        }else if([message hasComposingChatState]){
            state = COMPOSING;
        }else if([message hasInactiveChatState]){
            state = INACTIVE;
        }else if([message hasPausedChatState]){
            state = PAUSED;
        }else if([message hasGoneChatState]){
            state = GONE;
        }else{
            state = ACTIVE;
        }
        if(self.roomDelegate != nil)
        [self.roomDelegate didReceiveIrisChatState:state fromOccupant:from];
        
        
    }
    else if([message isChatMessage] && ![[[message to] full] containsString:[[self.xmppRoom myRoomJID] full]]){
        IRISLogInfo(@"IrisXMPPRoom::[[message to] full] = %@",[[message to] full]);
        IRISLogInfo(@"IrisXMPPRoom::[self.xmppRoom myRoomJID] full]] = %@",[[self.xmppRoom myRoomJID] full]);
        if([[message body] isEqualToString:@"mute"]){
            if(self.roomDelegate != nil)
            [self.roomDelegate didReceiveIrisStopVideoMessage];
        }else if([[message body] isEqualToString:@"unmute"]){
            if(self.roomDelegate != nil)
            [self.roomDelegate didReceiveIrisStartVideoMessage];
        }else if ([[message body] isEqualToString:@"Hold"]){
            if(self.roomDelegate != nil)
                [self.roomDelegate didReceiveIrisHoldAudioMessage:[from routingId]];
        }else if ([[message body] isEqualToString:@"Unhold"]){
            if(self.roomDelegate != nil)
            [self.roomDelegate didReceiveIrisUnholdAudioMessage:[from routingId]];
        }
    }
}
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *
                                                      
                                                      )iq
{
    
    IRISLogVerbose(@"IrisRtcRoom::didReceiveIQ ");
    // muc changes
    //IRISLogInfo(@"xmppStream : didReceiveIQ %@", iq.description);
    
    if (_resourceId == nil)
    {
        NSXMLElement *showStatus = [iq elementForName:@"ref"];
        NSString *uri= [showStatus attributeStringValueForName:@"uri"];
        _resourceId = [uri substringFromIndex:5];
        
    }
    
    NSArray *privateIqElements = [iq elementsForXmlns:@"jabber:iq:private"];
    // We are only looking for jingle related messages
    if (privateIqElements != nil && ([privateIqElements count] != 0)){
        // Iterate through elements
        for (NSXMLElement *element in privateIqElements)
        {
            NSXMLElement *data = [element elementForName:@"data"];
            if (data)
            {
                NSString *type = [[data attributeForName:@"type"] stringValue];
                if([type isEqualToString:@"leave room"]){
                   
                    [self.roomDelegate didReceiveIrisLeaveRoomMessage: [[data attributeForName:@"roomid"] stringValue]];
                    return  YES;
                }
                
            }
        }
        
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
        
        if([error isEqualToString:@"error"] && _roomDelegate != nil)
        {
            NSString *errorDesc = [[iq elementForName:@"error"]stringValue];
            NSString *errMsg;
            
            if([errorDesc containsString:@"item-not-found"])
            {
                errMsg = @"The JID of the specified target entity does not exist";
                [self.roomDelegate onIrisRtcRoomError:errorDesc _errorCode:ERR_XMPP_ERROR];
            }
            else if ([errorDesc containsString:@"not-allowed"])
            {
                errMsg = @"IQ procession not allowed";
                [self.roomDelegate onIrisRtcRoomError:errorDesc _errorCode:ERR_XMPP_ERROR];
                
            }
            else if ([errorDesc containsString:@"service-unavailable"])
            {
                errMsg = @"The target entity does not support this protocol";
                [self.roomDelegate onIrisRtcRoomError:errorDesc _errorCode:ERR_XMPP_ERROR];
            }
            else
            {
                IRISLogError(@"Error in IQ message");
                [self.roomDelegate onIrisRtcRoomError:errorDesc _errorCode:ERR_XMPP_ERROR];
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
    [_xmppStream resetIQArray];
    [[XMPPWorker sharedInstance]startAliveIQTimer];
}

-(void)sendPresence{
   
    XMPPPresence *presence = [XMPPPresence presenceWithType:nil to:[XMPPJID jidWithString:_fullRoomName resource:[[_xmppStream myJID] full]] id:@"c2p1"];
    
    
    [presence addChild:[_dataElement periodic]];
    
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
    
    @synchronized(self) {
        if(isDialSent)
            return;
        
        isDialSent = true;
        //XMPPIQ *iq = [XMPPRayo dial:to from:from roomName:room roomPass:@"" target:[xmppStream.myJID domain]];
        
        //to = [self targetPhoneNumber:to];
        //from = @"+12674550136";
        XMPPIQ *iq = [XMPPRayo dial:to from:from roomName:_fullRoomName roomPass:@"" target:[targetJid full]];
        [iq addChild:[_dataElement toRoutingId]];
        // send IQ
        [_xmppStream sendElement:iq];
    }
    
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
    isDialSent = false;
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

- (void)sendStats:(NSDictionary *)metaData streamInfo:(NSDictionary *)streamInfo eventsInfo:(NSArray *)events timeSeries:(NSDictionary *)timeSeries callSummary:(NSDictionary *)callSummary{
    
    NSMutableDictionary* statsDict = [[NSMutableDictionary alloc]init];
    
    [statsDict setValue:metaData forKey:@"meta"];
    [statsDict setValue:@"SDK_Timeseries" forKey:@"n"];
    [statsDict setValue:streamInfo forKey:@"streaminfo"];
    [statsDict setValue:timeSeries forKey:@"timeseries"];
    [statsDict setValue:callSummary forKey:@"callsummary"];
    //  [statsDict setValue:events forKey:@"events"];
    
    if(_statsQueueTimer != nil){
        [_statsQueue addObject:statsDict];
        return;
    }
    
    if ([NSJSONSerialization isValidJSONObject:statsDict] == false)
    {
        IRISLogError(@"Cannot post the logs to the server as the data is incorrect %@", statsDict);
        return;
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:statsDict options:kNilOptions error:nil];
    NSString *JSONString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    
    //XMPPIQ *iq = [[XMPPIQ alloc]initWithType:@"set" elementID:@"14:sendIQ"];
    XMPPIQ *iq = [[XMPPIQ alloc]initWithType:@"set" elementID:[NSString stringWithFormat:@"%ld", iqId++]];
    [iq addAttributeWithName:@"xmlns" stringValue:@"jabber:client"];
    
    NSXMLElement *jingleElement = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:private"];
    [jingleElement addAttributeWithName:@"strict" stringValue:@"false"];
    [iq addChild:jingleElement];
    
    NSXMLElement *dataelement = [_dataElement stats];
    [dataelement addAttributeWithName:@"stats" stringValue:JSONString];
    
    
    [iq addChild:dataelement];
    // send IQ
    [_xmppStream sendElement:iq];
    
}

-(void)sendStats:(NSDictionary*)event{
    
    if(_statsQueueTimer != nil){
        [_statsQueue addObject:event];
        return;
    }
    
    XMPPIQ *iq = [[XMPPIQ alloc]initWithType:@"set" elementID:[NSString stringWithFormat:@"%ld", iqId++]];
    
    [iq addAttributeWithName:@"xmlns" stringValue:@"jabber:client"];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:event options:kNilOptions error:nil];
    NSString *JSONString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSXMLElement *jingleElement = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:private"];
    [jingleElement addAttributeWithName:@"strict" stringValue:@"false"];
    [iq addChild:jingleElement];
    
    NSXMLElement *dataelement = [_dataElement stats];
    [dataelement addAttributeWithName:@"stats" stringValue:JSONString];
    
    [iq addChild:dataelement];
    // send IQ
    [_xmppStream sendElement:iq];
}

-(NSString*) getPSTNParticipantJid:(XMPPJID*)targetJid
{
    NSString* roomJid = [[targetJid full] stringByReplacingOccurrencesOfString:@"conference" withString:@"callcontrol"];
    
    return roomJid;
    
}

- (void)startStatsQueueTimer {
    
    IRISLogInfo(@"Starting  statsQueueTimer");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _statsQueueTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                                            target:self
                                                          selector:@selector(stopStatsQueueTimer)
                                                          userInfo:nil
                                                           repeats:NO
                            ];
    });
    
}

-(void)stopStatsQueueTimer {
    
    IRISLogInfo(@"Stoping  statsQueueTimer");
    
    [self processStatsQueueTimer];
    
    if(_statsQueueTimer != nil){
        [_statsQueueTimer invalidate];
        _statsQueueTimer  = nil;
    }
    
}

-(void)processStatsQueueTimer {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self sendStats:_statsQueue];
        [_statsQueue removeAllObjects];
    });
}

@end
