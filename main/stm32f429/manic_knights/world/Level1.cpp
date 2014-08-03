/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include "Application.h"


// auto-generated code

extern const uint16_t Level1_Tiles[];

// Enemy 1

static const PathDef Level1_Enemy1_Paths[]= {
  { 1148, 1482, 1148, 1340, ENEMY1_WALK1_R, ENEMY1_WALK12_R, EasingType::LINEAR, EasingMode::INOUT, 90, 0, 0 },
  { 1148, 1340, 1148, 1482, ENEMY1_WALK1_L, ENEMY1_WALK12_L, EasingType::LINEAR, EasingMode::INOUT, 90, 0, 0 }
};

// Enemy 2

static const PathDef Level1_Enemy2_Paths[]= {
 { 1084, 1152, 1084, 960,  ENEMY1_WALK1_R, ENEMY1_WALK12_R, EasingType::CUBIC, EasingMode::INOUT, 90, 0, 0 },
 { 1084, 960,  1084, 1152, ENEMY1_WALK1_L, ENEMY1_WALK12_L, EasingType::CUBIC, EasingMode::INOUT, 90, 0, 0 }
};

// Enemy 3

static const PathDef Level1_Enemy3_Paths[]= {
 { 1024, 512, 1024, 192, ENEMY2_WALK1_R, ENEMY2_WALK12_R, EasingType::LINEAR, EasingMode::INOUT, 150, 0, 0 },
 { 1024, 192, 1024, 512, ENEMY2_WALK1_L, ENEMY2_WALK12_L, EasingType::LINEAR, EasingMode::INOUT, 150, 0, 0 }
};

// Enemy 4

static const PathDef Level1_Enemy4_Paths[]= {
 { 832, 192, 832, 330, ENEMY1_WALK1_L, ENEMY1_WALK12_L, EasingType::LINEAR, EasingMode::INOUT, 60, 0, 0 },
 { 832, 330, 832, 192, ENEMY1_WALK1_R, ENEMY1_WALK12_R, EasingType::LINEAR, EasingMode::INOUT, 60, 0, 0 }
};

// Enemy 5

static const PathDef Level1_Enemy5_Paths[]= {
 { 832, 586, 832, 448, ENEMY1_WALK1_R, ENEMY1_WALK12_R, EasingType::LINEAR, EasingMode::INOUT, 75, 0, 0 },
 { 832, 448, 832, 586, ENEMY1_WALK1_L, ENEMY1_WALK12_L, EasingType::LINEAR, EasingMode::INOUT, 75, 0, 0 }
};

// Enemy 6

static const PathDef Level1_Enemy6_Paths[]= {
 { 832, 1408, 832, 1472, ENEMY2_WALK1_L, ENEMY2_WALK12_L, EasingType::LINEAR, EasingMode::INOUT, 60, 0, 0 },
 { 832, 1472, 832, 1408, ENEMY2_WALK1_R, ENEMY2_WALK12_R, EasingType::LINEAR, EasingMode::INOUT, 60, 0, 0 }
};

// Enemy 7

static const PathDef Level1_Enemy7_Paths[]= {
 { 128, 512, 128, 640, ENEMY2_WALK1_L, ENEMY2_WALK12_L, EasingType::CUBIC, EasingMode::INOUT, 90, 0, 0 },
 { 128, 640, 128, 512, ENEMY2_WALK1_R, ENEMY2_WALK12_R, EasingType::CUBIC, EasingMode::INOUT, 90, 0, 0 }
};

// Enemy 8

static const PathDef Level1_Enemy8_Paths[]= {
 { 128, 1024, 128, 1216, ENEMY1_WALK1_L, ENEMY1_WALK12_L, EasingType::CUBIC, EasingMode::INOUT, 90, 0, 0 },
 { 128, 1216, 128, 1024, ENEMY1_WALK1_R, ENEMY1_WALK12_R, EasingType::CUBIC, EasingMode::INOUT, 90, 0, 0 }
};

// Enemy 9

static const PathDef Level1_Enemy9_Paths[]= {
 { 384, 192, 384, 280, ENEMY2_WALK1_L, ENEMY2_WALK12_L, EasingType::CUBIC, EasingMode::INOUT, 90, 0, 0 },
 { 384, 280, 384, 192, ENEMY2_WALK1_R, ENEMY2_WALK12_R, EasingType::CUBIC, EasingMode::INOUT, 90, 0, 0 }
};

// Platform 1

