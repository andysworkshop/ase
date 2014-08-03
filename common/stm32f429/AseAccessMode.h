/*
* This file is a part of the open source stm32plus library.
* Copyright (c) 2011,2012,2013,2014 Andy Brown <www.andybrown.me.uk>
* Please see website for licensing terms.
*/

#pragma once


#include "LoadSpriteDef.h"
#include "MoveSpriteDef.h"
#include "AseCommands.h"


/**
 * The AseAccessMode implements the methods required of an stm32plus "access mode" that's
 * used to isolate the access to an LCD panel away from the graphics library. This means that
 * we can use the full power of the stm32plus graphics library after implementing just these
 * simple methods.
 */

using namespace stm32plus;


class AseAccessMode {

  protected:
  
    /*
     * GPIO pins
     */
  
    enum {
      LCD_RESET  = 1,     // PA1
      FPGA_BUSY  = 14,    // PC14
      FPGA_RESET = 9,     // PB9
    };

    uint32_t _busOutputRegister;
    GpioPinRef _busyPin;
    GpioPinRef _fpgaResetPin;
    
  public:
    AseAccessMode();
    void reset();
    void resetFpga() const;

    void writeCommand(uint16_t command) const;
    void writeCommand(uint16_t command,uint16_t parameter) const;
    void writeData(uint16_t value) const;
    void writeDataAgain(uint16_t value) const;
    void writeMultiData(uint32_t howMuch,uint16_t value) const;
    uint16_t readData() const;

    void writeFpgaCommand(uint16_t value) const;

    void rawTransfer(const void *buffer,uint32_t numWords) const;

    void loadSprite(const LoadSpriteDef& sd) const;
    void moveSprite(const MoveSpriteDef& md) const;
    void hideSprite(uint16_t spriteNumber) const;
    void showSprite(uint16_t spriteNumber) const;
    void spriteMode() const;
    void waitBusyEnd() const;
    void waitBusyStart() const;
};


/**
 * Constructor
 */

inline AseAccessMode::AseAccessMode() {

  // initialise and remember the busy pin

  GpioC<DefaultDigitalInputFeature<FPGA_BUSY>> pc;
  _busyPin=pc[FPGA_BUSY];

  // initialise the FPGA reset pin

  GpioB<DefaultDigitalOutputFeature<FPGA_RESET>> pb;
  _fpgaResetPin=pb[FPGA_RESET];

  // this is the address of the data output ODR register in the normal peripheral region.

  _busOutputRegister=GPIOE_BASE+offsetof(GPIO_TypeDef,ODR);

  // pins 0..10 to output, 50MHz slew rate

  GpioPinInitialiser::initialise(
      GPIOE,
      GPIO_Pin_0 | GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_3 | GPIO_Pin_4 | GPIO_Pin_5 | GPIO_Pin_6 | GPIO_Pin_7 | GPIO_Pin_8 | GPIO_Pin_9 | GPIO_Pin_10,
      Gpio::OUTPUT);

  // initialise to WR = high (inactive)

  GPIO_Write(GPIOE,0x400);
}


/**
 * Hard-reset the panel
 */

inline void AseAccessMode::reset() {

  GpioA<DefaultDigitalOutputFeature<LCD_RESET>> pa;
  
  // let the power stabilise

  MillisecondTimer::delay(10);

  // reset sequence

  pa[LCD_RESET].set();
  MillisecondTimer::delay(5);
  pa[LCD_RESET].reset();
  MillisecondTimer::delay(50);
  pa[LCD_RESET].set();
  MillisecondTimer::delay(50);
}


/**
 * Write a command to the FPGA. The 16-bit parameter is written as a 10-bit
 * value directly to the bus and WR is toggled.
 * @param value The value to write. Bits above 0..9 should be zero.
 */

inline void AseAccessMode::writeFpgaCommand(uint16_t value) const {

  // 20ns low, 20ns high = 25MHz max toggle rate

  __asm volatile(
    " str  %[value_low],  [%[data]]   \n\t"     // port <= value (WR = 0)
    " dsb                             \n\t"     // synchronise data
    " str  %[value_low],  [%[data]]   \n\t"     // port <= value (WR = 0)
    " dsb                             \n\t"     // synchronise data
    " str  %[value_low],  [%[data]]   \n\t"     // port <= value (WR = 0)
    " dsb                             \n\t"     // synchronise data
    " str  %[value_high],  [%[data]]  \n\t"     // port <= value (WR = 1)
    " dsb                             \n\t"     // synchronise data
    " str  %[value_high],  [%[data]]  \n\t"     // port <= value (WR = 1)
    " dsb                             \n\t"     // synchronise data
    " str  %[value_high],  [%[data]]  \n\t"     // port <= value (WR = 1)
    " dsb                             \n\t"     // synchronise data

    :: [value_low]  "l" (value),                // input value (WR = 0)
       [value_high] "l" (value | 0x400),        // input value (WR = 1)
       [data]       "l" (_busOutputRegister)    // the bus
  );
}


/**
 * Write a command to the LCD
 * @param command The command to write
 */

inline void AseAccessMode::writeCommand(uint16_t value) const {

  writeFpgaCommand(value & 0xff);
  writeFpgaCommand(value >> 8);
}


