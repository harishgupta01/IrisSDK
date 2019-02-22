//
//  IrisChatMessage+Internal.h
//  IrisRtcSdk
//
//  Created by Girish on 21/06/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#import <IrisRtcSdk/IrisRtcSdk.h>

@interface IrisChatMessage (Internal)

-(id)initWithMessage:message messageId:(NSString*)messageId rootNodeId:(NSString*)rootNodeId childNodeId:(NSString*)childNodeId timeReceived:(NSString*)timeReceived;

@end
