//
//  IrisRtcSdkStats.h :  Objective C code used to get stats related to session.
//
//
// Copyright 2015 Comcast Cable Communications Management, LLC
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


#ifndef IrisRtcSdkStats_h
#define IrisRtcSdkStats_h
@class IrisRtcSdkStats;
@class IrisRtcJingleSession;


/** The `IrisRtcSdkStatsDelegate` protocol defines the optional methods implemented by
 * delegates of the IrisRtcSdkStats class.
 *
 * These delegates are used to monitor  the stats that are collected during
 *  active session and also to get entire stats of session that will be accumlated and returned at end of session.
 * 
 * The delegate onStats:sessionStats: will be return stats that are collected during active session.
 * The final stats collected at end of seesion will be posted through delegate 
 * onSummary:sessionTimeSeries:streamInfo:metaData which has stats related to sesion and stream and metadata.
 */

@protocol IrisRtcSdkStatsDelegate<NSObject>

/**
 * This method will return stats that are collected during session.
 *
 * @param sessionStats Provides details of the stats at that instance.
 */
- (void)onStats:(NSDictionary *)sessionStats;

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
 - (void)onSummary:(NSDictionary*)sessionTimeseries streamInfo:(NSDictionary*)streamInfo metaData:(NSDictionary*)metaData;

@end

/** 
 * The 'IrisRtcSdkStats' class is useful to monitor stats.These stats can be used for quality improvement by debugging ,
 * since it provides the details of the quality of the call, meta data etc.
 *
 */

@interface IrisRtcSdkStats : NSObject

@property(readonly) NSDictionary* IrisRtcSdkMetaData;
@property(nonatomic) NSMutableArray* eventsArray;
@property(nonatomic) BOOL sendStatsIq;

///** 
// *
// * set postStatsToServer as true  to post stats to server.
// */
//@property BOOL postStatsToServer;

/**
 * This api used to  intiliaze IrisRtcSdkStats class for particular session which will be passed as parameter.
 *
 * @param session pointer to the IrisRtcJingleSession.
 * @param delegate The delegate object for the IrisRtcSdkStats.
 */
-(id)initWithSession:(IrisRtcJingleSession*)session delegate:(id)delegate;

/**-----------------------------------------------------------------------------
 * @name Start monitoring stats
 * -----------------------------------------------------------------------------
 */
/**
 * This api is used to collect stats of session.Stats that are collected will be posted using onStats:sessionStats
 * method based on time interval provided.
 *
 * @param interval Provides interval for monitoring stats to the timer.
 */
-(void)startMonitoringUsingInterval:(NSInteger)interval;
/**-----------------------------------------------------------------------------
 * @name Get Session Stats
 * -----------------------------------------------------------------------------
 */
/**
 * This api is used to collect stats of session.
 *
 * 
 */
-(NSMutableArray *)getstats;

/**-----------------------------------------------------------------------------
 * @name Stop monitoring stats
 * -----------------------------------------------------------------------------
 */
/**
 * This api is used to stop monitoring the stats and final stats will be posted using onSummary:sessionTimeSeries:streamInfo:metaData api.
 */

-(NSMutableDictionary*)getMetaData;

-(void)stopMonitoring;

-(void)setStatsIq:(BOOL)val;

-(NSMutableDictionary*)getCallSummaryStats;

@end

#endif /* IrisRtcSdkStats_h */
