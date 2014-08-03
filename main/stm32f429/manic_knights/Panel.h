/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#pragma once


/*
 * Class to manage all aspects of interacting with the LCD panel via the FPGA
 */

class Panel {

  public:

    /*
     * The LCD panel type to be used (note that it must be portrait mode)
     */

    typedef R61523_Portrait_64K_TypeB<AseAccessMode> LcdPanel;

  protected:

    AseAccessMode& _accessMode;
    LcdPanel _gl;
    R61523PwmBacklight<AseAccessMode> _backlight;

  public:
    Panel(AseAccessMode& accessMode);

    void enableSpriteMode();
    void setBacklight(uint8_t percentage);

    AseAccessMode& getAccessMode();

    uint16_t getHeight() const;
};


/*
 * Panel constructor
 */

inline Panel::Panel(AseAccessMode& accessMode)
  : _accessMode(accessMode),
    _gl(_accessMode),
    _backlight(_accessMode) {

  // backlight off

  _backlight.setPercentage(0);

  // apply the gamma curve. Note that gammas are panel specific. This curve is appropriate
  // to a replacement (non-original) panel obtained from ebay.

  uint8_t levels[13]={ 0xe,0,1,1,0,0,0,0,0,0,3,4,0 };
  R61523Gamma gamma(levels);
  _gl.applyGamma(gamma);
}


/*
 * Put the panel into sprite mode
 */

inline void Panel::enableSpriteMode() {

  // set the 16 to 24 bit colour expansion mode to copy the MSB to the LSBs

  _accessMode.writeCommand(r61523::SET_FRAME_AND_INTERFACE);
  _accessMode.writeData(0x80);
  _accessMode.writeData(0x80);     // EPF = 10 (msb => lsb)

  // set the frame rate to 61Hz. If it's too high then we won't have time to
  // transfer the frame to the graphics memory and corruption will appear at
  // the bottom of the display

  _accessMode.writeCommand(r61523::NORMAL_DISPLAY_TIMING);
  _accessMode.writeData(1);              // BC0 = 1
  _accessMode.writeData(0);
  _accessMode.writeData(26);             // reduce frame rate to 61Hz
  _accessMode.writeData(8);              // BP = 8
  _accessMode.writeData(8);              // FP = 8

  // set WEMODE = 1 to enable automatic wrapping of graphic data from the end
  // of the display window to the start

  _accessMode.writeCommand(r61523::SET_FRAME_AND_INTERFACE);
  _accessMode.writeData(0x82);           // WEMODE = 1
  _accessMode.writeData(0);              // DFM = 0    (5-6-5 colour format in 1 transfer)

  // TE must be enabled

  _gl.enableTearingEffect(LcdPanel::TE_VBLANK);

  // the display window must be set to full screen and the display
  // primed for receiving data

  _gl.moveTo(0,0,_gl.getWidth()-1,_gl.getHeight()-1);
  _gl.beginWriting();

  // now we're ready to set the mode to sprite

  _accessMode.spriteMode();
}


/*
 * Get a reference to the access mode class
 */

inline AseAccessMode& Panel::getAccessMode() {
  return _accessMode;
}


/*
 * Return the panel height
 */

inline uint16_t Panel::getHeight() const {
  return _gl.getHeight();
}


/*
 * Set the backlight percentage
 */

inline void Panel::setBacklight(uint8_t percentage) {
  _backlight.setPercentage(percentage);
}
