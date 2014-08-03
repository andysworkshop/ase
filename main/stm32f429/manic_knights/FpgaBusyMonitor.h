/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#pragma once


/*
 * This class allows monitoring the state of the BUSY pin (PC14). BUSY goes high when the FPGA is accessing
 * the sprite definitions and goes back to low when the FPGA has finished. A transition from high
 * to low is the signal that the game engine should start its update logic.
 */

class FpgaBusyMonitor {

  protected:
    enum { BUSY_PIN = 14 };

    GpioPinRef _busyPin;

  public:
    FpgaBusyMonitor();

    bool isBusy() const;
};


/*
 * Constructor
 */

inline FpgaBusyMonitor::FpgaBusyMonitor() {

  // get a pin reference

  GpioC<DefaultDigitalInputFeature<BUSY_PIN>> pc;
  _busyPin=pc[BUSY_PIN];
}


/*
 * Get the busy state
 */

inline bool FpgaBusyMonitor::isBusy() const {
  return _busyPin.read();
}
