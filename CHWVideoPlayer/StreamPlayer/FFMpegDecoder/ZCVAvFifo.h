//
//  ZCVAvFifo.h
//  Lifestamp
//
//  Created by Arton on 5/19/14.
//  Copyright (c) 2014 Arton. All rights reserved.
//

#import "ZCVQueue.h"

@interface ZCVFrameSec : NSObject 

@property (nonatomic, retain) NSData *data;
@property (nonatomic, assign) double pts;
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;

- (id) initWithData:(NSData*)data AndPts:(double)pts;
- (id) initWithData:(NSData*)data AndPts:(double)pts AndWidth:(int)width AndHeight:(int)height;
- (UIImage*) toUIImage;

@end

@interface ZCVAvFifo : ZCVQueue

@property (nonatomic, assign, readonly) int frameCount;

- (void) enqueue:(ZCVFrameSec*)frameSec;
- (ZCVFrameSec*) dequeue;
- (ZCVFrameSec*) front;
- (double) getFrameTotalTimeInSec;

@end
