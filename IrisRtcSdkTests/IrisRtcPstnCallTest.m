//
//  IrisRtcPstnCallTest.m
//  IrisRtcSdkTests
//
//  Created by Chinthalapalli, Vamsi (Contractor) on 11/7/18.
//  Copyright © 2018 Comcast. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UNIRest.h"
#import "IrisRtcSdk.h"

static NSDictionary *notificationData;
__weak  static XCTestExpectation *irisConnectedExpectation;
__weak  static XCTestExpectation *irisAudioSessionCreatedExpectation;
__weak  static XCTestExpectation *irisAudioSessionJoinExpectation;
__weak  static XCTestExpectation *irisNotificationReceivedExpectation;
__weak  static XCTestExpectation *irisDisconnectedExpectation;
__weak  static XCTestExpectation *irisInvalidSourceTNExpectation;
__weak  static XCTestExpectation *irisInvalidRoomIdExpectation;
__weak  static XCTestExpectation *irisInvalidRoomTokenExpectation;
__weak  static XCTestExpectation *irisInvalidRoomExpiryExpectation;
__weak  static XCTestExpectation *irisClosingSessionExpectation;

typedef NS_ENUM(NSUInteger ,IrisRtcPstnTestState){
    
    //for Pstn Outgoing with Valid Credentials.
    kTestPstnOutgoing,
    
    //for Pstn Incoming with Valid Credentials.
    kTestPstnIncoming,
    
    //for Pstn Outgoing with Invalid Source telephone Number.
    kTestInvalidSourceTN,
    
    //for Pstn Incoming with Invalid Target Telephone Number.
    kTestInvalidTargetTN,
    
    //for Pstn Incoming with Invalid Room Id.
    kTestInvalidRoomId,
    
    //for Pstn Incoming with Invalid Room Token.
    kTestInvalidRoomToken,
    
    //for Pstn Incoming with Invalid Room Expiry Time.
    kTestInvalidRoomExpiryTime,
    
    //for pstn closing session after call is connected.
    kTestCloseSession,
    
    //for Pstn outgoing closing session when sip status changed to kConnecting.
    kTestCloseSessionAfterSIPConnecting
    
}kTestState;

@interface IrisRtcPstnCallTest : XCTestCase <IrisRtcConnectionDelegate,IrisRtcAudioSessionDelegate>
{
    IrisRtcConnection *joinConnection;
    IrisRtcAudioSession *createAudioSession;
    IrisRtcAudioSession *joinAudioSession;
    IrisRtcSessionConfig *sessionconfig;
    
    NSString *IrisToken;
    NSString *UserId;
    NSString *roomId;
    NSString *appToken;
    NSString *routing_id;
    NSArray *public_ids;
    NSString *caller;
    
    NSString *APP_SERVER_URL;
    NSString *aumUrl;
    NSString *idmUrl;
    NSString *evmUrl;
    NSString *ntmUrl;
    NSString *appkey;
    NSString *appsecret;
    NSString *userid;
    NSString *userpwd;
    NSString *toTN;
    NSString *inboundUrl;
    NSString *inboundSecret;
    NSString *fromTN;
    NSString *env;
    
    NSTimer *disconnectTimeoutTimer;
}
@end

@implementation IrisRtcPstnCallTest

