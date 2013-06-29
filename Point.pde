
class Point {
  PVector location, direction;
  float time;
  float pressure;
  float rotation;
  
  Point() {
    this( 0, 0, 0, 0, 0, 0, 0, 1, 0 );
  }
  
  Point( float t, float lx, float ly, float lz ) {
    this( t, lx, ly, lz, 0, 0, 0, 1, 0 );
  }
  
  Point( float t, float lx, float ly, float lz, float dx, float dy, float dz, float p, float r ) {
    time = t;
    location = new PVector( lx, ly, lz );
    direction = new PVector( dx, dy, dz );
    pressure = p;
    rotation = r;
  }
  
  void list() {
    println( time + " - " + location.x + ", " + location.y + ", " + location.y ); 
  }
  
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

