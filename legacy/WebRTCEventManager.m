//
//  WebRTCEventManager.m
//  xfinity-webrtc-sdk
//
//  Created by Gupta, Harish (Contractor) on 7/14/16.
//  Copyright © 2016 Comcast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebRTCJSON.h"
#import "WebRTCEventManager.h"
#import "WebRTCError.h"
#import "WebRTCLogHandler.h"
#import "WebRTCLogging.h"

@implementation WebRTCEventManager
{
    NSURLSessionDataTask* datatask;
}

//NSString* const TAG1 = @"WebRTCEventManager";

@synthesize serverURL,jsonWebToken,requestTimeout,requestHeader,requestPayload, delegate;

+ (WebRTCEventManager *)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static WebRTCEventManager *_sharedEventManager = nil;
    dispatch_once(&pred, ^{
        _sharedEventManager = [[self alloc] init];
    });
    return _sharedEventManager;
}


/*- (id)initWithDefaultValue:(NSString*)endPointURL  _token:(NSString*)token
{
    self = [super init];
    if (self!=nil) {
        _url = endPointURL;
    }
    
    if ((endPointURL == nil) || (token == nil))
    {
        return nil;
    }
    
    _tokenStr = token;
    datatask = nil;
    return self;
}*/

-(void)createXmppRootEventWithRoomName
{
    NSLog(@"createXmppRootEventRequestWithRoomName::URL is = %@",serverURL );
    NSURL *url = [NSURL URLWithString:serverURL];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    // Set POST method
    request.HTTPMethod = @"PUT";
    NSError * err;
    NSData * requestData = [NSJSONSerialization  dataWithJSONObject:requestPayload options:0 error:&err];
    NSString *jsonString = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
    //__block NSInteger retrycount = requestRetryCount;
    
    NSLog(@"requestPayload = %@",jsonString);
    [request setHTTPBody: requestData];
    
    // Set session config
    NSURLSessionConfiguration * sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    // sessionConfig.HTTPAdditionalHeaders = @{ @"Content-Type" : @"application/json"  };
    NSMutableDictionary *httpHeaders = [requestHeader mutableCopy];
    [httpHeaders setObject:@"application/json" forKey:@"Content-Type"];
    
    [httpHeaders setObject:jsonWebToken forKey:@"Authorization"];
    NSLog(@"Harish::httpHeaders = %@",httpHeaders);
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
            
            NSLog(@"Recieved data statusCode = %lu",(unsigned long)statusCode);
            
            if (error || statusCode != 200) {
                
                //if status code equals 202,retry to join room.
                /*if(statusCode == 202 && retrycount>=1){
                    retrycount--;
                  [self createXmppRootEventRequestWithRoomName:requestPayload _requestHeaders:requestHeaders _requestTimeout:requestTimeoutInterval _requestType:requestType _requestretryCount:retrycount];
                    return;
                }else{
                   // [self ProcessSessionManagerError:data _response:response _error:error];
                    return;
                }*/
            }
            
            
            NSDictionary* innerJson =[WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            NSLog(@"createXmppRootEventRequestWithRoomName data = %@",innerJson);
            
            
            NSString* rootNodeId =[innerJson objectForKey:@"root_node_id"];
            NSString* childNodeId =[innerJson objectForKey:@"child_node_id"];
            NSDictionary* eventDataDict =[innerJson objectForKey:@"eventdata"];
            
            if (rootNodeId == nil || childNodeId == nil || eventDataDict == nil)
            {
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                [details setValue:@"Received incorrect parameters from RTCG" forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_INCORRECT_PARAMS userInfo:details];
                [self.delegate onEventManagerFailure:error.description errorCode:error.code additionalData:nil];
                return;
            }
            
            
            
            //NSDictionary* eventDataDict = [NSJSONSerialization JSONObjectWithData:[eventDataString dataUsingEncoding:NSUTF8StringEncoding]
                                            //options:NSJSONReadingMutableContainers
                                            //  error:&error];
            if(self.delegate != nil)
                [self.delegate onCreateRootEventSuccess:rootNodeId _childNodeId:childNodeId _eventData:eventDataDict];
            
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
    [httpHeaders setObject:jsonWebToken forKey:@"Authorization"];
    
    sessionConfig.HTTPAdditionalHeaders = httpHeaders;
    sessionConfig.timeoutIntervalForRequest = requestTimeout;
    
    NSURLSession * urlSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    
    
    [datatask =  [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data,
                                                                             NSURLResponse *response,
                                                                             NSError *error) {
        
        if(self.delegate != nil)
        {
            
            NSString *strData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            
            LogInfo(@"WebRTC HTTP: didReceiveData %@",strData );
            
            NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
            
            if (error || statusCode != 200) {
                NSError *httperror;
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                NSMutableDictionary* additionalData = nil;
                
                NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
                
                LogInfo(@"WebRTC HTTP: Received error code from HTTP server :: %lu",(unsigned long)statusCode);
                
                // Check if the error response has JSON format
                NSString *contentType = [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Content-Type"];
                if (contentType && ([contentType isEqualToString:@"application/json"]))
                {
                    /* The response is for JSON type so take out the JSON dict */
                    additionalData = [WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                    
                    [details setValue:additionalData forKey:NSLocalizedDescriptionKey];
                    httperror = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_HTTP_CONNECTION_FAILED userInfo:details];
                    
                }
                else
                {
                    if(statusCode == 401)
                    {
                        [details setValue:@"Invalid credential for http connection" forKey:NSLocalizedDescriptionKey];
                        httperror = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_INVALID_CREDENTIALS userInfo:details];
                    }
                    else
                    {
                        NSString *errorDetails = [NSString stringWithFormat:@"Get resources :  HTTP Connection failed with error code %lu", (unsigned long)statusCode];
                        [details setValue:errorDetails forKey:NSLocalizedDescriptionKey];
                        httperror = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_HTTP_CONNECTION_FAILED userInfo:details];
                    }
                }
                
                [self.delegate onEventManagerFailure:error.description errorCode:error.code additionalData:nil];
                return;
            }
            
            NSDictionary* innerJson =[WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            NSLog(@"Recieved register Info = %@",innerJson);
            
            
            NSString* rtcServer =[innerJson objectForKey:@"Rtc_server"];
            NSString* xmppToken =[innerJson objectForKey:@"Xmpp_token"];
            NSString* tokenExpiryTime =[innerJson objectForKey:@"Xmpp_token_expiry_time"];
            
            
            if(self.delegate != nil)
                [self.delegate onXmppRegisterInfoSuccess:rtcServer _xmppToken:xmppToken _tokenExpiryTime:tokenExpiryTime];
            
        }
    }]
     resume];
}
@end
