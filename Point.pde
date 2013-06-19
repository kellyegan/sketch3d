
class Point {
  PVector location, direction;
  float time;
  float pressure;
  float rotation;
  
  Point( float t, float lx, float ly, float lz, float dx, float dy, float dz, float p, float r ) {
    time = t;
    location = new PVector( lx, ly, lz );
    direction = new PVector( dx, dy, dz );
    pressure = p;
    rotation = r;
  }
  
  Point( float t, float x, float y, float z ) {
    this( t, x, y, z, 0, 0, 0, 1, 0 );
  }
  
  //Read a point from a GML object
  Point( XML pt ) {
    //Not scaled hmmmm....
    float lx = pt.getChild("x").getFloatContent;
    float ly = pt.getChild("y").getFloatContent;
    float lz = pt.getChild("z").getFloatContent;
    float t = pt.getChild("t").getFloatContent;
    this( lx, ly, lz, t );
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

