//
//  IrisRtcVideoCallTest.m
//  IrisRtcSdkTests
//
//  Copyright © 2018 Comcast. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UNIRest.h"
#import "IrisRtcSdk.h"

__weak  static XCTestExpectation *irisConnectedExpectation;
__weak  static XCTestExpectation *irisVideoSessionJoinedExpectation;
__weak  static XCTestExpectation *irisVideoSessionCreatedExpectation;
__weak  static XCTestExpectation *irisVideoSessionConnectedExpectation;
__weak  static XCTestExpectation *irisNotificationReceivedExpectation;
__weak  static XCTestExpectation *irisVideoSessionParticipantJoinedExpectation;
__weak  static XCTestExpectation *irisDisconnectedExpectation;
__weak  static XCTestExpectation *irisVideoSessionInvalidRoomIDExpectation;
__weak  static XCTestExpectation *irisVideoSessionInvalidRoomTokenExpectation;
__weak  static XCTestExpectation *irisVideoSessionInvalidRoomExpiryTime;

typedef  NS_ENUM(NSUInteger, IrisRtcVideoCallTestState){
    
    //for VideoCall outgoing test with valid credentials.
    kTestVideoOutgoing,
    
    //for VideoCall Incoming test With Valid Credentials.
    kTestVideoIncoming,
    
    //for  VideoCall outgoing test With Invalid Room Id.
    kTestInvalidRoomIdOutgoing,
    
    //for videoCall incoming test with Invalid Room Id.
    kTestInvalidRoomIdIncoming,
    
    //for VideoCall incoming test with Invalid Room Token.
    kTestInvalidRoomToken,
    
    //for VideoCall Incoming test with Invalid Room Expiry Time.
    kTestInvalidRoomExpiryTime
}kVideoTestState;


@interface IrisRtcVideoCallTest : XCTestCase <IrisRtcConnectionDelegate,IrisRtcVideoSessionDelegate,IrisRtcSessionDelegate>
{
    NSString *evmUrl;
    NSString *idmUrl;
    NSString *appkey;
    NSString *userid;
    NSString *aumUrl;
    NSString *roomId;
    NSString *userpwd;
    NSString *appToken;
    NSString *appsecret;
    NSString *IrisToken;
    NSString *appDomain;
    NSString *rtcServer;
    NSString *roomToken;
    NSString *calleeId;
    NSString *routingIdCaller;
    NSString *routingIdCallee;
    NSString *roomTokenExpiryTime;
    NSString *inboundUrl;
    NSString *inboundSecret;
    NSString *env;
    BOOL isOutgoing;
    
    NSTimer *disconnectTimeoutTimer;

    IrisRtcSessionConfig *sessionconfig;
    IrisRtcVideoSession *joinVideoSession;
    IrisRtcVideoSession *createVideoSession;
}

@end

@implementation IrisRtcVideoCallTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    
    [self readEnvironmentVariables];
    
    NSString *authMgrUrl = [NSMutableString stringWithFormat:@"%@/v1.1/login", aumUrl];
    NSString* AppToken = [@"Basic " stringByAppendingString:appToken];
    NSDictionary* headers = @{@"Content-Type": @"application/json",
                              @"User-Agent":@"apple/phone/iPhone/11.0/IrisRestClient/1.0",
                              @"Authorization":AppToken};
    NSDictionary* parameters = @{@"type":@"email",
                                 @"email":userid,
                                 @"password":userpwd};
    
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
    
    //Get routing id
    routingIdCaller = [self getRoutingId:userid];
}

-(NSString*)getRoutingId:userId{
    NSLog(@"Get routing id");
    
    NSString *url = [NSMutableString stringWithFormat:@"%@/v1/routingid/appdomain/%@/publicid/%@",idmUrl,appDomain,userId];
    NSDictionary* headers = @{@"Content-Type": @"application/json",
                              @"User-Agent":@"apple/phone/iPhone/11.0/IrisRestClient/1.0",
                              @"Authorization":[NSMutableString stringWithFormat:@"Bearer %@",IrisToken]};
    
    // Send request
    UNIHTTPJsonResponse *response = [[UNIRest get:^(UNISimpleRequest *request) {
        [request setUrl:url];
        [request setHeaders:headers];
    }] asJson];
    
    // Check if the response code is 200
    XCTAssert((response.code == 200), @"Test Setup :: Routing id request returned error %@ ", response.body.object.description);
    
    // Check if we have a key named "routing id"
    XCTAssert(([response.body.object objectForKey:@"routing_id"]), @"Test Setup ::Routing id request did not return a routing id, instead it returned %@", response.body.object.description);
    
    return [response.body.object objectForKey:@"routing_id"];
}

