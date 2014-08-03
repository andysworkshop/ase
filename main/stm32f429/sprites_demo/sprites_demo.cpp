/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include "config/stm32plus.h"
#include "config/timing.h"
#include "config/display/tft.h"
#include "Error.h"
#include "FpgaProgrammer.h"
#include "AseAccessMode.h"


using namespace stm32plus;
using namespace stm32plus::display;


/**
 */

class SpritesDemo {

  public:

    /*
     * The access mode that writes to Port E
     */

    AseAccessMode _accessMode;

    /*
     * Animation variables
     */

    Point _logoPosition;
    int8_t _logoxdir,_logoydir;

    Point _walkerPosition;
    int8_t _walkerDirection;
    int8_t _walkerSpriteIndex;


    /*
     * The LCD panel type to be used (note that it must be portrait mode)
     */

    typedef R61523_Portrait_64K_TypeB<AseAccessMode> LcdPanel;


    /**
     * Run the test
     */

    void run() {

      // program the FPGA

      FpgaProgrammer programmer;
      programmer.program();

      // reset the FPGA and run the test

      _accessMode.resetFpga();
      spriteTest();

      for(;;);
    }



    void spriteTest() {

      LcdPanel gl(_accessMode);
      R61523PwmBacklight<AseAccessMode> backlight(_accessMode);

      // set the backlight percentage to 90

      backlight.setPercentage(90);

      // put the device into sprite mode

      enableSpriteMode(gl);

      // load the sprites into the FPGA

      loadSprites();

      // animate the sprites

      animateSprites();
    }


    /*
     * Load the sprites used for the demo
     */

    void loadSprites() {

      LoadSpriteDef defs[8]= {
        { 0, 0, 90624,  360, 230400, 1, 1, 1, 0, 359, 0, 639 },     // background
        { 1, 0, 0    ,  112, 45248,  1, 1, 1, 0, 359, 0, 639 },     // andy's workshop
        { 2, 0, 551680, 32,  1024,   1, 1, 0, 0, 359, 0, 639 },     // left1
        { 3, 0, 553984, 32,  1024,   1, 1, 0, 0, 359, 0, 639 },     // left2
        { 4, 0, 556288, 32,  1024,   1, 1, 0, 0, 359, 0, 639 },     // left3
        { 5, 0, 558592, 32,  1024,   1, 1, 0, 0, 359, 0, 639 },     // right1
        { 6, 0, 560896, 32,  1024,   1, 1, 0, 0, 359, 0, 639 },     // right2
        { 7, 0, 563200, 32,  1024,   1, 1, 0, 0, 359, 0, 639 }      // right3
      };

      uint8_t i;

      // load up the sprites

      for(i=0;i<sizeof(defs)/sizeof(defs[0]);i++)
        _accessMode.loadSprite(defs[i]);
    }


    /*
     * Move to sprite mode
     */

    void enableSpriteMode(LcdPanel& gl) {

      // set the 16 to 24 bit colour expansion mode to copy the MSB to the LSBs

      _accessMode.writeCommand(r61523::SET_FRAME_AND_INTERFACE);
      _accessMode.writeData(0x80);
      _accessMode.writeData(0x80);     // EPF = 10 (msb => lsb)

      // set the frame rate to 61Hz. If it's too high then we won't have time to
      // transfer the frame to the graphics memory and corruption will appear at
      // the bottom of the display

      _accessMode.writeCommand(r61523::NORMAL_DISPLAY_TIMING);
      _accessMode.writeData(1);              // BC0 = 1
      _accessMode.writeData(0);
      _accessMode.writeData(26);             // reduce frame rate to 61Hz
      _accessMode.writeData(8);              // BP = 8
      _accessMode.writeData(8);              // FP = 8

      // set WEMODE = 1 to enable automatic wrapping of graphic data from the end
      // of the display window to the start

      _accessMode.writeCommand(r61523::SET_FRAME_AND_INTERFACE);
      _accessMode.writeData(0x82);           // WEMODE = 1
      _accessMode.writeData(0);              // DFM = 0    (5-6-5 colour format in 1 transfer)

      // TE must be enabled

      gl.enableTearingEffect(LcdPanel::TE_VBLANK);

      // the display window must be set to full screen and the display
      // primed for receiving data

      gl.moveTo(0,0,gl.getWidth()-1,gl.getHeight()-1);
      gl.beginWriting();

      // now we're ready to set the mode to sprite

      _accessMode.spriteMode();
    }


