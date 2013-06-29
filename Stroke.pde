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
