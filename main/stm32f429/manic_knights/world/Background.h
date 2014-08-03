/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#pragma once


/*
 * The background class looks after maintaining the tiles that make up
 * the background.
 */

class Background {

  protected:
    Panel& _panel;
    const LevelDef &_levelDef;
    Point _topLeft;
    Point _lastTopLeft;
    LoadSpriteDef _lsd;

  public:
    Background(Panel& panel,const LevelDef& ldef);

    void update();
    void setTopLeft(const Point& topLeft);
    const Point& getTopLeft() const;
};


/*
 * Set a new top-left point
 */

inline void Background::setTopLeft(const Point& topLeft) {
  _topLeft=topLeft;
}


/*
 * Get the current top-left
 */

inline const Point& Background::getTopLeft() const {
  return _topLeft;
}
