/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include "Application.h"


/*
 * Constructor
 */

World::World(Panel& panel,const LevelDef& ldef)
  : _levelDef(ldef),
    _panel(panel),
    _background(panel,ldef) {

  createActors(panel);
}


/*
 * Destructor
 */

World::~World() {

  for(int i=0;i<_levelDef.ActorCount;i++)
    delete &_actors[i];

  free(_actors);
}


/*
 * Update the components of the world
 */

void World::update(const Buttons& buttons,uint32_t frame_counter) {

  Point topLeft(_background.getTopLeft());
  uint16_t i;
  float f;

  // sample the navigation buttons

  if(buttons.isRightPressed() && topLeft.Y>0)
    topLeft.Y-=4;
  else if(buttons.isLeftPressed() && topLeft.Y!=1920-640)
    topLeft.Y+=4;

  if(buttons.isUpPressed() && topLeft.X>0)
    topLeft.X-=4;
  else if(buttons.isDownPressed() && topLeft.X!=1280-360)
    topLeft.X+=4;

  // set the new position

  _background.setTopLeft(topLeft);

  // update the components

  _background.update();

  f=static_cast<float>(frame_counter);
  for(i=0;i<_levelDef.ActorCount;i++)
    _actors[i]->update(f,_background.getTopLeft());
}


/*
 * Create the actors for this level
 */

void World::createActors(Panel& panel) {

  uint16_t i,fpgaSpriteIndex;

  // actor has a non-default constructor with reference members

  _actors=reinterpret_cast<Actor **>(malloc(sizeof(Actor)*_levelDef.ActorCount));

  fpgaSpriteIndex=FIRST_PATH_SPRITE;

  // initialise array

  for(i=0;i<_levelDef.ActorCount;i++)
    _actors[i]=new Actor(panel,_levelDef.ActorDefs[i],fpgaSpriteIndex++);
}
