import java.util.*;

import wblut.math.*;
import wblut.processing.*;
import wblut.core.*;
import wblut.*;
import wblut.hemesh.*;
import wblut.geom.*;

/**
 * A Stroke represents a curve in 3D space overtime
 * @author Kelly Egan
 * @version 0.1
 */
class Stroke {
  List<Point> points;
  color strokeColor;
  float strokeWeight;
  Point lastPoint;
  
  /**
   * Create an empty Stroke;
   */  
  Stroke() {
    points = new LinkedList<Point>();
    lastPoint = null;
  }
  
  /**
   * Add a point to the Stroke.
   * @param Point to add
   */
  void add(Point p) {
    points.add(p);
    lastPoint = p;
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
    display(0, 0, 0);
  }
  
  /**
   * 
   */
   void display( float x, float y, float z ) {
    Point lastPoint = new Point();
    int pointCount = 0;
    for( Point point : points ) {
      if(pointCount > 0 ) {
        line( x + lastPoint.location.x, y + lastPoint.location.y, z + lastPoint.location.z, x + point.location.x, y + point.location.y, z + point.location.z);
      }
      lastPoint = point;
      pointCount++;
    }     
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
  
  Point getLastPoint() {
    return lastPoint; 
  }
  
  float distanceToLast( float x, float y, float z ) {
    if( lastPoint != null ) {
      return dist( lastPoint.location.x, lastPoint.location.y, lastPoint.location.z, x, y, z );
    } else {
      return -1;
    }
  }
   
}
