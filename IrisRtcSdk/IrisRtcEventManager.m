//
//  IrisRtcEventManager.m
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 9/26/16.
//  Copyright © 2016 Gupta, Harish (Contractor). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebRTCJSON.h"
#import "IrisRtcEventManager.h"
#import "WebRTCError.h"
#import "WebRTCLogHandler.h"

#import "XMPPWorker.h"
#import "IrisLogging.h"

@interface IrisRtcEventManager()

@property(nonatomic) NSString* traceId;
@property(nonatomic) NSString* roomId;
@property(nonatomic) NSString* serverURL;
@end

@implementation IrisRtcEventManager
{
    NSURLSessionDataTask* datatask;
}

//NSString* const TAG1 = @"IrisRtcEventManager";

@synthesize serverURL,requestTimeout, delegate,isPSTNcallwithTN,useAnonymousRoom;

-(id)initWithURL:(NSString*)endPointURL _token:(NSString *)token delegate:(id<IrisRtcEventManagerDelegate>)eventMngrDelegate{
    
    self = [super init];
    if (self!=nil) {
        serverURL = endPointURL;
        delegate = eventMngrDelegate;
    }
    return self;
}

-(id)initWithTraceId:(NSString *)traceId _roomId:(NSString*)roomId delegate:(id<IrisRtcEventManagerDelegate>)eventMngrDelegate{
    
    self = [super init];
    if (self!=nil) {
        _traceId = traceId;
        delegate = eventMngrDelegate;
        _roomId = roomId;
        isPSTNcallwithTN = false;
    }
    return self;
}

