/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#pragma once


/*
 * Higher level actor class that manages the movement of an actor through a number of paths.
 * Paths should be closed, i.e. the last path should end at the start of the first path.
 */

class Actor {

  protected:
    const ActorDef& _def;
    PathBase **_paths;
    uint16_t _currentPath;

  public:
    Actor(Panel& panel,const ActorDef& def,uint16_t fpgaSpriteIndex);
    ~Actor();

    void update(float time,const Point& bgTopLeft);
};


/*
 * Destructor
 */

inline Actor::~Actor() {

  for(int i=0;i<_def.PathCount;i++)
    delete _paths[i];

  free(_paths);
}