-(void) getRoomId{
    NSLog(@"Get Room Id");
    
    NSMutableDictionary *callerDict = [self genrateParticipantDictionary:routingIdCaller];
    NSMutableDictionary *calleeDict = [self genrateParticipantDictionary:routingIdCallee];
    NSArray *participantArray = [[NSArray alloc]initWithObjects:callerDict,calleeDict, nil];
    NSMutableDictionary *participantDict = [[NSMutableDictionary alloc]init];
    [participantDict setObject:participantArray forKey:@"participants"];
    
    NSString *url = [NSString stringWithFormat:@"%@/v1/createroom/participants", evmUrl];
    NSString *authtoken = [NSMutableString stringWithFormat:@"%@ %@",@"Bearer",IrisToken];
    NSDictionary *headers = @{@"Content-Type": @"application/json",
                              @"Authorization":authtoken,
                              @"User-Agent":@"apple/phone/iPhone/11.2.6/IrisRestClient/1.0"};
    
    UNIHTTPJsonResponse *roomResponse = [[UNIRest putEntity:^(UNIBodyRequest *request) {
        [request setUrl:url];
        [request setHeaders:headers];
        [request setBody:[NSJSONSerialization dataWithJSONObject:participantDict options:0 error:nil]];
    }] asJson];

    XCTAssert((roomResponse.code == 200) || (roomResponse.code == 201), @"Test Setup :: Roomid request returned error %ld ", (long)roomResponse.code);

    // Check if we have a key named "Token"
    XCTAssert(([roomResponse.body.object objectForKey:@"room_id"]), @"Test Setup :: Roomid request did not return a room id, instead it returned %@", roomResponse.body.object.description);

    // Get the roomId
    roomId = roomResponse.body.object[@"room_id"];
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
    [super tearDown];
}

- (void)test1_VideoOutgoing {
    NSLog(@"Check RTC connection before making a video call");
    
    //get routing id of callee
    routingIdCallee = [self getRoutingId:calleeId];
    
    //Generate room id
    [self getRoomId];
    isOutgoing = true;
    
    NSError *error = nil;
    irisConnectedExpectation = [self expectationWithDescription:@"Connected with IRIS backend"];
    [[IrisRtcConnection sharedInstance] connectUsingServer:evmUrl irisToken:IrisToken routingId:routingIdCaller delegate:self error:&error];
    
    [self waitForExpectationsWithTimeout:25 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Connection Timeout Error: %@", error);
            NSLog(@"Check RTC connection before making video call - Failed");
        }
        else{
//            [self requestAutoAnswer];
            kVideoTestState = kTestVideoOutgoing;
            [self createVideoSession];
            
            // Connection and session Cleanup Excuted Only when the Testcases Completed
            if (createVideoSession!=nil){
                [createVideoSession close];
                createVideoSession=nil;
            }
            [self disconnectFromServer];
        }
    }];
}

- (void)test3_VideoOutgoingInvalidRoomID{
    NSLog(@"Check RTC connection before making a video call");
    
    //get routing id of callee
    routingIdCallee = [self getRoutingId:calleeId];
    
    //Generate room id
    [self getRoomId];
    isOutgoing = true;
    
    NSError *error = nil;
    irisConnectedExpectation = [self expectationWithDescription:@"Connected with IRIS backend"];
    [[IrisRtcConnection sharedInstance] connectUsingServer:evmUrl irisToken:IrisToken routingId:routingIdCaller delegate:self error:&error];
    
    [self waitForExpectationsWithTimeout:25 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Connection Timeout Error: %@", error);
            NSLog(@"Check RTC connection before making video call - Failed");
        }
        else{
            kVideoTestState = kTestInvalidRoomIdOutgoing;
            [self createVideoSession];
            
            // Connection and session Cleanup Excuted Only when the Testcases Completed
            if (createVideoSession!=nil){
                [createVideoSession close];
                createVideoSession=nil;
            }
            [self disconnectFromServer];
        }
    }];
}