-(void)renewToken:(NSString*)roomId{
    
    NSString* httpMethod = @"GET";
    NSString* serverURL = [NSString stringWithFormat:@"%@v1.1/xmpp/muc/%@/token", [XMPPWorker sharedInstance].eventManagerUrl,roomId];
    IRISLogInfo(@"renewToken::serverURL = %@",serverURL);
    NSError * err;
    NSURL *url = [NSURL URLWithString:serverURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = httpMethod;
    
    
    //NSMutableDictionary* jsonPayload = [[NSMutableDictionary alloc]init];
    //NSData * requestData = [NSJSONSerialization  dataWithJSONObject:jsonPayload options:0 error:&err];
    //[request setHTTPBody: requestData];
    [self getNewToken:request];
}


-(void)createRootEventWithPayload:(NSString*)notificationPayload _sessionType:(IrisRtcSessionType)sessionType
{
   
    double timePosted = (long long)(NSTimeInterval)([[NSDate date] timeIntervalSince1970]* 1000.0);
    
    
    NSMutableDictionary* jsonPayload = [[NSMutableDictionary alloc]init];
    
    [jsonPayload setObject:[IrisRtcUtils sessionTypetoString:sessionType] forKey:@"event_type"];
    
    [jsonPayload setObject:[NSNumber numberWithDouble:timePosted] forKey:@"time_posted"];
    
    
    if(sessionType == kSessionTypePSTN && isPSTNcallwithTN){
         [jsonPayload setObject:[XMPPWorker sharedInstance].sourceTelNum forKey:@"from"];
         [jsonPayload setObject:[XMPPWorker sharedInstance].targetTelNum forKey:@"to"];
         [jsonPayload setObject:[NSNumber numberWithBool:false] forKey:@"inbound"];
    }else{
        [jsonPayload setObject:[XMPPWorker sharedInstance].routingId forKey:@"from"];
    }
    
    
    if(notificationPayload != nil){
         [jsonPayload setObject:notificationPayload forKey:@"userdata"];
    }
   
    
    // Set POST method
    NSString* httpMethod = @"PUT";
    if(sessionType == kSessionTypeChat && !useAnonymousRoom){
        httpMethod = @"GET";
        serverURL = [NSString stringWithFormat:@"%@v1.1/xmpp/muc/%@/credentials", [XMPPWorker sharedInstance].eventManagerUrl,_roomId];
    }
    else
    if(sessionType == kSessionTypeVideoUpgrade && !useAnonymousRoom){
        serverURL = [NSString stringWithFormat:@"%@v1.1/xmpp/muc/%@/upgrade", [XMPPWorker sharedInstance].eventManagerUrl,_roomId];
    }
    else
    if(sessionType == kSessionTypePSTN ){
        if(isPSTNcallwithTN){
             serverURL = [NSString stringWithFormat:@"%@v1.1/pstn/startmuc/federation/pstn", [XMPPWorker sharedInstance].eventManagerUrl];
        }else{
             serverURL = [NSString stringWithFormat:@"%@v1.1/pstn/startmuc/room/%@", [XMPPWorker sharedInstance].eventManagerUrl,_roomId];
        }
       
    }
    else
    if(useAnonymousRoom ){
        serverURL = [NSString stringWithFormat:@"%@v1.1/anonymoususers/startmuc/room/%@", [XMPPWorker sharedInstance].eventManagerUrl,_roomId];
    }
    else{
        serverURL = [NSString stringWithFormat:@"%@v1/xmpp/startmuc/room/%@", [XMPPWorker sharedInstance].eventManagerUrl,_roomId];
    }
  
    NSError * err;
    NSURL *url = [NSURL URLWithString:serverURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = httpMethod;
    NSData * requestData = [NSJSONSerialization  dataWithJSONObject:jsonPayload options:0 error:&err];
    NSString *jsonString = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
    //__block NSInteger retrycount = requestRetryCount;
    //IRISLogInfo(@"createXmppRootEventRequestWithRoomName::URL is = %@",serverURL );
    //IRISLogInfo(@"requestPayload = %@",jsonString);
    [request setHTTPBody: requestData];
    if(sessionType == kSessionTypeChat && !useAnonymousRoom){
        [self getCredentials:request];
    }
    else{
        [self createRootEventWithRoomId:request];
    }
    

}


-(void)getNewToken:(NSMutableURLRequest*)request{
    NSMutableDictionary* httpHeaders = [[NSMutableDictionary alloc]init];
    NSURLSessionConfiguration * sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    [httpHeaders setObject:@"application/json" forKey:@"Content-Type"];
    //   IRISLogInfo(@"Authorization::jsonWebToken = %@",[XMPPWorker sharedInstance].jwToken);
    [httpHeaders setObject:[XMPPWorker sharedInstance].jwToken forKey:@"Authorization"];
    [httpHeaders setObject:_traceId forKey:@"Trace-Id"];
    IRISLogInfo(@"getNewToken::httpHeaders = %@",httpHeaders);
    IRISLogInfo(@"getNewToken::request = %@",request.description);
    sessionConfig.HTTPAdditionalHeaders = httpHeaders;
    
    sessionConfig.timeoutIntervalForRequest = requestTimeout;
    
    NSURLSession * urlSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    
    
    //NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    //[connection start];
    [datatask =  [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data,
                                                                             NSURLResponse *response,
                                                                             NSError *error) {
        NSDictionary* innerJson =[WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        IRISLogInfo(@"getNewToken::response = %ld",(long)((NSHTTPURLResponse *)response).statusCode);
        NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
        if(innerJson != nil)
            IRISLogInfo(@"getNewToken::token = %@",innerJson);
        
        if(self.delegate != nil){
            if(statusCode == 200){
                [self.delegate onRoomTokenRenewd:[innerJson objectForKey:@"roomToken"] _roomTokenExpiry:[innerJson objectForKey:@"roomTokenExpiryTime"]];
            }
            else if(statusCode == 404){
                [self.delegate onRoomInvalid];
            }
            else{
                 NSMutableDictionary* details = [NSMutableDictionary dictionary];
                NSDictionary* errorJson =[innerJson objectForKey:@"error"];
                [details setValue:[errorJson objectForKey:@"message"] forKey:NSLocalizedDescriptionKey];
                 NSError* httperror = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_JWT_EXPIRE userInfo:details];
                 [self.delegate onEventManagerFailure:httperror additionalData:nil];
            }
        }
        
    }]
     resume];
        
}


-(void)createRootEventWithRoomId:(NSMutableURLRequest*)request
{
    
    
    // Set session config
    NSMutableDictionary* httpHeaders = [[NSMutableDictionary alloc]init];
    NSURLSessionConfiguration * sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    // sessionConfig.HTTPAdditionalHeaders = @{ @"Content-Type" : @"application/json"  };
    [httpHeaders setObject:@"application/json" forKey:@"Content-Type"];
 //   IRISLogInfo(@"Authorization::jsonWebToken = %@",[XMPPWorker sharedInstance].jwToken);
    [httpHeaders setObject:[XMPPWorker sharedInstance].jwToken forKey:@"Authorization"];
    [httpHeaders setObject:_traceId forKey:@"Trace-Id"];
  
    sessionConfig.HTTPAdditionalHeaders = httpHeaders;
    
    sessionConfig.timeoutIntervalForRequest = requestTimeout;
    
    NSURLSession * urlSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    
    
    //NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    //[connection start];
    [datatask =  [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data,
                                                                             NSURLResponse *response,
                                                                             NSError *error) {
        
        if(self.delegate != nil)
        {
            NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
            
            IRISLogInfo(@"Recieved data statusCode = %lu",(unsigned long)statusCode);
            
            if (error || (statusCode != 200 && statusCode != 201)) {
                
                NSError *httperror;
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                NSMutableDictionary* additionalData = nil;
                NSString *contentType = [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Content-Type"];
                NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
                
                IRISLogInfo(@"WebRTC HTTP: Received error code from HTTP server :: %lu",(unsigned long)statusCode);
                
//                // Check if the error response has JSON format
//                NSString *contentType = [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Content-Type"];
//                if (contentType && ([contentType isEqualToString:@"application/json"]))
//                {
//                    /* The response is for JSON type so take out the JSON dict */
//                    additionalData = [WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
//
//                    [details setValue:additionalData forKey:NSLocalizedDescriptionKey];
//                    httperror = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_HTTP_CONNECTION_FAILED userInfo:details];
//
//                }
//                else
                if(statusCode == 401)
                {
                    // Check if the error response has JSON format
                    if (contentType && ([contentType isEqualToString:@"application/json"]))
                    {
                        /* The response is for JSON type so take out the JSON dict */
                        additionalData = [WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                        NSString *errorMessage = [[additionalData objectForKey:@"error"] objectForKey:@"message"];
                        [details setValue:errorMessage forKey:NSLocalizedDescriptionKey];
                    }
                    else{
                        [details setValue:@"Invalid token for http connection" forKey:NSLocalizedDescriptionKey];
                    }
                    httperror = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_JWT_EXPIRE userInfo:details];
                }
                else
                {
                    // Check if the error response has JSON format
                    if (contentType && ([contentType isEqualToString:@"application/json"]))
                    {
                        /* The response is for JSON type so take out the JSON dict */
                        additionalData = [WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                        NSString *errorMessage = [[additionalData objectForKey:@"error"] objectForKey:@"message"];
                        [details setValue:errorMessage forKey:NSLocalizedDescriptionKey];
                    }
                    else{
                        NSString *errorDetails = [NSString stringWithFormat:@"HTTP Connection failed with error code %lu", (unsigned long)statusCode];
                        [details setValue:errorDetails forKey:NSLocalizedDescriptionKey];
                    }
                    httperror = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_EVENT_MANAGER userInfo:details];
                }
                
                [self.delegate onEventManagerFailure:httperror additionalData:nil];
                return;
            }
            
            
            NSDictionary* innerJson =[WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            //IRISLogInfo(@"createXmppRootEventRequestWithRoomName data = %@",innerJson);
            
            if(error)
            {
                NSError *httperror;
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                NSString *errorMessage = @"Error in parsing event manager response";
                [details setValue:errorMessage forKey:NSLocalizedDescriptionKey];
                httperror = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_EVENT_MANAGER userInfo:details];
                [self.delegate onEventManagerFailure:httperror additionalData:nil];
                return;
            }
            else
            {
                if(useAnonymousRoom){
                    IrisRootEventInfo* rootEventInfo = [[IrisRootEventInfo alloc]init];
                    [rootEventInfo setRoomId:[innerJson objectForKey:@"room_id"]];
                    [rootEventInfo setRtcServer:[innerJson objectForKey:@"rtc_server"]];
                    [rootEventInfo setRoomToken:[innerJson objectForKey:@"room_token"]];
                    [rootEventInfo setRoomExpiryTime:[innerJson objectForKey:@"room_token_expiry_time"]];
                    [rootEventInfo setTargetRoutingId:[innerJson objectForKey:@"to_routing_id"]];
                    if(self.delegate != nil){
                        [self.delegate onCreateRootEventSuccess:rootEventInfo];
                    }
                }
                else{
                    NSString* rootNodeId =[innerJson objectForKey:@"root_node_id"];
                    NSString* childNodeId =[innerJson objectForKey:@"child_node_id"];
                    NSDictionary* eventDataDict =[innerJson objectForKey:@"eventdata"];
                    if (rootNodeId == nil || childNodeId == nil || eventDataDict == nil)
                    {
                        NSMutableDictionary* details = [NSMutableDictionary dictionary];
                        [details setValue:@"Received incorrect parameters from RTCG" forKey:NSLocalizedDescriptionKey];
                        NSError *error = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_INCORRECT_PARAMS userInfo:details];
                        [self.delegate onEventManagerFailure:error additionalData:nil];
                        return;
                    }
                
                
                    //  IRISLogInfo(@"eventDataDict = %@",eventDataDict);
                    //[self.delegate onCreateRootEventSuccess:rootNodeId _childNodeId:childNodeId _eventData:eventDataDict];
                    IrisRootEventInfo* rootEventInfo = [[IrisRootEventInfo alloc]init];
                    [rootEventInfo setRootNodeId:rootNodeId];
                    [rootEventInfo setChildNodeId:childNodeId];
                    [rootEventInfo setRoomId:[eventDataDict objectForKey:@"room_id"]];
                    [rootEventInfo setRtcServer:[eventDataDict objectForKey:@"rtc_server"]];
                    [rootEventInfo setRoomToken:[eventDataDict objectForKey:@"room_token"]];
                    [rootEventInfo setRoomExpiryTime:[eventDataDict objectForKey:@"room_token_expiry_time"]];
                    [rootEventInfo setTargetRoutingId:[eventDataDict objectForKey:@"to_routing_id"]];
                
                    if(self.delegate != nil){
                        [self.delegate onCreateRootEventSuccess:rootEventInfo];
                    }
                }
            }
        }
    }]
     resume];
    
    
    
}


