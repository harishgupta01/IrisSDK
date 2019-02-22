//
//  IrisXMPPCapabilities.h
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 11/22/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#ifndef IrisXMPPCapabilities_h
#define IrisXMPPCapabilities_h
#import "IrisDataElement.h"
@import XMPPFramework;

@interface IrisXMPPCapabilities : XMPPCapabilities

@property (nonatomic) IrisDataElement *dataElement;

@end

#endif /* IrisXMPPCapabilities_h */
