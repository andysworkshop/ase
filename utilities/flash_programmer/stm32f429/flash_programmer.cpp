/*
 * This file is a part of the open source stm32plus library.
 * Copyright (c) 2011,2012,2013,2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include "config/stm32plus.h"
#include "config/sdcard.h"
#include "config/filesystem.h"
#include "memory/scoped_ptr.h"
#include <vector>
#include <string>
#include "Error.h"
#include "FpgaProgrammer.h"


using namespace stm32plus;


/**
 * The flash programmer utility uses the FPGA to program graphics (or any other files really) into
 * the flash IC device. The graphics files must be stored on the SD Card in the same format as the
 * 'flash_spi_program' stm32plus example program: 
 *
 * The SD card must contain an "index.txt" file in the "/spiflash" folder. "/spiflash/index.txt"
 * contains one line per file to flash The line is of the form:
 *
 *   <filename>=<start-address-in-flash-in-decimal>
 *
 * For example:
 *
 *   /spiflash/graphic1.bin=0
 *   /spiflash/graphic2.bin=16384
 *   /spiflash/assets/line.bin=24576
 *
 * Whitespace is not permitted anywhere on the text lines. It is important that each address
 * is a multiple of the 256 byte device page size. If it's not then you will get data corruption.
 * A chip-erase command is used to wipe the device before programming and because this is a large
 * capacity flash IC it can take upwards of 30 seconds for the erase command to complete.
 *
 * The white LED is flashed at varying rates while the programming and verifying is taking place. If anything
 * goes wrong then the blue LED flashes an error code. When it's finished successfully the white LED will
 * flash continuously and rapidly. It can take several minutes to finish so give it time.
 */

class AseFlashProgram {

  // declare the peripheral pointers

  SdioDmaSdCard *_sdcard;
  FileSystem *_fs;

  // declare the program variables

  struct FlashEntry {
    char *filename;
    uint32_t length;
    uint32_t offset;
  };

  /*
   * Pins
   */

  enum {
    WHITE_LED = 10,   // PD10
    DEBUG = 1,        // PC1
    BUSY = 14,        // PC14
    FPGA_RESET = 9    // PB9
  };

  /*
   * commands
   */

  enum {
    CMD_VERIFY     = 0,       // verify page
    CMD_PROGRAM    = 1,       // program page
    CMD_BULK_ERASE = 2,       // bulk erase
    CMD_WRITE_CR   = 3        // write configuration register
  };

  /*
   * Errors
   */

  enum {
    E_SDIO = 1,
    E_FILESYSTEM = 2,
    E_OPEN_INDEX = 3,
    E_OPEN_FILE = 4,
    E_READ_FILE_PAGE = 5,
    E_UNEXPECTED_EOF = 6,
    E_READ_LINE = 7,
    E_BAD_INDEX_FORMAT = 8,
    E_CANNOT_OPEN_DATA = 9,
    E_VERIFY = 10
  };

  std::vector<FlashEntry> _flashEntries;
  GpioPinRef _whiteLed;
  GpioPinRef _debug;
  GpioPinRef _busy;
  bool _ledState;

  GpioE<DefaultDigitalOutputFeature<0,1,2,3,4,5,6,7,8,9,10>> _bus;

  public:

    void run() {

      _ledState=true;

      // program the FPGA

      FpgaProgrammer programmer;
      programmer.program();

      // initialise the white LED

      GpioD<DefaultDigitalOutputFeature<WHITE_LED>> pd;
      _whiteLed=pd[WHITE_LED];

      // initialise debug and busy (inputs)

      GpioC<DefaultDigitalInputFeature<DEBUG,BUSY>> pc;
      _debug=pc[DEBUG];
      _busy=pc[BUSY];

      // initialise the SD card

      _sdcard=new SdioDmaSdCard;

      if(errorProvider.hasError())
        Error::display(E_SDIO);

      // initialise the filesystem on the card

      NullTimeProvider timeProvider;

      if(!FileSystem::getInstance(*_sdcard,timeProvider,_fs))
        Error::display(E_FILESYSTEM);

      // reset FPGA

      resetFpga();

      // read the index file

      readIndexFile();

      // set the configuration register to 00 (serial mode)

      setConfigurationRegister(0);

      // erase the flash device (takes time)

      eraseFlash();

      // write each file

      for(auto it=_flashEntries.begin();it!=_flashEntries.end();it++)
        writeFile(*it);

      // verify each file

      for(auto it=_flashEntries.begin();it!=_flashEntries.end();it++)
        verifyFile(*it);

      // set the configuration register to 0x82 (quad mode, <= 104MHz LC = 10b)

      setConfigurationRegister(0x82);

      // done, flash rapidly

      for(;;) {
        _whiteLed.setState(true);
        MillisecondTimer::delay(50);
        _whiteLed.setState(false);
        MillisecondTimer::delay(50);
      }
    }


    /**
     * Reset the FPGA by pulsing the reset pin high for 10ms
     */