-(void)getCredentials:(NSMutableURLRequest*)request
{
    
    
    // Set session config
    NSMutableDictionary* httpHeaders = [[NSMutableDictionary alloc]init];
    NSURLSessionConfiguration * sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    // sessionConfig.HTTPAdditionalHeaders = @{ @"Content-Type" : @"application/json"  };
    [httpHeaders setObject:@"application/json" forKey:@"Content-Type"];
  //  IRISLogInfo(@"Authorization::jsonWebToken = %@",[XMPPWorker sharedInstance].jwToken);
    [httpHeaders setObject:[XMPPWorker sharedInstance].jwToken forKey:@"Authorization"];
    [httpHeaders setObject:_traceId forKey:@"Trace-Id"];
  //  IRISLogInfo(@"HttpHeaders = %@",httpHeaders);
    sessionConfig.HTTPAdditionalHeaders = httpHeaders;
    
    sessionConfig.timeoutIntervalForRequest = requestTimeout;
    
    NSURLSession * urlSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    
    
    //NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    //[connection start];
    [datatask =  [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data,
                                                                             NSURLResponse *response,
                                                                             NSError *error) {
        
        if(self.delegate != nil)
        {
            NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
            
            IRISLogInfo(@"Recieved data statusCode = %lu",(unsigned long)statusCode);
            
            if (error || statusCode != 200) {
                
                NSError *httperror;
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                NSMutableDictionary* additionalData = nil;
                NSString *contentType = [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Content-Type"];
                NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
                
                IRISLogInfo(@"WebRTC HTTP: Received error code from HTTP server :: %lu",(unsigned long)statusCode);
                
                // Check if the error response has JSON format
//                NSString *contentType = [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Content-Type"];
//                if (contentType && ([contentType isEqualToString:@"application/json"]))
//                {
//                    /* The response is for JSON type so take out the JSON dict */
//                    additionalData = [WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
//
//                    [details setValue:additionalData forKey:NSLocalizedDescriptionKey];
//                    httperror = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_HTTP_CONNECTION_FAILED userInfo:details];
//
//                }
//                else
                if(statusCode == 401)
                {
                    // Check if the error response has JSON format
                    if (contentType && ([contentType isEqualToString:@"application/json"]))
                    {
                        /* The response is for JSON type so take out the JSON dict */
                        additionalData = [WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                        NSString *errorMessage = [[additionalData objectForKey:@"error"] objectForKey:@"message"];
                        [details setValue:errorMessage forKey:NSLocalizedDescriptionKey];
                    }
                    else
                    {
                        [details setValue:@"Invalid token for http connection" forKey:NSLocalizedDescriptionKey];
                    }
                    httperror = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_JWT_EXPIRE userInfo:details];
                }
                else
                {
                    // Check if the error response has JSON format
                    if (contentType && ([contentType isEqualToString:@"application/json"]))
                    {
                        /* The response is for JSON type so take out the JSON dict */
                        additionalData = [WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                        NSString *errorMessage = [[additionalData objectForKey:@"error"] objectForKey:@"message"];
                        [details setValue:errorMessage forKey:NSLocalizedDescriptionKey];
                    }
                    else
                    {
                        NSString *errorDetails = [NSString stringWithFormat:@"HTTP Connection failed with error code %lu", (unsigned long)statusCode];
                        [details setValue:errorDetails forKey:NSLocalizedDescriptionKey];
                    }
                    httperror = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_EVENT_MANAGER userInfo:details];
                }
                
                [self.delegate onEventManagerFailure:httperror additionalData:nil];
                return;
            }
            
            
            NSDictionary* innerJson =[WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
         //   IRISLogInfo(@"createXmppRootEventRequestWithRoomName data = %@",innerJson);
            
            if(error)
            {
                NSError *httperror;
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                NSString *errorMessage = @"Error in parsing event manager response";
                [details setValue:errorMessage forKey:NSLocalizedDescriptionKey];
                httperror = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_EVENT_MANAGER userInfo:details];
                [self.delegate onEventManagerFailure:httperror additionalData:nil];
                return;
            }
            else
            {
                NSString* roomToken =[innerJson objectForKey:@"roomToken"];
                NSString* roomTokenExpiryTime =[innerJson objectForKey:@"roomTokenExpiryTime"];
                NSString* rtcServer =[innerJson objectForKey:@"rtcServer"];
            
                if (roomToken == nil || roomTokenExpiryTime == nil || rtcServer == nil)
                {
                    NSMutableDictionary* details = [NSMutableDictionary dictionary];
                    [details setValue:@"Received incorrect parameters from RTCG" forKey:NSLocalizedDescriptionKey];
                    NSError *error = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_INCORRECT_PARAMS userInfo:details];
                    [self.delegate onEventManagerFailure:error additionalData:nil];
                    return;
                }
            
                if(self.delegate != nil){
                    //[self.delegate onCreateRootEventSuccess:rootNodeId _childNodeId:childNodeId _eventData:eventDataDict];
                    IrisRootEventInfo* rootEventInfo = [[IrisRootEventInfo alloc]init];
                    [rootEventInfo setRtcServer:rtcServer];
                    [rootEventInfo setRoomToken:roomToken];
                    [rootEventInfo setRoomExpiryTime:roomTokenExpiryTime];
                    [self.delegate onCreateRootEventSuccess:rootEventInfo];
                }
            }
        }
    }]
     resume];
    
    
    
}

