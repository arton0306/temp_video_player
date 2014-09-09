//
//  CHWAvFifo.m
//  Lifestamp
//
//  Created by Arton on 5/19/14.
//  Copyright (c) 2014 Arton. All rights reserved.
//

#import "CHWVideoFrameFifo.h"

@implementation CHWFrameSec

- (id) initWithData:(NSData*)data AndPts:(double)pts
{
    if ( self = [super init] )
    {
        self.data = data;
        self.pts = pts;
    }
    return self;
}

- (id) initWithData:(NSData*)data AndPts:(double)pts AndWidth:(int)width AndHeight:(int)height
{
    if ( self = [super init] )
    {
        self.data = data;
        self.pts = pts;
        self.width = width;
        self.height = height;
    }
    return self;
}

- (UIImage*) toUIImage
{
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
	CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, [self.data bytes], self.width * self.height * 3,kCFAllocatorNull);
    // CFDataRef data = CFDataCreate(kCFAllocatorDefault, [self.data bytes], self.width * self.height * 3);
    NSAssert( [self.data length] == self.width * self.height * 3,
             @"Fatal error: data length:%d, width:%d, height:%d, mul3=%d",
             [self.data length],
             self.width, self.height, self.width * self.height * 3 );
    
	CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGImageRef cgImage = CGImageCreate(self.width,
									   self.height,
									   8,
									   24,
									   3 * self.width,
									   colorSpace,
									   bitmapInfo,
									   provider,
									   NULL,
									   NO,
									   kCGRenderingIntentDefault);
	UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
	CGColorSpaceRelease(colorSpace);
	CGDataProviderRelease(provider);
	CFRelease(data);
	
	return image;
}

@end

@interface CHWVideoFrameFifo ()

@property (nonatomic, retain) NSLock *lock;
@property (nonatomic, retain) CHWFrameSec *tailFrame; // invalid if frame count is 0

@end

@implementation CHWVideoFrameFifo

- (id) init
{
    if ( self = [super init] )
    {
        self.lock = [NSLock new];
        _frameCount = 0;
    }
    return self;
}

- (void) enqueue:(CHWFrameSec*)frameSec
{
    [self.lock lock];
    self.tailFrame = frameSec;
    [super enqueue:frameSec];
    ++_frameCount;
    [self.lock unlock];
}

- (CHWFrameSec*) dequeue
{
    CHWFrameSec *frameSec;
    [self.lock lock];
    frameSec = [super dequeue];
    --_frameCount;
    [self.lock unlock];
    return frameSec;
}

- (CHWFrameSec*) front
{
    CHWFrameSec *frameSec;
    [self.lock lock];
    frameSec = super.head.object;
    [self.lock unlock];
    return frameSec;
}

- (double) getFrameTotalTimeInSec
{
    double result = -1.0;
    [self.lock lock];
    if ( self.frameCount > 1 )
    {
        CHWFrameSec *nearestFrame = super.head.object;
        result = self.tailFrame.pts - nearestFrame.pts;
    }
    [self.lock unlock];
    return result;
}

@end
