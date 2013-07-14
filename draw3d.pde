/*
  draw3d
*/

import controlP5.*;
import processing.core.PApplet;

Drawing d;
ControlP5 cp5;
ColorPicker cp;

Brush defaultBrush = new Brush("draw3d_default_00001", color(0, 0, 0, 255), 1);
float strokeWeight = 1;
int brushColor = color(0, 0, 0);

int strokeVal = 175;

int count = 0;
boolean drawing = false;
  
//View stuff
PMatrix3D inverseTransform;
float xRotation, yRotation, zRotation;

float rotationStep = TWO_PI / 180;
PVector offset, rotation;
PVector cursor, cursorTransformed;


void setup() {
  size(1024, 768, OPENGL);
  smooth();
  
  //GUI
  createControllers();
  
  xRotation = 0;
  yRotation = 0;
  zRotation = 0;
  
  inverseTransform = new PMatrix3D();
  
  cursor = new PVector( mouseX, mouseY, 0);
  cursorTransformed = new PVector();
  offset = new PVector( width/2, height/2, 0);
  
  File path = new File(sketchPath + "/data");  

  for( File file : path.listFiles() ) {
    if( file.toString().endsWith(".gml") ) {
      background(255);
      d = new Drawing(this, file.toString() );
      
    }
  }
  println(this);
  d = new Drawing(this, "default.gml");
}

void draw() {
  if( mousePressed && !cp5.isMouseOver() ) {
    checkForDrawing();   
  } 
  background(200, 200, 190);
  
  cursor.set( mouseX, mouseY, 0 );
  cursorTransformed.set( cursor );
  
  inverseTransform.reset();
  inverseTransform.rotateZ( -zRotation );
  inverseTransform.rotateY( -yRotation );
  inverseTransform.rotateX( -xRotation );
  inverseTransform.translate( -offset.x, -offset.y, -offset.z );
  inverseTransform.mult( cursor, cursorTransformed );
  
  hint(ENABLE_DEPTH_TEST);
  pushMatrix();
  translate(offset.x, offset.y, offset.z);
  rotateX(xRotation);
  rotateY(yRotation);

  d.display();
  
  pushMatrix();
  translate( cursorTransformed.x, cursorTransformed.y, cursorTransformed.z);
  ellipse(0, 0, 6, 6);
  popMatrix();
  
  popMatrix();
  hint(DISABLE_DEPTH_TEST);
  
}

void mousePresssed() {
    println("PRESSED!");
}

void checkForDrawing() {
  if( !drawing ) {
    drawing = true;
    d.startStroke(new Brush( "", cp.getColorValue(), strokeWeight ) );
  }
  
  cursor.set( mouseX, mouseY, 0 );
  cursorTransformed.set( cursor );
  
  inverseTransform.reset();
  inverseTransform.rotateZ( -zRotation );
  inverseTransform.rotateY( -yRotation );
  inverseTransform.rotateX( -xRotation );
  inverseTransform.translate( -offset.x, -offset.y, -offset.z );
  inverseTransform.mult( cursor, cursorTransformed );

  d.addPoint( (float)millis() / 1000.0, cursorTransformed.x, cursorTransformed.y, cursorTransformed.z);  
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
        d.save("data/default.gml");
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

void createControllers() {
   //GUI
  cp5 = new ControlP5(this);
  
  Group brushCtrl = cp5.addGroup("Brush")
      .setPosition(50, 50)
      .setBackgroundHeight(100)
      .setBackgroundColor(color(100,100))
      .setSize(270,125)
      ;
                
  cp5.addSlider("strokeWeight")
     .setGroup(brushCtrl)
     .setRange(1,50)
     .setPosition(5,20)
     .setSize(200,20)
     .setValue(1)
     .setLabel("Stroke weight");
     ;
     
  cp = cp5.addColorPicker("brushColor")
      .setPosition(5, 50)
      .setColorValue(color(0, 0, 0, 255))
      .setGroup(brushCtrl)
      ;
     
  // reposition the Label for controller 'slider'
  cp5.getController("strokeWeight").getValueLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE).setPaddingX(0);
  cp5.getController("strokeWeight").getCaptionLabel().align(ControlP5.RIGHT, ControlP5.TOP_OUTSIDE).setPaddingX(0);
   
}


void rotateVectorX( float theta, PVector vector, PVector target ) {
  float x = vector.x;
  float y = cos(theta) * vector.y - sin(theta) * vector.z;
  float z = sin(theta) * vector.y + cos(theta) * vector.z;
  target.set( x, y, z );
}


