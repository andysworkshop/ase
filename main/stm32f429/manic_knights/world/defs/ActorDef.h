/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */


#pragma once


/*
 * Definition of an actor (auto-animated entity)
 */

struct ActorDef {
  AnimationType PathType;   // moving or static

  uint8_t PathCount;        // number of paths to be followed by this actor
  const PathDef *Paths;     // array of path definitions
};
