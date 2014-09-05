//
//  FrameFifo.h
//  Lifestamp
//
//  Created by Arton on 5/16/14.
//  Copyright (c) 2014 Arton. All rights reserved.
//

#ifndef __Lifestamp__FrameFifo__
#define __Lifestamp__FrameFifo__

#include <queue>
#include <vector>

typedef unsigned char uint8;

class FrameFifo
{
public:
    FrameFifo();
    void push( std::vector<uint8> a_frame, double a_time );
    std::vector<uint8> pop();
    bool isEmpty() const;
    int getCount() const;
    double getMaxTime() const;  // not used for the time being
    double getFrontFrameSecond() const;
    void clear();
    long long getBytes() const;
    
private:
    std::queue<std::vector<uint8> > mFifo;
    std::queue<double> mTime; // in sec
    double mMaxTime; // in sec
    NSLock *mLock;
    long long mBytes;
};

#endif /* defined(__Lifestamp__FrameFifo__) */
