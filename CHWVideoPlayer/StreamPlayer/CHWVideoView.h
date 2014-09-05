//
//  CHWVideoView.h
//  PushCam
//
//  Created by Arton on 8/8/14.
//  Copyright (c) 2014 Arton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CHWVideoView : UIImageView

typedef void(^TimeChangedHandler)(int second);
typedef void(^InfoGetHandler)(NSString *error, int width, int height, float videoSeconds);
typedef void(^VoidHandler)();

typedef NS_ENUM( NSUInteger, CHW_VIDEO_PLAY_STATE )
{
    CHW_VIDEO_STATE_INIT,
    CHW_VIDEO_STATE_INFO_GET,
    CHW_VIDEO_STATE_PAUSE,
    CHW_VIDEO_STATE_STOP,
    CHW_VIDEO_STATE_PLAYING,
    CHW_VIDEO_STATE_REACH_END
};

typedef void(^StateChangedHandler)(CHW_VIDEO_PLAY_STATE oldState, CHW_VIDEO_PLAY_STATE newState);

@property (nonatomic, copy) StateChangedHandler stateChangedHandler;
@property (nonatomic, assign) CHW_VIDEO_PLAY_STATE videoState;
@property (nonatomic, copy) NSString *videoUrlString;

- (void) load:(NSString*)videoUrlString WithInfoGetHandler:(InfoGetHandler)infoGetHandler;
- (void) playWithTimeChangedHandler:(TimeChangedHandler)timeChangedHandler AndReachEndHandler:(VoidHandler)reachEndHandler;
- (void) pause;
- (void) stop;

@end
