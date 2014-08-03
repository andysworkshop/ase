/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */


#pragma once


namespace Error {
  
  /**
   * This helper function will light up the blue LED on PD11, flashing a number
   * of times to indicate an error code
   */

  static void display(uint8_t code) {
  
    using namespace stm32plus;

    uint8_t i;

    GpioD<DefaultDigitalOutputFeature<11> > pd;

    for(;;) {

      // flash the blue led quickly 'code' number of times

      for(i=0;i<code;i++) {

        pd[11].reset();
        MillisecondTimer::delay(250);
        pd[11].set();
        MillisecondTimer::delay(250);
      }

      // wait for a second after flashing

      MillisecondTimer::delay(1000);
    }
  }
}
