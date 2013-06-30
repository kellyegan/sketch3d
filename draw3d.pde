/*
  draw3d
*/

Drawing d;

void setup() {
  size(640, 480, OPENGL);
  Drawing blank = new Drawing();
  
  File path = new File(sketchPath + "/data");  

  for( File file : path.listFiles() ) {
    if( file.toString().endsWith(".gml") ) {
      d = new Drawing(file.toString() );
    }
  } 
}

//void draw() {
//  
//}









