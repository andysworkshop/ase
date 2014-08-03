/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include "config/stm32plus.h"
#include "config/gpio.h"
#include "config/timing.h"


using namespace stm32plus;


/**
 * This example will verify the basic operation of the STM32F429 by alternately flashing the
 * white and blue LEDs on PD10 and PD11 at 1Hz. If you can successfully run this test then you
 * have verified the following aspects of the board:
 *
 *   1. The MCU powers up and you've got SWD/SWCLK connectivity.
 *   2. PD10 and PD11 are OK.
 *   3. The core clock is correctly sourced from the HSI.
 */

class Blink {

  public:

    /*
     * LED pins on port D
     */

    enum {
      WHITE_LED = 10,
      BLUE_LED  = 11
    };


    /*
     * run the test
     */

    void run() {

      // initialise the LED pins for output

      GpioD<DefaultDigitalOutputFeature<WHITE_LED,BLUE_LED> > pd;

      // loop forever switching it on and off with a 1 second
      // delay in between each cycle

      for(;;) {

        pd[WHITE_LED].reset();
        pd[BLUE_LED].set();
        MillisecondTimer::delay(1000);

        pd[WHITE_LED].set();
        pd[BLUE_LED].reset();
        MillisecondTimer::delay(1000);
      }
    }
};


/*
 * Main entry point
 */

int main() {

  // set up SysTick at 1ms resolution
  MillisecondTimer::initialise();

  Blink blink;
  blink.run();

  // not reached
  return 0;
}
