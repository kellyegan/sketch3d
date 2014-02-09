/**
 * A Stroke represents a curve in 3D space over time
 * @author Kelly Egan
 * @version 0.1
 */

import java.util.*;
import processing.core.PApplet;
import shapes3d.utils.*;
import shapes3d.*;

class Stroke implements I_PathGen {
  List<Point> points;
  color strokeColor;
  float strokeWeight;
  Point lastPoint;
  
  Brush style;
 
  PApplet app; 
  PathTube mesh;
  boolean meshCreated;
  
  /**
   * Create an empty Stroke with a specific Brush
   * @param b Brush to attach to this Stroke
   */
  Stroke(PApplet a, Brush b) {
    app = a;
    points = new LinkedList<Point>();
    style = b;
    lastPoint = null;
    meshCreated = false;
  }
  
  /**
   * Create an empty Stroke and a new Brush
   * @param n Name of the new Brush
   * @param w Width of the Stroke
   * @param c Color of the new Stroke
   */
  Stroke(PApplet a, String n, int c, int w) {
    this(a, new Brush(n, c, w));
  }
  
  /**
   * Create an empty Stroke with a default Brush
   */  
  Stroke(PApplet a) {
    this( a, new Brush() );
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
    if( points != null && points.size() >= 2) {
      PVector[] pts = new PVector[points.size()];
      
      for( int i = 0; i < points.size(); i++ ) {
        pts[i] = points.get(i).location; 
      }
      
      mesh = new PathTube( app, this, style.getWeight(), points.size(), 5, false );
      mesh.drawMode( Shape3D.SOLID );
      mesh.fill( style.getColor() );
      mesh.fill( style.getColor(), Tube.BOTH_CAP );
      meshCreated = true;
    }
  }
  
  /**
   * Display the stroke
   */
  void display() { 
    if( meshCreated ) {
      mesh.draw();
    } else {
      style.apply();
      beginShape();
      for( Point point : points ) {
        vertex( point.location.x, point.location.y, point.location.z );
      }
      endShape();
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
