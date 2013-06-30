/**
 * A Point contains information about a single location in a stroke
 * In addition to location in also contains, time, pressure, direction of the stroke at that point.
 * @author Kelly Egan
 * @version 0.1
 */
class Point {
  PVector location, direction;
  float time;
  float pressure;
  float rotation;
  
  
  /**
   * Create a point at (0, 0, 0)
   */
  Point() {
    this( 0, 0, 0, 0, 0, 0, 0, 1, 0 );
  }
  
  /**
   * Create a point with given location and time
   * @param t Time value (as flaot of the current point
   * @param lx X coordinate of point location
   * @param ly Y coordinate of point location
   * @param lz Z coordinate of point location
   */
  Point( float t, float lx, float ly, float lz ) {
    this( t, lx, ly, lz, 0, 0, 0, 1, 0 );
  }
  
  /**
   * Create a point with given location, time, direction, pressure and rotation values
   * @param t Time value (as flaot of the current point
   * @param lx X coordinate of point location
   * @param ly Y coordinate of point location
   * @param lz Z coordinate of point location
   * @param dx X coordinate of point direction
   * @param dy Y coordinate of point direction
   * @param dz Z coordinate of point direction
   * @param p Pressure value of point
   * @param r Rotation value of point
   */
  Point( float t, float lx, float ly, float lz, float dx, float dy, float dz, float p, float r ) {
    time = t;
    location = new PVector( lx, ly, lz );
    direction = new PVector( dx, dy, dz );
    pressure = p;
    rotation = r;
  }
  
  /**
    * Print out the values of the point
    */
  void list() {
    println( time + " - " + location.x + ", " + location.y + ", " + location.y ); 
  }
  
  /**
   * Compare a point to another based on time value
   * Useful for sorting points in a List object
   * @param a First point to compare
   * @param b Second point to compare
   * @return returns -1 if a < b, 1 if a > b and 0 if they are equal
   */
  int Compare( Point a, Point b ) {
    if(a.time < b.time) {
      return -1;
    } else if( a.time > b.time ) {
      return 1;
    } else {
      return 0;
    }
  }
  
}

