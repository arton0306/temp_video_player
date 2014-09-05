//
//  ZCVStreamViewController.h
//
//  ref: DFURTSPPlayer
//  which is 
//  Created by Bogdan Furdui on 3/7/13.
//  Copyright (c) 2013 Bogdan Furdui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZCVVideoProgressView.h"

@class RTSPPlayer;

@interface ZCVStreamViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UILabel *fpsLabel;
@property (nonatomic, retain) IBOutlet UILabel *durationLabel;
@property (nonatomic, retain) IBOutlet UILabel *currentLabel;
@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) IBOutlet ZCVVideoProgressView *playtimeProgress;
@property (nonatomic, retain) RTSPPlayer *video;

- (IBAction)playButtonAction:(id)sender;

@end
