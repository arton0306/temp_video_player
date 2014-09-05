//
//  ZCVQueue.m
//  Lifestamp
//
//  Created by Arton on 5/18/14.
//  Copyright (c) 2014 Arton. All rights reserved.
//

#import "ZCVQueue.h"

@implementation Node
@end

@interface ZCVQueue ()

@property (nonatomic, retain) Node* tail;

@end

@implementation ZCVQueue

- (id)init
{
	if ( self=[super init] )
    {
        self.head = nil;
        self.tail = self.head;
        return self;
    }
    return nil;
}

- (void)enqueue:(id)object
{
    Node *node = [Node new];
    node.object = object;
    node.next = nil;
    
    if ( self.head )
    {
        self.tail.next = node;
        self.tail = self.tail.next;
    }
    else
    {
        self.head = node;
        self.tail = node;
    }
}

- (id)front
{
    return self.head.object;
}

- (id)dequeue
{
    if ( ![self isEmpty] )
    {
        Node *retNode = self.head.object;
        
        if ( self.head == self.tail )  // has only one object in queue
        {
            self.head = nil;
            self.tail = nil;
        }
        else
        {
            self.head = self.head.next;
        }
        
        return retNode;
    }
    else
    {
        NSLog( @"dequeue an empty queue!" );
        return nil;
    }
}

- (BOOL)isEmpty
{
    return ( self.head == nil );
}

@end
