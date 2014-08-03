/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#pragma once


/*
 * Path management class. Will manage the transition of a sprite along a
 * straight line using an easing function
 */

class MovingPath : public PathBase {

  protected:
    bool _horizontal;         // true if this sprite moves horizontally Y1==Y2
    int16_t _lastPoint;       // the last position of this sprite

  public:
    MovingPath(Panel& p,const PathDef& def,uint16_t fpgaSpriteIndex);
    virtual ~MovingPath() {}

    // overrides from PathBase

    virtual void restart(float timebase) override;
    virtual void doUpdate(float time,const Point& bgTopLeft,Point& p);
    virtual bool hasFinished(float time) const override;
};