static const PathDef Level1_Platform1_Paths[]= {
 { 1088, 768, 1088, 576, MOVING_PLATFORM, MOVING_PLATFORM, EasingType::LINEAR, EasingMode::INOUT, 60, 0, 0 },
 { 1088, 576, 1088, 768, MOVING_PLATFORM, MOVING_PLATFORM, EasingType::LINEAR, EasingMode::INOUT, 60, 0, 0 }
};

// Platform 2

static const PathDef Level1_Platform2_Paths[]= {
 { 704,  96, 1088, 96, MOVING_PLATFORM, MOVING_PLATFORM, EasingType::BOUNCE, EasingMode::OUT,  120, 0, 0 },
 { 1088, 96, 704,  96, MOVING_PLATFORM, MOVING_PLATFORM, EasingType::CUBIC,  EasingMode::INOUT, 120, 0, 0 }
};

// Platform 3

static const PathDef Level1_Platform3_Paths[]= {
 { 768, 672, 896, 672, MOVING_PLATFORM, MOVING_PLATFORM, EasingType::LINEAR, EasingMode::INOUT, 60, 0, 0 },
 { 896, 672, 768, 672, MOVING_PLATFORM, MOVING_PLATFORM, EasingType::LINEAR, EasingMode::INOUT, 60, 0, 0 }
};

// Platform 4

static const PathDef Level1_Platform4_Paths[]= {
 { 576, 1792, 832, 1792, MOVING_PLATFORM, MOVING_PLATFORM, EasingType::CUBIC, EasingMode::INOUT, 120, 0, 0 },
 { 832, 1792, 576, 1792, MOVING_PLATFORM, MOVING_PLATFORM, EasingType::CUBIC, EasingMode::INOUT, 120, 0, 0 }
};

// Platform 5

static const PathDef Level1_Platform5_Paths[]= {
 { 448, 1344, 576, 1344, MOVING_PLATFORM, MOVING_PLATFORM, EasingType::BOUNCE, EasingMode::OUT, 120, 0, 0 },
 { 576, 1344, 448, 1344, MOVING_PLATFORM, MOVING_PLATFORM, EasingType::CUBIC, EasingMode::INOUT, 150, 0, 0 }
};

// Platform 6

static const PathDef Level1_Platform6_Paths[]= {
 { 256, 128, 448, 128, MOVING_PLATFORM, MOVING_PLATFORM, EasingType::CUBIC, EasingMode::INOUT, 60, 0, 0 },
 { 448, 128, 256, 128, MOVING_PLATFORM, MOVING_PLATFORM, EasingType::CUBIC, EasingMode::INOUT, 60, 0, 0 }
};

// Platform 7

static const PathDef Level1_Platform7_Paths[]= {
 { 256, 384, 256, 448, MOVING_PLATFORM, MOVING_PLATFORM, EasingType::LINEAR, EasingMode::INOUT, 60, 0, 0 },
 { 256, 448, 256, 384, MOVING_PLATFORM, MOVING_PLATFORM, EasingType::LINEAR, EasingMode::INOUT, 60, 0, 0 }
};

// Platform 8

static const PathDef Level1_Platform8_Paths[]= {
 { 192, 768, 192, 960, MOVING_PLATFORM, MOVING_PLATFORM, EasingType::BOUNCE, EasingMode::OUT, 90, 0, 0 },
 { 192, 960, 192, 768, MOVING_PLATFORM, MOVING_PLATFORM, EasingType::CUBIC, EasingMode::INOUT, 60, 0, 0 }
};

// Platform 9

static const PathDef Level1_Platform9_Paths[]= {
 { 256, 1344, 256, 1472, MOVING_PLATFORM, MOVING_PLATFORM, EasingType::CUBIC, EasingMode::INOUT, 90, 0, 0 },
 { 256, 1472, 256, 1344, MOVING_PLATFORM, MOVING_PLATFORM, EasingType::CUBIC, EasingMode::INOUT, 90, 0, 0 }
};

// disc 1

static const PathDef Level1_Disc1_Paths[]= {
 { 640, 64,  640, 256, SAW_1, SAW_6, EasingType::LINEAR, EasingMode::INOUT, 60, 0, 0 },
 { 640, 256, 640, 64,  SAW_1, SAW_6, EasingType::LINEAR, EasingMode::INOUT, 60, 0, 0 }
};

// disc 2

static const PathDef Level1_Disc2_Paths[]= {
 { 640, 576, 768, 576, SAW_1, SAW_6, EasingType::BOUNCE, EasingMode::OUT, 90, 0, 0 },
 { 768, 576, 640, 576, SAW_1, SAW_6, EasingType::CUBIC, EasingMode::INOUT, 60, 0, 0 }
};

