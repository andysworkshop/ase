/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#pragma once


/*
 * Simple synchronous button sampler not using interrupts
 */

class Buttons {

  protected:
    enum {
      LEFT_PIN = 12,
      RIGHT_PIN = 13,
      UP_PIN = 14,
      DOWN_PIN = 15,

      LEFT_INDEX = 0,
      RIGHT_INDEX = 1,
      UP_INDEX = 2,
      DOWN_INDEX =3
    };

    GpioPinRef _pins[4];

  public:
    Buttons();

    bool isLeftPressed() const;
    bool isRightPressed() const;
    bool isUpPressed() const;
    bool isDownPressed() const;
};


/*
 * Constructor
 */

inline Buttons::Buttons() {

  // the 4-way buttons are on port B

  GpioB<
    DigitalInputFeature<GPIO_Speed_50MHz,Gpio::PUPD_DOWN,LEFT_PIN,RIGHT_PIN,UP_PIN,DOWN_PIN>
  > pb;

  _pins[LEFT_INDEX]=pb[LEFT_PIN];
  _pins[RIGHT_INDEX]=pb[RIGHT_PIN];
  _pins[UP_INDEX]=pb[UP_PIN];
  _pins[DOWN_INDEX]=pb[DOWN_PIN];
}


/*
 * Check if left is pressed
 */

inline bool Buttons::isLeftPressed() const {
  return _pins[LEFT_INDEX].read();
}


/*
 * Check if right is pressed
 */

inline bool Buttons::isRightPressed() const {
  return _pins[RIGHT_INDEX].read();
}


/*
 * Check if up is pressed
 */

inline bool Buttons::isUpPressed() const {
  return _pins[UP_INDEX].read();
}


/*
 * Check if down is pressed
 */

inline bool Buttons::isDownPressed() const {
  return _pins[DOWN_INDEX].read();
}