/**
 * Write a data value to the panel
 * @param value The data value to write
 */

inline void AseAccessMode::writeData(uint16_t value) const {

  writeFpgaCommand(value & 0xff);
  writeFpgaCommand((value >> 8) | 0x200);     // RS = 1
}


/**
 * Write a command to the panel that takes a parameter
 * @param command The command to write
 * @param parameter The parameter to the command
 */

inline void AseAccessMode::writeCommand(uint16_t command,uint16_t parameter) const {
  writeCommand(command);
  writeData(parameter);
}


/**
 * Write multiple data. A possible optimisation point that we can't take advantage of
 * in this access mode
 * @param howMuch How many pixels
 * @param value The pixel
 */

inline void AseAccessMode::writeMultiData(uint32_t howMuch,uint16_t value) const {
  while(howMuch--)
    writeData(value);
}


/**
 * Write the same data again to the panel - no optimisation possible
 * @param value The data value to write
 */

inline void AseAccessMode::writeDataAgain(uint16_t value) const {
  writeData(value);
}


/**
 * Read a data value from the panel
 * @return always zero (not supported)
 */

inline uint16_t AseAccessMode::readData() const {
  return 0;
}


/**
 * Bulk copy data to the panel
 * @param buffer data source
 * @param numWords number of words to transfer
 */

inline void AseAccessMode::rawTransfer(const void *buffer,uint32_t numWords) const {

  const uint16_t *ptr=static_cast<const uint16_t *>(buffer);

  // shift all the pixels

  while(numWords--)
    writeData(*ptr++);
}


/**
 * Load the sprite definition into the FPGA
 * @param sd The sprite definition structure
 */

inline void AseAccessMode::loadSprite(const LoadSpriteDef& sd) const {

  writeFpgaCommand(AseCommands::CMD_LOAD);
  writeFpgaCommand(sd.SpriteNumber);                // sprite number
  writeFpgaCommand(sd.SramAddress & 0x3ff);         // addr-low
  writeFpgaCommand(sd.SramAddress >> 10);           // addr-high
  writeFpgaCommand(sd.PixelWidth);                  // pixel width
  writeFpgaCommand(sd.NumPixels & 0x3ff);           // pixel size (low)
  writeFpgaCommand(sd.NumPixels >> 10);             // pixel size (high)
  writeFpgaCommand(sd.FlashAddress & 0xff);         // flash low
  writeFpgaCommand((sd.FlashAddress >> 8) & 0xff);  // flash mid
  writeFpgaCommand(sd.FlashAddress >> 16);          // flash high
  writeFpgaCommand(sd.RepeatX);                     // repeat x
  writeFpgaCommand(sd.RepeatY);                     // repeat y
  writeFpgaCommand(sd.Visible);                     // visible
  writeFpgaCommand(sd.FirstX);                      // first X column
  writeFpgaCommand(sd.LastX);                       // last X column
  writeFpgaCommand(sd.FirstY);                      // first Y row
  writeFpgaCommand(sd.LastY);                       // last Y row
}


/**
 * Set the FPGA to sprite mode
 */

inline void AseAccessMode::spriteMode() const {
  writeFpgaCommand(AseCommands::CMD_SPRITE);
}


/**
 * Wait for the busy period to end (assumes busy at the moment of the call)
 */

inline void AseAccessMode::waitBusyEnd() const {
  while(_busyPin.read());
}


/**
 * Wait for the busy period to start (assumes not busy at the moment of the call)
 */

inline void AseAccessMode::waitBusyStart() const {
  while(!_busyPin.read());
}


/**
 * Reset the FPGA
 */

inline void AseAccessMode::resetFpga() const {

  // hold high for 5ms (way more than enough)

  _fpgaResetPin.set();
  MillisecondTimer::delay(5);

  // set back to low

  _fpgaResetPin.reset();
  MillisecondTimer::delay(5);
}


/**
 * Move a sprite to a new position and make it visible
 * @param md The move definition
 */

inline void AseAccessMode::moveSprite(const MoveSpriteDef& md) const {

  writeFpgaCommand(AseCommands::CMD_MOVE_PARTIAL);
  writeFpgaCommand(md.SpriteNumber);          // sprite number
  writeFpgaCommand(md.SramAddress & 0x3ff);   // addr (lo 10)
  writeFpgaCommand(md.SramAddress >> 10);     // addr (hi 8)
  writeFpgaCommand(md.FirstX);                // first X column
  writeFpgaCommand(md.LastX);                 // last X column
  writeFpgaCommand(md.FirstY);                // first Y row
  writeFpgaCommand(md.LastY);                 // last Y row
}


/**
 * Hide a sprite
 * @param spriteNumber The sprite to hide
 */

inline void AseAccessMode::hideSprite(uint16_t spriteNumber) const {
  writeFpgaCommand(AseCommands::CMD_HIDE);
  writeFpgaCommand(spriteNumber);             // sprite number
}


/**
 * Show a sprite
 * @param spriteNumber The sprite to show
 */

inline void AseAccessMode::showSprite(uint16_t spriteNumber) const {
  writeFpgaCommand(AseCommands::CMD_SHOW);
  writeFpgaCommand(spriteNumber);             // sprite number
}
