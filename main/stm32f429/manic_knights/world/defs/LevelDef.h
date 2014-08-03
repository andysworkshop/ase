/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#pragma once


/*
 * Definition of a level
 */

struct LevelDef {
  const uint16_t *Tiles;            // The tile array (30*20)
  uint16_t ActorCount;              // number of actors in the array below
  const ActorDef *ActorDefs;        // pointer to array of actors
};
