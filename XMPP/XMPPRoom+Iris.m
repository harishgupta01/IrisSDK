//
//  XMPPRoom+Iris.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 11/21/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#import "XMPPRoom+Iris.h"

@implementation XMPPRoom (Iris)

- (void)joinRoomUsingNickname:(NSString *)desiredNickname{
    /*dispatch_block_t block = ^{ @autoreleasepool {
        
        XMPPLogTrace2(@"%@[%@] - %@", THIS_FILE, roomJID, THIS_METHOD);
        
        // Check state and update variables
        
        if (![self preJoinWithNickname:desiredNickname])
        {
            return;
        }
        
        // <presence to='darkcave@chat.shakespeare.lit/firstwitch'>
        //   <x xmlns='http://jabber.org/protocol/muc'/>
        //     <history/>
        //     <password>passwd</password>
        //   </x>
        // </presence>
        
        NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:XMPPMUCNamespace];
    
        
        XMPPPresence *presence = [XMPPPresence presenceWithType:nil to:myRoomJID];
        [presence addChild:x];
        if(participant != nil){
            NSXMLElement *userProfile = [NSXMLElement elementWithName:@"nick" xmlns:@"http://jabber.org/protocol/nick"];
            [userProfile addAttributeWithName:@"name" stringValue:participant.name];
            [userProfile addAttributeWithName:@"avatar" stringValue:participant.avatarUrl];
            
            [presence addChild:userProfile];
        }
        
        if(dataElement != nil){
            [presence addChild:[dataElement full]];
        }
        [xmppStream sendElement:presence];
        
        state |= kXMPPRoomStateJoining;
        
    }};
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);*/
}

@end
