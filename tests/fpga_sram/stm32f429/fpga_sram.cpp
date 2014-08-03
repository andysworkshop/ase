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
 * This test will write a continuous pattern to the entire 4Mb SRAM array and then read it back
 * to verify the integrity of the device. The pattern is continually varied with each loop to ensure
 * that each bit at each address is exercised. The test runs continuously. A successful run will
 * light the white LED. If there is any single error at all then the white LED will switch off and
 * the blue light will latch on and stay on. White good. Blue bad.
 *
 * If this test succeeds then you have proved that you have soldered the ISSI 4Mb SRAM device
 * correctly and the bucket-load of pins that connect it to the FPGA are all soldered down.
 */

class fpga_sram {

  /*
   * pins
   */

  enum {
    WHITE_LED = 10,   // PD10
    BLUE_LED  = 11,   // PD11
    DEBUG_PIN = 1     // PC1
  };


  public:

    void run() {

      bool debug;

      GpioC<DefaultDigitalInputFeature<DEBUG_PIN>> pc;
      GpioD<DefaultDigitalOutputFeature<WHITE_LED,BLUE_LED>> pd;

      // program the FPGA

      FpgaProgrammer programmer;
      programmer.program();

      // There's no reset for this test. The SRAM test runs continuously
      // from the moment the 100MHz DCM output is locked.

      for(;;) {

        // continuously show the output of the debug pin. it goes high if
        // there any errors and will stay high.

        debug=pc[DEBUG_PIN].read();
        pd[WHITE_LED].setState(debug);
        pd[BLUE_LED].setState(!debug);
      }
    }
};


/*
 * Main entry point
 */

int main() {

  // set up SysTick at 1ms resolution
  MillisecondTimer::initialise();

  fpga_sram program;
  program.run();

  // not reached
  return 0;
}
