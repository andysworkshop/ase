using System;
using System.Collections.Generic;
using System.Xml;
using System.Drawing;
using System.IO;

namespace cropper {
  
  public class TsxReader {

    protected Dictionary<int,int> _seenTiles=new Dictionary<int,int>();
    protected int _width,_height;
    protected int _index;

    public void Run(string tmxname,string tsxname,List<string> tiles) {

      XmlDocument doc;
      String tilesName;
      Bitmap image;
      TextWriter mapwriter;
      int spriteNumber;
      string levelName;

      Console.WriteLine("Reading "+tsxname);

      doc=new XmlDocument();
      doc.Load(tsxname);

      tilesName=XmlUtil.GetString(doc,"/tileset/image/@source",null,true);
      _width=XmlUtil.GetInt(doc,"/tileset/image/@width",0,true);
      _height=XmlUtil.GetInt(doc,"/tileset/image/@height",0,true);
      _index=0;

      Console.WriteLine("Reading "+tilesName+", width="+_width+", height="+_height);

      image=(Bitmap)Image.FromFile(tilesName);

      if(Directory.Exists("converted-tiles"))
        Directory.Delete("converted-tiles",true);

      Directory.CreateDirectory("converted-tiles");

      levelName=Path.GetFileNameWithoutExtension(tmxname);
      
      mapwriter=new StreamWriter(string.Format("converted-tiles/{0}_Tiles.cpp",levelName));

      mapwriter.Write(@"/*

 * This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
 * Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
 * Please see website for licensing terms.
 */

#include ""Application.h""


/*
 * Level world definition
 */

extern const uint16_t Level1_Tiles[] = {
  ");

      int basetile,offset;

      basetile=29;
      offset=0;

      for(int i=0;i<600;i++) {

        string tile=tiles[basetile+offset];

        Console.WriteLine(basetile+","+offset);
        spriteNumber=processTile(image,int.Parse(tile)-1);
        mapwriter.Write(string.Format("{0,3}",spriteNumber));
        
        if(i!=599)
          mapwriter.Write(",");

        if (offset == 570) {
          mapwriter.Write("\n  ");
          offset=0;
          basetile--;
        }
        else
          offset+=30;
      }
    
      mapwriter.WriteLine("};");

      mapwriter.Close();
    }


    protected int processTile(Bitmap image, int tileNumber) {

      int spriteNumber;

      if(_seenTiles.TryGetValue(tileNumber,out spriteNumber))
        return spriteNumber;

      saveCropped(image,tileNumber);
      _seenTiles[tileNumber]=_index;

      return _index++;
    }


    protected void saveCropped(Bitmap image,int tileNumber) {

      Bitmap clone;
      Rectangle area;

      area=new Rectangle((tileNumber % (_width/64))*64,(tileNumber/(_width/64))*64,64,64);
      clone=image.Clone(area,image.PixelFormat);
      clone.RotateFlip(RotateFlipType.Rotate270FlipNone);

      Console.WriteLine("Saving tile "+tileNumber+" ("+area.X+","+area.Y+","+area.Width+","+area.Height+")");

      clone.Save(string.Format("converted-tiles/{0}_tile{1}.png",_index.ToString("D3"),tileNumber),System.Drawing.Imaging.ImageFormat.Png);
    }
  }
}
