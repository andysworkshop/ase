#!/bin/sh

bm2rgbi=../../../../../../stm32plus/utils/bm2rgbi/bm2rgbi/bin/Release/bm2rgbi.exe

if [ ! -x ${bm2rgbi} ] ; then
  echo "bm2rgbi not found at ${bm2rgbi}"
fi

offset=0
rm -f spiflash/*

for i in `ls *.png  | sort`; do 
  
  outfile=spiflash/${i%.png}.bin
  ${bm2rgbi} $i $outfile r61523 64 > /dev/null
  echo $outfile=$offset >> spiflash/index.txt

  filesize=$(stat -c%s $outfile)
  offset=$(($offset+$filesize))
  offset=$(((($offset/256)+1)*256))

  echo $i $filesize $offset

done
