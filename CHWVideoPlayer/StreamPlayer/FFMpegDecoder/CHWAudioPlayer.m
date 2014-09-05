//
//  CHWAudioPlayer.m
//  CHWVideoPlayer
//
//  Created by Arton on 9/5/14.
//  Copyright (c) 2014 Arton. All rights reserved.
//

#import "CHWAudioPlayer.h"
#import "avcodec.h"
#import <AudioToolbox/AudioToolbox.h>

static const int kNumAQBufs = 3;
static const int kAudioBufferSeconds = 3;

static void audioQueueOutputCallback(void *inClientData, AudioQueueRef inAQ,
                              AudioQueueBufferRef inBuffer) {
    
    CHWAudioPlayer *audioPlayer = (__bridge CHWAudioPlayer*)inClientData;
    [audioPlayer audioQueueOutputCallback:inAQ inBuffer:inBuffer];
}

static void audioQueueIsRunningCallback(void *inClientData, AudioQueueRef inAQ,
                                 AudioQueuePropertyID inID) {
    
    CHWAudioPlayer *audioPlayer = (__bridge CHWAudioPlayer*)inClientData;
    [audioPlayer audioQueueIsRunningCallback];
}

@interface CHWAudioPlayer()
{
    AudioStreamBasicDescription audioStreamBasicDesc;
    AudioQueueRef audioQueue;
    AVCodecContext *audioCodecContext;
    AudioQueueBufferRef audioQueueBuffer[kNumAQBufs];
}

@end

@implementation CHWAudioPlayer

- (BOOL)createAudioQueueWithAVCodecContext:(AVCodecContext*)aAudioCodecContext
{
    audioCodecContext = audioCodecContext;

    audioStreamBasicDesc.mFormatID = -1;
    audioStreamBasicDesc.mSampleRate = audioCodecContext->sample_rate;
    
    if (audioStreamBasicDesc.mSampleRate < 1) {
        NSLog( @"weird sample rate: %lf, force para to 32000", audioStreamBasicDesc.mSampleRate );
        audioStreamBasicDesc.mSampleRate = 32000;
    }
    
    audioStreamBasicDesc.mFormatFlags = 0;
    
    switch ( audioCodecContext->codec_id ) {
        case CODEC_ID_MP3:
        {
            audioStreamBasicDesc.mFormatID = kAudioFormatMPEGLayer3;
            break;
        }
        case CODEC_ID_AAC:
        {
            audioStreamBasicDesc.mFormatID = kAudioFormatMPEG4AAC;
            audioStreamBasicDesc.mFormatFlags = kMPEG4Object_AAC_LC;
            audioStreamBasicDesc.mSampleRate = 44100;
            audioStreamBasicDesc.mChannelsPerFrame = 2;
            audioStreamBasicDesc.mBitsPerChannel = 0;
            audioStreamBasicDesc.mFramesPerPacket = 1024;
            audioStreamBasicDesc.mBytesPerPacket = 0;
            NSLog(@"audio format %s (%d) is  supported", audioCodecContext->codec_descriptor->name, audioCodecContext->codec_id);
            
            break;
        }
        case CODEC_ID_AC3:
        {
            audioStreamBasicDesc.mFormatID = kAudioFormatAC3;
            break;
        }
        case CODEC_ID_PCM_MULAW:
        {
            audioStreamBasicDesc.mFormatID = kAudioFormatULaw;
            audioStreamBasicDesc.mSampleRate = 8000.0;
            audioStreamBasicDesc.mFormatFlags = 0;
            audioStreamBasicDesc.mFramesPerPacket = 1;
            audioStreamBasicDesc.mChannelsPerFrame = 1;
            audioStreamBasicDesc.mBitsPerChannel = 8;
            audioStreamBasicDesc.mBytesPerPacket = 1;
            audioStreamBasicDesc.mBytesPerFrame = 1;
            NSLog(@"found audio codec mulaw");
            break;
        }
        default:
        {
            NSLog(@"Error: audio format '%s' (%d) is not supported", audioCodecContext->codec_descriptor->name, audioCodecContext->codec_id);
            audioStreamBasicDesc.mFormatID = kAudioFormatAC3;
            break;
        }
    }
    
    //    if (audioStreamBasicDesc_.mFormatID != kAudioFormatULaw) {
    //        audioStreamBasicDesc_.mBytesPerPacket = 0;
    //        audioStreamBasicDesc_.mFramesPerPacket = _audioCodecContext->frame_size;
    //        audioStreamBasicDesc_.mBytesPerFrame = 0;
    //        audioStreamBasicDesc_.mChannelsPerFrame = _audioCodecContext->channels;
    //        audioStreamBasicDesc_.mBitsPerChannel = 0;
    //    }
    
    OSStatus status = AudioQueueNewOutput( &audioStreamBasicDesc, audioQueueOutputCallback, (__bridge void*)self, NULL, NULL, 0, &audioQueue );
    if (status != noErr) {
        NSLog(@"Could not create new audio queue.");
        return NO;
    }
    
    status = AudioQueueAddPropertyListener( audioQueue, kAudioQueueProperty_IsRunning, audioQueueIsRunningCallback, (__bridge void*)self );
    if (status != noErr) {
        NSLog(@"Could not add propery listener. (kAudioQueueProperty_IsRunning)");
        return NO;
    }
    
    for (NSInteger i = 0; i < kNumAQBufs; ++i) {
        status = AudioQueueAllocateBufferWithPacketDescriptions(audioQueue,
                                                                audioStreamBasicDesc.mSampleRate * kAudioBufferSeconds / 8,
                                                                audioCodecContext->sample_rate * kAudioBufferSeconds / (audioCodecContext->frame_size + 1),
                                                                &audioQueueBuffer[i]);
        if (status != noErr) {
            NSLog(@"Could not allocate buffer.");
            return NO;
        }
    }
    
    return YES;
}

