//
//  ZCVAVInfo.h
//  Lifestamp
//
//  Created by Arton on 5/18/14.
//  Copyright (c) 2014 Arton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "samplefmt.h"

@interface ZCVAVInfo : NSObject

@property (nonatomic, assign) int videoWidth;
@property (nonatomic, assign) int videoHeight;
@property (nonatomic, assign) double fps;
@property (nonatomic, assign) double durationUsecs;
@property (nonatomic, assign) unsigned audioChannel;
@property (nonatomic, assign) unsigned audioSampleRate;
@property (nonatomic, assign) unsigned audioBitsPerSample;
@property (nonatomic, assign) enum AVSampleFormat audioSampleFormat;

- (void) dump;

@end
