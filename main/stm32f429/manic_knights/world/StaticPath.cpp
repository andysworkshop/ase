/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include "Application.h"


/*
 * Constructor
 */

StaticPath::StaticPath(Panel& p,const PathDef& def,uint16_t fpgaSpriteIndex)
  : PathBase(p,def,fpgaSpriteIndex) {

  // set change extent

  _easingFunction->setTotalChangeInPosition(static_cast<float>(_def.LastSpriteNumber-_def.FirstSpriteNumber+1));
}


/*
 * Update the position using the easing function
 */

void StaticPath::doUpdate(float time,const Point& /* bgTopLeft */,Point& myPos) {

  float newPosition;
  uint16_t newSpriteNumber;

  // the position doesn't change

  myPos.X=_def.StartX;
  myPos.Y=_def.StartY;

  // get the new frame index

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

    default:
      newPosition=0;        // not reached
      break;
  }

  newSpriteNumber=static_cast<uint16_t>(newPosition)+_def.FirstSpriteNumber;

  // update the sprite number if the position has changed

  if(newSpriteNumber!=_currentSpriteNumber && newSpriteNumber>=_def.FirstSpriteNumber && newSpriteNumber<=_def.LastSpriteNumber) {

    _currentSpriteNumber=newSpriteNumber;
    _currentSpriteDef=&AllSprites.PathSprites[_currentSpriteNumber];
  }
}


/*
 * Restart this path walk at the given elapsed time
 */

void StaticPath::restart(float timeBase) {
  _currentSpriteNumber=_def.FirstSpriteNumber;
  _currentSpriteDef=_spriteArray;
  _timeBase=timeBase;
}


/*
 * Check if this path has finished
 */

bool StaticPath::hasFinished(float time) const {
  return time-_timeBase==_def.EasingDuration;
}
