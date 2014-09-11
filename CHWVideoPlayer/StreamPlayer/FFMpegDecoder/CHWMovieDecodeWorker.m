#import "CHWMovieDecodeWorker.h"
#import "CHWUtilities.h"
#import "CHWAVInfo.h"
#import "CHWVideoFrameFifo.h"

#define BITS_PER_BYTES 8

@interface CHWMovieDecodeWorker ()

@property (nonatomic, assign) AVCodecContext *videoCodecCtx;
@property (nonatomic, assign) AVCodecContext *audioCodecCtx;
@property (nonatomic, assign) int outputWidth;
@property (nonatomic, assign) int outputHeight;

@property (nonatomic, assign) int videoStreamIndex;
@property (nonatomic, assign) int audioStreamIndex;

@property (nonatomic, assign) struct SwsContext *imgConvertCtx;
@property (nonatomic, assign) AVFrame *frameRGB;
@property (nonatomic, assign) uint8_t *frameRGB_Buffer;

@property (nonatomic, assign) BOOL isDecodeAudioBySoftware;

-(void)savePicture:(AVPicture)pFrame width:(int)width height:(int)height index:(int)iFrame;
@end

@implementation CHWMovieDecodeWorker

#pragma mark - setter and getter




#pragma mark - init and dealloc
- (id)initWithVideo:(NSString *)moviePath usesTcp:(BOOL)usesTcp decodeAudioBySoftware:(BOOL)bDecodeAudioBySoftware
{
	if (!(self=[super init])) return nil;
 
    self.videoFifo = [CHWVideoFrameFifo new];
    self.audioFifo = [CHWVideoFrameFifo new];
    self.isDecodeAudioBySoftware = bDecodeAudioBySoftware;
    self.isDecodeAudioBySoftware = YES;
    
    // Register all formats and codecs
    avcodec_register_all();
    av_register_all();
    avformat_network_init();
    
    // Set the RTSP Options
    AVDictionary *opts = 0;
    if (usesTcp) 
        av_dict_set(&opts, "rtsp_transport", "tcp", 0);

    NSLog( @"open %@", moviePath );
    if (avformat_open_input(&pFormatCtx, [moviePath UTF8String], NULL, &opts) !=0 ) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't open file\n");
        return nil;
    }
    
    // Retrieve stream information
    if (avformat_find_stream_info(pFormatCtx,NULL) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't find stream information\n");
        return nil;
    }
    
    // Find the first video stream
    self.videoStreamIndex=-1;
    self.audioStreamIndex=-1;
    {
        for (int i=0; i<pFormatCtx->nb_streams; i++) {
            if (pFormatCtx->streams[i]->codec->codec_type==AVMEDIA_TYPE_VIDEO) {
                NSLog(@"found video stream: %d", i);
                self.videoStreamIndex=i;
            }
            
            if (pFormatCtx->streams[i]->codec->codec_type==AVMEDIA_TYPE_AUDIO) {
                self.audioStreamIndex=i;
                NSLog(@"found audio stream: %d", i);
            }
        }
        
        if ( self.videoStreamIndex==-1 && self.audioStreamIndex==-1) {
            NSLog( @"no video/audio stream" );
            return nil;
        }
    }
    
    // Get a pointer to the codec context
    _videoCodecCtx = NULL;
    _audioCodecCtx = NULL;
    {
        if ( self.videoStreamIndex >= 0 )
        {
            _videoCodecCtx = p_getCodecCtxWithCodec( pFormatCtx, self.videoStreamIndex );
        }
        if ( self.audioStreamIndex >= 0 )
        {
            _audioCodecCtx = p_getCodecCtxWithCodec( pFormatCtx, self.audioStreamIndex );
            self.audioPlayer = [[CHWAudioPlayer alloc] initWithAVCodecContext:_audioCodecCtx AndAudioFifo:self.audioFifo];
        }
    }
    
    [self setOutputWidth:_videoCodecCtx->width andHeight:_videoCodecCtx->height];
    
    self.avInfo = [CHWAVInfo new];
    self.avInfo.fps = av_q2d( pFormatCtx->streams[self.videoStreamIndex]->avg_frame_rate );
    NSLog( @"!!! fps = %lf", av_q2d( pFormatCtx->streams[self.videoStreamIndex]->avg_frame_rate ) );
    self.avInfo.durationUsecs = pFormatCtx->duration;
    self.avInfo.videoWidth = self.videoCodecCtx->width;
    self.avInfo.videoHeight = self.videoCodecCtx->height;
    self.avInfo.audioChannel = _audioCodecCtx->channels;
    self.avInfo.audioSampleFormat = _audioCodecCtx->sample_fmt;
    self.avInfo.audioSampleRate = _audioCodecCtx->sample_rate;
    self.avInfo.audioBitsPerSample = av_get_bytes_per_sample( _audioCodecCtx->sample_fmt ) * BITS_PER_BYTES;
    
    // [self dumpVideoInfo];
    [self.avInfo dump];
    [self p_dumpAudioInfo];
    
    return self;
}

