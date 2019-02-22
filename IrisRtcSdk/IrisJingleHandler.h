//
//  IrisJingleHandler.h
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 7/28/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#ifndef IrisJingleHandler_h
#define IrisJingleHandler_h

#import "XMPPWorker.h"

@interface IrisJingleHandler : NSObject

-(id)initWithDataElement:(IrisDataElement*)dataElement roomId:(NSString*)roomId;
    
- (void)activateJingle: (id<XMPPJingleDelegate>)appDelegate;

- (void)deactivateJingle;

- (void)sendJingleMessage:(NSString*)type data:(NSDictionary*)data target:(XMPPJID *)target;

- (void)sendVideoInfo:(NSString*)type data:(NSDictionary*)data target:(XMPPJID *)target;

-(NSString*)routingId:(NSString*)streamId;

@end

#endif /* IrisJingleHandler_h */