    /*
     * Animate our sprites. This is not the most efficient way to do this because it does not
     * make use of the busy period to do 'game' calculations.
     */

    void animateSprites() {

      // set up the animation sequences for the walker

      uint8_t walkerLeftSprites[]= { 2,3,4,3 };
      uint8_t walkerRightSprites[]= { 5,6,7,6 };

      // set the logo position and dimensions

      _logoPosition.X=0;
      _logoPosition.Y=0;
      _logoxdir=2;
      _logoydir=2;

      // set the walker variables

      _walkerPosition.X=328;
      _walkerPosition.Y=0;
      _walkerSpriteIndex=0;
      _walkerDirection=1;

      for(;;) {

        // wait for the next frame

        _accessMode.waitBusyStart();
        _accessMode.waitBusyEnd();

        // animate the parts

        animateLogo();
        animateWalker(walkerLeftSprites,walkerRightSprites);
      }
    }


    /*
     * Animate the logo by bouncing it around the screen
     */

    void animateLogo() {

      MoveSpriteDef msd;

      // reverse directions if the limits are reached

      if(_logoPosition.X+_logoxdir>=248 || _logoPosition.X+_logoxdir<0)
        _logoxdir=-_logoxdir;

      if(_logoPosition.Y+_logoydir>=236 || _logoPosition.Y+_logoydir<0)
        _logoydir=-_logoydir;

      // update the background with the new position

      _logoPosition.X+=_logoxdir;
      _logoPosition.Y+=_logoydir;

      // move the sprite

      msd.SpriteNumber=1;
      msd.FirstX=0;
      msd.FirstY=0;
      msd.LastX=0x3ff;
      msd.LastY=0x3ff;
      msd.SramAddress=(_logoPosition.Y*360)+_logoPosition.X;

      _accessMode.moveSprite(msd);
    }

    void animateWalker(const uint8_t *leftSprites,const uint8_t *rightSprites) {

      const uint8_t *sprites;
      MoveSpriteDef msd;

      sprites=_walkerDirection==1 ? leftSprites : rightSprites;

      // hide the current sprite

      _accessMode.hideSprite(sprites[_walkerSpriteIndex]);

      // reverse direction if the limits are reached

      if(_walkerPosition.Y+_walkerDirection>=608 || _walkerPosition.Y+_walkerDirection<0) {
        _walkerDirection=-_walkerDirection;
        sprites=_walkerDirection==1 ? leftSprites : rightSprites;
      }

      // update the sprite index

      if(_walkerSpriteIndex==3)
        _walkerSpriteIndex=0;
      else
        _walkerSpriteIndex++;

      // update the Y position (this is landscape mode so Y is horizontal)

      _walkerPosition.Y+=_walkerDirection;

      // move the sprite

      msd.SpriteNumber=sprites[_walkerSpriteIndex];
      msd.FirstX=0;
      msd.FirstY=0;
      msd.LastX=0x3ff;
      msd.LastY=0x3ff;
      msd.SramAddress=(_walkerPosition.Y*360)+_walkerPosition.X;

      _accessMode.moveSprite(msd);
    }
};


/*
 * Main entry point
 */

int main() {

  // set up SysTick at 1ms resolution
  MillisecondTimer::initialise();

  SpritesDemo demo;
  demo.run();

  // not reached
  return 0;
}