- (void)setUp {
    
    [super setUp];
    
    [self readEnvironmentVariables];
    
    
    sessionconfig = [[IrisRtcSessionConfig alloc]init];
    sessionconfig.maxStreamCount = 1;
    
    /* Get Iris Token - Begin */
    NSString* AuthMgrUrl = [NSString stringWithFormat:@"%@/v1.1/login", aumUrl];
    NSString* AppToken = [@"Basic " stringByAppendingString:appToken];
    NSDictionary* headers = @{@"Content-Type": @"application/json",
                              @"User-Agent":@"apple/phone/iPhone/11.0/IrisRestClient/1.0",
                              @"Authorization":AppToken
                              };
    NSDictionary* parameters = @{@"type": @"Email",
                                 @"email": userid,
                                 @"password": userpwd
                                 };
    
    // Send request
    UNIHTTPJsonResponse *response = [[UNIRest postEntity:^(UNIBodyRequest *request) {
        [request setUrl:AuthMgrUrl];
        [request setHeaders:headers];
        [request setBody:[NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil]];
    }] asJson];
    
    NSLog(@"Test Setup :: Http response %@", response.body.object.description);
    // Check if the response code is 200
    XCTAssert((response.code == 200), @"Test Setup :: Iristoken request returned error %@ ", response.body.object.description);
    
    // Check if we have a key named "Token"
    XCTAssert(([response.body.object objectForKey:@"token"]), @"Test Setup ::Iristoken request did not return a token, instead it returned %@", response.body.object.description);
    
    // Get the token
    IrisToken = response.body.object[@"token"];
    NSLog(@"Test Setup :: Received token %@", IrisToken);
    
    /* Get Iris Token - End */
    
    /* Get Routing Id - Begin */
    
    NSString* IdMgrUrl = [NSString stringWithFormat:@"%@/v1/allidentities", idmUrl];
    NSString* authToken = [@"Bearer " stringByAppendingString:IrisToken];
    NSDictionary* idmHeaders = @{@"Content-Type": @"application/json",
                                 @"User-Agent":@"apple/phone/iPhone/11.0/IrisRestClient/1.0",
                                 @"Authorization":authToken};
    // Send request
    UNIHTTPJsonResponse *idmResponse = [[UNIRest get:^(UNISimpleRequest *request) {
        [request setUrl:IdMgrUrl];
        [request setHeaders:idmHeaders];
    }] asJson];
    
    NSLog(@"Test Setup :: Http response %@", idmResponse.body.object.description);
    // Check if the response code is 200
    XCTAssert((idmResponse.code == 200), @"Test Setup :: Iristoken request returned error %@ ", response.body.object.description);
    
    routing_id = idmResponse.body.object[@"routing_id"];
    public_ids = idmResponse.body.object[@"public_ids"];
    
    for (int i=0 ; i < [public_ids count]; i++) {
        if([self isPhoneNumber:public_ids[i]]) {
            caller = public_ids[i];
            break;
        }
    }
    NSLog(@"Test Setup :: Received token %@", routing_id);
    
    /* Get Routing Id - End */
    
}

- (void)tearDown {
    [super tearDown];
}

- (void)test1_PstnOutgoing {
    NSLog(@"Test For Pstn Succesfull Outgoing call Flow");
    NSLog(@"Check RTC connection before making a pstn call");
    
    NSError *Error = nil;
    
    irisConnectedExpectation = [self expectationWithDescription:@"Connected with IRIS backend"];
    [[IrisRtcConnection sharedInstance] connectUsingServer:evmUrl irisToken:IrisToken routingId:routing_id delegate:self error:&Error];
    
    [self waitForExpectationsWithTimeout:35 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Connection Timeout Error: %@", error);
            NSLog(@"Check RTC connection before making audio call - Failed");
        }
        else
        {
            kTestState = kTestPstnOutgoing;
            [self createAudioSession];
            
            // Connection and session Cleanup Excuted Only when the Testcases Completed
            if (createAudioSession != nil) {
                [createAudioSession close];
                createAudioSession = nil;
            }
            [self disconnectFromServer];
        }
      }];
}

