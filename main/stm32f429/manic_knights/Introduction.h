/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#pragma once


/*
 * Introduction displays an introductory message over a continually panning background
 */

class Introduction {

  public:
    Panel& _panel;
    World _world;

  public:
    Introduction(Panel& panel);

    void run();
};
