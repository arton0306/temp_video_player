//
//  CHWAudioPlayer.m
//  CHWVideoPlayer
//
//  Created by Arton on 9/5/14.
//  Copyright (c) 2014 Arton. All rights reserved.
//

#import "CHWAudioPlayer.h"
// #import "avformat.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "CHWVideoFrameFifo.h"
#import "CHWUtilities.h"

static const int kNumAQBufs = 3;
static const int kAudioBufferSeconds = 3;

void audioQueueOutputCallback(void *inClientData, AudioQueueRef inAQ,
                              AudioQueueBufferRef inBuffer);
void audioQueueIsRunningCallback(void *inClientData, AudioQueueRef inAQ,
                                 AudioQueuePropertyID inID);

void audioQueueOutputCallback(void *inClientData, AudioQueueRef inAQ,
                              AudioQueueBufferRef inBuffer) {
    
    CHWAudioPlayer *audioPlayer = (__bridge CHWAudioPlayer*)inClientData;
    [audioPlayer audioQueueOutputCallback:inAQ inBuffer:inBuffer];
}

void audioQueueIsRunningCallback(void *inClientData, AudioQueueRef inAQ,
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

@property (nonatomic, retain) CHWVideoFrameFifo *audioFifo;
@property (nonatomic, retain) CHWFrameSec *currentAudioFrame;

@property (nonatomic, assign) BOOL isAudioQueueCreated;

@end

@implementation CHWAudioPlayer

- (id) initWithAVCodecContext:(AVCodecContext*)aAudioCodecContext AndAudioFifo:(CHWVideoFrameFifo*)audioFifo
{
    if ( self = [super init] )
    {
        [self p_setupAudioSession];
        
        audioCodecContext = aAudioCodecContext;
        self.audioFifo = audioFifo;
        self.currentAudioFrame = nil;
        self.state = CHW_AUDIO_STATE_INIT;
        self.isAudioQueueCreated = NO;
    }
    
    return self;
}

- (void) p_setupAudioSession
{
    NSError *error = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:&error];
    
    /*
    AudioSessionInitialize(NULL, NULL, NULL, NULL);
    UInt32 category = kAudioSessionCategory_MediaPlayback; // plays through sleep lock and silent switch
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
    AudioSessionSetActive(true);
     */
    
    if ( error )
    {
        NSLog( @"Failed to setup audio session, error: %@", error );
    }
    else
    {
        NSLog( @"Success to setup audio session" );
    }
}

- (BOOL) play
{
    NSLog(@"play audio");
    if ( !self.isAudioQueueCreated )
    {
        [self p_createAudioQueue];
        
        for (NSInteger i = 0; i < kNumAQBufs; ++i)
        {
            [self enqueueBuffer:audioQueueBuffer[i]];
        }
        
        UInt32 outNumberOfFramesPrepared = 0;
        OSStatus status = AudioQueuePrime( audioQueue, 0, &outNumberOfFramesPrepared );
        if ( status != noErr )
        {
            NSLog( @"AudioQueuePrime Failed, error:%d", (int)status );
            return NO;
        }
        NSLog( @"outNumberOfFramesPrepared = %u", (unsigned int)outNumberOfFramesPrepared );
    }
    OSStatus status = AudioQueueStart(audioQueue, NULL);
    if ( status != noErr )
    {
        NSLog( @"AudioQueueStart Failed, error:%d", (int)status );
        return NO;
    }
    self.state = CHW_AUDIO_STATE_PLAYING;
    return YES;
}

- (BOOL) pause
{
    if ( self.state == CHW_AUDIO_STATE_PLAYING )
    {
        OSStatus status = AudioQueuePause( audioQueue );
        if ( status != noErr )
        {
            NSLog( @"AudioQueuePause Failed, error:%d", (int)status );
            return NO;
        }
        
        self.state = CHW_AUDIO_STATE_PAUSE;
        return YES;
    }
    
    NSLog( @"AudioQueuePause Failed, due to not playing" );
    return NO;
}