- (void) setOutputWidth:(int)width andHeight:(int)height
{
    self.outputWidth = width;
    self.outputHeight = height;
    
    // set converter
    {
        av_free( self.frameRGB );
        self.frameRGB = avcodec_alloc_frame();
        assert( self.frameRGB != NULL );
        
        // Create a buffer for converted frame
        av_free( self.frameRGB_Buffer );
        self.frameRGB_Buffer = (uint8_t *)av_malloc( avpicture_get_size( PIX_FMT_RGB24, self.outputWidth, self.outputHeight ) );
        assert( self.frameRGB_Buffer != NULL );
        // Assign appropriate parts of buffer to image planes in self.frameRGB
        // Note that self.frameRGB is an AVFrame, but AVFrame is a superset
        // of AVPicture
        avpicture_fill( (AVPicture *)self.frameRGB, self.frameRGB_Buffer, PIX_FMT_RGB24,
                       self.outputWidth, self.outputHeight );
        
        sws_freeContext( self.imgConvertCtx );
        int sws_flags =  SWS_FAST_BILINEAR;
        self.imgConvertCtx = sws_getContext(_videoCodecCtx->width, _videoCodecCtx->height, _videoCodecCtx->pix_fmt,
                                            self.outputWidth, self.outputHeight, PIX_FMT_RGB24,
                                            sws_flags, NULL, NULL, NULL );
    }
}

- (void)dealloc
{
    NSLog( @"RTSPPlayer dealloc" );
	// Free scaler
    av_free( self.frameRGB_Buffer );
    self.frameRGB_Buffer = nil;
    av_free( self.frameRGB );
    self.frameRGB = nil;
	sws_freeContext( self.imgConvertCtx );
    self.imgConvertCtx = nil;
    
	// Free RGB picture
	avpicture_free(&picture);
    
    // Free the packet that was allocated by av_read_frame
    av_free_packet(&packet);
	
    // Free the YUV frame
    av_free(pFrame);
	
    // Close the video file
    if (pFormatCtx) avformat_close_input(&pFormatCtx);
}

#pragma mark - private functions
AVCodecContext *p_getCodecCtxWithCodec( AVFormatContext * aFormatCtx, int aStreamIndex )
{
    AVCodecContext * codecCtx = aFormatCtx->streams[aStreamIndex]->codec;
    AVCodec * codec = avcodec_find_decoder( codecCtx->codec_id );
    if ( codec == NULL )
    {
        NSLog( @"can not dind decoder for %d stream", aStreamIndex );
    }
    else
    {
        NSLog( @"decoder founded for %d stream", aStreamIndex );
        if ( avcodec_open2( codecCtx, codec, NULL ) < 0 )
            NSLog( @"can not open decoder for %d stream", aStreamIndex );
        else
            NSLog( @"open decoder successfully for %d stream", aStreamIndex );
    }
    
    return codecCtx;
}

// result is in self.frameRGB
- (void) p_convertToRGBFrameWithCodecContext:(AVCodecContext*)videoCodecCtx
                                   fromFrame:(AVFrame*)decodedFrame
{
    sws_scale( self.imgConvertCtx,
              (const uint8_t * const *)(decodedFrame->data), decodedFrame->linesize,
              0, videoCodecCtx->height,
              self.frameRGB->data, self.frameRGB->linesize );

}

- (BOOL) p_isDecodedFrameEnough
{
    return ( self.videoFifo.frameCount >= 20 ) && ( [self.audioFifo getFrameTotalTimeInSec] > 3 );
    //return ( self.videoFifo.frameCount >= 3 );
}