    void resetFpga() {

      GpioB<DefaultDigitalOutputFeature<FPGA_RESET>> pb;

      // hold reset for 10ms, much more than is actually required

      pb[FPGA_RESET].set();
      MillisecondTimer::delay(10);
      pb[FPGA_RESET].reset();
      MillisecondTimer::delay(10);
    }


    /*
     * Erase the entire device
     */

    void eraseFlash() {
      writeCommand(CMD_BULK_ERASE);
      waitIdle();
    }


    /*
     * Set the status register
     */

    void setConfigurationRegister(uint8_t cr) {
      writeCommand(CMD_WRITE_CR);
      writeCommand(cr);
      waitIdle();
    }


    /*
     * Wait for the device to become idle after writing
     */

    void waitIdle() {

      uint32_t start;

      start=MillisecondTimer::millis();

      for(;;) {

        if(!_busy.read())
          return;

        if(MillisecondTimer::hasTimedOut(start,250)) {
          toggleLed();
          start=MillisecondTimer::millis();
        }
      }
    }


    /*
     * Write a command to the FPGA
     */

    void writeCommand(uint16_t command) {
      _bus.write(command);              // WR = 0
      _bus.write(command);              // WR = 0
      _bus.write(command | 0x400);      // WR = 1
      _bus.write(command | 0x400);      // WR = 1
    }


    /*
     * Write the file to the flash device
     */

    void writeFile(const FlashEntry& fe) {

      uint8_t page[256];          // page size is 256
      scoped_ptr<File> file;
      uint32_t remaining,actuallyRead,address,i;

      if(!_fs->openFile(fe.filename,file.address()))
        Error::display(E_OPEN_FILE);

      address=fe.offset;

      for(remaining=fe.length;remaining;remaining-=actuallyRead) {

        // read a page from the file

        memset(page,0,sizeof(page));
        if(!file->read(page,sizeof(page),actuallyRead))
          Error::display(E_READ_FILE_PAGE);

        // cannot hit EOF here

        if(!actuallyRead)
          Error::display(E_UNEXPECTED_EOF);

        // write the program command and the 24 bit page address

        writeCommand(CMD_PROGRAM);
        writeCommand((address >> 16) & 0xff);
        writeCommand((address >> 8) & 0xff);
        writeCommand(address & 0xff);
        while(_busy.read());

        // write each byte in the page

        for(i=0;i<sizeof(page);i++) {

          // write the byte and wait for the FPGA to become ready

          writeCommand(page[i]);
          while(_busy.read());
        }

        // update for next page

        address+=sizeof(page);
        toggleLed();
      }
    }


    /*
     * Verify the file just written to the device
     */

    void verifyFile(const FlashEntry& fe) {

      uint8_t page[256];
      scoped_ptr<File> file;
      uint32_t remaining,actuallyRead,address,i;

      if(!_fs->openFile(fe.filename,file.address()))
        Error::display(E_OPEN_FILE);

      address=fe.offset;

      for(remaining=fe.length;remaining;remaining-=actuallyRead) {

        // read a page from the file

        memset(page,0,sizeof(page));
        if(!file->read(page,sizeof(page),actuallyRead))
          Error::display(E_READ_FILE_PAGE);

        // cannot hit EOF here

        if(!actuallyRead)
          Error::display(E_UNEXPECTED_EOF);

        // write the verify command and the 24 bit page address

        writeCommand(CMD_VERIFY);
        writeCommand((address >> 16) & 0xff);
        writeCommand((address >> 8) & 0xff);
        writeCommand(address & 0xff);
        while(_busy.read());

        // write each byte in the page

        for(i=0;i<sizeof(page);i++) {

          // write the byte and wait for the FPGA to become ready

          writeCommand(page[i]);
          while(_busy.read());

          // check for verification failure

          if(_debug.read())
            Error::display(E_VERIFY);
        }

        // update for next page

        address+=sizeof(page);
        toggleLed();
      }
    }


    /*
     * Read index.txt
     */

    void readIndexFile() {

      scoped_ptr<File> file;
      char line[200],*ptr;

      // open the file

      if(!_fs->openFile("/spiflash/index.txt",file.address()))
        Error::display(E_OPEN_INDEX);

      // attach a reader and read each line

      FileReader reader(*file);

      while(reader.available()) {

        toggleLed();

        scoped_ptr<File> dataFile;

        // read line

        if(!reader.readLine(line,sizeof(line)))
          Error::display(E_READ_LINE);

        // search for the = separator and break the text line at it

        if((ptr=strchr(line,'='))==nullptr)
          Error::display(E_BAD_INDEX_FORMAT);

        *ptr='\0';

        // ensure this file can be opened

        if(!_fs->openFile(line,dataFile.address()))
          Error::display(E_CANNOT_OPEN_DATA);

        FlashEntry fe;
        fe.filename=strdup(line);
        fe.offset=atoi(ptr+1);
        fe.length=dataFile->getLength();

        _flashEntries.push_back(fe);
      }
    }

    void toggleLed(){
      _whiteLed.setState(_ledState);
      _ledState^=true;
    }
};


/*
 * Main entry point
 */

int main() {

  MillisecondTimer::initialise();

  AseFlashProgram afp;
  afp.run();

  // not reached
  return 0;
}
