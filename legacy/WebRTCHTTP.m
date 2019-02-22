//
//  WebRTCHTTP.m
//  xfinity-webrtc-sdk
//
//  Created by Pankaj on 05/08/14.
//  Copyright (c) 2014 Comcast. All rights reserved.
//

#import "WebRTCJSON.h"
#import "WebRTCHTTP.h"
#import "WebRTCError.h"
#import "WebRTCLogHandler.h"
#import "WebRTCLogging.h"

@implementation WebRTCHTTP
{
    NSURLSessionDataTask* datatask;
}

NSString* const TAG1 = @"WebRTCHTTP";

@synthesize url = _url;

-(id)init
{
    self = [super init];
    if (self!=nil) {
    }
        return self;
}

- (id)initWithDefaultValue:(NSString*)endPointURL  _token:(NSData*)token
{
    self = [super init];
    if (self!=nil) {
        _url = endPointURL;
    }
    
    if ((endPointURL == nil) || (token == nil))
    {
        return nil;
    }
    
    NSString *tokenDataString = [[NSString alloc] initWithData:token encoding:NSUTF8StringEncoding];
    _tokenStr = [NSString stringWithFormat:@"Bearer %@", tokenDataString];
    datatask = nil;
    return self;
}


-(void)sendResourceRequest:(NSDictionary*)requestHeaders _usingRTC20:(BOOL)usingRTC20 _requestTimeout:(NSTimeInterval)requestTimeoutInterval
{
    LogInfo(@"URL is = %@",_url );
    NSURL *url = [NSURL URLWithString:_url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
   
    // Set POST method
    request.HTTPMethod = @"GET";
    
    // Set session config
    NSURLSessionConfiguration * sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
  
    NSMutableDictionary *httpHeaders = [requestHeaders mutableCopy];
    [httpHeaders setObject:@"application/x-www-form-urlencoded" forKey:@"Content-Type"];
    [httpHeaders setObject:_tokenStr forKey:@"Authorization"];
    
    sessionConfig.HTTPAdditionalHeaders = httpHeaders;
    sessionConfig.timeoutIntervalForRequest = requestTimeoutInterval;
    
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
                
                [self.delegate onHTTPError:httperror.description errorCode:httperror.code additionalData:additionalData];
                    return;
                }
        
            
        if(self.delegate != nil)
            [self.delegate startSignalingServer:data];

    }
    }]
        resume];

}

-(void)sendCreateJoinRoomRequest:(NSDictionary*)requestPayload _requestHeaders:(NSDictionary*)requestHeaders _requestTimeout:(NSTimeInterval)requestTimeoutInterval _requestType:(NSString *)requestType _requestretryCount:(NSInteger)requestRetryCount
{
    NSLog(@"sendCreateRoomRequest::URL is = %@",_url );
    NSURL *url = [NSURL URLWithString:_url];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    // Set POST method
    request.HTTPMethod = @"PUT";
    NSError * err;
    NSData * requestData = [NSJSONSerialization  dataWithJSONObject:requestPayload options:0 error:&err];
    NSString *jsonString = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
    __block NSInteger retrycount = requestRetryCount;
  
    NSLog(@"jsonString = %@",jsonString);
    [request setHTTPBody: requestData];
    
    // Set session config
    NSURLSessionConfiguration * sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
   // sessionConfig.HTTPAdditionalHeaders = @{ @"Content-Type" : @"application/json"  };
    NSMutableDictionary *httpHeaders = [requestHeaders mutableCopy];
    [httpHeaders setObject:@"application/json" forKey:@"Content-Type"];
    [httpHeaders setObject:_tokenStr forKey:@"Authorization"];
    
    sessionConfig.HTTPAdditionalHeaders = httpHeaders;
    
    sessionConfig.timeoutIntervalForRequest = requestTimeoutInterval;
    
    NSURLSession * urlSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    
    
    //NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    //[connection start];
    [datatask =  [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data,
                                                                             NSURLResponse *response,
                                                                             NSError *error) {
        
        if(self.delegate != nil)
        {
            NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
            
            if (error || statusCode != 200) {
                
                //if status code equals 202,retry to join room.
                if(statusCode == 202 && retrycount>=1){
                    retrycount--;
                    [self sendCreateJoinRoomRequest:requestPayload _requestHeaders:requestHeaders _requestTimeout:requestTimeoutInterval _requestType:requestType _requestretryCount:retrycount];
                    return;
                }else{
                    [self ProcessSessionManagerError:data _response:response _error:error];
                    return;
                }
            }
            
            
            NSDictionary* innerJson =[WebRTCJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            NSLog(@"Recieved data = %@",innerJson);           

            
            NSString* mucid =[innerJson objectForKey:@"mucid"];
            NSString* timestamp =[innerJson objectForKey:@"timestamp"];
            NSString* xmppToken =[innerJson objectForKey:@"xmppToken"];
            
            if (mucid == nil || timestamp == nil || xmppToken == nil)
            {
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                [details setValue:@"Received incorrect parameters from RTCG" forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_INCORRECT_PARAMS userInfo:details];
                [self.delegate onHTTPError:error.description errorCode:error.code additionalData:nil];
                return;
            }
            
            if(self.delegate != nil)
                [self.delegate createXMPPConnection:mucid _timestamp:timestamp _xmppToken:xmppToken _requestType:requestType];
            
        }
    }]
     resume];
    
}

