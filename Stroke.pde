/**
 * A Stroke represents a curve in 3D space overtime
 * @author Kelly Egan
 * @version 0.1
 */

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
  Point lastPoint;
  
  HE_Mesh mesh;
  
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
    if( points != null && points.size() > 1) {
      println( points.size() );
      WB_Point3d[] wbPoints = new WB_Point3d[points.size()];
      WB_BSpline spline;
      HEC_SweepTube tube = new HEC_SweepTube();
      mesh = new HE_Mesh();
      
      //Convert PVector points to WB_Points3d
      int index = 0;
      for( Point point : points ) {
        wbPoints[index] = new WB_Point3d(point.location.x, point.location.y, point.location.z);
        index++;
        
      }
      println("Stroke has " + index + " points" );
      
      //Create the tube spline and tube object
      spline = new WB_BSpline(wbPoints, 1);
      tube.setCurve(spline);
      tube.setRadius( 5 );
      tube.setSteps( wbPoints.length * 1 );
      tube.setFacets( 6 );
      tube.setCap(true, true); // Cap start, cap end?
      
      //Create and assign mesh to stroke mesh object
      mesh = new HE_Mesh( tube );
    }
  }
  
  /**
   * Display the stroke
   */
  void display() {
    
    Point lastPoint = new Point();
    int pointCount = 0;
    for( Point point : points ) {
      if(pointCount > 0 ) {
        line( lastPoint.location.x, lastPoint.location.y, lastPoint.location.z, point.location.x, point.location.y, point.location.z);
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
