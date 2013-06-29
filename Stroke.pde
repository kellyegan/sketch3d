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
  
  /**
   * Create an empty Stroke;
   */
  
  Stroke() {
    points = new LinkedList<Point>();
  }
  
  /**
   * Add a point to the Stroke.
   * @param Point to add
   */
  void add(Point p) {
    points.add(p);
  }
  
  /** Create a mesh for the given stroke
   *  Not sure if this is needed or should just be implemented for the drawing class
   */
  void createMesh() {
    
  }
  
  /**
   * Display the stroke
   */
  void display() {
    
  }
  
  /**
   * List the points within the Stroke
   */
  void list() {
    for( Point point : points ) {
      point.list();
    }
    println();
  }
   
}
