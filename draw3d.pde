/*
  draw3d 0.1
  Copyright Kelly Egan 2013
  
  
*/

import controlP5.*;
import processing.core.PApplet;
import SimpleOpenNI.*;

/******************* Drawing related *******************/
Drawing d;
ControlP5 cp5;
ColorPicker cp;

Brush defaultBrush = new Brush("draw3d_default_00001", color(0, 0, 0, 255), 1);
float strokeWeight = 1;
int brushColor = color(0, 0, 0);

int strokeVal = 175;

int count = 0;
boolean drawing = false;
/*******************************************************/


/*********************** Kinect ************************/

SimpleOpenNI kinect;       //OpenNI context
boolean deviceReady;       //True if the Kinect is ready
Skeleton skeleton;           //Class for containing and drawing skeleton data
String kinectStatus;       //Reports current status of Kinect, User and Calibration

/*****************************************************/



/*********************** View ************************/
PVector offset;
float yRotation = 0;
float xRotation = 0;
float scale;

float rotationStep = TWO_PI / 180;
PVector mouseLocation, mouseLocationRotated;
/*****************************************************/


PFont statusFont;
PVector cursor;

void setup() {
  size(1024, 768, OPENGL);
  smooth();
  
  /*********************** GUI *************************/
  createControllers();
  
  statusFont = createFont("Helvetica", 30);
  textFont(statusFont, 30);
  /*****************************************************/
  
  /*********************** View ************************/
  offset = new PVector(width/2, height/2 , -1000);
  xRotation = PI;
  yRotation = PI;
  scale = 0.5;
  /*****************************************************/
  
  /********************** Drawing **********************/
  mouseLocation = new PVector( mouseX, mouseY, 0);
  mouseLocationRotated = new PVector();
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
  /*****************************************************/
  
  
  /********************** Kinect ***********************/
  kinect = new SimpleOpenNI(this);
  kinectStatus = "Looking for Kinect...";
  
  //Check if there is a Kinect connected
  if ( kinect.deviceCount() > 0 ) {
    deviceReady = true;
    kinect.enableDepth();
    kinect.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
    kinectStatus = "Kinect found. Waiting for user...";
    skeleton = new Skeleton(this, kinect, 1, Skeleton.LEFT_HANDED );
    cursor = new PVector();
  } 
  else {
    kinectStatus = "No Kinect found. ";
    deviceReady = false;
  }
  
  /*****************************************************/
  
}

void draw() {
  if( mousePressed && !cp5.isMouseOver() ) {
    checkForDrawing();   
  } 
  background(200, 200, 190);
  
  mouseLocation.set( mouseX, mouseY, 0 );
  mouseLocation.sub( offset );
  rotateVectorX(-xRotation, mouseLocation, mouseLocationRotated);
  rotateVectorY(-yRotation, mouseLocationRotated, mouseLocationRotated);
  
  hint(ENABLE_DEPTH_TEST);
  pushMatrix();
  translate(offset.x, offset.y, offset.z);
  rotateX(xRotation);
  rotateY(yRotation);

  // Drawing
  d.display();
  
  // Origin cross hairs
  noFill();
  stroke(200, 0, 0);
  line( 50, 0, 0, -50, 0, 0 );
  stroke(0, 200, 0);
  line( 0, 50, 0, 0, -50, 0 );
  stroke(0, 0, 200);
  line( 0, 0, 50, 0, 0, -50 );
  
  pushMatrix();
  translate( mouseLocationRotated.x, mouseLocationRotated.y, mouseLocationRotated.z);
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
  
  mouseLocation.set( mouseX, mouseY, 0 );
  mouseLocation.sub( offset );
  rotateVectorX(-xRotation, mouseLocation, mouseLocationRotated);
  rotateVectorY(-yRotation, mouseLocationRotated, mouseLocationRotated);

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

/**
  * Rotate a vector around the origin by a specific angle
  * @param theta Angle of rotation
  * @param vector 
  */
void rotateVectorX( float theta, PVector vector, PVector target ) {
  float x = vector.x;
  float y = cos(theta) * vector.y - sin(theta) * vector.z;
  float z = sin(theta) * vector.y + cos(theta) * vector.z;
  target.set( x, y, z );
}

/**
  * 
  */
void rotateVectorY( float theta, PVector vector, PVector target ) {
  float x =  cos(theta) * vector.x + 0 * vector.y + sin(theta) * vector.z;
  float y =           0 * vector.x + 1 * vector.y + 0          * vector.z;
  float z = -sin(theta) * vector.x + 0 * vector.y + cos(theta) * vector.z;
  target.set( x, y, z );
}



/************************************** SimpleOpenNI callbacks **************************************/

void onNewUser(int userId) {
  kinectStatus = "User found. Please assume Psi pose.";
  kinect.startPoseDetection("Psi",userId);   
}

void onLostUser(int userId) {
  kinectStatus = "User lost.";
}

void onStartPose(String pose, int userId) {
  kinectStatus = "Pose detected. Requesting calibration skeleton.";

  kinect.stopPoseDetection(userId); 
  kinect.requestCalibrationSkeleton(userId, true);
}

void onEndCalibration(int userId, boolean successfull) {
  if (successfull) { 
    kinectStatus = "Calibration ended successfully for user " + userId + " Tracking user.";
    println("  User calibrated !!!");
    kinect.startTrackingSkeleton(userId);
  } 
  else { 
    kinectStatus = "Calibration failed starting pose detection.";
    kinect.startPoseDetection("Psi", userId);
  }
}