- (void)test2_PstnIncoming {
    NSLog(@"Test For Pstn Succesfull Incoming call Flow");
    NSLog(@"Check RTC connection before joining pstn call");
    
    NSError *Error = nil;
    
    irisConnectedExpectation = [self expectationWithDescription:@"Connected with IRIS backend"];
    [[IrisRtcConnection sharedInstance] connectUsingServer:evmUrl irisToken:IrisToken routingId:routing_id delegate:self error:&Error];
    
    [self waitForExpectationsWithTimeout:1000 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Connection Timeout Error: %@", error);
            NSLog(@"Check RTC connection before making audio call - Failed");
        }
        else{
            irisNotificationReceivedExpectation  = [self expectationWithDescription:@"Incoming call notification received"];
            [self invokeIncomingNotification];
            
            [self waitForExpectationsWithTimeout:100 handler:^(NSError *error) {
                if (error) {
                    NSLog(@"Incoming call notification Timeout Error: %@", error);
                    NSLog(@"Incoming call notification for join session - Failed");
                }
                else{
                    kTestState = kTestPstnIncoming;
                    [self joinAudioSession:notificationData];
                    notificationData = nil;
                    
                    // Connection and session Cleanup Excuted Only when the Testcases Completed
                    if (joinAudioSession != nil) {
                        [joinAudioSession close];
                        joinAudioSession = nil;
                    }
                }
            }];
            [self disconnectFromServer];
        }
    }];
}
- (void)test3_Close {
    NSLog(@"Test For Succesfull Closing of session");
    NSLog(@"Check RTC connection before making a pstn call");
    
    NSError *Error = nil;
    
    irisConnectedExpectation = [self expectationWithDescription:@"Connected with IRIS backend"];
    [[IrisRtcConnection sharedInstance] connectUsingServer:evmUrl irisToken:IrisToken routingId:routing_id delegate:self error:&Error];
    
    [self waitForExpectationsWithTimeout:35 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Connection Timeout Error: %@", error);
            NSLog(@"Check RTC connection before making audio call - Failed");
        }
        else
        {
            kTestState = kTestCloseSession;
            [self createAudioSession];
            
            // Connection and session Cleanup Excuted Only when the Testcases Completed
            [self disconnectFromServer];
        }
    }];
}

-(void)test4_CloseSessionAfterInitilazation{
    NSLog(@"Test For Succesfull Closing of session");
    NSLog(@"Check RTC connection before making a pstn call");
    
    NSError *Error = nil;
    
    irisConnectedExpectation = [self expectationWithDescription:@"Connected with IRIS backend"];
    [[IrisRtcConnection sharedInstance] connectUsingServer:evmUrl irisToken:IrisToken routingId:routing_id delegate:self error:&Error];
    
    [self waitForExpectationsWithTimeout:35 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Connection Timeout Error: %@", error);
            NSLog(@"Check RTC connection before making audio call - Failed");
        }
        else
        {
            kTestState = kTestCloseSessionAfterSIPConnecting;
            [self createAudioSession];
            
            // Connection and session Cleanup Excuted Only when the Testcases Completed
            [self disconnectFromServer];
        }
    }];
}

//TestCases with Invalid Credentials
- (void)test5_InvalidSourceTN{
    NSLog(@"Test For Pstn Outgoing with Invalid Source TN");
    NSLog(@"Check RTC connection before making a pstn call");
    
    NSError *Error = nil;
    
    irisConnectedExpectation = [self expectationWithDescription:@"Connected with IRIS backend"];
    [[IrisRtcConnection sharedInstance] connectUsingServer:evmUrl irisToken:IrisToken routingId:routing_id delegate:self error:&Error];
    
    [self waitForExpectationsWithTimeout:35 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Connection Timeout Error: %@", error);
            NSLog(@"Check RTC connection before making audio call - Failed");
        }
        else
        {
            kTestState = kTestInvalidSourceTN;
            [self createAudioSession];
            
            // Connection and session Cleanup Excuted Only when the Testcases Completed
            if (createAudioSession != nil) {
                [createAudioSession close];
                createAudioSession = nil;
            }
            [self disconnectFromServer];
        }
    }];
}

- (void)test6_InvalidRoomId{
    NSLog(@"Test For Pstn incoming with Invalid Room Id");
    NSLog(@"Check RTC connection before joining pstn call");
    
    NSError *Error = nil;
    
    irisConnectedExpectation = [self expectationWithDescription:@"Connected with IRIS backend"];
    [[IrisRtcConnection sharedInstance] connectUsingServer:evmUrl irisToken:IrisToken routingId:routing_id delegate:self error:&Error];
    
    [self waitForExpectationsWithTimeout:100 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Connection Timeout Error: %@", error);
            NSLog(@"Check RTC connection before making audio call - Failed");
        }
        else{
            irisNotificationReceivedExpectation  = [self expectationWithDescription:@"Incoming call notification received"];
            [self invokeIncomingNotification];
            
            [self waitForExpectationsWithTimeout:100 handler:^(NSError *error) {
                if (error) {
                    NSLog(@"Incoming call notification Timeout Error: %@", error);
                    NSLog(@"Incoming call notification for join session - Failed");
                }
                else{
                    kTestState = kTestInvalidRoomId;
                    [self joinAudioSession:notificationData];
                    
                    // Connection and session Cleanup Excuted Only when the Testcases Completed
                    if (joinAudioSession != nil) {
                        [joinAudioSession close];
                        joinAudioSession = nil;
                    }
                }
            }];
            [self disconnectFromServer];
        }
    }];
}

