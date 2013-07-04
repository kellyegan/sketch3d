/*
  draw3d
*/

Drawing d;
int strokeVal = 175;

int count = 0;
boolean drawing = false;

//View stuff
float yRotation = 0;
float xRotation = 0;
float rotationStep = TWO_PI / 180;
PVector mouseLocation, mouseLocationRotated, offset;

void setup() {
  size(640, 480, OPENGL);
  
  mouseLocation = new PVector( mouseX, mouseY, 0);
  mouseLocationRotated = new PVector();
  offset = new PVector( width/2, height/2, 0);
  
  File path = new File(sketchPath + "/data");  

//  for( File file : path.listFiles() ) {
//    if( file.toString().endsWith(".gml") ) {
//      background(255);
//      d = new Drawing(file.toString() );
//      
//    }
//  }
  
  d = new Drawing("banana.gml");
}

void draw() {
  background(255);
  mouseLocation.set( mouseX, mouseY, 0 );
  mouseLocation.sub( offset );
  rotateVectorX(-xRotation, mouseLocation, mouseLocationRotated);
  rotateVectorY(-yRotation, mouseLocationRotated, mouseLocationRotated);
  
  
  translate(offset.x, offset.y, offset.z);
  rotateX(xRotation);
  rotateY(yRotation);

  stroke(0);
  d.display();
  
  pushMatrix();
  translate( mouseLocationRotated.x, mouseLocationRotated.y, mouseLocationRotated.z);
  ellipse(0, 0, 6, 6);
  popMatrix();
  
}

void mousePresssed() {
    println("PRESSED!");
}

void mouseDragged() {
  if( !drawing ) {
    drawing = true;
    d.startStroke();
  }
  
  mouseLocation.set( mouseX, mouseY, 0 );
  mouseLocation.sub( offset );
  rotateVectorX(-xRotation, mouseLocation, mouseLocationRotated);
  rotateVectorY(-yRotation, mouseLocationRotated, mouseLocationRotated);
  
  println( "Mouse: " + mouseLocation + "  Rotated: " + mouseLocationRotated );
  d.addPoint( (float)millis() / 1000.0, mouseLocationRotated.x, mouseLocationRotated.y, mouseLocationRotated.z);
}

void mouseReleased() {
  drawing = false;
  d.endStroke();
}

void keyPressed() {
  if( key == CODED ) {
    switch(keyCode) {
      case UP:
        xRotation += rotationStep;
        break;
      case DOWN:
        xRotation -= rotationStep;
        break;
      case RIGHT:
        yRotation += rotationStep;
        break;
      case LEFT:
        yRotation -= rotationStep;
        break;
      default:
    }    
  } else {
    switch(key) {
      case 's':
      case 'S':
        d.save("banana.gml");
        break;
      case 'c':
      case 'C':
        d.clearStrokes();
        break;
      case 'u':
      case 'U':
        d.undoLastStroke();
        break;
      default:
    }
  }
}

PVector rotateVectorX( float theta, PVector vector ) {
  PVector rotated = new PVector();
  
  rotated.x = vector.x;
  rotated.y = cos(theta) * vector.y - sin(theta) * vector.z;
  rotated.z = sin(theta) * vector.y + cos(theta) * vector.z;
  
  return rotated;
}

void rotateVectorX( float theta, PVector vector, PVector target ) {
  float x = vector.x;
  float y = cos(theta) * vector.y - sin(theta) * vector.z;
  float z = sin(theta) * vector.y + cos(theta) * vector.z;
  target.set( x, y, z );
}

PVector rotateVectorY( float theta, PVector vector ) {
  PVector rotated = new PVector();
  
  rotated.x =  cos(theta) * vector.x + 0 * vector.y + sin(theta) * vector.z;
  rotated.y =           0 * vector.x + 1 * vector.y + 0          * vector.z;
  rotated.z = -sin(theta) * vector.x + 0 * vector.y + cos(theta) * vector.z;
  
  return rotated;
}

void rotateVectorY( float theta, PVector vector, PVector target ) {
  float x =  cos(theta) * vector.x + 0 * vector.y + sin(theta) * vector.z;
  float y =           0 * vector.x + 1 * vector.y + 0          * vector.z;
  float z = -sin(theta) * vector.x + 0 * vector.y + cos(theta) * vector.z;
  target.set( x, y, z );
}











