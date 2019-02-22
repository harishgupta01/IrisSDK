//
//  XMPPRayo.m
//  xfinity-webrtc-sdk
//
//  Created by Vamsi on 4/22/15.
//  Copyright (c) 2015 Comcast. All rights reserved.
//

#import "XMPPRayo.h"

@implementation XMPPRayo

+ (XMPPIQ *)dial:(NSString*)to from:(NSString*)from roomName:(NSString*)roomName roomPass:(NSString*)roomPass target:(NSString*)target
{
    XMPPIQ *xmpp;
    
    NSXMLElement *dialElement = [NSXMLElement elementWithName:@"dial"];
    [dialElement addAttributeWithName:@"xmlns" stringValue:RAYO_XMLNS];
    [dialElement addAttributeWithName:@"to" stringValue:to];
    [dialElement addAttributeWithName:@"from" stringValue:from];
    
    NSXMLElement *headerElement = [NSXMLElement elementWithName:@"header"];
    [headerElement addAttributeWithName:@"name" stringValue:@"JvbRoomName"];
    [headerElement addAttributeWithName:@"value" stringValue:roomName];
    
    [dialElement addChild:headerElement];
    
    if ([roomPass isEqual:@""] && roomPass.length)
    {
        NSXMLElement *passElement = [NSXMLElement elementWithName:@"header"];
        [passElement addAttributeWithName:@"name" stringValue:@"JvbRoomPassword"];
        [passElement addAttributeWithName:@"value" stringValue:roomPass];
        
        [dialElement addChild:passElement];
    }
    
    // New DNS related changes
    //XMPPJID *focusmucjid = [XMPPJID jidWithString:@"callcontrol.focus.xrtc.me"];
    
    /*NSMutableString *focusmucjid = [[NSMutableString alloc]init];
    [focusmucjid appendString:@"callcontrol."];
    [focusmucjid appendString:target];*/
    
    //NSString *focusmucjid = target;
    //focusmucjid = [focusmucjid stringByReplacingOccurrencesOfString:@"xmpp" withString:@"callcontrol"];
    
    /*NSMutableString *focusmucjid = [[NSMutableString alloc]init];
    [focusmucjid appendString:roomName];
    [focusmucjid appendString:@"/focus"];*/
    
    XMPPJID *targetJid = [XMPPJID jidWithString:target];
    
    xmpp  = [[XMPPIQ alloc]initWithType:@"set" to:targetJid elementID:nil child:[dialElement copy]];
    
    return xmpp;

}

+ (XMPPIQ *)hangup:(NSString*)to from:(NSString*)from roomName:(NSString*)roomName roomPass:(NSString*)roomPass target:(NSString*)target
{
    XMPPIQ *xmpp;
    
    NSXMLElement *dialElement = [NSXMLElement elementWithName:@"hangup"];
    [dialElement addAttributeWithName:@"xmlns" stringValue:RAYO_XMLNS];
    
    XMPPJID *targetJid = [XMPPJID jidWithString:target];
    
    //xmpp  = [[XMPPIQ alloc]initWithType:@"set" to:targetJid elementID:nil child:[dialElement copy]];
    
    xmpp  = [[XMPPIQ alloc]initWithType:@"set" to:targetJid elementID:nil child:[dialElement copy]];
    
    return xmpp;
  
}

+ (XMPPIQ *)merge:(NSString*)target secondParticipantJid:(NSString*)participantJid
{
    XMPPIQ *xmpp;
    
    NSXMLElement *mergeElement = [NSXMLElement elementWithName:@"merge"];
    [mergeElement addAttributeWithName:@"xmlns" stringValue:RAYO_XMLNS];
    NSXMLElement *header = [NSXMLElement elementWithName:@"header"];
    [header addAttributeWithName:@"name" stringValue:@"secondParticipant"];
    [header addAttributeWithName:@"value" stringValue:participantJid];
    [mergeElement addChild:header];
    XMPPJID *targetJid = [XMPPJID jidWithString:target];
    
    xmpp  = [[XMPPIQ alloc]initWithType:@"set" to:targetJid elementID:nil child:[mergeElement copy]];
    
    return xmpp;
    
}

+ (XMPPIQ *)hold:(NSString*)to from:(NSString*)from roomName:(NSString*)roomName roomPass:(NSString*)roomPass target:(NSString*)target
{
    XMPPIQ *xmpp;
    
    NSXMLElement *holdElement = [NSXMLElement elementWithName:@"hold"];
    [holdElement addAttributeWithName:@"xmlns" stringValue:RAYO_XMLNS];
    
    XMPPJID *targetJid = [XMPPJID jidWithString:target];
    
    xmpp  = [[XMPPIQ alloc]initWithType:@"set" to:targetJid elementID:nil child:[holdElement copy]];
    
    return xmpp;
    
}

+ (XMPPIQ *)unHold:(NSString*)to from:(NSString*)from roomName:(NSString*)roomName roomPass:(NSString*)roomPass target:(NSString*)target
{
    XMPPIQ *xmpp;
    
    NSXMLElement *unholdElement = [NSXMLElement elementWithName:@"unhold"];
    [unholdElement addAttributeWithName:@"xmlns" stringValue:RAYO_XMLNS];
    
    XMPPJID *targetJid = [XMPPJID jidWithString:target];
    
    xmpp  = [[XMPPIQ alloc]initWithType:@"set" to:targetJid elementID:nil child:[unholdElement copy]];
    
    return xmpp;
    
}


@end