- (void)test7_InvalidRoomToken{
    NSLog(@"Test For Pstn incoming with Invalid Room Token");
    NSLog(@"Check RTC connection before joining pstn call");
    
    NSError *Error = nil;
    
    irisConnectedExpectation = [self expectationWithDescription:@"Connected with IRIS backend"];
    [[IrisRtcConnection sharedInstance] connectUsingServer:evmUrl irisToken:IrisToken routingId:routing_id delegate:self error:&Error];
    
    [self waitForExpectationsWithTimeout:100 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Connection Timeout Error: %@", error);
            NSLog(@"Check RTC connection before making audio call - Failed");
        }
        else{
            kTestState = kTestInvalidRoomToken;
            [self joinAudioSession:notificationData];
            
            // Connection and session Cleanup Excuted Only when the Testcases Completed
            if (joinAudioSession != nil) {
                [joinAudioSession close];
                joinAudioSession = nil;
            }
            [self disconnectFromServer];
        }
    }];
}

-(void)test8_InvalidRoomExpiry{
    NSLog(@"Test For Pstn incoming with Invalid RoomExpiryToken");
    NSLog(@"Check RTC connection before joining pstn call");
    
    NSError *Error = nil;
    
    irisConnectedExpectation = [self expectationWithDescription:@"Connected with IRIS backend"];
    [[IrisRtcConnection sharedInstance] connectUsingServer:evmUrl irisToken:IrisToken routingId:routing_id delegate:self error:&Error];
    
    [self waitForExpectationsWithTimeout:100 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Connection Timeout Error: %@", error);
            NSLog(@"Check RTC connection before making audio call - Failed");
        }
        else{
            if (error) {
                NSLog(@"Incoming call notification Timeout Error: %@", error);
                NSLog(@"Incoming call notification for join session - Failed");
            }
            else{
                kTestState = kTestInvalidRoomExpiryTime;
                [self joinAudioSession:notificationData];
                notificationData = nil;
                
                // Connection and session Cleanup Excuted Only when the Testcases Completed
                if (joinAudioSession != nil) {
                    [joinAudioSession close];
                    joinAudioSession = nil;
                }
                [self disconnectFromServer];
            }
        }
    }];
    
}

-(void)invokeIncomingNotification
{
    // TO-DO for other country codes
    NSString* tn = [NSString stringWithFormat:@"+1%@", fromTN];
    
    NSString* url = [NSString stringWithFormat:@"%@/makeInboundCall", inboundUrl];
    NSString* AppToken = [@"Basic " stringByAppendingString:inboundSecret];
    NSDictionary* headers = @{@"Content-Type": @"application/json",
                              @"User-Agent":@"apple/phone/iPhone/11.0/IrisRestClient/1.0",
                              @"Authorization":AppToken
                              };
    
    NSDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setValue:env forKey:@"env"];
    [parameters setValue:[NSArray arrayWithObjects:tn, nil] forKey:@"destNumbers"];
    
    // Send request
    UNIHTTPJsonResponse *response = [[UNIRest postEntity:^(UNIBodyRequest *request) {
        [request setUrl:url];
        [request setHeaders:headers];
        [request setBody:[NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil]];
    }] asJson];
    
    XCTAssert((response.code == 200), @"Test Setup :: Iristoken request returned error %@ ", response.body.object.description);
}

