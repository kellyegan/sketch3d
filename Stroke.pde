/**
 * A Stroke represents a curve in 3D space over time
 * @author Kelly Egan
 * @version 0.1
 */

import java.util.*;
import processing.core.PApplet;
import shapes3d.utils.*;
import shapes3d.*;

class Stroke {
  List<Point> points;
  color strokeColor;
  float strokeWeight;
  Point lastPoint;
  
  Brush style;
  
  /**
   * Create an empty Stroke with a specific Brush
   * @param b Brush to attach to this Stroke
   */
  Stroke(Brush b) {
    points = new LinkedList<Point>();
    style = b;
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
    style.apply();
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
  
  /**
   * Return x position along stroke length
   */
  public float x( float t ) {
    float xPos = 0;
    if( t < 1.0 ) {
      float pathPos = t * (points.size() - 1);
      int startPt = floor(pathPos);
      int endPt = startPt + 1;
      float amt = pathPos - startPt;
      xPos = lerp( points.get( startPt ).location.x, points.get( endPt ).location.x, amt );
    } else { 
      xPos =  points.get( points.size() - 1 ).location.x;
    }    
    return xPos;
  }
  
  /**
   * Return x position along stroke
   */
  public float y( float t ) {
    float yPos = 0;
    if( t < 1.0 ) {
      float pathPos = t * (points.size() - 1);
      int startPt = floor(pathPos);
      int endPt = startPt + 1;
      float amt = pathPos - startPt;
      yPos = lerp( points.get( startPt ).location.y, points.get( endPt ).location.y, amt );
    } else { 
      yPos =  points.get( points.size() - 1 ).location.y;
    }    
    return yPos;
  }
  
  /**
   * Return x position along stroke
   */
  public float z( float t ) {
    float zPos = 0;
    if( t < 1.0 ) {
      float pathPos = t * (points.size() - 1);
      int startPt = floor(pathPos);
      int endPt = startPt + 1;
      float amt = pathPos - startPt;
      zPos = lerp( points.get( startPt ).location.z, points.get( endPt ).location.z, amt );
    } else { 
      zPos =  points.get( points.size() - 1 ).location.z;
    }    
    return zPos;
  }
   
}
