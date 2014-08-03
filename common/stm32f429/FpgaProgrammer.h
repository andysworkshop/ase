/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */


#pragma once

using namespace stm32plus;

extern uint32_t BitFileStart,BitFileSize;


/**
 * Utility class to program the FPGA from a bit file compiled into flash. See the examples and
 * utilities for how to include an ASM file that compiles in the bit file.
 */

class FpgaProgrammer {

  protected:
    
    /*
     * FPGA GPIO pins
     */
    
    enum {
      PROG_B = 5,     // PD5
      INIT_B = 13,    // PC13
      DONE   = 15,    // PC15
      CCLK   = 2,     // PC2
      DIN    = 0,     // PA0
    };
    
    /*
     * LED pins
     */
  
    enum {
      WHITE_LED = 10
    };
    
    GpioC<
      DefaultDigitalOutputFeature<CCLK>,
      DefaultDigitalInputFeature<INIT_B,DONE>
    > pc;

    GpioD<DefaultDigitalOutputFeature<PROG_B,WHITE_LED>> pd;
    GpioA<DefaultDigitalOutputFeature<DIN>> pa;

  public:
    void program();
};


inline void FpgaProgrammer::program() {

  uint8_t *ptr,nextByte,i;
  bool doneFlag,toggle;
  uint32_t count,bitSize;

  // set up the pins for easier access
  
  GpioPinRef progb=pd[PROG_B];
  GpioPinRef initb=pc[INIT_B];
  GpioPinRef done=pc[DONE];
  GpioPinRef cclk=pc[CCLK];
  GpioPinRef din=pa[DIN];
  
  // hold PROG_B low for a few ms and bring the clock low

  progb.reset();
  cclk.reset();
  MillisecondTimer::delay(10);
  progb.set();

  // INIT_B must now go high indicating that the FPGA is ready to receive data.
  // Give it 5 seconds before giving up.

  pd[WHITE_LED].reset();

  uint32_t start=MillisecondTimer::millis();
  while(!initb.read())
    if(MillisecondTimer::hasTimedOut(start,5000))
      Error::display(1);

  pd[WHITE_LED].set();

  // supply the data and clocks until INIT_B goes low (error) or DONE goes
  // high (finished).

  // probably unnecessary, but there is a defined min time between INIT_B(low) and first CCLK

  MillisecondTimer::delay(1);

  doneFlag=false;
  count=0;
  bitSize=reinterpret_cast<uint32_t>(&BitFileSize);
  toggle=true;

  for(ptr=reinterpret_cast<uint8_t *>(&BitFileStart);;ptr++) {

    if(!doneFlag && done.read())
      doneFlag=true;

    // check for error

    if(!doneFlag && !initb.read())
      Error::display(2);

    // check for end

    if(count==bitSize)
      break;

    // read the next byte

    nextByte=*ptr;

    /*
     * Generate clocks for the data. The max Spartan 3 CCLK is 66MHz (no compression) / 20MHz
     * (with compression).
     */

    for(i=0;i<8;i++) {

      // set DIN

      if((nextByte & 0x80)==0)
        din.reset();
      else
        din.set();

      // ensure clock is low

      cclk.reset();

      // shift byte for next output

      nextByte<<=1;

      // bring clock high (data transfer)

      cclk.set();
    }

    count++;
    if(count % 1000==0) {
      pd[WHITE_LED].setState(toggle);
      toggle^=true;
    }
  }

  /*
   * Docs say that there may be some extra CCLK cycles at the end of the bitstream
   * but is not clear as to whether they're included in the .bit file or not. To be
   * safe we'll generate extra cycles if DONE has not gone high
   */

  while(!done.read()) {

    if(!initb.read())
      Error::display(3);

    cclk.reset();
    cclk.set();
  }
  
  // light off
  
  pd[WHITE_LED].set();
}
