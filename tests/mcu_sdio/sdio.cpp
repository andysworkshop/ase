/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include "config/stm32plus.h"
#include "config/sdcard.h"
#include "config/filesystem.h"
#include "Error.h"

using namespace stm32plus;


/**
 * This example will verify the connectivity to a FAT formatted microSD card inserted into
 * the chassis on the board. The SDIO peripheral will be powered up and an instance of a FAT
 * file system driver will be created. This test will verify that...

 *   1. You've got the wiring to the SD card chassis correct.
 *   2. Your PLL_Q divider (see System.c) is yielding a clock speed that's compatible with SDIO.
 *   3. Your SDIO SD card actually has a FAT16 or FAT32 filesystem.
 */

class SdioTest {

  public:

    enum {
      WHITE_LED = 10,
      BLUE_LED  = 11
    };

    void run() {

      SdioDmaSdCard sdcard;

      if(errorProvider.hasError())
        Error::display(1);

      FileSystem *fs;
      NullTimeProvider timeProvider;

      if(!FileSystem::getInstance(sdcard,timeProvider,fs))
        Error::display(2);

      // it worked, light up the white led and lock up

      GpioD<DefaultDigitalOutputFeature<WHITE_LED> > pd;
      pd[WHITE_LED].reset();
      for(;;);
    }
};


/*
 * Main entry point
 */

int main() {

  // set up SysTick at 1ms resolution
  MillisecondTimer::initialise();

  SdioTest test;
  test.run();

  // not reached
  return 0;
}
