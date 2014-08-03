/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include "Application.h"


/*
 * Constructor
 */

MovingPath::MovingPath(Panel& p,const PathDef& def,uint16_t fpgaSpriteIndex)
  : PathBase(p,def,fpgaSpriteIndex) {

  // horizontal flag

  _horizontal=def.StartY==def.EndY;

  // set change extent

  if(_horizontal)
    _easingFunction->setTotalChangeInPosition(static_cast<float>(_def.EndX-_def.StartX+1));
  else
    _easingFunction->setTotalChangeInPosition(static_cast<float>(_def.EndY-_def.StartY+1));
}


/*
 * Update the position using the easing function
 */

void MovingPath::doUpdate(float time,const Point& /* bgTopLeft */,Point& myPos) {

  float newPosition;
  int16_t newPoint;

  // get the new position

  switch(_def.EasingInOutMode) {

    case EasingMode::IN:
      newPosition=_easingFunction->easeIn(time-_timeBase);
      break;

    case EasingMode::OUT:
      newPosition=_easingFunction->easeOut(time-_timeBase);
      break;

    case EasingMode::INOUT:
      newPosition=_easingFunction->easeInOut(time-_timeBase);
      break;
  }

  if(_horizontal) {
    myPos.X=_def.StartX+static_cast<int16_t>(newPosition);
    myPos.Y=_def.StartY;
    newPoint=myPos.X;
  }
  else {
    myPos.X=_def.StartX;
    myPos.Y=_def.StartY+static_cast<int16_t>(newPosition);
    newPoint=myPos.Y;
  }

  // update the sprite number if the position has changed

  if(newPoint!=_lastPoint) {

    if(_currentSpriteNumber==_def.LastSpriteNumber) {
      _currentSpriteNumber=_def.FirstSpriteNumber;
      _currentSpriteDef=_spriteArray;
    }
    else {
      _currentSpriteNumber++;
      _currentSpriteDef++;
    }

    // remember the new last position

    _lastPoint=newPoint;
  }
}


/*
 * Restart this path walk at the given elapsed time
 */

void MovingPath::restart(float timeBase) {
  _currentSpriteNumber=_def.FirstSpriteNumber;
  _currentSpriteDef=_spriteArray;
  _lastPoint=-1;
  _timeBase=timeBase;
}


/*
 * Check if this path has finished
 */

bool MovingPath::hasFinished(float time) const {
  return time-_timeBase==_def.EasingDuration;
}
