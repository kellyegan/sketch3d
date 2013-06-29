import java.util.*;

import wblut.math.*;
import wblut.processing.*;
import wblut.core.*;
import wblut.*;
import wblut.hemesh.*;
import wblut.geom.*;

class Stroke {
  List<Point> points;
  color strokeColor;
  float strokeWeight;
    
  Stroke() {
    points = new LinkedList<Point>();
  }
  
  //Create a new stroke from a GML <stroke> node
  Stroke( XML stroke ) {
    points = new LinkedList<Point>();
    
    XML [] ptNodes = stroke.getChildren("pt");
    
    if( ptNodes != null ) {
      for( XML pt : ptNodes ) {

        try {     
          float lx = pt.getChild("x").getFloatContent();
          float ly = pt.getChild("y").getFloatContent();
          float lz = pt.getChild("z").getFloatContent(); 

        //Look for <t> node if it doesn't exist look for <time> node if it doesn't exist set time to 0
        XML t = pt.getChild("t");
        float time = 0.0;       
        if( t == null ) {
          t = pt.getChild("time");
          if(t != null) {
            time = t.getFloatContent();
          } else {
            System.err.println("ERROR: Couldn't find <t> or <time> node in " + ". Setting time to 0.0.");
          }
        }
                 
        points.add( new Point( time, lx, ly, lz ) );
          
        } catch( Exception e ) {
          System.err.println("ERROR: Location data missing from <pt> node in " + ". Couldn't create point."); 
        }
      }
    }
  }
  
  void add(Point p) {
    points.add(p);
  }
  
  void createMesh() {
    
  }
  
  void display() {
    
  }
  void list() {
    for( Point point : points ) {
      point.list();
    }
    println();
  }
   
}
