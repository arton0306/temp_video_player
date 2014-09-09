//
//  CHWAudioPlayer.h
//  CHWVideoPlayer
//
//  Created by Arton on 9/5/14.
//  Copyright (c) 2014 Arton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "avcodec.h"

@class CHWVideoFrameFifo;

@interface CHWAudioPlayer : NSObject

typedef NS_ENUM( NSInteger, CHW_AUDIO_STATE )
{
    CHW_AUDIO_STATE_INIT            = -1,
    CHW_AUDIO_STATE_READY           = 0,
    CHW_AUDIO_STATE_STOP            = 1,
    CHW_AUDIO_STATE_PLAYING         = 2,
    CHW_AUDIO_STATE_PAUSE           = 3,
    CHW_AUDIO_STATE_SEEKING         = 4
};

@property (nonatomic, assign) CHW_AUDIO_STATE state;

- (id) initWithAVCodecContext:(AVCodecContext*)aAudioCodecContext AndAudioFifo:(CHWVideoFrameFifo*)audioFifo;
- (BOOL) play;
- (BOOL) pause;

// TODO: make audioQueueOutputCallback audioQueueIsRunningCallback be not interfaces
- (void)audioQueueOutputCallback:(AudioQueueRef)inAQ inBuffer:(AudioQueueBufferRef)inBuffer;
- (void)audioQueueIsRunningCallback;

@end
