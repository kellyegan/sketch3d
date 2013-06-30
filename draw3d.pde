/*
  draw3d
*/

Drawing d;
int strokeVal = 175;

int count = 0;
boolean drawing = false;

void setup() {
  size(640, 480, OPENGL);
  
  
  File path = new File(sketchPath + "/data");  

  for( File file : path.listFiles() ) {
    if( file.toString().endsWith(".gml") ) {
      background(255);
      d = new Drawing(file.toString() );
    }
  }
  
  d = new Drawing("banana.gml");
}

void draw() {
  d.display();
}

void mousePresssed() {
    println("PRESSED!");
}

void mouseDragged() {
  if( !drawing ) {
    drawing = true;
    d.startStroke();
  }
  d.addPoint( (float)millis() / 1000.0, mouseX, mouseY, 0.0);
}

void mouseReleased() {
  drawing = false;
  d.endStroke();
}

void keyPressed() {
  switch(key) {
    case 's':
    case 'S':
      d.save("banana.gml");
    default:
  }
}













