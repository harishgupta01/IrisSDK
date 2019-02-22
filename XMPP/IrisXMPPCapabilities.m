//
//  IrisXMPPCapabilities.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 11/22/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IrisXMPPCapabilities.h"

#define DISCO_NODE @"https://github.com/robbiehanson/XMPPFramework"
#define XMLNS_DISCO_INFO  @"http://jabber.org/protocol/disco#info"
#define XMLNS_CAPS        @"http://jabber.org/protocol/caps"

@implementation IrisXMPPCapabilities

@synthesize dataElement;

- (void)handleDiscoRequest:(XMPPIQ *)iqRequest
{
    // This method must be invoked on the moduleQueue
    NSAssert(dispatch_get_specific(moduleQueueTag), @"Invoked on incorrect queue");
    
    
    
    
    NSXMLElement *myCapabilitiesQuery = [NSXMLElement elementWithName:@"query" xmlns:XMLNS_DISCO_INFO];
    
    NSXMLElement *feature1 = [NSXMLElement elementWithName:@"feature"];
    [feature1 addAttributeWithName:@"var" stringValue:XMLNS_DISCO_INFO];
    
    NSXMLElement *feature2 = [NSXMLElement elementWithName:@"feature"];
    [feature2 addAttributeWithName:@"var" stringValue:XMLNS_CAPS];
    
    NSXMLElement *feature10 = [NSXMLElement elementWithName:@"feature"];
    [feature10 addAttributeWithName:@"var" stringValue:@"urn:xmpp:jingle:apps:rtp:1"];
    
    NSXMLElement *feature3 = [NSXMLElement elementWithName:@"feature"];
    [feature3 addAttributeWithName:@"var" stringValue:@"urn:ietf:rfc:5761"];
    
    NSXMLElement *feature4 = [NSXMLElement elementWithName:@"feature"];
    [feature4 addAttributeWithName:@"var" stringValue:@"urn:ietf:rfc:5888"];
    
    NSXMLElement *feature5 = [NSXMLElement elementWithName:@"feature"];
    [feature5 addAttributeWithName:@"var" stringValue:@"urn:xmpp:jingle:1"];
    
    NSXMLElement *feature6 = [NSXMLElement elementWithName:@"feature"];
    [feature6 addAttributeWithName:@"var" stringValue:@"urn:xmpp:jingle:apps:rtp:audio"];
    
    NSXMLElement *feature7 = [NSXMLElement elementWithName:@"feature"];
    [feature7 addAttributeWithName:@"var" stringValue:@"urn:xmpp:jingle:apps:rtp:video"];
    
    NSXMLElement *feature8 = [NSXMLElement elementWithName:@"feature"];
    [feature8 addAttributeWithName:@"var" stringValue:@"urn:xmpp:jingle:transports:ice-udp:1"];
    
    NSXMLElement *feature9 = [NSXMLElement elementWithName:@"feature"];
    [feature9 addAttributeWithName:@"var" stringValue:@"urn:xmpp:rayo:client:1"];
    
    NSXMLElement *feature11 = [NSXMLElement elementWithName:@"feature"];
    [feature11 addAttributeWithName:@"var" stringValue:@"http://jabber.org/protocol/si"];
    
    NSXMLElement *feature12 = [NSXMLElement elementWithName:@"feature"];
    [feature12 addAttributeWithName:@"var" stringValue:@"http://jabber.org/protocol/si/profile/file-transfer"];
    
    NSXMLElement *feature13 = [NSXMLElement elementWithName:@"feature"];
    [feature13 addAttributeWithName:@"var" stringValue:@"http://jabber.org/protocol/bytestreams"];
    
    NSXMLElement *feature14 = [NSXMLElement elementWithName:@"feature"];
    [feature14 addAttributeWithName:@"var" stringValue:@"http://jabber.org/protocol/ibb"];
    
    NSXMLElement *feature15 = [NSXMLElement elementWithName:@"feature"];
    [feature15 addAttributeWithName:@"var" stringValue:@"urn:xmpp:jingle:transports:dtls-sctp:1"];
    
    [myCapabilitiesQuery addChild:feature1];
    [myCapabilitiesQuery addChild:feature2];
    
    // muc changes
    [myCapabilitiesQuery addChild:feature10];
    [myCapabilitiesQuery addChild:feature3];
    [myCapabilitiesQuery addChild:feature4];
    [myCapabilitiesQuery addChild:feature5];
    [myCapabilitiesQuery addChild:feature6];
    [myCapabilitiesQuery addChild:feature7];
    [myCapabilitiesQuery addChild:feature8];
    [myCapabilitiesQuery addChild:feature9];
    
    //fileTransfer
    [myCapabilitiesQuery addChild:feature11];
    [myCapabilitiesQuery addChild:feature12];
    [myCapabilitiesQuery addChild:feature13];
    [myCapabilitiesQuery addChild:feature14];
    [myCapabilitiesQuery addChild:feature15];
    
    
    NSXMLElement *queryRequest = [iqRequest childElement];
    NSString *node = [queryRequest attributeStringValueForName:@"node"];
    
    // <iq to="jid" id="id" type="result">
    //   <query xmlns="http://jabber.org/protocol/disco#info">
    //     <feature var="feature1"/>
    //     <feature var="feature2"/>
    //   </query>
    // </iq>
    
    if (node)
    {
        [myCapabilitiesQuery addAttributeWithName:@"node" stringValue:node];
    }
    
    XMPPIQ *iqResponse = [XMPPIQ iqWithType:@"result"
                                         to:[iqRequest from]
                                  elementID:[iqRequest elementID]
                                      child:myCapabilitiesQuery];
    if(dataElement){
        [iqResponse addChild:[dataElement bare]];
    }
    
    [xmppStream sendElement:iqResponse];
    
}

@end

