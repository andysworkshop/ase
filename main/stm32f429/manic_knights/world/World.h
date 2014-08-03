/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#pragma once


/*
 * Our view of the world for the current level
 */

class World {

  protected:
    const LevelDef& _levelDef;
    Panel& _panel;
    Background _background;
    Actor **_actors;

  public:
    World(Panel& panel,const LevelDef& ldef);
    ~World();

    void update(const Buttons& buttons,uint32_t frame_counter);
    void createActors(Panel& panel);
};
