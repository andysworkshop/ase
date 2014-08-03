/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#pragma once


/*
 * Definition of an actor's path. A path starts and finishes at a point in the world. The
 * path should be horizontal or vertical. The actor is eased between the points using the
 * easing function to allow for acceleration and deceleration.
 */

struct PathDef {
  int16_t StartX,StartY;          // the starting point in world pixels
  int16_t EndX,EndY;              // the ending point in world pixels

  uint16_t FirstSpriteNumber;     // first sprite index
  uint16_t LastSpriteNumber;      // last sprite index

  EasingType EasingFunction;      // the easing function used to move the sprite
  EasingMode EasingInOutMode;     // the easing mode (in,out,inout)
  float EasingDuration;           // total duration, in frames
  float EasingParameter1;         // optional. used if easing function has parameters
  float EasingParameter2;         // optional. used if easing function has parameters
};
