#import <Foundation/Foundation.h>
#import "avformat.h"
#import "avcodec.h"
#import "avio.h"
#import "swscale.h"
#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CHWAvFifo.h"
#import "CHWAVInfo.h"

@interface RTSPPlayer : NSObject {
	AVFormatContext *pFormatCtx;
    AVFrame *pFrame;
    AVPacket packet;
	AVPicture picture;

    
    NSLock *audioPacketQueueLock;
    AVCodecContext *_audioCodecContext;
    int16_t *_audioBuffer;
    int audioPacketQueueSize;
    NSMutableArray *audioPacketQueue;
    AVStream *_audioStream;
    NSUInteger _audioBufferSize;
    BOOL _inBuffer;
    AVPacket *_packet, _currentPacket;
    BOOL primed;
}

@property (nonatomic, retain) NSMutableArray *audioPacketQueue;
@property (nonatomic, assign) AVCodecContext *_audioCodecContext;
@property (nonatomic, assign) AudioQueueBufferRef emptyAudioBuffer;
@property (nonatomic, assign) int audioPacketQueueSize;
@property (nonatomic, assign) AVStream *_audioStream;

// Arton added -->

@property (nonatomic, retain) CHWAvFifo *videoFifo;
@property (nonatomic, retain) CHWAvFifo *audioFifo;
@property (nonatomic, retain) CHWAVInfo *avInfo;

// Arton added <--

/* Seek to closest keyframe near specified time */
-(void)seekTime:(double)seconds;
-(void)closeAudio;

- (AVPacket*)readPacket;

// Arton added -->
- (void) dumpVideoInfo;
- (void) dumpAudioInfo;
- (double) nextVideoFrameTime;
- (CHWFrameSec*) getNextVideoFrameSec;
-(id)initWithVideo:(NSString *)moviePath usesTcp:(BOOL)usesTcp;
- (void) setOutputWidth:(int)width andHeight:(int)height;
- (void) startDecode;
// Arton added <--

@end
