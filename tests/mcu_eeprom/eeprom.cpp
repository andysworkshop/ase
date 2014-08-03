/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include "config/stm32plus.h"
#include "config/eeprom.h"
#include "config/timing.h"
#include "Error.h"


using namespace stm32plus;


/**
 * This example will verify that the ROHM BR24G32 EEPROM is up and running. A bit pattern will be
 * written to a random location on the EEPROM and then read back for verification. If the EEPROM
 * is functioning correctly then the white LED will be illuminated. If it doesn't work then the
 * blue LED will flash to indicate an error code.
 */

class Eeprom {

  public:

    void run() {

      /*
       * LED pins
       */

      enum {
        WHITE_LED = 10,
        BLUE_LED  = 11
      };

      /*
       * Define a type for the EEPROM
       */

      typedef BR24G32<
        I2C2_Default<I2CTwoByteMasterPollingFeature>    // the EEPROM has 2-byte addresses
      > MyEeprom;

      uint16_t address;
      uint32_t actuallyRead;
      uint8_t i,c,buffer[237];

      /*
       * initialise the LEDs and switch them off
       */

      GpioD<DefaultDigitalOutputFeature<WHITE_LED,BLUE_LED> > pd;
      pd[WHITE_LED].set();
      pd[BLUE_LED].set();

      /*
       * Initialise the BR24G32 on I2C #2. We will be the bus master
       * and we will poll it
       */

      I2C::Parameters params;
      MyEeprom eeprom(params);

      /*
       * Fill a buffer with a simple test pattern
       */

      for(i=0;i<sizeof(buffer);i++)
        buffer[i]=i;

      /*
       * Reset to position zero and write a byte. Note that the SerialEeprom
       * base class inherits from InputStream and OutputStream so you can use
       * the overloaded << and >> operators to write to and read from the EEPROM
       */

      eeprom.seek(0);

      if(!eeprom.writeByte(0xaa))
        Error::display(1);

      /*
       * Let the device settle after write (10ms max, see datasheet)
       */

      MillisecondTimer::delay(10);

      /*
       * Read back the byte and check it
       */

      eeprom.seek(0);
      c=0;

      if(!eeprom.readByte(c) || c!=0xaa)
        Error::display(2);

      /*
       * Write the 237 byte sequence at a random position
       */

      address=rand() % (MyEeprom::SIZE_IN_BYTES-sizeof(buffer));

      eeprom.seek(address);
      if(!eeprom.write(buffer,sizeof(buffer)))
        Error::display(3);

      /*
       * Let the device settle after write (5ms max, see datasheet)
       */

      MillisecondTimer::delay(7);

      /*
       * Clear the buffer and read back the data
       */

      memset(buffer,0,sizeof(buffer));

      eeprom.seek(address);
      if(!eeprom.read(buffer,sizeof(buffer),actuallyRead))
        Error::display(4);

      for(i=0;i<sizeof(buffer);i++)
        if(buffer[i]!=i)
          Error::display(5);

      /*
       * Success, light the white LED
       */

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

  Eeprom eeprom;
  eeprom.run();

  // not reached
  return 0;
}
