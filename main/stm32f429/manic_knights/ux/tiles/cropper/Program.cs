using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace cropper {
  class Program {
    static void Main(string[] args) {

      try {

        if (args.Length!=1)
          System.Console.WriteLine("usage: cropper <tmx-file>");
        else {
          
          TmxReader tmx;
          tmx=new TmxReader();

          tmx.Run(args[0]);
        }
      }
      catch (Exception ex) {
        Console.WriteLine(ex.StackTrace);
      }
    }
  }
}
