/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include "Application.h"


/*
 * Main application startup class
 */

class ManicKnights {

  protected:
    scoped_ptr<Panel> _panel;
    AseAccessMode _accessMode;

  protected:
    void programFpga();
    void introduction();

  public:
    void run();
};
