//
// IrisRtcJingleSession.h : Objective C code used to create and manage session.
//
// Copyright 2016 Comcast Cable Communications Management, LLC
//
// Permission to use, copy, modify, and/or distribute this software for any purpose
// with or without fee is hereby granted, provided that the above copyright notice
// and this permission notice appear in all copies.
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO
// THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
// DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
// AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION
// WITH THE USE OR PERFORMANCE OF THIS SOFTWARE
//

#ifndef IrisRtcJingleSession_h
#define IrisRtcJingleSession_h


@class IrisRtcJingleSession;
@class IrisRtcMediaTrack;


/**
 * Iris RTC Video codec types
 * <li>kCodecTypeVP8</li>
 * <li>kCodecTypeH264</li>
 */
typedef NS_ENUM(NSUInteger, IrisRtcSdkVideoCodecType) {
    
    /**
     * Indicates that the video codec type is VP8.
     */
    kCodecTypeVP8, //Default Codec
    /**
     * Indicates that the video codec type is H264.
     */
    kCodecTypeH264
};

/**
 * Iris RTC Audio codec types
 * <li>kCodecTypeOPUS</li>
 * <li>kCodecTypeISAC16000</li>
 * <li>kCodecTypeISAC32000</li>
 */
typedef NS_ENUM(NSUInteger, IrisRtcSdkAudioCodecType) {
    
    /**
     * Indicates that the audio codec type is OPUS.
     */
    kCodecTypeOPUS, //Default Codec
    /**
     * Indicates that the audio codec type is ISAC16000.
     */
    kCodecTypeISAC16000,
    /**
     * Indicates that the audio codec type is ISAC32000.
     */
    kCodecTypeISAC32000
    
    
};

/**
 * Iris RTC Network types
 * <li>kNetworkTypeIPv4Only</li>
 * <li>kNetworkTypeIPv4AndIPv6</li>
 */
typedef NS_ENUM(NSUInteger, IrisNetworkType) {
    /**
     * Indicates that the network type is Ipv4 only.
     */
    kNetworkTypeIPv4Only, //Default Codec
    /**
     * Indicates that the network type can be Ipv4 or Ipv6.
     */
    kNetworkTypeIPv4AndIPv6
};

/** The `IrisRtcUserProfile` class is used to provide the user profile information
 * to Iris SDK
 *
 */
@interface IrisRtcUserProfile : NSObject

/** private variable
 */
@property (strong) NSString *name;

/** private variable
 */
@property (strong) NSString *avatarUrl;

@end


@interface IrisRtcJingleSessionOptions : NSObject



/**
 * private variable
 * set isVideoBridgeEnable as true  to make calls using videobridge.
 */
@property (nonatomic) BOOL isVideoBridgeEnable;



/**
 * private variable
 * set room token from the incoming call notification.
 */
@property (nonatomic) NSString* roomToken;

/**
 * private variable
 * set room token expiry time.
 */
@property (nonatomic) NSString* roomTokenExpiryTime;

@end

@interface IrisRtcSessionConfig : NSObject

/**
 * private variable
 * maxstreamcount Restricting max number of stream mobile client want to recieve in case of multiple partcipant.
 * By Default, will get stream for those participant who joins last.
 */

@property(nonatomic) int maxStreamCount;
/**
 * private variable
 * statsCollectorInterval time interval to get stats
 */

@property(nonatomic) NSInteger statsCollectorInterval;

/**
 * private variable
 * set ToDomain
 */
@property(nonatomic) NSString* toDomain;

@end

/**
 * The `IrisRtcJingleSessionDelegate` protocol defines the optional methods implemented by
 * delegates of the IrisRtcJingleSession class.
 */
@protocol IrisRtcJingleSessionDelegate <NSObject>

/**
 * Callback:This method is called when the room is created successfully.
 *
 * @param roomId room id.
 * @param traceId trace id.
 */
-(void)onSessionCreated:(NSString *)roomId traceId:(NSString *)traceId;

/**
 * Callback: This is called when the room is joined successfully from reciever.
 *
 * @param roomId room id.
 * @param traceId trace id.
 */
-(void)onSessionJoined:(NSString *)roomId traceId:(NSString *)traceId;


/**
 * Callback: This is called at the sender side when the remote participant joins the room.
 *
 * @param participantId paritcipant id.
 * @param roomId room id.
 * @param traceId trace id.
 */
-(void)onSessionParticipantJoined:(NSString *)participantId roomId:(NSString*)roomId traceId:(NSString *)traceId;

/**
 * Callback: This is called when the Ice connection state that is,session is connected.
 *
 * @param roomId room id.
 * @param traceId trace id.
 */
-(void)onSessionConnected:(NSString *)roomId traceId:(NSString *)traceId;

/**
 * Callback: This is called when the session ends.
 *
 * @param roomId room id.
 * @param traceId trace id.
 *
 */
- (void)onSessionEnded:(NSString*)roomId traceId:(NSString *)traceId;

