//
//  CHWVideoProgressView.h
//  Lifestamp
//
//  Created by Arton on 5/16/14.
//  Copyright (c) 2014 Arton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CHWVideoProgressView : UIProgressView

typedef void(^ProgressClickHandler)(float percentage); /* 0 ~ 1.0 */

@property (nonatomic, copy) ProgressClickHandler progressClickHandler;

@end