-(void)test2_VideoIncoming {
    NSLog(@"Check RTC connection before joining a video call");
    isOutgoing = false;
    
    NSError *Error = nil;
    
    irisConnectedExpectation = [self expectationWithDescription:@"Connected with IRIS backend"];
    [[IrisRtcConnection sharedInstance] connectUsingServer:evmUrl irisToken:IrisToken routingId:routingIdCaller delegate:self error:&Error];
    
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Connection Timeout Error: %@", error);
            NSLog(@"Check RTC connection before making video call - Failed");
        }
        else{
            irisNotificationReceivedExpectation = [self expectationWithDescription:@"Notification Received"];
            [self invokeIncomingNotification];
            
            [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"Connection Timeout Error: %@", error);
                    NSLog(@"invoke notifiation failed");
                }
                else{
                    kVideoTestState = kTestVideoIncoming;
                    [self joinVideoSession];
                    
                    // Connection and session Cleanup Excuted Only when the Testcase Completed
                    if (joinVideoSession!=nil){
                        [joinVideoSession close];
                        joinVideoSession=nil;
                    }
                    [self disconnectFromServer];
                }
            }];
        }
    }];
}

- (void)test4_VideoIncomingInvalidRoomId{
    NSLog(@"Check RTC connection before joining a video call");
    
    NSError *Error = nil;
    
    irisConnectedExpectation = [self expectationWithDescription:@"Connected with IRIS backend"];
    [[IrisRtcConnection sharedInstance] connectUsingServer:evmUrl irisToken:IrisToken routingId:routingIdCaller delegate:self error:&Error];
    
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Connection Timeout Error: %@", error);
            NSLog(@"Check RTC connection before making video call - Failed");
        }
        else{
            irisNotificationReceivedExpectation = [self expectationWithDescription:@"Notification Received"];
            [self invokeIncomingNotification];
            
            [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"Connection Timeout Error: %@", error);
                    NSLog(@"invoke notifiation failed");
                }
                else{
                    kVideoTestState = kTestInvalidRoomIdIncoming;
                    [self joinVideoSession];
                    
                    // Connection and session Cleanup Excuted Only when the Testcase Completed
                    if (joinVideoSession!=nil){
                        [joinVideoSession close];
                        joinVideoSession=nil;
                    }
                }
            }];
            [self disconnectFromServer];
        }
    }];
    
}

- (void)test5_VideoIncomingInvalidRoomToken{
    NSLog(@"Check RTC connection before joining a video call");
    
    NSError *Error = nil;
    
    irisConnectedExpectation = [self expectationWithDescription:@"Connected with IRIS backend"];
    [[IrisRtcConnection sharedInstance] connectUsingServer:evmUrl irisToken:IrisToken routingId:routingIdCaller delegate:self error:&Error];
    
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Connection Timeout Error: %@", error);
            NSLog(@"Check RTC connection before making video call - Failed");
        }
        else{
            irisNotificationReceivedExpectation = [self expectationWithDescription:@"Notification Received"];
            [self invokeIncomingNotification];
            
            [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"Connection Timeout Error: %@", error);
                    NSLog(@"invoke notifiation failed");
                }
                else{
                    kVideoTestState = kTestInvalidRoomToken;
                    [self joinVideoSession];
                    
                    // Connection and session Cleanup Excuted Only when the Testcase Completed
                    if (joinVideoSession!=nil){
                        [joinVideoSession close];
                        joinVideoSession=nil;
                    }
                }
            }];
            [self disconnectFromServer];
        }
    }];
    
}

- (void)test6_VideoIncomingInvalidRoomExpireyTime{
    NSLog(@"Check RTC connection before joining a video call");
    
    NSError *Error = nil;
    
    irisConnectedExpectation = [self expectationWithDescription:@"Connected with IRIS backend"];
    [[IrisRtcConnection sharedInstance] connectUsingServer:evmUrl irisToken:IrisToken routingId:routingIdCaller delegate:self error:&Error];
    
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Connection Timeout Error: %@", error);
            NSLog(@"Check RTC connection before making video call - Failed");
        }
        else{
            irisNotificationReceivedExpectation = [self expectationWithDescription:@"Notification Received"];
            [self invokeIncomingNotification];
            
            [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"Connection Timeout Error: %@", error);
                    NSLog(@"invoke notifiation failed");
                }
                else{
                    kVideoTestState = kTestInvalidRoomExpiryTime;
                    [self joinVideoSession];
                    
                    // Connection and session Cleanup Excuted Only when the Testcase Completed
                    if (joinVideoSession!=nil){
                        [joinVideoSession close];
                        joinVideoSession=nil;
                    }
                }
            }];
            [self disconnectFromServer];
        }
    }];
}