- (NSMutableData*) p_convertToPpmFrame:(AVFrame*)aDecodedFrame withWidth:(int)width andHeight:(int) height
{
    // Write ppm header to a temp buffer
    char ppmHeader[30];
    int const headerSize = sprintf( ppmHeader, "P6\n%d %d\n255\n", width, height );
    
    // Write ppm totally
    int const contentSize = height * width * 3; // =aDecodedFrame->linesize[0]
    int const ppmSize = headerSize + contentSize;
    NSAssert( ppmSize != 0, @"ppmSize wrong" );
    
    NSMutableData *result = [[NSMutableData alloc] initWithCapacity:ppmSize];
    [result appendBytes:ppmHeader length:headerSize];
    [result appendBytes:aDecodedFrame->data[0] length:contentSize];
    
    return result;
}

#pragma mark - decode!
- (void) startDecode
{
    NSAssert( ![NSThread isMainThread], @"Fatal error: should not be executed in main thread" );

    /*
    if (audioStreamIndex > -1 ) {
        NSLog(@"set up audiodecoder");
        [self setupAudioDecoder];
    }
    */
	
    /******************************************
     Frame & Buffer Init
     ******************************************/
    
    // Declare frame
    AVFrame *decodedFrame = avcodec_alloc_frame();
    assert( decodedFrame != NULL );
    
    /*
    AVFrame *pFrameRGB = avcodec_alloc_frame();
    assert( pFrameRGB != NULL );
    
    // Create a buffer for converted frame
    uint8_t * buffer = (uint8_t *)av_malloc( avpicture_get_size( PIX_FMT_RGB24, self.outputWidth, self.outputHeight ) );
    
    // Assign appropriate parts of buffer to image planes in pFrameRGB
    // Note that pFrameRGB is an AVFrame, but AVFrame is a superset
    // of AVPicture
    avpicture_fill( (AVPicture *)pFrameRGB, buffer, PIX_FMT_RGB24,
                    self.outputWidth, self.outputHeight );
    */
    
    /******************************************
     Reading the Data
     ******************************************/
    int frameFinished;
    int videoFrameIndex = 0;
    int audioFrameIndex = 0;
    int packetIndex = 0;
			
    /***********************************
     ***********************************/
    
    while ( true )
    {
        bool stop_flag = false;
        
        /*
        // determine whether be forced stop
        if ( mIsReceiveStopSignal )
        {
            mVideoFifo.clear();
            mAudioFifo.clear();
            mIsReceiveStopSignal = false;
            stop_flag = true;
        }
        
        // determine whether seek or not
        if ( mIsReceiveSeekSignal )
        {
            const long long INT64_MIN = (-0x7fffffffffffffffLL - 1);
            const long long INT64_MAX = (9223372036854775807LL);
            // timestamp = seconds * AV_TIME_BASE
            int ret = avformat_seek_file( formatCtx, -1, INT64_MIN, (double)mSeekMSec / 1000 * AV_TIME_BASE, INT64_MAX, 0);
            DEBUG() << "============================================================ seek " << (double)mSeekMSec / 1000 << " return:" << ret;
            if ( ret < 0 )
            {
                seekState( false );
                is_seek_or_new_play = false;
                DEBUG() << "============================================================ seek fail";
            }
            else
            {
                seekState( true );
                mAudioTuner.flush();
                is_seek_or_new_play = true;
                mVideoFifo.clear();
                mAudioFifo.clear();
            }
            mIsReceiveSeekSignal = false;
        }
        */
        
        // read a frame
        if ( av_read_frame( pFormatCtx, &packet ) < 0 || stop_flag )
        {
            // there may some audio samples in soundtouch internal buffer, but we ignore them
            break;
        }
        
        // the index is just for debug
        ++packetIndex;
        
        // Is this packet from the video stream?
        if ( packet.stream_index == self.videoStreamIndex )
        {
            // Decode video frame
            int const bytesUsed = avcodec_decode_video2( _videoCodecCtx, decodedFrame, &frameFinished, &packet );
            if ( bytesUsed != packet.size )
            {
                // check if one packet is corresponding to one frame
                // DEBUG() << bytesUsed << " " << packet.size;
            }
            
            // Did we get a video frame?
            if ( frameFinished )
            {
                double const dtsSec = packet.dts * av_q2d(pFormatCtx->streams[self.videoStreamIndex]->time_base );
                double const ptsSec = packet.pts * av_q2d(pFormatCtx->streams[self.videoStreamIndex]->time_base );
                [self p_convertToRGBFrameWithCodecContext:_videoCodecCtx fromFrame:decodedFrame];
                BOOL isAvDumpNeeded = NO;
                if ( isAvDumpNeeded )
                {
                    NSData *ppmFrame = [self p_convertToPpmFrame:self.frameRGB withWidth:self.outputWidth andHeight:self.outputHeight];
                    [self p_savePPM:ppmFrame index:videoFrameIndex];
                }
                NSLog( @"video frame, packet ndx:%4d, video frame ndx:%4d, dts:%8.4lf, pts:%8.4lf", packetIndex, videoFrameIndex, dtsSec, ptsSec );
                
                // fill in our ppm buffer
                // TODO: the origin code use ptsSec, check it
                NSData *frameData = [NSData dataWithBytes:self.frameRGB->data[0] length:self.outputWidth*self.outputHeight*3];
                CHWFrameSec *frameSec = [[CHWFrameSec alloc] initWithData:frameData
                                                                   AndPts:dtsSec
                                                                 AndWidth:self.outputWidth
                                                                AndHeight:self.outputHeight];
                [self.videoFifo enqueue:frameSec];
                
                ++videoFrameIndex;
            }
            else
            {
                // DEBUG() << "p ndx:" << packetIndex << "    (unfinished video packet)";
            }
            
            // Free the packet that was allocated by av_read_frame
            av_free_packet( &packet );
        }
        else if ( packet.stream_index == self.audioStreamIndex && !self.isDecodeAudioBySoftware )
        {
            NSData *data = [NSData dataWithBytes:packet.data length:packet.size];
            double const dtsSec = packet.dts * av_q2d( pFormatCtx->streams[self.audioStreamIndex]->time_base );
            double const ptsSec = packet.pts * av_q2d( pFormatCtx->streams[self.audioStreamIndex]->time_base );
            [self.audioFifo enqueue:[[CHWFrameSec alloc] initWithData:data AndPts:ptsSec]];
            //NSLog( @"self.audioFifo frame count: %d", self.audioFifo.frameCount );
            NSLog( @"undecoded audio frame, packet ndx:%4d, audio frame ndx:%4d, dts:%8.4lf, pts:%8.4lf", packetIndex, audioFrameIndex, dtsSec, ptsSec );
            
            BOOL AUDIO_DEBUG = NO;
            if ( AUDIO_DEBUG )
            {
                //NSLog( @"%@", data );
                [self p_debugAudioStream:data];
            }
            
            ++audioFrameIndex;
            av_free_packet( &packet );
        }
        else if ( packet.stream_index == self.audioStreamIndex && self.isDecodeAudioBySoftware )
        {
            avcodec_get_frame_defaults( decodedFrame );
            uint8_t * const packetDataHead = packet.data;
            while ( packet.size > 0 )
            {
                // Decode audio frame
                int const bytesUsed = avcodec_decode_audio4( _audioCodecCtx, decodedFrame, &frameFinished, &packet );
                if ( bytesUsed < 0 )
                {
                    fprintf( stderr, "Error while decoding audio!\n" );
                    assert( false );
                }
                else
                {
                    if ( frameFinished )
                    {
                        /*
                        NSLog( @"channels:%d nb_samples:%d sample_fmt:%d",
                              _audioCodecCtx->channels,
                              decodedFrame->nb_samples,
                              _audioCodecCtx->sample_fmt );
                         */
                        int const data_size = av_samples_get_buffer_size(NULL, _audioCodecCtx->channels,
                                                                         decodedFrame->nb_samples,
                                                                         _audioCodecCtx->sample_fmt, 1);
                        // TODO: investigate why the back-half in decodedFrame->data[0] are all zero
                        NSData *data = [NSData dataWithBytes:decodedFrame->data[0] length:data_size / 2];
                        double const dtsSec = packet.dts * av_q2d( pFormatCtx->streams[self.audioStreamIndex]->time_base );
                        double const ptsSec = packet.pts * av_q2d( pFormatCtx->streams[self.audioStreamIndex]->time_base );
                        [self.audioFifo enqueue:[[CHWFrameSec alloc] initWithData:data AndPts:ptsSec]];
                        
                        BOOL AUDIO_DEBUG = NO;
                        if ( AUDIO_DEBUG )
                        {
                            //NSLog( @"%@", data );
                            [self p_debugAudioStream:data];
                        }

                        //NSLog( @"audio frame, packet ndx:%4d, audio frame ndx:%4d, dts:%8.4lf, pts:%8.4lf", packetIndex, audioFrameIndex, dtsSec, ptsSec );
                        ++audioFrameIndex;
                    }
                    else
                    {
                        // DEBUG() << "p ndx:" << packetIndex << "    (unfinished audio packet)";
                    }
                    packet.data += bytesUsed;
                    packet.size -= bytesUsed;
                }
            }
            packet.data = packetDataHead;
            if (packet.data)
            {
                av_free_packet( &packet );
            }
        }
        else
        {
            // Free the packet that was allocated by av_read_frame
            av_free_packet( &packet );
            // DEBUG() << "p ndx:" << packetIndex << "     packet.stream_index:" << packet.stream_index;
        }
        
        // determine whether decoded frame is enough and determine whether interrupt signal received
        /*
        while ( isAvFrameEnough( fps ) && !mIsReceiveStopSignal && !mIsReceiveSeekSignal )
        {
            if ( is_seek_or_new_play )
            {
                initAVFrameReady( mFirstAudioFrameTime * 1000);
                is_seek_or_new_play = false;
            }
            Sleep::msleep( 1 );
        }
        */
        while ( [self p_isDecodedFrameEnough] )
        {
            usleep( 10000 );
        }
    }

    NSLog( @"video decode done!!" );
    /******************************************
     Release the Resource
     ******************************************/
    
    // Free the YUV frame
    av_free( decodedFrame );
    
    // Close the codec
    if (self.videoCodecCtx) avcodec_close(self.videoCodecCtx);
    if (self.audioCodecCtx) avcodec_close(self.audioCodecCtx);
}

