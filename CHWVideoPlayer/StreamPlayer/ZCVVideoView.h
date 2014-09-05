//
//  ZCVVideoView.h
//  PushCam
//
//  Created by Arton on 8/8/14.
//  Copyright (c) 2014 Arton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZCVVideoView : UIImageView

typedef void(^TimeChangedHandler)(int second);
typedef void(^InfoGetHandler)(NSString *error, int width, int height, float videoSeconds);
typedef void(^VoidHandler)();

typedef NS_ENUM( NSUInteger, ZCV_VIDEO_PLAY_STATE )
{
    ZCV_VIDEO_STATE_INIT,
    ZCV_VIDEO_STATE_INFO_GET,
    ZCV_VIDEO_STATE_PAUSE,
    ZCV_VIDEO_STATE_STOP,
    ZCV_VIDEO_STATE_PLAYING,
    ZCV_VIDEO_STATE_REACH_END
};

typedef void(^StateChangedHandler)(ZCV_VIDEO_PLAY_STATE oldState, ZCV_VIDEO_PLAY_STATE newState);

@property (nonatomic, copy) StateChangedHandler stateChangedHandler;
@property (nonatomic, assign) ZCV_VIDEO_PLAY_STATE videoState;
@property (nonatomic, copy) NSString *videoUrlString;

- (void) load:(NSString*)videoUrlString WithInfoGetHandler:(InfoGetHandler)infoGetHandler;
- (void) playWithTimeChangedHandler:(TimeChangedHandler)timeChangedHandler AndReachEndHandler:(VoidHandler)reachEndHandler;
- (void) pause;
- (void) stop;

@end
