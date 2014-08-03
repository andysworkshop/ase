/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#pragma once


/*
 * Base class for path management. A sprite is animated by continually reloading its
 * slot in the FPGA with the appropriate image definition. If the sprite is offscreen
 * then it's hidden and will not consume FPGA resources.
 */

class PathBase {

  protected:
    Panel& _panel;
    const PathDef& _def;
    EasingBase *_easingFunction;
    uint16_t _currentSpriteNumber;
    uint16_t _fpgaSpriteIndex;
    const PathSpriteDef *_spriteArray;
    const PathSpriteDef *_currentSpriteDef;
    bool _hidden;
    float _timeBase;

  protected:
    EasingBase *createEasingFunction() const;

  public:
    PathBase(Panel& p,const PathDef& def,uint16_t fpgaSpriteIndex);
    virtual ~PathBase();

    void update(float time,const Point& bgTopLeft);
    void hide();
    bool isOnScreen(const Point& myPos,const Point& bgTopLeft) const;

    virtual void restart(float timebase)=0;
    virtual bool hasFinished(float time) const=0;
    virtual void doUpdate(float time,const Point& bgTopLeft,Point& p)=0;
};