// disc 3

static const PathDef Level1_Disc3_Paths[]= {
 { 704, 1152, 832, 1152, SAW_1, SAW_6, EasingType::QUARTIC, EasingMode::INOUT, 90, 0, 0 },
 { 832, 1152, 704, 1152, SAW_1, SAW_6, EasingType::QUARTIC, EasingMode::INOUT, 90, 0, 0 }
};

// disc 4

static const PathDef Level1_Disc4_Paths[]= {
 { 640, 1536, 640, 1792, SAW_1, SAW_6, EasingType::CUBIC, EasingMode::INOUT, 90, 0, 0 },
 { 640, 1792, 640, 1536, SAW_1, SAW_6, EasingType::LINEAR, EasingMode::INOUT, 70, 0, 0 }
};

// disc 5

static const PathDef Level1_Disc5_Paths[]= {
 { 128, 896, 256, 896, SAW_1, SAW_6, EasingType::LINEAR, EasingMode::INOUT, 50, 0, 0 },
 { 256, 896, 128, 896, SAW_1, SAW_6, EasingType::LINEAR, EasingMode::INOUT, 50, 0, 0 }
};

// torch 1

static const PathDef Level1_Torch1_Paths[]= {
 { 1024, 1600, 1024, 1600, TORCH_1, TORCH_4, EasingType::LINEAR, EasingMode::INOUT, 30, 0, 0 },
};

// torch 2

static const PathDef Level1_Torch2_Paths[]= {
 { 704, 320, 704, 320, TORCH_1, TORCH_4, EasingType::LINEAR, EasingMode::INOUT, 30, 0, 0 },
};

// torch 3

static const PathDef Level1_Torch3_Paths[]= {
 { 320, 1344, 320, 1344, TORCH_1, TORCH_4, EasingType::LINEAR, EasingMode::INOUT, 30, 0, 0 },
};

// torch 4

static const PathDef Level1_Torch4_Paths[]= {
 { 192, 320, 192, 320, TORCH_1, TORCH_4, EasingType::LINEAR, EasingMode::INOUT, 30, 0, 0 },
};

/*
 * Actors in level1
 */

static const ActorDef Level1_Actors[]={
  { AnimationType::STATIC, 1, Level1_Torch1_Paths },
  { AnimationType::STATIC, 1, Level1_Torch2_Paths },
  { AnimationType::STATIC, 1, Level1_Torch3_Paths },
  { AnimationType::STATIC, 1, Level1_Torch4_Paths },

  { AnimationType::MOVING, 2, Level1_Enemy1_Paths },
  { AnimationType::MOVING, 2, Level1_Enemy2_Paths },
  { AnimationType::MOVING, 2, Level1_Enemy3_Paths },
  { AnimationType::MOVING, 2, Level1_Enemy4_Paths },
  { AnimationType::MOVING, 2, Level1_Enemy5_Paths },
  { AnimationType::MOVING, 2, Level1_Enemy6_Paths },
  { AnimationType::MOVING, 2, Level1_Enemy7_Paths },
  { AnimationType::MOVING, 2, Level1_Enemy8_Paths },
  { AnimationType::MOVING, 2, Level1_Enemy9_Paths },

  { AnimationType::MOVING, 2, Level1_Platform1_Paths },
  { AnimationType::MOVING, 2, Level1_Platform2_Paths },
  { AnimationType::MOVING, 2, Level1_Platform3_Paths },
  { AnimationType::MOVING, 2, Level1_Platform4_Paths },
  { AnimationType::MOVING, 2, Level1_Platform5_Paths },
  { AnimationType::MOVING, 2, Level1_Platform6_Paths },
  { AnimationType::MOVING, 2, Level1_Platform7_Paths },
  { AnimationType::MOVING, 2, Level1_Platform8_Paths },
  { AnimationType::MOVING, 2, Level1_Platform9_Paths },

  { AnimationType::MOVING, 2, Level1_Disc1_Paths },
  { AnimationType::MOVING, 2, Level1_Disc2_Paths },
  { AnimationType::MOVING, 2, Level1_Disc3_Paths },
  { AnimationType::MOVING, 2, Level1_Disc4_Paths },
  { AnimationType::MOVING, 2, Level1_Disc5_Paths }
};

/*
 * Level1 definition
 */

const LevelDef Level1={
  Level1_Tiles,
  sizeof(Level1_Actors)/sizeof(Level1_Actors[0]),
  Level1_Actors
};