-(void)createVideoSession {
    NSLog(@"Create a video session");
    
    if(createVideoSession == nil){
        createVideoSession = [[IrisRtcVideoSession alloc]init];
        createVideoSession.isVideoBridgeEnable=true;
        createVideoSession.preferredVideoCodecType = kCodecTypeH264;
    }
    NSError * err;
    NSError *error = nil;
    
    NSDictionary *notification = [[NSDictionary alloc]initWithObjectsAndKeys:@"video",@"type",@"iristest.comcast.com/video",@"topic",nil];
    NSDictionary *data = [[NSDictionary alloc]initWithObjectsAndKeys:userid,@"cid",userid,@"cname",[NSNumber numberWithBool:true],@"isVideoOnly", nil];
    NSDictionary *notificationData = [[NSDictionary alloc]initWithObjectsAndKeys:notification,@"notification",data,@"data",nil];
    NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:notificationData options:0 error:&err];
    NSString * NotificationData = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    if (kVideoTestState == kTestVideoOutgoing) {
        irisVideoSessionCreatedExpectation = [self expectationWithDescription:@"Video Session Created"];
        [createVideoSession createWithRoomId:roomId notificationData:NotificationData stream:nil sessionConfig:sessionconfig delegate:self error:&error];
    }
    else if (kVideoTestState == kTestInvalidRoomIdOutgoing){
        irisVideoSessionInvalidRoomIDExpectation = [self expectationWithDescription:@"Invalid RoomID"];
        [createVideoSession createWithRoomId:@"hdvnlz" notificationData:NotificationData stream:nil sessionConfig:sessionconfig delegate:self error:&error];
    }
    if (error){
        NSLog(@"Create a video session Error: %@", error);
        XCTFail(@"Create a video session - Failed");
        return;
    }
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Create a video session timeout Error: %@", error);
            NSLog(@"Create a Video Session Failed");
            return ;
        }
    }];
}


-(void)joinVideoSession {
    NSLog(@"Join video session");
    
    if(joinVideoSession == nil){
        joinVideoSession = [[IrisRtcVideoSession alloc]init];
        joinVideoSession.isVideoBridgeEnable=true;
        joinVideoSession.preferredVideoCodecType = kCodecTypeH264;
    }
    
    NSError *error = nil;
    if (kVideoTestState == kTestVideoIncoming) {
        irisVideoSessionJoinedExpectation = [self expectationWithDescription:@"Video Session joined"];
        [joinVideoSession joinWithSessionId:roomId roomToken:roomToken roomTokenExpiryTime:[roomTokenExpiryTime integerValue] stream:nil rtcServer:rtcServer sessionConfig:sessionconfig delegate:self error:&error];
    }
    else if (kVideoTestState == kTestInvalidRoomIdIncoming){
        irisVideoSessionInvalidRoomIDExpectation = [self expectationWithDescription:@"Invalid RoomId"];
        [joinVideoSession joinWithSessionId:@"hsdjvb" roomToken:roomToken roomTokenExpiryTime:[roomTokenExpiryTime integerValue] stream:nil rtcServer:rtcServer sessionConfig:sessionconfig delegate:self error:&error];
    }
    else if (kVideoTestState == kTestInvalidRoomToken){
        irisVideoSessionInvalidRoomTokenExpectation = [self expectationWithDescription:@"Invalid Room Token"];
        [joinVideoSession joinWithSessionId:roomId roomToken:@"edsjv" roomTokenExpiryTime:[roomTokenExpiryTime integerValue] stream:nil rtcServer:rtcServer sessionConfig:sessionconfig delegate:self error:&error];
    }
    else if (kVideoTestState == kTestInvalidRoomExpiryTime){
        irisVideoSessionInvalidRoomExpiryTime = [self expectationWithDescription:@"InValid Room Expirey Time"];
        [joinVideoSession joinWithSessionId:roomId roomToken:roomToken roomTokenExpiryTime:2345 stream:nil rtcServer:rtcServer sessionConfig:sessionconfig delegate:self error:&error];
    }
    if (error)
    {
        NSLog(@"Join video session Error: %@", error);
        NSLog(@"Join video session - Failed");
        return;
    }
    [self waitForExpectationsWithTimeout:90 handler:^(NSError *error){
        if(error){
            NSLog(@"Join video session timeout Error:%@",error);
            NSLog(@"Join video session - Failed");
            return;
        }
    }];
}