-(void)createAudioSession
{
    NSLog(@"This test is to check Audio call");
    
    if(createAudioSession == nil){
        createAudioSession = [[IrisRtcAudioSession alloc]init];
        createAudioSession.isVideoBridgeEnable=true;
        
        NSDictionary *data=[[NSDictionary alloc]initWithObjectsAndKeys:caller,@"cid",caller,@"cname",toTN,@"tar", nil];
        NSDictionary *notif=[[NSDictionary alloc]initWithObjectsAndKeys:@"federation\\/pstn",@"topic",@"pstn",@"type", nil];
        NSDictionary *final=[[NSDictionary alloc]initWithObjectsAndKeys: data,@"data",notif,@"notification", nil];
        
        NSData *tempData = [NSJSONSerialization dataWithJSONObject:final options:kNilOptions error:nil];
        NSString *tempString = [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
        
        NSError *error = nil;
        
        if (kTestState == kTestPstnOutgoing || kTestState == kTestCloseSession) {
            irisAudioSessionCreatedExpectation = [self expectationWithDescription:@"Audio session created"];
            [createAudioSession createWithTN:toTN _sourceTelephoneNum:caller notificationData:tempString stream:nil sessionConfig:sessionconfig delegate:self error:&error];
        }
        else if (kTestState == kTestInvalidSourceTN) {
            irisInvalidSourceTNExpectation = [self expectationWithDescription:@"Invalid Source TN"];
            [createAudioSession createWithTN:toTN _sourceTelephoneNum:@"765432AA21" notificationData:tempString stream:nil sessionConfig:sessionconfig delegate:self error:&error];
        }
        else if (kTestState == kTestCloseSessionAfterSIPConnecting){
            irisClosingSessionExpectation = [self expectationWithDescription:@"Session is Closed"];
            [createAudioSession createWithTN:toTN _sourceTelephoneNum:caller notificationData:tempString stream:nil sessionConfig:sessionconfig delegate:self error:&error];
        }
        
        if (error)
        {
            NSLog(@"Check audio call Error: %@", error);
            NSLog(@"Check audio call - Failed");
        }
        
        [self waitForExpectationsWithTimeout:100 handler:^(NSError *error) {
            if (error) {
                NSLog(@"Check audio call timeout Error: %@", error);
                NSLog(@"Check audio call - Failed");
            }
            else{
                if (kTestState == kTestCloseSession) {
                    irisClosingSessionExpectation = [self expectationWithDescription:@"Session is Closed"];
                    [createAudioSession close];
                    [self waitForExpectationsWithTimeout:100 handler:^(NSError * _Nullable error) {
                        if (error) {
                            NSLog(@"Iris Session Failed To Close");
                        } else {
                            NSLog(@"Iris Session Succesfully Closed");
                            createAudioSession = nil;
                        }
                    }];
                }
            }
        }];
    }
    
}

- (void)joinAudioSession:(NSDictionary *)data {
    
    NSLog(@"This test is to check join Audio call");

    roomId = data[@"roomid"];
    NSString *roomToken = data[@"roomtoken"];
    NSString *roomtokenexpirytime = data[@"roomtokenexpirytime"];
    NSString *rtcserver = data[@"rtcserver"];
    
    
    if(joinAudioSession == nil){
        joinAudioSession = [[IrisRtcAudioSession alloc]init];
        joinAudioSession.isVideoBridgeEnable=true;
        
        NSError *error = nil;
        
        if (kTestState == kTestPstnIncoming) {
            irisAudioSessionJoinExpectation = [self expectationWithDescription:@"Audio session join"];
            [joinAudioSession joinWithSessionId:roomId roomToken:roomToken roomTokenExpiryTime:[roomtokenexpirytime intValue] stream:nil rtcServer:rtcserver sessionConfig:sessionconfig delegate:self error:&error];
        }
        else if (kTestState == kTestInvalidRoomId){
            irisInvalidRoomIdExpectation = [self expectationWithDescription:@"Invalid Room ID"];
            [joinAudioSession joinWithSessionId:@"547gfd" roomToken:roomToken roomTokenExpiryTime:[roomtokenexpirytime intValue] stream:nil rtcServer:rtcserver sessionConfig:sessionconfig delegate:self error:&error];
        }
        else if (kTestState == kTestInvalidRoomToken){
            irisInvalidRoomTokenExpectation = [self expectationWithDescription:@"Invalid Room Token"];
            [joinAudioSession joinWithSessionId:roomId roomToken:@"abcd" roomTokenExpiryTime:[roomtokenexpirytime intValue] stream:nil rtcServer:rtcserver sessionConfig:sessionconfig delegate:self error:&error];
        }
        else if (kTestState == kTestInvalidRoomExpiryTime){
            irisInvalidRoomExpiryExpectation = [self expectationWithDescription:@"Invalid RoomExpiryTime"];
            [joinAudioSession joinWithSessionId:roomId roomToken:roomToken roomTokenExpiryTime:[@"54781" intValue] stream:nil rtcServer:rtcserver sessionConfig:sessionconfig delegate:self error:&error];
            
        }
        
        if (error)
        {
            NSLog(@"Check audio call Error: %@", error);
            NSLog(@"Check audio call - Failed");
        }
        
        [self waitForExpectationsWithTimeout:1000 handler:^(NSError *error) {
            if (error) {
                NSLog(@"Check audio call timeout Error: %@", error);
                NSLog(@"Check audio call - Failed");
            }
        }];
    }
}

- (bool) isPhoneNumber: (NSString *)newString {
    NSCharacterSet *characters = [NSCharacterSet characterSetWithCharactersInString:@"+0123456789"];
    NSCharacterSet* notDigits = [characters invertedSet];
    if ([newString rangeOfCharacterFromSet:notDigits].location == NSNotFound)
    {
        // newString consists only of the digits 0 through 9
        return true;
    }
    return false;
}

- (void)readEnvironmentVariables {
    
    aumUrl = [[NSProcessInfo processInfo] environment][@"IRISAUMURL"];
    idmUrl = [[NSProcessInfo processInfo] environment][@"IRISIDMURL"];
    evmUrl = [[NSProcessInfo processInfo] environment][@"IRISEVMURL"];
    ntmUrl = [[NSProcessInfo processInfo] environment][@"IRISNTMURL"];
    appkey = [[NSProcessInfo processInfo] environment][@"IRISAPPKEY"];
    appsecret = [[NSProcessInfo processInfo] environment][@"IRISAPPSECRET"];
    userid = [[NSProcessInfo processInfo] environment][@"IRISUSERID"];
    userpwd = [[NSProcessInfo processInfo] environment][@"IRISUSERPWD"];
    toTN = [[NSProcessInfo processInfo] environment][@"IRISTOTN"];
    inboundUrl = [[NSProcessInfo processInfo] environment][@"IRISINBOUNDSERVICE"];
    inboundSecret = [[NSProcessInfo processInfo] environment][@"IRISINBOUNDSECRET"];
    fromTN = [[NSProcessInfo processInfo] environment][@"IRISFROMTN"];
    env = [[NSProcessInfo processInfo] environment][@"IRISENV"];
    
    NSString *plainString = [NSString stringWithFormat: @"%@:%@", appkey, appsecret];
    NSData *plainData = [plainString dataUsingEncoding:NSUTF8StringEncoding];
    appToken = [plainData base64EncodedStringWithOptions:0];
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

#pragma mark - IrisRtcConnectionDelegate delegates

- (void)onConnected {
    NSLog(@"IrisRtcConnectionDelegate :: onConnected");
    [irisConnectedExpectation fulfill];
}

- (void)onDisconnected {
    NSLog(@"IrisRtcConnectionDelegate :: onDisconnected");
}

- (void)onError:(nonnull NSError *)error withAdditionalInfo:(nullable NSDictionary *)info {
    NSLog(@"IrisRtcConnectionDelegate :: onError");
}

- (void)onNotification:(nonnull NSDictionary *)data {
    NSLog(@"IrisRtcConnectionDelegate :: onNotification");
    if ([[data objectForKey:@"type"]  isEqual: @"notify"]){
        if (notificationData == nil) {
            [irisNotificationReceivedExpectation fulfill];
            notificationData = data;
            irisNotificationReceivedExpectation = nil;
        }
    }
    
}

- (void)onReconnecting {
    NSLog(@"IrisRtcConnectionDelegate :: onReconnecting");
}

#pragma mark - IrisRtcAudioSessionDelegate delegates

- (void)onSessionConnected:(NSString *)roomId traceId:(NSString *)traceId {
    NSLog(@"IrisRtcAudioSessionDelegate :: onSessionConnected: %@",roomId);
}

- (void)onSessionCreated:(NSString *)roomId traceId:(NSString *)traceId {
    NSLog(@"IrisRtcAudioSessionDelegate :: onSessionCreated: %@",roomId);
}

- (void)onSessionDominantSpeakerChanged:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId {
    NSLog(@"IrisRtcAudioSessionDelegate :: onSessionDominantSpeakerChanged");
}

- (void)onSessionEnded:(NSString *)roomId traceId:(NSString *)traceId {
    NSLog(@"IrisRtcAudioSessionDelegate :: onSessionEnded");
    if (kTestState == kTestCloseSession) {
        [irisClosingSessionExpectation fulfill];
        irisClosingSessionExpectation = nil;
    }
    else if (kTestState == kTestCloseSessionAfterSIPConnecting){
        [irisClosingSessionExpectation fulfill];
        irisClosingSessionExpectation = nil;
    }
}

- (void)onSessionJoined:(NSString *)roomId traceId:(NSString *)traceId {
    NSLog(@"IrisRtcAudioSessionDelegate :: onSessionJoined");
}

- (void)onSessionParticipantJoined:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId {
    NSLog(@"IrisRtcAudioSessionDelegate :: onSessionParticipantJoined");
}

- (void)onSessionParticipantLeft:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId {
    NSLog(@"IrisRtcAudioSessionDelegate :: onSessionParticipantLeft");
}

- (void)onSessionParticipantProfile:(NSString *)participantId userProfile:(IrisRtcUserProfile *)userprofile roomId:(NSString *)roomid traceId:(NSString *)traceId {
    NSLog(@"IrisRtcAudioSessionDelegate :: onSessionParticipantProfile");
}

- (void)onSessionEarlyMedia:(NSString *)roomId traceId:(NSString *)traceId {
    NSLog(@"IrisRtcAudioSessionDelegate :: onSessionEarlyMedia");
}

- (void)onSessionMerged:(NSString *)roomId traceId:(NSString *)traceId {
    NSLog(@"IrisRtcAudioSessionDelegate :: onSessionMerged");
}

- (void)onSessionSIPStatus:(IrisSIPStatus)status roomId:(NSString *)roomId traceId:(NSString *)traceId {
    NSLog(@"IrisRtcAudioSessionDelegate :: onSessionSIPStatus :%ld",(long)status);
    
    if(status == kConnected){
        
        if (irisAudioSessionCreatedExpectation){
            [irisAudioSessionCreatedExpectation fulfill];
            irisAudioSessionCreatedExpectation = nil;
        }
        if (irisAudioSessionJoinExpectation){
            [irisAudioSessionJoinExpectation fulfill];
            irisAudioSessionJoinExpectation = nil;
        }
    }
    else if (status == kConnecting){
        if (kTestState == kTestCloseSessionAfterSIPConnecting) {
            [createAudioSession close];
        }
    }
}

- (void)onSessionError:(NSError *)error withAdditionalInfo:(NSDictionary *)info roomId:(NSString *)roomId traceId:(NSString *)traceId{
    NSLog(@"IrisRtcAudioSessionDelegate :: onSessionError :%@,%ld",error.localizedDescription,(long)error.code);
    if (kTestState == kTestInvalidSourceTN) {
        [irisInvalidSourceTNExpectation fulfill];
        irisInvalidSourceTNExpectation = nil;
    }
    else if (error.code == -802) {
        if (kTestState == kTestInvalidRoomId) {
            [irisInvalidRoomIdExpectation fulfill];
            irisInvalidRoomIdExpectation = nil;
        }
        else if (kTestState == kTestInvalidRoomToken){
            [irisInvalidRoomTokenExpectation fulfill];
            irisInvalidRoomTokenExpectation = nil;
        }
        else if (kTestState == kTestInvalidRoomExpiryTime){
            [irisInvalidRoomExpiryExpectation fulfill];
            irisInvalidRoomExpiryExpectation = nil;
        }
    }
}
@end
