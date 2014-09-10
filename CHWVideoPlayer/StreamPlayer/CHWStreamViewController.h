//
//  CHWStreamViewController.h
//
//  ref: DFURTSPPlayer
//  which is 
//  Created by Bogdan Furdui on 3/7/13.
//  Copyright (c) 2013 Bogdan Furdui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHWVideoProgressView.h"

@class CHWMovieDecodeWorker;

@interface CHWStreamViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UILabel *fpsLabel;
@property (nonatomic, retain) IBOutlet UILabel *durationLabel;
@property (nonatomic, retain) IBOutlet UILabel *currentLabel;
@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) IBOutlet CHWVideoProgressView *playtimeProgress;
@property (nonatomic, retain) CHWMovieDecodeWorker *video;

- (IBAction)playButtonAction:(id)sender;

@end