- (BOOL) p_createAudioQueue
{
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
    
    AudioStreamBasicDescription format;
    memset(&format, 0, sizeof(format));
    format.mSampleRate          = 44100;
    format.mFormatID            = kAudioFormatLinearPCM;
    format.mFormatFlags         = kLinearPCMFormatFlagIsFloat;
    //format.mFormatFlags         = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    format.mChannelsPerFrame    = 1;
    format.mBitsPerChannel      = 16;
    format.mBytesPerFrame       = (format.mBitsPerChannel / 8) * format.mChannelsPerFrame;
    format.mFramesPerPacket     = 1;
    format.mBytesPerPacket      = format.mBytesPerFrame * format.mFramesPerPacket;
    
    /*
     AudioStreamBasicDescription format;
     memset(&format, 0, sizeof(format));
     format.mSampleRate          = 44100;
     format.mFormatID            = kAudioFormatLinearPCM;
     format.mFormatFlags         = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
     format.mChannelsPerFrame    = 1;
     format.mBitsPerChannel      = 16;
     format.mBytesPerFrame       = (format.mBitsPerChannel / 8) * format.mChannelsPerFrame;
     format.mFramesPerPacket     = 1;
     format.mBytesPerPacket      = format.mBytesPerFrame * format.mFramesPerPacket;
     */
    
    //    if (audioStreamBasicDesc_.mFormatID != kAudioFormatULaw) {
    //        audioStreamBasicDesc_.mBytesPerPacket = 0;
    //        audioStreamBasicDesc_.mFramesPerPacket = _audioCodecContext->frame_size;
    //        audioStreamBasicDesc_.mBytesPerFrame = 0;
    //        audioStreamBasicDesc_.mChannelsPerFrame = _audioCodecContext->channels;
    //        audioStreamBasicDesc_.mBitsPerChannel = 0;
    //    }
    
    //OSStatus status = AudioQueueNewOutput( &audioStreamBasicDesc, audioQueueOutputCallback, (__bridge void*)self, NULL, NULL, 0, &audioQueue );
    //OSStatus status = AudioQueueNewOutput( &format, audioQueueOutputCallback, (__bridge void*)self, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &audioQueue );
    OSStatus status = AudioQueueNewOutput( &audioStreamBasicDesc, audioQueueOutputCallback, (__bridge void*)self, NULL, NULL, 0, &audioQueue );
    if (status != noErr) {
        NSLog(@"Could not create new audio queue. error = %d", (int)status );
        return NO;
    }
    
    status = AudioQueueAddPropertyListener( audioQueue, kAudioQueueProperty_IsRunning, audioQueueIsRunningCallback, (__bridge void*)self );
    if (status != noErr) {
        NSLog(@"Could not add propery listener. (kAudioQueueProperty_IsRunning)");
        return NO;
    }
    
    for (NSInteger i = 0; i < kNumAQBufs; ++i) {
        /*
        status = AudioQueueAllocateBufferWithPacketDescriptions(audioQueue,
                                                                audioStreamBasicDesc.mSampleRate * kAudioBufferSeconds / 8,
                                                                audioCodecContext->sample_rate * kAudioBufferSeconds / (audioCodecContext->frame_size + 1),
                                                                &audioQueueBuffer[i]);
         */
        //int inBufferByteSize = audioStreamBasicDesc.mSampleRate * kAudioBufferSeconds * 3 / 8;
        int inBufferByteSize = 9192;
        //NSLog( @"buffer size:%d", inBufferByteSize );
        status = AudioQueueAllocateBuffer( audioQueue, inBufferByteSize, &audioQueueBuffer[i] );
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

- (void) p_debugAudioStream:(NSData*)data
{
    static NSString *debug_audio_file = @"audio_stream.pcm";
    NSString *fullpathFilename = [CHWUtilities documentsPath:debug_audio_file];

    // if file exsits, clear all contents
    {
        static BOOL firstRun = YES;
        if ( firstRun )
        {
            NSData *emptyData = [NSData new];
            [emptyData writeToFile:fullpathFilename atomically:NO];
            
            NSError *error = nil;
            NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:fullpathFilename
                                                                                            error:&error];
            NSAssert( error == nil && [fileDictionary fileSize] == 0, @"fatal error" );
            
            firstRun = NO;
        }
    }
    
    long long beforeFilesize = [CHWUtilities getFileSizeInBytes:fullpathFilename];
    [CHWUtilities appendData:data ToFile:fullpathFilename];
    long long afterFilesize = [CHWUtilities getFileSizeInBytes:fullpathFilename];
    
    NSLog( @"%@ file size : %lld => %lld", fullpathFilename, beforeFilesize, afterFilesize );
}

- (OSStatus)enqueueBuffer:(AudioQueueBufferRef)buffer
{
    OSStatus status = noErr;
    
    if (buffer) {

        AudioTimeStamp bufferStartTime;
        buffer->mAudioDataByteSize = 0;
        buffer->mPacketDescriptionCount = 0;
        
        if ( [self.audioFifo isEmpty] )
        {
            NSLog( @"audio fifo is empty when enqueueBuffer 1st called" );
            return status;
        }
        
        while ( YES )
        {
            if ( [self.audioFifo isEmpty] && self.currentAudioFrame == nil ) break;
            
            if ( self.currentAudioFrame == nil )
            {
                self.currentAudioFrame = [self.audioFifo dequeue];
                //NSLog( @"audio frame count=%d", self.audioFifo.frameCount );
            }
            int decodedAudioDataSize = [[self.currentAudioFrame data] length];
            if ( buffer->mAudioDataBytesCapacity - buffer->mAudioDataByteSize >= decodedAudioDataSize )
            {
                memcpy((uint8_t *)buffer->mAudioData + buffer->mAudioDataByteSize, [self.currentAudioFrame.data bytes], decodedAudioDataSize );
                buffer->mAudioDataByteSize += decodedAudioDataSize;
                
                // for dump audio raw data to debug
                const BOOL AUDIO_STREAM_DUMP = NO;
                if ( AUDIO_STREAM_DUMP )
                {
                    [self p_debugAudioStream:self.currentAudioFrame.data];
                }
                
                self.currentAudioFrame = nil;                
            }
            else
            {
                break;
            }
        }

        
        /*
        buffer->mAudioDataByteSize = buffer->mAudioDataBytesCapacity;
        for (int i = 0; i < buffer->mAudioDataByteSize/sizeof(int); ++i)
        {
            ((int*)buffer->mAudioData)[i] = (int)rand(); // refill the buffer
        }
        */
        
        status = AudioQueueEnqueueBuffer(audioQueue, buffer, 0, NULL);
        if (status != noErr) {
            NSLog(@"Could not enqueue buffer.");
        }
    }
    
    return status;
}

@end
