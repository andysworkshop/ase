/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#pragma once


/*
 * Path management class. Will manage the animation of a non-moving sprite
 * througout its frames
 */

class StaticPath : public PathBase {

  public:
    StaticPath(Panel& p,const PathDef& def,uint16_t fpgaSpriteIndex);
    virtual ~StaticPath() {}

    // overrides from PathBase

    virtual void restart(float timebase) override;
    virtual void doUpdate(float time,const Point& bgTopLeft,Point& p);
    virtual bool hasFinished(float time) const override;
};
