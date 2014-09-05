//
//  CHWAVInfo.m
//  Lifestamp
//
//  Created by Arton on 5/18/14.
//  Copyright (c) 2014 Arton. All rights reserved.
//

#import "CHWAVInfo.h"

@implementation CHWAVInfo

- (NSString*) stringAVSampleFormat:(enum AVSampleFormat)format
{
    /* libav audio sample format ( ref: libav\libavutil\samplefmt.h )
     enum AVSampleFormat {
     AV_SAMPLE_FMT_NONE = -1,
     AV_SAMPLE_FMT_U8,          ///< unsigned 8 bits
     AV_SAMPLE_FMT_S16,         ///< signed 16 bits
     AV_SAMPLE_FMT_S32,         ///< signed 32 bits
     AV_SAMPLE_FMT_FLT,         ///< float
     AV_SAMPLE_FMT_DBL,         ///< double
     
     AV_SAMPLE_FMT_U8P,         ///< unsigned 8 bits, planar
     AV_SAMPLE_FMT_S16P,        ///< signed 16 bits, planar
     AV_SAMPLE_FMT_S32P,        ///< signed 32 bits, planar
     AV_SAMPLE_FMT_FLTP,        ///< float, planar
     AV_SAMPLE_FMT_DBLP,        ///< double, planar
     
     AV_SAMPLE_FMT_NB           ///< Number of sample formats. DO NOT USE if linking dynamically
     };
     */
    
    switch ( format )
    {
        case AV_SAMPLE_FMT_U8:  return @"AV_SAMPLE_FMT_U8";
        case AV_SAMPLE_FMT_S16: return @"AV_SAMPLE_FMT_S16";
        case AV_SAMPLE_FMT_S32: return @"AV_SAMPLE_FMT_S32";
        case AV_SAMPLE_FMT_FLT: return @"AV_SAMPLE_FMT_FLT";
        case AV_SAMPLE_FMT_DBL: return @"AV_SAMPLE_FMT_DBL";
        case AV_SAMPLE_FMT_U8P: return @"AV_SAMPLE_FMT_U8P";
        case AV_SAMPLE_FMT_S16P: return @"AV_SAMPLE_FMT_S16P";
        case AV_SAMPLE_FMT_S32P: return @"AV_SAMPLE_FMT_S32P";
        case AV_SAMPLE_FMT_FLTP: return @"AV_SAMPLE_FMT_FLTP";
        case AV_SAMPLE_FMT_DBLP: return @"AV_SAMPLE_FMT_DBLP";
        default:
            return @"AV_SAMPLE_FMT_OTHER";
    }
}

- (void) dump
{
    NSLog( @"=============== video info =================" );
    NSLog( @"video fps:%lf", self.fps );
    NSLog( @"video length: %f", self.durationUsecs / 1000000.0 );
    NSLog( @"video width=%d, height=%d", self.videoWidth, self.videoHeight );
    NSLog( @"audio channel:%u", self.audioChannel );
    NSLog( @"audio sample rate:%u", self.audioSampleRate );
    NSLog( @"audio sample format: %@", [self stringAVSampleFormat:self.audioSampleFormat] );
    NSLog( @"audio bits per sample:%u", self.audioBitsPerSample );
    NSLog( @"--------------------------------------------" );
}

@end
