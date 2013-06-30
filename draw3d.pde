/*
  draw3d
*/

Drawing d;
int strokeVal = 175;
void setup() {
  size(640, 480, OPENGL);
  Drawing blank = new Drawing();
  
  File path = new File(sketchPath + "/data");  

  for( File file : path.listFiles() ) {
    if( file.toString().endsWith(".gml") ) {
      background(255);
      d = new Drawing(file.toString() );
      d.display();
    }
    
  } 
}

//void draw() {
//  
//}









