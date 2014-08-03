/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include "Application.h"


/*
 * constructor
 */

Actor::Actor(Panel& panel,const ActorDef& def,uint16_t fpgaSpriteIndex)
  : _def(def) {

  uint16_t i;

  // allocate array space

  _paths=reinterpret_cast<PathBase **>(malloc(sizeof(PathBase)*def.PathCount));

  // create each array element

  for(i=0;i<def.PathCount;i++) {

    if(def.PathType==AnimationType::MOVING)
      _paths[i]=new MovingPath(panel,def.Paths[i],fpgaSpriteIndex);
    else
      _paths[i]=new StaticPath(panel,def.Paths[i],fpgaSpriteIndex);
  }

  // initialise the first path

  _currentPath=0;
  _paths[_currentPath]->restart(0);
}


/*
 * Update the path for this actor
 */

void Actor::update(float time,const Point& bgTopLeft) {

  // check if this path has finished

  if(_paths[_currentPath]->hasFinished(time)) {

    // hide this path's sprite

    _paths[_currentPath]->hide();

    // update to the next path or reset to the beginning

    _currentPath++;

    if(_currentPath==_def.PathCount)
      _currentPath=0;

    // initialise the new path

    _paths[_currentPath]->restart(time);
  }

  // update the path

  _paths[_currentPath]->update(time,bgTopLeft);
}