- (void)audioQueueOutputCallback:(AudioQueueRef)inAQ inBuffer:(AudioQueueBufferRef)inBuffer
{
    if ( _state == CHW_AUDIO_STATE_PLAYING) {
        [self enqueueBuffer:inBuffer];
    }
}

- (void)audioQueueIsRunningCallback
{
    UInt32 isRunning;
    UInt32 size = sizeof(isRunning);
    OSStatus status = AudioQueueGetProperty(audioQueue, kAudioQueueProperty_IsRunning, &isRunning, &size);
    
    if ( status == noErr && !isRunning && _state == CHW_AUDIO_STATE_PLAYING)
    {
        _state = CHW_AUDIO_STATE_STOP;
    }
}

- (OSStatus)enqueueBuffer:(AudioQueueBufferRef)buffer
{
    OSStatus status = noErr;
    
    if (buffer) {
        AudioTimeStamp bufferStartTime;
        buffer->mAudioDataByteSize = 0;
        buffer->mPacketDescriptionCount = 0;
        
        if (_streamer.audioPacketQueue.count <= 0) {
            _streamer.emptyAudioBuffer = buffer;
            return status;
        }
        
        _streamer.emptyAudioBuffer = nil;
        
        while (_streamer.audioPacketQueue.count && buffer->mPacketDescriptionCount < buffer->mPacketDescriptionCapacity) {
            AVPacket *packet = [_streamer readPacket];
            
            if (buffer->mAudioDataBytesCapacity - buffer->mAudioDataByteSize >= packet->size) {
                if (buffer->mPacketDescriptionCount == 0) {
                    bufferStartTime.mSampleTime = packet->dts * _audioCodecContext->frame_size;
                    bufferStartTime.mFlags = kAudioTimeStampSampleTimeValid;
                }
                
                memcpy((uint8_t *)buffer->mAudioData + buffer->mAudioDataByteSize, packet->data, packet->size);
                buffer->mPacketDescriptions[buffer->mPacketDescriptionCount].mStartOffset = buffer->mAudioDataByteSize;
                buffer->mPacketDescriptions[buffer->mPacketDescriptionCount].mDataByteSize = packet->size;
                buffer->mPacketDescriptions[buffer->mPacketDescriptionCount].mVariableFramesInPacket = _audioCodecContext->frame_size;
                
                buffer->mAudioDataByteSize += packet->size;
                buffer->mPacketDescriptionCount++;
                
                
                _streamer.audioPacketQueueSize -= packet->size;
                
                av_free_packet(packet);
            }
            else {
                break;
            }
        }
        
        [decodeLock_ lock];
        if (buffer->mPacketDescriptionCount > 0) {
            status = AudioQueueEnqueueBuffer(audioQueue_, buffer, 0, NULL);
            if (status != noErr) {
                NSLog(@"Could not enqueue buffer.");
            }
        } else {
            AudioQueueStop(audioQueue_, NO);
            finished_ = YES;
        }
        
        [decodeLock_ unlock];
    }
    
    return status;
}

@end