-(void)invokeIncomingNotification
{
    NSLog(@"Making Request to Notification Server");
    NSString* url = [NSString stringWithFormat:@"%@/makeVideoCall", inboundUrl];
    NSString* AppToken = [@"Basic " stringByAppendingString:inboundSecret];
    NSDictionary* headers = @{@"Content-Type": @"application/json",
                              @"User-Agent":@"apple/phone/iPhone/11.0/IrisRestClient/1.0",
                              @"Authorization":AppToken
                              };
    
    NSDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:env forKey:@"env"];
    [parameters setValue:userid forKey:@"toUser"];
    
    // Send request
    UNIHTTPJsonResponse *response = [[UNIRest postEntity:^(UNIBodyRequest *request) {
        [request setUrl:url];
        [request setHeaders:headers];
        [request setBody:[NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil]];
    }] asJson];
    
    XCTAssert((response.code == 200), @"Test Setup :: Failed to Invoke Notification %@ ", response.body.object.description);
}

-(void)requestAutoAnswer
{
    NSLog(@"Requesting for AutoAnswer");
    NSString* url = [NSString stringWithFormat:@"%@/acceptVideoCall", inboundUrl];
    NSString* AppToken = [@"Basic " stringByAppendingString:inboundSecret];
    NSDictionary* headers = @{@"Content-Type": @"application/json",
                              @"User-Agent":@"apple/phone/iPhone/11.0/IrisRestClient/1.0",
                              @"Authorization":AppToken
                              };
    
    NSDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setValue:env forKey:@"env"];
    
    // Send request
    UNIHTTPJsonResponse *response = [[UNIRest postEntity:^(UNIBodyRequest *request) {
        [request setUrl:url];
        [request setHeaders:headers];
        [request setBody:[NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil]];
    }] asJson];
    
    XCTAssert((response.code == 200), @"Test Setup :: Iristoken request returned error %@ ", response.body.object.description);
    
}

- (void)readEnvironmentVariables {
    
    appkey = [[NSProcessInfo processInfo]environment][@"IRISAPPKEY"];
    idmUrl = [[NSProcessInfo processInfo] environment][@"IRISIDMURL"];
    aumUrl = [[NSProcessInfo processInfo] environment][@"IRISAUMURL"];
    evmUrl = [[NSProcessInfo processInfo] environment][@"IRISEVMURL"];
    inboundUrl = [[NSProcessInfo processInfo] environment][@"IRISINBOUNDSERVICE"];
    userid = [[NSProcessInfo processInfo] environment][@"IRISUSERID"];
    userpwd = [[NSProcessInfo processInfo]environment][@"IRISUSERPWD"];
    appsecret = [[NSProcessInfo processInfo]environment][@"IRISAPPSECRET"];
    inboundSecret = [[NSProcessInfo processInfo] environment][@"IRISINBOUNDSECRET"];
    appDomain = [[NSProcessInfo processInfo]environment][@"IRISAPPDOMAIN"];
    calleeId = [[NSProcessInfo processInfo] environment][@"IRISCALLEEID"];
    env = [[NSProcessInfo processInfo] environment][@"IRISENV"];
    
    NSString *plainString = [NSString stringWithFormat: @"%@:%@", appkey, appsecret];
    NSData *plainData = [plainString dataUsingEncoding:NSUTF8StringEncoding];
    appToken = [plainData base64EncodedStringWithOptions:0];
}

-(NSMutableDictionary*)genrateParticipantDictionary:routingId{
    
    NSMutableDictionary *ParticapantDict = [[NSMutableDictionary alloc]init];
    [ParticapantDict setObject:[NSNumber numberWithBool:true] forKey:@"notification"];
    [ParticapantDict setObject:[NSNumber numberWithBool:true] forKey:@"owner"];
    [ParticapantDict setObject:[NSNumber numberWithBool:true]  forKey:@"room_identifier"];
    [ParticapantDict setObject:[NSNumber numberWithBool:true] forKey:@"history"];
    [ParticapantDict setObject:routingId forKey:@"routing_id"];
    return ParticapantDict;
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
    if ([[data objectForKey:@"type"]  isEqual: @"notify"]) {
        roomId = [data objectForKey:@"roomid"];
        roomToken = [data objectForKey:@"roomtoken"];
        rtcServer = [data objectForKey:@"rtcserver"];
        roomTokenExpiryTime = data[@"roomtokenexpirytime"];
        [irisNotificationReceivedExpectation fulfill];
    }
}

- (void)onReconnecting {
    NSLog(@"IrisRtcConnectionDelegate :: onReconnecting");
}

#pragma mark - IrisRtcVideoSessionDelegate delegates