/**
 * Callback: This is called when the participant leaves the room.
 *
 * @param participantId paritcipant id.
 * @param roomId room id.
 * @param traceId trace id.
 */
- (void)onSessionParticipantLeft:(NSString*)participantId roomId:(NSString*)roomId traceId:(NSString *)traceId;

/**
 * Callback: This is called when the participant profile is changed.
 *
 * @param participantId paritcipant id.
 * @param userprofile  IriRtcuserProfile object containing participant's name and image url .
 * @param roomId room id.
 * @param traceId trace id.
 */
- (void)onSessionParticipantProfile:(NSString*)participantId userProfile:(IrisRtcUserProfile*)userprofile roomId:(NSString*)roomid traceId:(NSString *)traceId;

/**
 * Callback: This is called when dominant speaker is changed in multiple stream.
 *
 * @param participantId paritcipant id.
 * @param roomId room id.
 * @param traceId trace id.
 *
 */
- (void)onSessionDominantSpeakerChanged:(NSString*)participantId roomId:(NSString*)roomId traceId:(NSString *)traceId;
/**
 * Callback: This is called when stream of particular particiapnt is activated/viewed in multiple stream.
 *
 * @param participantId paritcipant id.
 * @param roomId room id.
 * @param traceId trace id.
 *
 */
@optional
- (void)onSessionRemoteParticipantActivated:(NSString*)participantId roomId:(NSString*)roomId traceId:(NSString *)traceId;
/**
 * Callback: This is called when remote participant is not responding.
 *
 * @param participantId paritcipant id.
 * @param roomId room id.
 * @param traceId trace id.
 *
 */
- (void)onSessionParticipantNotResponding:(NSString*)participantId roomId:(NSString*)roomId traceId:(NSString *)traceId;

/**
 * Callback: This is called when there is change in sessiontype.
 *
 * @param sessionType session type.
 * @param participantId paritcipant id.
 * @param roomId room id.
 * @param traceId trace id.
 *
 */
@optional
- (void)onSessionTypeChanged:(NSString*)sessionType participantId:(NSString*)participantId roomId:(NSString*)roomId traceId:(NSString *)traceId;
/**
 * Callback: This is called when audio of remote participant muted or unmuted.
 *
 * @param mute audio state mute or unmute.
 * @param participantId paritcipant id.
 * @param roomId room id.
 * @param traceId trace id.
 *
 */
@optional
- (void)onSessionParticipantAudioMuted:(BOOL)mute participantId:(NSString*)participantId roomId:(NSString*)roomId traceId:(NSString *)traceId;
/**
 * Callback: This is called when video of remote participant muted or unmuted.
 *
 * @param mute video state mute or unmute.
 * @param participantId paritcipant id.
 * @param roomId room id.
 * @param traceId trace id.
 */
@optional
- (void)onSessionParticipantVideoMuted:(BOOL)mute participantId:(NSString*)participantId roomId:(NSString*)roomId traceId:(NSString *)traceId;
/**
 * Callback: This is called when there is error while the session is active.
 *
 * @param error     The basic error code details.
 * @param info      Additional error details including description.
 * @param roomId    room id.
 * @param traceId   trace id.
 */
- (void)onSessionError:(NSError*)error withAdditionalInfo:(NSDictionary *)info roomId:(NSString*)roomId traceId:(NSString *)traceId;
/**
 * Callback: This is called when there is any message is to be convey to the app.
 *
 * @param log message to the app.
 * @param roomId room id.
 * @param traceId trace id.
 */
- (void)onLogAnalytics:(NSString*)log roomId:(NSString*)roomId traceId:(NSString *)traceId;

/**
 * This method will return stats that are collected during session.
 *
 * @param sessionStats Provides details of the stats at that instance.
 */
//- (void)onStats:(NSDictionary *)sessionStats;

/**
 * This method is called on disconnecting the call
 * or when monitoring the stats have to stopped.
 * It provides details of the entire stats, right from starting of the call
 * to end of the call/stopping to monitor the stats.
 *
 * @param sessionTimeseries The details of audio/video of the call eg., bitrate, bandwidth etc.
 * @param streamInfo Contains details of the stream like start time, duration, stop time.
 * @param metaData contains meta details like sdk version , networktype, model etc.
 */
//- (void)onSummary:(NSDictionary*)sessionTimeseries streamInfo:(NSDictionary*)streamInfo metaData:(NSDictionary*)metaData;


@end


@interface IrisRtcJingleSession : NSObject

/**
 * private variable used to set the networktype like IPV4 only or it can be IPV4 or IPV6.
 *
 */
@property(nonatomic) IrisNetworkType networkType;


/**
 * private variable
 * set autoDisconnect as true to autodisconnect when all participants have left: Default is true
 */
@property(nonatomic) bool autoDisconnect;

/**
 * private variable used to set traceid.
 *
 */
@property (nonatomic) NSString* traceId;


/**
 * private variable
 */
@property(nonatomic) BOOL useAnonymousRoom;


-(void)close;

-(void) setStatsWS: (bool) flag;

@end
#endif /* IrisRtcSession_h */