-(void)sendCloseRoomRequest:(NSDictionary*)requestPayload _requestHeaders:(NSDictionary*)requestHeaders _requestTimeout:(NSTimeInterval)requestTimeoutInterval
{
    NSLog(@"sendCloseRoomRequest::URL is = %@",_url );
    NSURL *url = [NSURL URLWithString:_url];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    // Set POST method
    request.HTTPMethod = @"PUT";
    NSError * err;
    NSData * requestData = [NSJSONSerialization  dataWithJSONObject:requestPayload options:0 error:&err];
    NSString *jsonString = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
    
    NSLog(@"jsonString = %@",jsonString);
    [request setHTTPBody: requestData];
    
    // Set session config
    NSURLSessionConfiguration * sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    // sessionConfig.HTTPAdditionalHeaders = @{ @"Content-Type" : @"application/json"  };
    NSMutableDictionary *httpHeaders = [requestHeaders mutableCopy];
    [httpHeaders setObject:@"application/json" forKey:@"Content-Type"];
    [httpHeaders setObject:_tokenStr forKey:@"Authorization"];
    
    sessionConfig.HTTPAdditionalHeaders = httpHeaders;
    
    sessionConfig.timeoutIntervalForRequest = requestTimeoutInterval;
    
    NSURLSession * urlSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    
    
    //NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    //[connection start];
    [datatask =  [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data,
                                                                             NSURLResponse *response,
                                                                             NSError *error) {
        
        if(self.delegate != nil)
        {
            NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
            
            if (error || statusCode != 200) {
                [self ProcessSessionManagerError:data _response:response _error:error];
                return;
            }
            
            if(self.delegate != nil)
            {
                [self.delegate onCloseRoom];
            }
            
            
        }
    }]
     resume];
    
}

/* Method which processes session manager related error codes */
-(void)ProcessSessionManagerError: (NSData *)data _response:(NSURLResponse *)response _error:(NSError *)error
{
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
        
        LogInfo(@"WebRTC HTTP: Received error: Details are :: %@",[additionalData description]);
        NSString *errorDetails = [NSString stringWithFormat:@"Error from session manager with code %lu, see additional data for more details", (unsigned long)statusCode];
        [details setValue:errorDetails forKey:NSLocalizedDescriptionKey];
        httperror = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_SESSION_MANAGER userInfo:details];

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
            NSString *errorDetails = [NSString stringWithFormat:@"Session manager : HTTP Connection failed with error code %lu", (unsigned long)statusCode];
            [details setValue:errorDetails forKey:NSLocalizedDescriptionKey];
            httperror = [NSError errorWithDomain:IrisRtcSessionTag code:ERR_HTTP_CONNECTION_FAILED userInfo:details];
        }
    }
    
    [self.delegate onHTTPError:httperror.description errorCode:httperror.code additionalData:additionalData];
}

-(void)End
{
    if (datatask != nil)
        [datatask cancel];
    datatask = nil;
}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    LogError(@"didFailWithError" );
    [self.delegate onHTTPError:error.description errorCode:error.code additionalData:nil];
    
}

@end
