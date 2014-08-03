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
 * This test will verify that you've got full communication access to the LCD. A custom 'AseAccessMode'
 * class gives us access to all the features of the stm32plus graphics library. We will use it to display
 * a 'test card' of coloured bars across the top of the screen and a grey scale across most of the bottom.
 * If this works then you will have verified the following:
 *
 *   1. The wiring from the FPGA to the latch is working.
 *   2. The latch is wired correctly.
 *   3. The LCD socket is wired correctly.
 *   4. The LCD backlight generator is functioning correctly.
 *   5. The LCD 2.8V voltage regulator is functioning correctly.
 *   6. The LCD reset line to the MCU is functioning correctly.
 *
 * Note that the LCD declaration is for the type B panel more commonly found on ebay (R61523_Portrait_64K_TypeB).
 * If you have a type A (see my reverse engineering article) then strip off the _TypeB from the end.
 */

class lcd {

  public:
    /*
     * FPGA GPIO pins
     */

    enum {
      FPGA_RESET = 9   // PB9
    };

    /**
     * The access mode that writes to Port E
     */

    AseAccessMode _accessMode;


    /**
     * Run the test
     */

    void run() {

      FpgaProgrammer programmer;
      programmer.program();

      _accessMode.resetFpga();
      lcdTest();

      for(;;);
    }


    /**
     * Draw some coloured bars and a grey scale
     */

    void lcdTest() {

      R61523_Portrait_64K_TypeB<AseAccessMode> gl(_accessMode);
      R61523PwmBacklight<AseAccessMode> backlight(_accessMode);
      Rectangle rc;
      uint16_t i;

      static const uint32_t colours[8]={
        ColourNames::RED,
        ColourNames::GREEN,
        ColourNames::BLUE,
        ColourNames::CYAN,
        ColourNames::MAGENTA,
        ColourNames::YELLOW,
        ColourNames::WHITE,
        ColourNames::BLACK,
      };

      // set the backlight percentage to 75

      backlight.setPercentage(75);

      // draw a block of solid colours

      rc.X=0;
      rc.Y=0;
      rc.Height=gl.getHeight()/9;
      rc.Width=gl.getWidth();

      for(i=0;i<sizeof(colours)/sizeof(colours[0]);i++) {

        gl.setForeground(colours[i]);
        gl.fillRectangle(rc);

        rc.Y+=rc.Height;
      }

      // draw a greyscale

      rc.X=0;
      rc.Width=gl.getWidth()/256;
      rc.Height=gl.getHeight()-rc.Y;

      for(i=0;i<256;i++) {
        gl.setForeground(i | (i << 8) | (i << 16));
        gl.fillRectangle(rc);
        rc.X+=rc.Width;
      }
    }
};


/*
 * Main entry point
 */

int main() {

  // set up SysTick at 1ms resolution
  MillisecondTimer::initialise();

  lcd program;
  program.run();

  // not reached
  return 0;
}
