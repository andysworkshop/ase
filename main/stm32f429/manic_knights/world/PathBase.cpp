/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include "Application.h"


/*
 * Constructor
 */

PathBase::PathBase(Panel& p,const PathDef& def,uint16_t fpgaSpriteIndex)
  : _panel(p),
    _def(def) {

  _spriteArray=&AllSprites.PathSprites[def.FirstSpriteNumber];
  _hidden=true;
  _fpgaSpriteIndex=fpgaSpriteIndex;

  // create the easing function from the path definition

  _easingFunction=createEasingFunction();
}


/*
 * Destructor
 */

PathBase::~PathBase() {
  delete _easingFunction;
}


/*
 * Create the easing function
 */

EasingBase *PathBase::createEasingFunction() const {

  EasingBase *eb;

  switch(_def.EasingFunction) {

    case EasingType::BACK:
      eb=new BackEase;
      static_cast<BackEase *>(eb)->setOvershoot(_def.EasingParameter1);
      break;

    case EasingType::BOUNCE:
      eb=new BounceEase;
      break;

    case EasingType::CIRCULAR:
      eb=new CircularEase;
      break;

    case EasingType::CUBIC:
      eb=new CubicEase;
      break;

    case EasingType::ELASTIC:
      eb=new ElasticEase;
      static_cast<ElasticEase *>(eb)->setPeriod(_def.EasingParameter1);
      static_cast<ElasticEase *>(eb)->setAmplitude(_def.EasingParameter2);
      break;

    case EasingType::EXPONENTIAL:
      eb=new ExponentialEase;
      break;

    case EasingType::LINEAR:
      eb=new LinearEase;
      break;

    case EasingType::QUADRATIC:
      eb=new QuadraticEase;
      break;

    case EasingType::QUARTIC:
      eb=new QuarticEase;
      break;

    case EasingType::QUINTIC:
      eb=new QuinticEase;
      break;

    case EasingType::SINE:
      eb=new SineEase;
      break;

    default:
      eb=nullptr;
      break;
  }

  eb->setDuration(_def.EasingDuration);

  return eb;
}


/*
 * Call the derived class to update the state and then display it
 */

void PathBase::update(float time,const Point& bgTopLeft) {

  Point myPos;

  // call the derived class to do the update

  doUpdate(time,bgTopLeft,myPos);

  // if the sprite is on-screen then we show it in the correct location

  if(isOnScreen(myPos,bgTopLeft)) {

    LoadSpriteDef lsd;
    uint16_t firstx,lastx,firsty,lasty;
    int32_t sram_address;

    // calculate the overlaps

    firstx=myPos.X>=bgTopLeft.X ? 0 : bgTopLeft.X-myPos.X;
    lastx=myPos.X+_currentSpriteDef->PixelWidth-1<=bgTopLeft.X+359 ? 0x3ff : _currentSpriteDef->PixelWidth-((myPos.X+_currentSpriteDef->PixelWidth)-(bgTopLeft.X+360))-1;
    firsty=myPos.Y>=bgTopLeft.Y ? 0 : bgTopLeft.Y-myPos.Y;
    lasty=myPos.Y+_currentSpriteDef->PixelHeight-1<=bgTopLeft.Y+639 ? 0x3ff : _currentSpriteDef->PixelHeight-((myPos.Y+_currentSpriteDef->PixelHeight)-(bgTopLeft.Y+639))-1;

    // y part of the sram address

    if(myPos.Y>=bgTopLeft.Y)
      sram_address=(myPos.Y-bgTopLeft.Y)*360;
    else
      sram_address=524288-((bgTopLeft.Y-myPos.Y)*360);

    // x part of the sram address

    sram_address+=(myPos.X-bgTopLeft.X);

    // replace the active sprite for this actor

    lsd.SpriteNumber=_fpgaSpriteIndex;
    lsd.SramAddress=sram_address;
    lsd.FlashAddress=_currentSpriteDef->FlashAddress;
    lsd.PixelWidth=_currentSpriteDef->PixelWidth;
    lsd.NumPixels=_currentSpriteDef->PixelHeight*_currentSpriteDef->PixelWidth;
    lsd.FirstX=firstx;
    lsd.LastX=lastx;
    lsd.FirstY=firsty;
    lsd.LastY=lasty;
    lsd.Visible=1;
    lsd.RepeatX=1;
    lsd.RepeatY=1;

    _panel.getAccessMode().loadSprite(lsd);

    // this is visible

    _hidden=false;
  }
  else
    hide();
}


/*
 * Hide this sprite
 */

void PathBase::hide() {

  if(_hidden)
    return;

  _panel.getAccessMode().hideSprite(_fpgaSpriteIndex);
  _hidden=true;
}


/*
 * Check if this sprite is at least partially on screen
 */

bool PathBase::isOnScreen(const Point& myPos,const Point& bgTopLeft) const {

  return myPos.X<bgTopLeft.X+359 && myPos.X+_currentSpriteDef->PixelWidth-1>bgTopLeft.X &&
         myPos.Y<bgTopLeft.Y+639 && myPos.Y+_currentSpriteDef->PixelHeight-1>bgTopLeft.Y;
}
