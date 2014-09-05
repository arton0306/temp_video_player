//
//  CHWVideoProgressView.m
//  Lifestamp
//
//  Created by Arton on 5/16/14.
//  Copyright (c) 2014 Arton. All rights reserved.
//

#import "CHWVideoProgressView.h"

@implementation CHWVideoProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        NSLog( @"CHWVideoProgressView initWithFrame" );
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        NSLog( @"CHWVideoProgressView initWithCoder" );
        
        [self setTransform:CGAffineTransformMakeScale(1.0, 5.0)];
        
        UITapGestureRecognizer *singleFingerTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(handleSingleTap:)];
        [self addGestureRecognizer:singleFingerTap];
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

//The event handling method
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:recognizer.view];
    float click_pos = location.x;
    float width = recognizer.view.frame.size.width;
    float ratio = click_pos / width;
    NSLog( @"click on x:(%3f/%3f)=>%f", click_pos, width, ratio );
    
    self.progressClickHandler( ratio );
    
    //Do stuff here...
}

@end
