//
//  IrisRoomManager.h
//  IrisRtcSdk
//
//  Created by Girish on 08/08/17.
//  Copyright © 2017 Gupta, Harish (Contractor). All rights reserved.
//

#ifndef IrisRoomManager_h
#define IrisRoomManager_h

@interface IrisRtcParticipant : NSObject


/**
 * private variable
 * set participant routing id.
 */
@property (nonatomic) NSString* participantId;

/**
 * private variable
 * set time when presence received.
 */
@property (nonatomic) NSDate* timeElapse;
/**
 * private variable
 * set participant routing id.
 */
@property (nonatomic) NSString* name;
/**
 * private variable
 * set time when presence received.
 */
@property (nonatomic) NSString* avatarUrl;

/**
 * private variable
 * set time when presence received.
 */
@property (nonatomic) NSString* eventType;
/**
 * private variable
 * set time when presence received.
 */
@property (nonatomic) BOOL audioMute;
/**
 * private variable
 * set time when presence received.
 */
@property (nonatomic) BOOL videoMute;


/**
 * Initialize chat message class with message,messageId.
 *
 * @param participantId participant routing id.
 * @param timeElapse   time when presence received.
 *
 */
-(id)initWithParticipant:participantId timeElapse:(NSDate*)timeElapse;


@end


#endif /* IrisRoomManager_h */
