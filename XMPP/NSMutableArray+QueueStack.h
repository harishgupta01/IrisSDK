//
//  NSMutableArray+QueueStack.h
//  IrisRtcSdk
//
//  Created by Gupta, Harish (Contractor) on 7/12/18.
//  Copyright © 2018 Gupta, Harish (Contractor). All rights reserved.
//

#ifndef NSMutableArray_QueueStack_h
#define NSMutableArray_QueueStack_h

#import <Foundation/Foundation.h>

@interface NSMutableArray (QueueStack)
-(id)queuePop;
-(void)queuePush:(id)obj;
-(id)stackPop;
-(void)stackPush:(id)obj;
@end

#endif /* NSMutableArray_QueueStack_h */


