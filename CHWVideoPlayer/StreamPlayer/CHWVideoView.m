//
//  CHWVideoView.m
//  PushCam
//
//  Created by Arton on 8/8/14.
//  Copyright (c) 2014 Arton. All rights reserved.
//

#import "CHWVideoView.h"
#import "CHWMovieDecodeWorker.h"

@interface CHWVideoView()

@property (nonatomic, copy) TimeChangedHandler timeChangedHandler;
@property (nonatomic, copy) InfoGetHandler infoGetHandler;
// @property (nonatomic, copy) VoidHandler readyToDecodeHandler;
@property (nonatomic, copy) VoidHandler reachEndHandler;
@property (nonatomic, copy) VoidHandler stopHandler;
@property (nonatomic, copy) VoidHandler seekDoneHandler;

@property (nonatomic, retain) NSTimer *nextFrameTimer;
@property (nonatomic, retain) CHWMovieDecodeWorker *video;

@end

@implementation CHWVideoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSLog( @"CHWVideoView init" );
        self.videoState = CHW_VIDEO_STATE_INIT;
        // Initialization code
    }
    return self;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

#pragma mark - video play interface
- (void) load:(NSString*)videoUrlString WithInfoGetHandler:(InfoGetHandler)infoGetHandler
{
    self.videoUrlString = videoUrlString;
    self.infoGetHandler = infoGetHandler;
}

- (void) playWithTimeChangedHandler:(TimeChangedHandler)timeChangedHandler AndReachEndHandler:(VoidHandler)reachEndHandler
{
    
}

- (void) pause
{
    
}

- (void) stop
{
    
}

@end
