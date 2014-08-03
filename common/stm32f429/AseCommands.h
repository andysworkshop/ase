/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#pragma once


namespace AseCommands {

  /**
   * This is the command set recognised by the FPGA. Commands may be followed by zero or more parameters.
   */

  enum E {

    /**
     * Enable passthrough mode. Subsequent 16-bit words are sent direct to the LCD panel. Those 16-bits are
     * written over the FPGA interface as two 8-bit bytes in (lo,hi) order. The RS bit is taken from bit 9
     * of (hi). To escape out to sprite mode write a (lo) command with bit 9 set. e.g. 0x200.
     */

    CMD_PASSTHROUGH = 0x0A2,

    /**
     * This is the escape from passthrough mode back to sprite mode. It can actually be any number
     * that's got bit 9 set. The display window must be set to full screen and the lcd's write data
     * command must be issued before this command is executed.
     */

    CMD_SPRITE = 0x200,

    /**
     * Show a sprite. Must be followed by a 9-bit sprite index
     */

    CMD_SHOW = 0x0A3,

    /**
     * Hide a sprite. Must be followed by a 9-bit sprite index
     */

    CMD_HIDE = 0x0A4,

    /**
     * Load a sprite into the FPGA. Must be followed by:
     *  9-bit   sprite index
     *  10-bit  SRAM position (low) [9..0]
     *  8-bit   SRAM position (high) [7..0]
     *  9-bit   pixel width
     *  10-bit  pixel size (low) [9..0]
     *  8-bit   pixel size (high) [17..10]
     *  8-bit   flash address (low) [7..0]
     *  8-bit   flash address (mid) [15..8]
     *  8-bit   flash address (high) [23..16]
     *  9-bit   repeat-x (number of times to auto-repeat in x direction. min = 1)
     *  10-bit  repeat-y (number of times to auto-repeat in y direction. min = 1)
     *  1-bit   visible flag [0..0]
     *  9-bit   first visible x column (zero based)
     *  9-bit   last visible x column
     *  10-bit  first visible y row (zero based)
     *  10-bit  last visible y row
     */

    CMD_LOAD = 0x0A5,

    /**
     * Move a sprite to a new position. Must be followed by:
     *  9-bit   sprite index
     *  10-bit  SRAM position (low) [9..0]
     *  8-bit   SRAM position (high) [7..0]
     */

    CMD_MOVE = 0x0A6,


    /**
     * Move a sprite to a new position where it's partially on the screen. Must be followed by:
     *  9-bit   sprite index
     *  10-bit  SRAM position (low) [9..0]
     *  8-bit   SRAM position (high) [7..0]
     *  9-bit   first visible x column (zero based)
     *  9-bit   last visible x column
     *  10-bit  first visible y row (zero based)
     *  10-bit  last visible y row
     */

    CMD_MOVE_PARTIAL = 0x004 | 0x200
  };
}