- (void)seekTime:(double)seconds
{
	AVRational timeBase = pFormatCtx->streams[self.videoStreamIndex]->time_base;
	int64_t targetFrame = (int64_t)((double)timeBase.den / timeBase.num * seconds);
	avformat_seek_file(pFormatCtx, self.videoStreamIndex, targetFrame, targetFrame, targetFrame, AVSEEK_FLAG_FRAME);
	avcodec_flush_buffers(self.videoCodecCtx);
}

#pragma mark - for debug
- (void) p_debugAudioStream:(NSData*)data
{
    static NSString *debug_audio_file = @"rtspplayer_audio_stream.pcm";
    NSString *saveFilename = [CHWUtilities documentsPath:debug_audio_file];
    
    static BOOL firstRun = YES;
    if ( firstRun )
    {
        [CHWUtilities purgeFile:saveFilename];
        firstRun = NO;
    }
    
    long long beforeFilesize = [CHWUtilities getFileSizeInBytes:saveFilename];
    [CHWUtilities appendData:data ToFile:saveFilename];
    long long afterFilesize = [CHWUtilities getFileSizeInBytes:saveFilename];
    
    NSLog( @"%@ file size : %lld => %lld", saveFilename, beforeFilesize, afterFilesize );
}

- (void)p_savePPM:(NSData*)data index:(int)iFrame
{
	NSString *fileName;
	fileName = [CHWUtilities documentsPath:[NSString stringWithFormat:@"image%04d.ppm",iFrame]];
    NSLog(@"write image file: %@",fileName);
    [data writeToFile:fileName atomically:YES];
}

#pragma mark - interface
- (double) nextVideoFrameTime
{
    CHWFrameSec *frameSec = [self.videoFifo front];
    if ( !frameSec ) return -1;
    return frameSec.pts;
}

- (CHWFrameSec*) getNextVideoFrameSec
{
    CHWFrameSec *frameSec = [self.videoFifo dequeue];
    return frameSec;
}

#pragma mark - dumper
- (void) p_dumpAudioInfo
{
    NSLog( @"=============== audio more info =================" );
    NSLog( @"audio sample rate:%d", self.audioCodecCtx->sample_rate );
    NSLog( @"audio channel count:%d", self.audioCodecCtx->channels );
    NSLog( @"audio codec id:%d", self.audioCodecCtx->codec_id );
    NSLog( @"audio bits per sample:%d", av_get_bits_per_sample( self.audioCodecCtx->codec_id ) );
    NSLog( @"audio exact bits per sample:%d", av_get_exact_bits_per_sample( self.audioCodecCtx->codec_id ) );
    NSLog( @"audio codec name:%s", avcodec_get_name( self.audioCodecCtx->codec_id ) );
    NSLog( @"--------------------------------------------" );
}

@end
