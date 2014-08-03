/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include "Application.h"


/*
 * Run the application
 */

void ManicKnights::run() {

  // program and reset the FPGA

  programFpga();

  // show the intro screen

  introduction();
}


/*
 * Show the introduction screen
 */

void ManicKnights::introduction() {

  // there's a class for that

  Introduction intro(*_panel);
  intro.run();
}


/*
 * Program the FPGA with the main bit file
 */

void ManicKnights::programFpga() {

  // program the FPGA

  FpgaProgrammer programmer;
  programmer.program();

  // reset the FPGA

  _accessMode.resetFpga();

  // create the panel

  _panel.reset(new Panel(_accessMode));
}


/*
 * Main entry point
 */

int main() {

  // set up SysTick at 1ms resolution
  MillisecondTimer::initialise();

  ManicKnights mk;
  mk.run();

  // not reached
  return 0;
}

