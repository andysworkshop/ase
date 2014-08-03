/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include "Application.h"


/*
 * Constructor: set ourselves up to show level 1
 */

Introduction::Introduction(Panel& panel)
  : _panel(panel),
    _world(panel,Level1) {
}


/*
 * Run the introduction
 */

void Introduction::run() {

  uint32_t start,busy_elapsed,free_elapsed,frame_counter;
  Buttons buttons;

  // fade up the backlight to 90%

  _panel.setBacklight(90);

  // enable sprite mode. the backlight cannot be adjusted once we're in sprite mode
  // without coming back to passthrough mode first.

  _panel.enableSpriteMode();

  // create a busy monitor

  FpgaBusyMonitor busyMonitor;

  // infinite loop

  for(frame_counter=0;;frame_counter++) {

    // wait for busy to go high and then back to low

    while(!busyMonitor.isBusy());
    start=MillisecondTimer::millis();
    while(busyMonitor.isBusy());
    busy_elapsed=MillisecondTimer::millis()-start;
    if(busy_elapsed>16)
      for(;;);          // lock up so a debugger break can detect this 'too many graphics' case

    // update the sprites based on the state of the world

    start=MillisecondTimer::millis();
    _world.update(buttons,frame_counter);
    free_elapsed=MillisecondTimer::millis()-start;
  }
}
