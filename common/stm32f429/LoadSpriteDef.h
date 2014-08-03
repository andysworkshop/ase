/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#pragma once


/**
 * Definition for a sprite to be loaded using CMD_LOAD
 */

struct LoadSpriteDef {
  uint16_t SpriteNumber;      // sprite number (0..511)
  uint32_t SramAddress;       // pixel address on the screen (y * 360) + x
  uint32_t FlashAddress;      // flash address of the graphic
  uint16_t PixelWidth;        // width of this sprite in pixels
  uint32_t NumPixels;         // total number of pixels
  uint16_t RepeatX;           // number of times to repeat on X axis (minimum = 1)
  uint16_t RepeatY;           // number of times to repeat on Y axis (minimum = 1)
  uint8_t Visible;            // 1 if visible, 0 if hidden
  uint16_t FirstX;            // first visible X column (or zero if fully on screen)
  uint16_t LastX;             // last visible X column (or 359 if fully on screen)
  uint16_t FirstY;            // first visible Y column (or zero if fully on screen)
  uint16_t LastY;             // last visible Y column (or 639 if fully on screen)
};
