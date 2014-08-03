/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include "Application.h"


/*
 * Constructor. Start the world off at the bottom left
 */

Background::Background(Panel& panel,const LevelDef& ldef)
  : _panel(panel),
    _levelDef(ldef),
    _topLeft(1280-360,1920-640),
    _lastTopLeft(0,0) {

  // constants for the load

  _lsd.PixelWidth=64;
  _lsd.NumPixels=64*64;
  _lsd.RepeatX=1;
  _lsd.RepeatY=1;
  _lsd.Visible=1;
}


/*
 * Update the 77 slots reserved for the background tiles in the FPGA
 */

void Background::update() {

  const uint16_t *tile,*row_tile;
  uint8_t x,y,left_firstx,top_firsty;
  uint16_t spriteNumber;
  int16_t px,py;
  int32_t sram_address,row_sram_address;

  // check if update required

  if(_lastTopLeft==_topLeft)
    return;

  // get a pointer to the first tile

  row_tile=&_levelDef.Tiles[((_topLeft.Y / 64)*20)+(_topLeft.X / 64)];

  // calculate overlapping pixels at each edge

  left_firstx=_topLeft.X % 64;
  top_firsty=_topLeft.Y % 64;

  // there are (10+1)*(6+1) = 77 slots reserved for the scene, slots 0..76

  spriteNumber=0;

  // initial sram address

  row_sram_address=0;

  if(top_firsty)
    row_sram_address-=top_firsty*360;

  if(left_firstx)
    row_sram_address-=left_firstx;

  py=-top_firsty;

  for(y=0;y<11;y++) {

    tile=row_tile;
    sram_address=row_sram_address;

    // values unique to the row

    _lsd.FirstY=y==0 ? top_firsty : 0;
    _lsd.LastY=y==10 ? top_firsty-1 : 63;

    px=-left_firstx;

    for(x=0;x<7;x++) {

      if(px<360 && py<640) {

        // values unique to the individual sprite

        _lsd.SpriteNumber=spriteNumber++;
        _lsd.FirstX=x==0 ? left_firstx : 0;
        _lsd.LastX=px+64>360 ? 63-(px+64-360) : 63;
        _lsd.SramAddress=sram_address>=0 ? sram_address : 524288+sram_address;
        _lsd.FlashAddress=BackgroundSprites[*tile].FlashAddress;

        // load the sprite

        _panel.getAccessMode().loadSprite(_lsd);
      }
      else
        _panel.getAccessMode().hideSprite(spriteNumber++);

      // move to the adjacent sprite on the X axis

      sram_address+=64;
      px+=64;
      tile++;
    }

    // advance to the next row

    row_tile=row_tile+20;
    row_sram_address+=360*64;
    py+=64;
  }

  // done

  _lastTopLeft=_topLeft;
}
