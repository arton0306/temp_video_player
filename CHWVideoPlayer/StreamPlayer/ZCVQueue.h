//
//  ZCVQueue.h
//  Lifestamp
//
//  Created by Arton on 5/18/14.
//  Copyright (c) 2014 Arton. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Node : NSObject

@property (nonatomic, retain) id object;
@property (nonatomic, retain) Node *next;

@end

@interface ZCVQueue : NSObject

@property (nonatomic, retain) Node* head;

- (id)front;
- (void)enqueue:(id)object;
- (id)dequeue;
- (BOOL)isEmpty;

@end
