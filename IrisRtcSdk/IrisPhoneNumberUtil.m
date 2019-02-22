//
//  IrisPhoneNumberUtil.m
//  IrisRtcSdk
//
//  Created by Girish on 14/06/18.
//  Copyright © 2018 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IrisPhoneNumberUtil.h"
#import "IrisLogging.h"

@implementation IrisPhoneNumberUtil 

{
    NSString* rawTelephonenum;
}


-(id)initWithPhonenumber:(NSString*)phonenumber{
    self = [super init];
    if (self!=nil) {
         rawTelephonenum = phonenumber;
    }
    return self;
}


-(BOOL)hasStarCode{
    
    if([rawTelephonenum hasPrefix:@"*"]) {
        return  true;
    }
    return false;
}

-(BOOL)hasE164Prefix{
    
    if([rawTelephonenum hasPrefix:@"+"]) {
        return  true;
    }
    return false;
}

-(BOOL)isNonStdTN{
    return ![self hasStarCode] && ![self hasE164Prefix] && [rawTelephonenum length] < 10;
}
-(NSString*)getRayoiqNumber{
    
    if([self hasStarCode] || [self isNonStdTN]){
        return rawTelephonenum;
    }
    return  [self parsedNum:rawTelephonenum];;
}

-(NSString*)getMucRequestNumber{
    
    if([self hasStarCode]){
        
        if([rawTelephonenum length] > 3){
            NSString* code;
            //code = [rawTelephonenum substringWithRange:NSMakeRange(0, 3)];
            //code = [rawTelephonenum substringWithRange:NSMakeRange(3,[rawTelephonenum length]-[code length])];
            code = [rawTelephonenum substringFromIndex:3];
            return [self parsedNum:code];
        }
     
        return rawTelephonenum;
        
    }else if([self isNonStdTN]){
        return  rawTelephonenum;
    }else{
        return  [self parsedNum:rawTelephonenum];
    }
   
}

-(NSString*)parsedNum:(NSString*)number{
    
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSString *countryCode = [usLocale objectForKey:NSLocaleCountryCode];
    NSError *error = nil;
    NSString *targetNum;
    NBPhoneNumber *targetNumObj =  [[NBPhoneNumberUtil sharedInstance]parse:number defaultRegion:countryCode error:&error];
    if(error){
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Incorrect parameters" forKey:NSLocalizedDescriptionKey];
        IRISLogError(@"Error in target telephone num conversion: %@", details);
        return @"";
    }else{
        NSError *err = nil;
        targetNum = [[NBPhoneNumberUtil sharedInstance]format:targetNumObj numberFormat:NBEPhoneNumberFormatE164 error:&err];
        if(err){
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Incorrect parameters" forKey:NSLocalizedDescriptionKey];
            IRISLogError(@"Error in target telephone num conversion: %@", details);
             return @"";
        }
       
        return  targetNum;
    }
}


@end
