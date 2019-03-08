//
//  IrisRtcConnectionTest.m
//  IrisRtcSdk
//
//  Copyright © 2018 Comcast. All rights reserved.
//
#import <XCTest/XCTest.h>
#import "UNIRest.h"
#import "IrisRtcSdk.h"
#import "XMPPWorker.h"

__weak  static XCTestExpectation *irisConnectedExpectation;
__weak  static XCTestExpectation *irisInvalidUrlExpectation;
__weak  static XCTestExpectation *irisInvalidTokenExpectation;
__weak  static XCTestExpectation *irisHitlessUpgradeExpectation;
__weak  static XCTestExpectation *irisDisconnectedExpectation;
__weak  static XCTestExpectation *irisInvalidRoutingIdExpectation;


@interface IrisRtcConnectionTest : XCTestCase <IrisRtcConnectionDelegate>
{
    NSString *mId;
    NSString *evmUrl;
    NSString *idmUrl;
    NSString *appkey;
    NSString *userid;
    NSString *aumUrl;
    NSString *HitlessUpgradeServerUrl;
    NSString *userpwd;
    NSString *appToken;
    NSString *appsecret;
    NSString *IrisToken;
    NSString *routingId;
    NSTimer *disconnectTimeoutTimer;
}

@end

@implementation IrisRtcConnectionTest

- (void)setUp {
    [super setUp];
    
    [self readEnvironmentVariables];
    
    NSString *authMgrUrl = [NSMutableString stringWithFormat:@"%@/v1.1/login", aumUrl];
    NSString* AppToken = [@"Basic " stringByAppendingString:appToken];
    NSDictionary* headers = @{@"Content-Type": @"application/json",
                              @"Authorization":AppToken
                             };
    NSDictionary* parameters = @{@"type":@"email",
                                 @"email":userid,
                                 @"password":userpwd
                                };
    
    // Send request
    UNIHTTPJsonResponse *response = [[UNIRest postEntity:^(UNIBodyRequest *request) {
        [request setUrl:authMgrUrl];
        [request setHeaders:headers];
        [request setBody:[NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil]];
    }] asJson];
    
    // Check if the response code is 200
    XCTAssert((response.code == 200), @"Test Setup :: Iristoken request returned error %@ ", response.body.object.description);
    
    // Check if we have a key named "Token"
    XCTAssert(([response.body.object objectForKey:@"token"]), @"Test Setup ::Iristoken request did not return a token, instead it returned %@", response.body.object.description);
    
    // Get the token
    IrisToken = response.body.object[@"token"];
    mId = response.body.object[@"id"];
    
    //Get routing id
    [self getRoutingId];
}

-(void)getRoutingId{
    NSLog(@"Get routing id");
    
    NSString *url = [NSMutableString stringWithFormat:@"%@/v1/routingid/user/%@",idmUrl,mId];
    NSDictionary* headers = @{@"Content-Type": @"application/json",
                              @"Authorization":[NSMutableString stringWithFormat:@"Bearer %@",IrisToken]
                             };
    
    // Send request
    UNIHTTPJsonResponse *response = [[UNIRest get:^(UNISimpleRequest *request) {
        [request setUrl:url];
        [request setHeaders:headers];
    }] asJson];
    
    // Check if the response code is 200
    XCTAssert((response.code == 200), @"Test Setup :: Routing id request returned error %@ ", response.body.object.description);
    
    // Check if we have a key named "routing id"
    XCTAssert(([response.body.object objectForKey:@"routing_id"]), @"Test Setup ::Routing id request did not return a routing id, instead it returned %@", response.body.object.description);
    
    routingId = [response.body.object objectForKey:@"routing_id"];
}

-(void) waitForDisconnect{
    disconnectTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:5 repeats:false block:^(NSTimer * _Nonnull timer) {
        [irisDisconnectedExpectation fulfill];
    }];
}

-(void)disconnectFromServer{
    irisDisconnectedExpectation = [self expectationWithDescription:@"Iris Connection Disconnected"];
    [[IrisRtcConnection sharedInstance]disconnect];
    [self waitForDisconnect];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Connection Failed to Disconnect");
        }
        else{
            if (disconnectTimeoutTimer!=nil) {
                [disconnectTimeoutTimer invalidate];
                disconnectTimeoutTimer = nil;
            }
        }
    }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test4_ValidRtcConnection {
    
    NSLog(@"Test for RTC connection with valid credentials");
    NSError *Error = nil;
    
    irisConnectedExpectation = [self expectationWithDescription:@"Connected with IRIS backend"];
    [[IrisRtcConnection sharedInstance] connectUsingServer:evmUrl irisToken:IrisToken routingId:routingId delegate:self error:&Error];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Connection Timeout Error: %@", error);
            NSLog(@"RTC connection with valid credentials - Failed");
        }
        else{
            [self disconnectFromServer];
        }
    }];
}

- (void)test1_InvalidTokenRtcConnection {
    
    NSLog(@"Test for RTC connection with invalid token");
    NSError *Error = nil;
    NSString *invalidToken = @"abcd";
    
    irisInvalidTokenExpectation = [self expectationWithDescription:@"Error with IRIS backend"];
    [[IrisRtcConnection sharedInstance] connectUsingServer:evmUrl irisToken:invalidToken routingId:routingId delegate:self error:&Error];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Connection Timeout Error: %@", error);
            NSLog(@"RTC connection with invalid token - Failed");
        }
    }];
}