-(void)getXmppRegisterInfo
{
    NSURL *url = [NSURL URLWithString:serverURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    // Set POST method
    request.HTTPMethod = @"GET";
    
    // Set session config
    NSURLSessionConfiguration * sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSMutableDictionary *httpHeaders = [[NSMutableDictionary alloc]init];
    [httpHeaders setObject:@"application/x-www-form-urlencoded" forKey:@"Content-Type"];
    IRISLogInfo(@"Authorization::jsonWebToken = %@",[XMPPWorker sharedInstance].jwToken);
    [httpHeaders setObject:[XMPPWorker sharedInstance].jwToken forKey:@"Authorization"];
    
    sessionConfig.HTTPAdditionalHeaders = httpHeaders;
    sessionConfig.timeoutIntervalForRequest = requestTimeout;
    
    NSURLSession * urlSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    
   
    [datatask =  [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data,
                                                                             NSURLResponse *response,
                                                                             NSError *error) {
        
        if(self.delegate != nil)
        {
            
            NSString *strData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            
         //   IRISLogInfo(@"WebRTC HTTP: didReceiveData %@",strData );
            
            NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
            
            if (error || statusCode != 200) {
                NSError *httperror;
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                NSMutableDictionary* additionalData = nil;
                NSString *contentType = [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Content-Type"];
                NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
                
                IRISLogInfo(@"WebRTC HTTP: Received error code from HTTP server :: %lu",(unsigned long)statusCode);
                
//                // Check if the error response has JSON format
//                NSString *contentType = [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Content-Type"];
//                if (contentType && ([contentType isEqualToString:@"application/json"]))
//                {
//                    /* The response is for JSON type so take out the JSON dict */
//                    additionalData = [WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
//
//                    [details setValue:additionalData forKey:NSLocalizedDescriptionKey];
//                    httperror = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_HTTP_CONNECTION_FAILED userInfo:details];
//
//                }
//                else
                if(statusCode == 401)
                {
                    // Check if the error response has JSON format
                    if (contentType && ([contentType isEqualToString:@"application/json"]))
                    {
                        /* The response is for JSON type so take out the JSON dict */
                        additionalData = [WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                        NSString *errorMessage = [[additionalData objectForKey:@"error"] objectForKey:@"message"];
                        [details setValue:errorMessage forKey:NSLocalizedDescriptionKey];
                    }
                    else
                    {
                        [details setValue:@"Invalid token for http connection" forKey:NSLocalizedDescriptionKey];
                    }
                    httperror = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_JWT_EXPIRE userInfo:details];
                }
                else
                {
                    // Check if the error response has JSON format
                    if (contentType && ([contentType isEqualToString:@"application/json"]))
                    {
                        /* The response is for JSON type so take out the JSON dict */
                        additionalData = [WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                        NSString *errorMessage = [[additionalData objectForKey:@"error"] objectForKey:@"message"];
                        [details setValue:errorMessage forKey:NSLocalizedDescriptionKey];
                    }
                    else
                    {
                        NSString *errorDetails = [NSString stringWithFormat:@"HTTP Connection failed with error code %lu", (unsigned long)statusCode];
                        [details setValue:errorDetails forKey:NSLocalizedDescriptionKey];
                    }
                    httperror = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_EVENT_MANAGER userInfo:details];
                }
                [self.delegate onEventManagerFailure:httperror additionalData:nil];
                return;
            }
            
            NSDictionary* innerJson =[WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            // IRISLogInfo(@"Recieved register Info = %@",innerJson);
            
            if(error)
            {
                NSError *httperror;
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                NSString *errorMessage = @"Error in parsing event manager response";
                [details setValue:errorMessage forKey:NSLocalizedDescriptionKey];
                httperror = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_EVENT_MANAGER userInfo:details];
                [self.delegate onEventManagerFailure:httperror additionalData:nil];
                return;
            }
            else
            {
                NSError* jsonError;
                NSData *objectData = [[innerJson objectForKey:@"turn_credentials"] dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *turnServer;
                if(objectData != nil)
                {
                    turnServer = [NSJSONSerialization JSONObjectWithData:objectData
                                                                           options:NSJSONReadingMutableContainers
                                                                             error:&jsonError];
                    //   IRISLogInfo(@"TurnServer are = %@",turnServer);
                }

        
                NSString* rtcServer =[innerJson objectForKey:@"websocket_server"];
                NSString* xmppToken =[innerJson objectForKey:@"websocket_server_token"];
                NSString* tokenExpiryTime =[innerJson objectForKey:@"websocket_server_token_expiry_time"];
            
            
                if(self.delegate != nil)
                    [self.delegate onXmppRegisterInfoSuccess:rtcServer _xmppToken:xmppToken _tokenExpiryTime:tokenExpiryTime _turnServer:turnServer];;
            }
        }
    }]
     resume];
}

-(void)End{
    if(datatask)
    [datatask cancel];
    self.delegate=nil;
}



@end
