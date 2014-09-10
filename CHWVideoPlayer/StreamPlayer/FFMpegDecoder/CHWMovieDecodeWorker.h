#import <Foundation/Foundation.h>
#import "avformat.h"
#import "avcodec.h"
#import "avio.h"
#import "swscale.h"
#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CHWVideoFrameFifo.h"
#import "CHWAVInfo.h"
#import "CHWAudioPlayer.h"

@interface CHWMovieDecodeWorker : NSObject
{
	AVFormatContext *pFormatCtx;
    AVFrame *pFrame;
    AVPacket packet;
	AVPicture picture;
    AVPacket *_packet, _currentPacket;
}

// Arton added -->

@property (nonatomic, retain) CHWVideoFrameFifo *videoFifo;
@property (nonatomic, retain) CHWVideoFrameFifo *audioFifo;
@property (nonatomic, retain) CHWAVInfo *avInfo;

@property (nonatomic, retain) CHWAudioPlayer *audioPlayer;

// Arton added <--

/* Seek to closest keyframe near specified time */
-(void)seekTime:(double)seconds;

// Arton added -->
- (id)initWithVideo:(NSString *)moviePath usesTcp:(BOOL)usesTcp decodeAudioBySoftware:(BOOL)bDecodeAudioBySoftware;

- (void) dumpVideoInfo;
- (void) p_dumpAudioInfo;
- (double) nextVideoFrameTime;
- (CHWFrameSec*) getNextVideoFrameSec;
- (void) setOutputWidth:(int)width andHeight:(int)height;
- (void) startDecode;
// Arton added <--

@end