    //
//  WebRTCFactory.m
//  XfinityVideoShare
//
//  Created by Ganvir, Manish (Contractor) on 5/29/14.
//  Copyright (c) 2014 Infosys. All rights reserved.
//

#import "WebRTCFactory.h"
#import "WebRTC/WebRTC.h"

@implementation WebRTCFactory

// Shared factory for all the classes
static RTCPeerConnectionFactory *FactoryInstance = nil;

+ (RTCPeerConnectionFactory *)getPeerConnectionFactory{
    
    if (FactoryInstance == nil)
    {
        FactoryInstance = [[RTCPeerConnectionFactory alloc] init];
        //RTCInitFieldTrials(RTCFieldTrialOptionsSendSideBwe);
        RTCInitializeSSL();
        //RTCSetupInternalTracer();
        
        // In debug builds the default level is LS_INFO and in non-debug builds it is
        // disabled. Continue to log to console in non-debug builds, but only
        // warnings and errors.
        
        //For Debug build enable Iris native logs
        #ifdef DEBUG
        RTCSetMinDebugLogLevel(RTCLoggingSeverityInfo);
        #endif
        
        //For Release build disable Iris native logs
        #ifndef DEBUG
        RTCSetMinDebugLogLevel(RTCLoggingSeverityError+1);
        #endif

        //[RTCPeerConnectionFactory initializeSSL];
    }
    return FactoryInstance;
}

+ (void)DestroyPeerConnectionFactory
{
    if (FactoryInstance != nil)
    {
        //[RTCPeerConnectionFactory deinitializeSSL];
        FactoryInstance = nil;
    }
    RTCShutdownInternalTracer();
    RTCCleanupSSL();
}



@end
