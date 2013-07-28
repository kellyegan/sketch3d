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
boolean clickStarted;

//View stuff
PMatrix3D inverseTransform;
PVector offset, rotation;
PVector cursor, cursorTransformed, max, min;
PVector rotationStarted, rotationEnded, oldRotation, rotationCenter;


float rotationStep = TWO_PI / 45;

void setup() {
  size(1280, 768, P3D);
//  size(displayWidth, displayHeight, P3D);

  smooth();

  //GUI
  createControllers();

  //Kinect
  kinect = new SimpleOpenNI(this);
  kinectStatus = "Looking for Kinect...";
  if ( SimpleOpenNI.deviceCount() > 0 ) {
    kinect.enableDepth();
    kinect.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
    kinectStatus = "Kinect found. Waiting for user...";
    skeleton = new Skeleton(this, kinect, 1, Skeleton.LEFT_HANDED );
    cursor = new PVector();
    min = new PVector( Float.MAX_VALUE, Float.MAX_VALUE, Float.MAX_VALUE );
    max = new PVector( Float.MIN_VALUE, Float.MIN_VALUE, Float.MIN_VALUE );
    deviceReady = true;
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
  clickStarted = false;

  //View
  inverseTransform = new PMatrix3D();
  offset = new PVector( 0, 0, -1750);
  rotation = new PVector();

  cursor = new PVector();
  cursorTransformed = new PVector();
  
  rotationStarted = new PVector();
  rotationEnded = new PVector();
  rotationCenter = new PVector( 0, 0, 1000 );
  oldRotation = new PVector();

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

    if ( mousePressed && !cp5.isMouseOver() ) {
      switch( mouseButton ) {
        //DRAWING
        case LEFT:
          if ( !clickStarted ) {
            clickStarted = true;
            d.startStroke(new Brush( "", cp.getColorValue(), strokeWeight ) );
          }
          d.addPoint( (float)millis() / 1000.0, cursorTransformed.x, cursorTransformed.y, cursorTransformed.z);
          break;
        //ROTATION
        case RIGHT:
          if ( !clickStarted ) {
            clickStarted = true;
            rotationStarted.set(cursorTransformed);
            oldRotation.set( rotation );
          }
          rotationEnded.set(cursorTransformed);
          stroke(255, 0,0);
          line( 0,0,0, rotationEnded.x, rotationEnded.y, rotationEnded.z);
          rotation.y = oldRotation.y + atan2( rotationEnded.x, rotationEnded.z ) - atan2( rotationStarted.x, rotationStarted.z );
          println( "Rotation: " + rotation.y);
//          rotation.y = oldRotation.y + PVector.angleBetween( rotationStarted, cursorTransformed );
          break;
        //COLOR
        case CENTER:
          if ( !clickStarted ) {
            clickStarted = true;
          }
          break;
      }
    }

    updateCursor();
    println("Cursor: " + cursor + "  Max: " + max + "  Min: " + min);
  }

  /*************************************** DISPLAY **************************************/
  background(220);

  pushMatrix();
  translate(width/2, height/2, offset.z);

  if ( deviceReady ) {
    pushMatrix();
    rotateX(PI);
    rotateY(PI);
    translate(offset.x, offset.y, offset.z);
    skeleton.display();
    popMatrix();
  }

  rotateX(rotation.x);
  rotateY(rotation.y);

  d.display();

  popMatrix();
}

void mouseReleased() {
  clickStarted = false;
  d.endStroke();
}

void mousePressed() {
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
  //cursor.set( mouseX, mouseY, 0 );
  cursorTransformed.set( cursor );
  inverseTransform.reset();
  inverseTransform.rotateY( PI - rotation.y );
  inverseTransform.rotateX( PI - rotation.x );
  inverseTransform.translate( offset.x, offset.y, offset.z );
  inverseTransform.mult( cursor, cursorTransformed );
  
  max.set( max( cursor.x, max.x), max( cursor.y, max.y), max( cursor.z, max.z) );
  min.set( min( cursor.x, min.x), min( cursor.y, min.y), min( cursor.z, min.z) );
}

void createControllers() {
  //GUI
  cp5 = new ControlP5(this);

  Group brushCtrl = cp5.addGroup("Brush")
    .setPosition(width- (270 + 25), 150)
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
  kinect.startPoseDetection("Psi", userId);
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
