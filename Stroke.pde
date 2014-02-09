/**
 * A Stroke represents a curve in 3D space overtime
 * @author Kelly Egan
 * @version 0.1
 */

import java.util.*;

class Stroke {
  List<Point> points;
  color strokeColor;
  float strokeWeight;
  Point lastPoint;
  
  Brush brushStyle;
  
  /**
   * Create an empty Stroke with a specific Brush
   * @param b Brush to attach to this Stroke
   */
  Stroke(Brush b) {
    points = new LinkedList<Point>();
    brushStyle = b;
    lastPoint = null;
  }
  
  /**
   * Create an empty Stroke and a new Brush
   * @param n Name of the new Brush
   * @param w Width of the Stroke
   * @param c Color of the new Stroke
   */
  Stroke(String n, int c, int w) {
    this(new Brush(n, c, w));
  }
  
  /**
   * Create an empty Stroke with a default Brush
   */  
  Stroke() {
    this( new Brush() );
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
    if( points != null && points.size() > 1) {

    }
  }
  
  /**
   * Display the stroke
   */
  void display() { 
    brushStyle.apply();
    beginShape();
    for( Point point : points ) {
      vertex( point.location.x, point.location.y, point.location.z );
    }
    endShape();
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
