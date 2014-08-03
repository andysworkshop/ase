/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#pragma once


/**
 * Definition for a sprite to be moved using CMD_MOVE_PARTIAL
 */

struct MoveSpriteDef {
  uint16_t SpriteNumber;      // sprite number (0..511)
  uint32_t SramAddress;       // pixel address on the screen (y * 360) + x
  uint16_t FirstX;            // first visible X column (or zero if fully on screen)
  uint16_t LastX;             // last visible X column (or 359 if fully on screen)
  uint16_t FirstY;            // first visible Y column (or zero if fully on screen)
  uint16_t LastY;             // last visible Y column (or 639 if fully on screen)
};
