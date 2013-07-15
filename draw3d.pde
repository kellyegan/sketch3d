/*
  draw3d
  Copyright Kelly Egan 2013
  
 */

import controlP5.*;
import processing.core.PApplet;
import SimpleOpenNI.*;


ControlP5 cp5;
ColorPicker cp;

//Kinect
SimpleOpenNI kinect;
boolean deviceReady;
Skeleton skeleton;
String kinectStatus;

//Drawing
Drawing d;
Brush defaultBrush;
float strokeWeight;
int brushColor;
boolean drawing;

//View stuff
PMatrix3D inverseTransform;
PVector offset, rotation;
PVector cursor, cursorTransformed;

float rotationStep = TWO_PI / 180;

void setup() {
  size(1024, 768, OPENGL);
  smooth();

  //GUI
  createControllers();
  
  //Kinect
  kinect = new SimpleOpenNI(this);
  kinectStatus = "Looking for Kinect...";
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
  
  //Drawing
  d = new Drawing(this, "default.gml");
  defaultBrush = new Brush("draw3d_default_00001", color(0, 0, 0, 255), 1);
  strokeWeight = 1;
  brushColor = color(0, 0, 0);
  drawing = false;

  //View
  inverseTransform = new PMatrix3D();
  offset = new PVector( width/2, height/2, 0);
  rotation = new PVector();
  
  cursor = new PVector();
  cursorTransformed = new PVector();
  
//
//  File path = new File(sketchPath + "/data");  
//
//  for ( File file : path.listFiles() ) {
//    if ( file.toString().endsWith(".gml") ) {
//      background(255);
//      d = new Drawing(this, file.toString() );
//    }
//  }
//  println(this);
  
}

void draw() {
  /*************************************** UPDATE ***************************************/
  if (deviceReady) {
    kinect.update();
    skeleton.update( cursor );
  }
  
  updateCursor();

  if ( mousePressed && !cp5.isMouseOver() ) {
    if ( !drawing ) {
      drawing = true;
      d.startStroke(new Brush( "", cp.getColorValue(), strokeWeight ) );
    }
    d.addPoint( (float)millis() / 1000.0, cursorTransformed.x, cursorTransformed.y, cursorTransformed.z);
  } 

  /*************************************** DISPLAY **************************************/
  background(200, 200, 190);
    
  pushMatrix();
  translate(offset.x, offset.y, offset.z);
  rotateX(rotation.x);
  rotateY(rotation.y);

  d.display();

  pushMatrix();
  translate( cursorTransformed.x, cursorTransformed.y, cursorTransformed.z);
  ellipse(0, 0, 6, 6);
  popMatrix();

  popMatrix();
}

void mouseReleased() {
  drawing = false;
  d.endStroke();
}

void keyPressed() {
  if ( key == CODED ) {
    switch(keyCode) {
    case UP:
      rotation.x += rotationStep;
      break;
    case DOWN:
      rotation.x -= rotationStep;
      break;
    case RIGHT:
      rotation.y += rotationStep;
      break;
    case LEFT:
      rotation.y -= rotationStep;
      break;
    default:
    }
  } 
  else {
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

void updateCursor() {
  cursor.set( mouseX, mouseY, 0 );
  cursorTransformed.set( cursor );
  inverseTransform.reset();
  inverseTransform.rotateZ( -rotation.z );
  inverseTransform.rotateY( -rotation.y );
  inverseTransform.rotateX( -rotation.x );
  inverseTransform.translate( -offset.x, -offset.y, -offset.z );
  inverseTransform.mult( cursor, cursorTransformed );
}

void createControllers() {
  //GUI
  cp5 = new ControlP5(this);

  Group brushCtrl = cp5.addGroup("Brush")
    .setPosition(50, 50)
    .setBackgroundHeight(100)
    .setBackgroundColor(color(100, 100))
    .setSize(270, 125)
    ;

  cp5.addSlider("strokeWeight")
    .setGroup(brushCtrl)
    .setRange(1, 50)
    .setPosition(5, 20)
    .setSize(200, 20)
    .setValue(1)
    .setLabel("Stroke weight");
    ;

  cp = cp5.addColorPicker("brushColor")
    .setPosition(5, 50)
    .setColorValue(color(0, 0, 0, 255))
    .setGroup(brushCtrl)
    ;

  // reposition the Label for controller 'slider'
  cp5.getController("strokeWeight")
    .getValueLabel()
    .align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE)
    .setPaddingX(0)
    ;
  cp5.getController("strokeWeight")
    .getCaptionLabel()
    .align(ControlP5.RIGHT, ControlP5.TOP_OUTSIDE)
    .setPaddingX(0)
    ;
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
