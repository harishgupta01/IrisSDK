//
//  IrisPhoneNumberUtil.h
//  IrisRtcSdk
//
//  Created by Girish on 14/06/18.
//  Copyright © 2018 Gupta, Harish (Contractor). All rights reserved.
//

#ifndef IrisPhoneNumberUtil_h
#define IrisPhoneNumberUtil_h
@import libPhoneNumber_iOS;
@interface IrisPhoneNumberUtil : NSObject

-(id)initWithPhonenumber:(NSString*)phonenumber;

-(NSString*)getRayoiqNumber;

-(NSString*)getMucRequestNumber;

-(NSString*)parsedNum:(NSString*)number;
@end

#endif /* IrisPhoneNumberUtil_h */
