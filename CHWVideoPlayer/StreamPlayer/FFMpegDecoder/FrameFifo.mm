//
//  FrameFifo.cpp
//  Lifestamp
//
//  Created by Arton on 5/16/14.
//  Copyright (c) 2014 Arton. All rights reserved.
//

#include <cassert>
#include "FrameFifo.h"

using namespace std;

FrameFifo::FrameFifo()
{
    mLock = [NSLock new];
    mMaxTime = 0.0;
    mBytes = 0;
}

void FrameFifo::push( vector<uint8> a_frame, double a_time )
{
    [mLock lock];
    {
        mFifo.push( a_frame );
        mTime.push( a_time );
        assert( a_time >= mMaxTime );
        mMaxTime = a_time;
        mBytes += a_frame.size();
    }
    [mLock unlock];
}

vector<uint8> FrameFifo::pop()
{
    vector<uint8> retFrame;
    [mLock lock];
    {
        if ( mFifo.size() > 0 )
        {
            retFrame = mFifo.front();
            mFifo.pop();
            mTime.pop();
            mBytes -= retFrame.size();
        }
    }
    [mLock unlock];
    return retFrame;
}

// return negtive if the fifo is empty
double FrameFifo::getFrontFrameSecond() const
{
    double result = -100.0;
    [mLock lock];
    {
        if ( !mTime.empty() )
        {
            result = mTime.front();
        }
    }
    [mLock unlock];
    return result;
}

int FrameFifo::getCount() const
{
    int result = 0;
    [mLock lock];
    {
        result = mFifo.size();
    }
    [mLock unlock];
    return result;
}

bool FrameFifo::isEmpty() const
{
    return getCount() == 0;
}

double FrameFifo::getMaxTime() const
{
    return mMaxTime;
}

void FrameFifo::clear()
{
    [mLock lock];
    {
        assert( mFifo.size() == mTime.size() );
        while ( !mFifo.empty() )
        {
            mFifo.pop();
            mTime.pop();
        }
        mMaxTime = 0.0;
        mBytes = 0;
    }
    [mLock unlock];
}

long long FrameFifo::getBytes() const
{
    return mBytes;
}