- (void)test2_InvalidUrlRtcConnection {
    
    NSLog(@"Test for RTC connection with invalid URL");
    NSError *Error = nil;
    
    irisInvalidUrlExpectation = [self expectationWithDescription:@"Error with IRIS backend"];
    [[IrisRtcConnection sharedInstance] connectUsingServer:aumUrl irisToken:IrisToken routingId:routingId delegate:self error:&Error];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Connection Timeout Error: %@", error);
            NSLog(@"RTC connection with invalid URL - Failed");
        }
    }];
}

- (void)test3_InvalidRoutingId{
    NSLog(@"Test for RTC connection with invalid URL");
    NSError *Error = nil;
    NSString *invalidRoutingId = @"ABCD";
    irisInvalidRoutingIdExpectation = [self expectationWithDescription:@"Error with IRIS backend"];
    [[IrisRtcConnection sharedInstance] connectUsingServer:evmUrl irisToken:IrisToken routingId:invalidRoutingId delegate:self error:&Error];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Connection Timeout Error: %@", error);
            NSLog(@"RTC connection with invalid URL - Failed");
        }
    }];
    
}

//-(void)test4_HitlessUpgrade{
//
//    NSLog(@"Check hitless upgrade when there is no active sessions");
//    NSError *Error = nil;
//
//    irisConnectedExpectation = [self expectationWithDescription:@"Connected with IRIS backend"];
//    [[IrisRtcConnection sharedInstance] connectUsingServer:evmUrl irisToken:IrisToken routingId:routingId delegate:self error:&Error];
//    [self waitForExpectationsWithTimeout:120 handler:^(NSError *error) {
//        if (error) {
//            NSLog(@"Connection Timeout Error: %@", error);
//            XCTFail(@"RTC connection before hitless upgrade - Failed");
//        }
//        else{
//            irisHitlessUpgradeExpectation = [self expectationWithDescription:@"Hitless upgrade"];
//
//            NSString *serverUrl = [NSMutableString stringWithFormat:@"https://%@/v1/disconnectnotification",HitlessUpgradeServerUrl];
//
//            // Send request
//            UNIHTTPJsonResponse *response = [[UNIRest postEntity:^(UNIBodyRequest *request) {
//                [request setUrl:serverUrl];
//            }] asJson];
//
//            [self waitForExpectationsWithTimeout:120 handler:^(NSError *error) {
//                if (error) {
//                    NSLog(@"Connection Timeout Error: %@", error);
//                    XCTFail(@"RTC connection after receiving disconnect iq - Failed");
//                }
//                else
//                    [[IrisRtcConnection sharedInstance] disconnect];
//            }];
//        }
//    }];
//}

- (void)readEnvironmentVariables {
    
    appkey = [[NSProcessInfo processInfo]environment][@"IRISAPPKEY"];
    idmUrl = [[NSProcessInfo processInfo] environment][@"IRISIDMURL"];
    aumUrl = [[NSProcessInfo processInfo] environment][@"IRISAUMURL"];
    evmUrl = [[NSProcessInfo processInfo] environment][@"IRISEVMURL"];
    userid = [[NSProcessInfo processInfo] environment][@"IRISUSERID"];
    userpwd = [[NSProcessInfo processInfo]environment][@"IRISUSERPWD"];
    appsecret = [[NSProcessInfo processInfo]environment][@"IRISAPPSECRET"];
    HitlessUpgradeServerUrl =  [[NSProcessInfo processInfo] environment][@"IRISINBOUNDSERVICE"];
    NSString *plainString = [NSString stringWithFormat: @"%@:%@", appkey, appsecret];
    NSData *plainData = [plainString dataUsingEncoding:NSUTF8StringEncoding];
    appToken = [plainData base64EncodedStringWithOptions:0];
}

#pragma mark - IrisRtcConnectionDelegate delegates

- (void)onConnected{
    NSLog(@"IrisRtcConnectionDelegate :: onConnected");
    if(irisHitlessUpgradeExpectation){
        [irisHitlessUpgradeExpectation fulfill];
        irisHitlessUpgradeExpectation = nil;
    }
    else if (irisConnectedExpectation){
        [irisConnectedExpectation fulfill];
        irisConnectedExpectation = nil;
    }
    
}

- (void)onDisconnected{
    NSLog(@"IrisRtcConnectionDelegate :: onDisconnected");
}

- (void)onError:(NSError *)error withAdditionalInfo:(nullable NSDictionary *)info{
    NSLog(@"onError:%@ Code:%ld",error.localizedDescription,(long)error.code);
    if (error.code == -105){
        [irisInvalidTokenExpectation fulfill];
        irisInvalidTokenExpectation = nil;
        [irisInvalidRoutingIdExpectation fulfill];
        irisInvalidRoutingIdExpectation = nil;
    }
    else if (error.code == -902){
        [irisInvalidUrlExpectation fulfill];
        irisInvalidUrlExpectation = nil;
    }
}

- (void)onNotification:(NSDictionary *)data{
}

- (void)onReconnecting {
}


@end
