/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

 	.global BitFileStart
	.global BitFileSize

BitFileStart:
	.incbin "../xc3s50/flash_programmer.bit"
	BitFileSize=.-BitFileStart
