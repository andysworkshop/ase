#!/usr/bin/perl -w

use strict;
use warnings;
use File::Copy;

my $bm2rgbi="../../../../../../stm32plus/utils/bm2rgbi/bm2rgbi/bin/Release/bm2rgbi.exe";
my $cropper="cropper/bin/Debug/cropper.exe";

if( ! -x $bm2rgbi ) {
  print "bm2rgbi not found at ${bm2rgbi}\n";
  exit 0;
}

die("cropper not found at tiles/${cropper}")
  unless(-x "tiles/${cropper}");

my $offset=0;
`rm -f spiflash/*`;

# run the cropper

chdir "tiles";
`${cropper} level1.tmx`;
chdir "..";

my (@files,$id,$indexfile,$spritesfile,$i,$name,$outfile,$filesize,$sprites_count,$w,$h,$newnumber);

# prepare output files

open($indexfile,">>spiflash/index.txt");
open($spritesfile,">tiles/converted-tiles/BackgroundSprites.cpp");

print $spritesfile qq[
/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include "Application.h"

/*
 * All sprites in this world
 */

  const BackgroundSpriteDef BackgroundSprites[]={
];

#
# convert the background pngs
#

$sprites_count=0;
@files=`ls tiles/converted-tiles/*.png | sort`;
foreach $i (@files) {
  
  chomp($i);

  $i =~ m/tiles\/converted-tiles\/(.*).png/;
  $name=$1;

  $outfile="spiflash/${name}.bin";
  `${bm2rgbi} ${i} ${outfile} r61523 64 > /dev/null`;
  print $indexfile "${outfile}=${offset}\n";

  print $spritesfile "  { ${sprites_count}, ${offset} },\n";

  $filesize = -s $outfile;
  print "${name} ${filesize} ${offset}\n";

  $offset = $offset + $filesize;
  $offset = (int($offset / 256) + 1) * 256;
  $sprites_count++;
}

print $spritesfile "};\n\n";
close $spritesfile;

# create the header file 

open($spritesfile,">tiles/converted-tiles/BackgroundSprites.h");
print $spritesfile qq!
/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#pragma once


extern const BackgroundSpriteDef BackgroundSprites[];
enum { BACKGROUND_SPRITES_COUNT=${sprites_count} };\n
!;

close $spritesfile;

#
# convert characters
#

open($spritesfile,">tiles/converted-tiles/PathSprites.cpp");
print $spritesfile qq!
/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include "Application.h"


const PathSpriteDef PathSprites[]={
!;

$sprites_count=0;
$id="";

@files=`ls characters/*.png | sort`;
foreach $i (@files) {
  
  chomp($i);

  $i =~ m/characters\/(.*).png/;
  $name=$1;

  $name=~m/(\d+)_(.*)/;
  $newnumber=${1}-100;

  $id="${id}  " . uc($2) . " = ${newnumber},\n";

  $outfile="spiflash/${name}.bin";
  `${bm2rgbi} ${i} ${outfile} r61523 64 > /tmp/log.txt`;
  print $indexfile "${outfile}=${offset}\n";

  $w=`grep Width /tmp/log.txt | cut -d: -f2`;
  chomp($w);
  $w =~ s/^\s+//;

  $h=`grep Height /tmp/log.txt | cut -d: -f2`;
  chomp($h);
  $h =~ s/^\s+//;

  print $spritesfile "  { ${offset}, ${w}, ${h} },    // ${name} \n";

  $filesize = -s $outfile;
  print "${name} ${filesize} ${offset}\n";

  $offset = $offset + $filesize;
  $offset = (int($offset / 256) + 1) * 256;

  $sprites_count=$sprites_count+1;
}

print $spritesfile "};\n";
close $spritesfile;

# create the header file

open($spritesfile,">tiles/converted-tiles/PathSprites.h");
print $spritesfile qq!
/*
 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#pragma once


extern const PathSpriteDef PathSprites[];

enum {
  PATH_SPRITES_COUNT=${sprites_count},

$id};
!;

close $spritesfile;

# done

close $indexfile;

# copy the level map definition

move("tiles/converted-tiles/level1_Tiles.cpp","../world/Level1_Tiles.cpp") or die("Copy failed: $!");
move("tiles/converted-tiles/BackgroundSprites.cpp","../world/BackgroundSprites.cpp") or die("Copy failed: $!");
move("tiles/converted-tiles/BackgroundSprites.h","../world/BackgroundSprites.h") or die("Copy failed: $!");
move("tiles/converted-tiles/PathSprites.cpp","../world/PathSprites.cpp") or die("Copy failed: $!");
move("tiles/converted-tiles/PathSprites.h","../world/PathSprites.h") or die("Copy failed: $!");