- (void)onSessionConnected:(NSString *)roomId traceId:(NSString *)traceId {
    NSLog(@"IrisRtcVideoSessionDelegate :: onSessionConnected: %@",roomId);
    if (kVideoTestState == kTestVideoOutgoing)
        [irisVideoSessionCreatedExpectation fulfill];
    else if(kVideoTestState == kTestVideoIncoming)
        [irisVideoSessionJoinedExpectation fulfill];
}

- (void)onSessionCreated:(NSString *)roomId traceId:(NSString *)traceId {
    NSLog(@"IrisRtcVideoSessionDelegate :: onSessionCreated: %@",roomId);
}

- (void)onSessionDominantSpeakerChanged:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId{
    NSLog(@"IrisRtcVideoSessionDelegate :: onSessionDominantSpeakerChanged: %@",roomId);
}

- (void)onSessionEnded:(NSString *)roomId traceId:(NSString *)traceId{
    NSLog(@"IrisRtcVideoSessionDelegate :: onSessionEnded: %@",roomId);
}

- (void)onSessionJoined:(NSString *)roomId traceId:(NSString *)traceId {
    NSLog(@"IrisRtcVideoSessionDelegate :: onSessionJoined: %@",roomId);
}

- (void)onSessionParticipantJoined:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId {
    NSLog(@"IrisRtcVideoSessionDelegate :: onSessionParticipantJoined: %@",roomId);
}

- (void)onSessionParticipantLeft:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId {
    NSLog(@"IrisRtcVideoSessionDelegate :: onSessionParticipantLeft: %@",roomId);
}

- (void)onSessionParticipantProfile:(NSString *)participantId userProfile:(IrisRtcUserProfile *)userprofile roomId:(NSString *)roomid traceId:(NSString *)traceId{
    NSLog(@"IrisRtcVideoSessionDelegate :: onSessionParticipantProfile: %@",roomId);
}

- (void)onAddRemoteStream:(IrisRtcMediaTrack *)track participantId:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId{
    NSLog(@"IrisRtcVideoSessionDelegate :: onAddRemoteStream: %@",roomId);
}

- (void)onChatMessageError:(NSString *)messageId withAdditionalInfo:(NSDictionary *)info roomId:(NSString *)roomId traceId:(NSString *)traceId{
    NSLog(@"IrisRtcVideoSessionDelegate :: onChatMessageError: %@",roomId);
}

- (void)onChatMessageState:(IrisChatState)state participantId:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId{
    NSLog(@"IrisRtcVideoSessionDelegate :: onChatMessageState: %@",roomId);
}

- (void)onChatMessageSuccess:(IrisChatMessage *)message roomId:(NSString *)roomId traceId:(NSString *)traceId{
    NSLog(@"IrisRtcVideoSessionDelegate :: onChatMessageSuccess: %@",roomId);
}

- (void)onRemoveRemoteStream:(IrisRtcMediaTrack *)track participantId:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId {
    NSLog(@"IrisRtcVideoSessionDelegate :: onRemoveRemoteStream: %@",roomId);
}

- (void)onSessionParticipantMessage:(IrisChatMessage *)message participantId:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId{
    NSLog(@"IrisRtcVideoSessionDelegate :: onSessionParticipantMessage: %@",roomId);
}

- (void)onSessionError:(NSError *)error withAdditionalInfo:(NSDictionary *)info roomId:(NSString *)roomId traceId:(NSString *)traceId{
    NSLog(@"IrisRtcAudioSessionDelegate :: onSessionError :%@,%ld",error.localizedDescription,(long)error.code);
    if (kVideoTestState == kTestInvalidRoomIdOutgoing) {
        [irisVideoSessionInvalidRoomIDExpectation fulfill];
        irisVideoSessionInvalidRoomIDExpectation = nil;
    }
    else if (kVideoTestState == kTestInvalidRoomIdIncoming){
        [irisVideoSessionInvalidRoomIDExpectation fulfill];
        irisVideoSessionInvalidRoomIDExpectation = nil;
    }
    else if (kVideoTestState == kTestInvalidRoomToken){
        [irisVideoSessionInvalidRoomTokenExpectation fulfill];
        irisVideoSessionInvalidRoomTokenExpectation = nil;
    }
    else if (kVideoTestState == kTestInvalidRoomExpiryTime){
        [irisVideoSessionInvalidRoomExpiryTime fulfill];
        irisVideoSessionInvalidRoomExpiryTime = nil;
    }
}

@end
