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
    for( XML point : stroke.getChildren("pt") ) {
      points.add( new Point( point ) );
    }
  }
  
  void add(Point p) {
    points.add(p);
  }
  
  void createMesh() {
    
  }
  
  void display() {
    
  }
   
}
