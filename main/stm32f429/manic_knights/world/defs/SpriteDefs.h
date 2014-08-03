/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */


#pragma once


/*
 * Constants
 */

enum {
  FIRST_PATH_SPRITE = 100
};


/*
 * Definition of a background 64x64 sprite
 */

struct BackgroundSpriteDef {
  uint16_t SpriteNumber;
  uint32_t FlashAddress;
};


/*
 * Definition of a path (moving) sprite. The sprite number is assigned during the initialisation
 */

struct PathSpriteDef {
  uint32_t FlashAddress;
  uint16_t PixelWidth;
  uint16_t PixelHeight;
};


/*
 * All sprites
 */

struct AllSpritesDef {
  uint16_t BackgroundSpritesCount;
  const BackgroundSpriteDef *BackgroundSprites;

  uint16_t PathSpritesCount;
  const PathSpriteDef *PathSprites;
};

extern const AllSpritesDef AllSprites;
