//
//  ZCVStreamViewController.m
//
//  ref: DFURTSPPlayer
//  which is
//  Created by Bogdan Furdui on 3/7/13.
//  Copyright (c) 2013 Bogdan Furdui. All rights reserved.
//

#import "ZCVStreamViewController.h"
#import "RTSPPlayer.h"
#import "Utilities.h"
#import "ZCVVideoProgressView.h"

@interface ZCVStreamViewController ()
@property (nonatomic, retain) NSTimer *nextFrameTimer;
@property (nonatomic, retain) ZCVFrameSec *frameSec;
@end

@implementation ZCVStreamViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // NSString *thePath=[[NSBundle mainBundle] pathForResource:@"sophie" ofType:@"mov"];
    NSString *thePath=[[NSBundle mainBundle] pathForResource:@"Sawmah-ImBusy(640x360)" ofType:@"mp4"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //self.video = [[RTSPPlayer alloc] initWithVideo:thePath usesTcp:NO];
        
        
        self.video = [[RTSPPlayer alloc] initWithVideo:@"rtsp://media1.law.harvard.edu/Media/policy_a/2012/02/02_unger.mov" usesTcp:NO];//
        
        // video = [[RTSPPlayer alloc] initWithVideo:@"http://www.wowza.com/_h264/BigBuckBunny_115k.mov" usesTcp:NO];
        
        // video = [[RTSPPlayer alloc] initWithVideo:@"http://112.65.235.145/vlive.qqvideo.tc.qq.com/v00113mzdsr.mp4?vkey=03BDF0A68787D1B7937B386F359603E71EB7DD4C2F924DCCD1A956178BAAD4C5B958596242EB5FF8&br=72&platform=0&fmt=mp4&level=3" usesTcp:NO];
        
        [self.video setOutputWidth:426 andHeight:320];
        NSLog( @"start decode %@", thePath );
        [self.video startDecode];
    });
    
    self.durationLabel.text = [NSString stringWithFormat:@"%.1lf", self.video.avInfo.durationUsecs / 1000000.0];
    self.currentLabel.text = @"0";
    [self.playtimeProgress setProgress:0.0];
    /*
    [self.playtimeProgress setProgressClickHandler:^(float percentage) {
        // todo: remove cycle retain 
        [self.playtimeProgress setProgress:percentage];
        [video seekTime:percentage * video.duration];
    }];
    */
    
    //[imageView setContentMode:UIViewContentModeScaleAspectFit];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)playButtonAction:(id)sender {
	[self.playButton setEnabled:NO];
	
	// seek to 0.0 seconds
	// [video seekTime:0.0];
    
    /*
    [_nextFrameTimer invalidate];
	self.nextFrameTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/video.fps
                                                           target:self
                                                         selector:@selector(displayNextFrame:)
                                                         userInfo:nil
                                                          repeats:YES];
    */
    [self p_displayNextFrame];
}

-(void)updateCurrentTimeLabel
{
    /*
    int prev_seconds = [self.currentLabel.text intValue];
    int cur_seconds = self.video.currentTime;
    if ( cur_seconds != prev_seconds )
    {
        prev_seconds = cur_seconds;
        self.currentLabel.text = [NSString stringWithFormat:@"%d", cur_seconds];
        [self.playtimeProgress setProgress:(self.video.currentTime/self.video.duration)];
    }
    */
}

-(void)p_displayNextFrame
{
    self.frameSec = [self.video getNextVideoFrameSec];
    
    UIImage *frame = [self.frameSec toUIImage];

    if ( frame )
    {
        NSAssert( [NSThread isMainThread], @"Fatal error: must be main thread" );
        self.imageView.image = frame;
        [self.fpsLabel setText:[NSString stringWithFormat:@"%.0lf",self.frameSec.pts]];
        [self updateCurrentTimeLabel];
    }

    double delayInSeconds = 1.0 / self.video.avInfo.fps;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self p_displayNextFrame];
    });
}

/*
-(void)displayNextFrame:(NSTimer *)timer
{
    //NSLog( @"displayNextFrame" );
    @autoreleasepool {
        ZCVFrameSec *frameSec = [video getNextVideoFrameSec];
        
        UIImage *frame = [frameSec toUIImage];
        if ( frame )
        {
            //NSAssert( [NSThread isMainThread], @"Fatal error: must be main thread" );
            imageView.image = frame;
            //[fpsLabel setText:[NSString stringWithFormat:@"%.0lf",frameSec.pts]];
            //[self updateCurrentTimeLabel];
        }
    }
}
*/

@end
