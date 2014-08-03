using System;
using System.Collections.Generic;
using System.Xml;
using System.Text;


namespace cropper {
  
  public class TmxReader {

    public void Run(string filename) {

      XmlDocument doc;
      String tsx;
      List<string> tiles;
      TsxReader tsxreader;

      Console.WriteLine("Reading "+filename);

      doc=new XmlDocument();
      doc.Load(filename);

      tsx=XmlUtil.GetString(doc,"/map/tileset/@source",null,true);
      tiles=new List<string>();

      foreach(XmlNode node in doc.SelectNodes("/map/layer[@name='background']/data/tile/@gid"))
        tiles.Add(node.InnerText);

      tsxreader=new TsxReader();
      tsxreader.Run(filename,tsx,tiles);
    }
  }
}
