/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include "config/stm32plus.h"
#include "config/gpio.h"
#include "config/timing.h"
#include "Error.h"
#include "FpgaProgrammer.h"


using namespace stm32plus;

/*
 * This example will verify the basic operation of the FPGA and its ability to be programmed
 * by the MCU. If this works then the FPGA will blink LED3 at a rate of 1Hz. It does this be outputting
 * a 1Hz signal to the DEBUG pin which is mapped to PC1 on the MCU. The code here maps that incoming
 * signal on to the LED output pin. This example verifies the following aspects of the design:
 *
 *   1. The FPGA powers up and can be programmed by the MCU.
 *   2. The 40MHz oscillator is up and running.
 *   3. User I/O pins on the FPGA can communicate with the MCU.
 *
 * You must have built "blink.bit" in the fpga example directory.
 */

class fpga_blink {

  /*
   * pins
   */

  enum {
    WHITE_LED = 10,   // PD10
    DEBUG_PIN = 1     // PC1
  };


  public:

    void run() {

      FpgaProgrammer programmer;
      programmer.program();

      blinkTest();
    }


    void blinkTest() {

      GpioC<DefaultDigitalInputFeature<DEBUG_PIN>> pc;
      GpioD<DefaultDigitalOutputFeature<WHITE_LED>> pd;

      // all we're going to do is copy the state of pc[1] to pd[10]

      for(;;)
        pd[WHITE_LED].setState(pc[DEBUG_PIN].read());
    }
};


/*
 * Main entry point
 */

int main() {

  // set up SysTick at 1ms resolution
  MillisecondTimer::initialise();

  fpga_blink program;
  program.run();

  // not reached
  return 0;
}
