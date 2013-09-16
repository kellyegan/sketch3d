/*
 draw3d
 Copyright Kelly Egan 2013
 */

import controlP5.*;
import processing.core.PApplet;
import SimpleOpenNI.*;

ControlP5 cp5;
ColorPicker cp;

boolean drawingNow, moveDrawing, rotatingNow;    //Current button states 
boolean up, down, left, right;

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

color bgColor;

//View stuff
PVector cameraPos, cameraFocus;

PMatrix3D inverseTransform;
PVector offset, rotation;
PVector moveStart, moveNow, moveDelta, moveModel, oldOffset;

PVector drawingHand, drawingHandTransformed, secondaryHand, secondaryHandTransformed;
PVector rotationStarted, rotationEnded, oldRotation, rotationCenter;
PShader fogShader, fogTextShader;
PImage brush;

boolean displayOrigin;  //Display the origin
boolean displayUser;  //Display the origin

float rotationStep = TAU / 180;

void setup() {
  //size(1280, 768, P3D);
  size(displayWidth, displayHeight, P3D);

  smooth();

  //GUI
  createControllers();
  displayOrigin = true;
  displayUser = true;  
  
  drawingNow = false;
  moveDrawing = false;
  rotatingNow= false;

  //Kinect
  kinect = new SimpleOpenNI(this);
  kinectStatus = "Looking for Kinect...";
  if ( SimpleOpenNI.deviceCount() > 0 ) {
    kinect.enableDepth();
    kinect.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
    kinectStatus = "Kinect found. Waiting for user...";
    skeleton = new Skeleton(this, kinect, 1, Skeleton.LEFT_HANDED );
    deviceReady = true;
  } else {
    kinectStatus = "No Kinect found. ";
    deviceReady = false;
  }

  //Drawing
  d = new Drawing(this, "default.gml");
  defaultBrush = new Brush("draw3d_default_00001", color(0, 0, 0, 255), 1);
  strokeWeight = 20.0;
  brushColor = color(0, 0, 0);
  clickStarted = false;

  //View
  cameraPos = new PVector( 0, 0, 4000 );
  cameraFocus = new PVector();
  inverseTransform = new PMatrix3D();
  offset = new PVector( 0, 0, 0);
  moveStart = new PVector();
  moveNow = new PVector();
  moveDelta = new PVector();
  moveModel = new PVector();
  oldOffset = new PVector();
  
  rotation = new PVector();
  
  bgColor = color(220.0);
  fogShader = loadShader("fog_frag.glsl", "fog_vert.glsl");
  fogShader.set("fogNear", -offset.z);
  fogShader.set("fogFar", 4000.0);
  fogShader.set("fogColor", red(bgColor)/255, green(bgColor)/255, blue(bgColor)/255, 1.0);
  
  fogTextShader = loadShader("fog_text_frag.glsl", "fog_text_vert.glsl");
  fogTextShader.set("weight", 100.0);
  brush = loadImage("brush.png");
  fogTextShader.set("sprite", brush);
  fogTextShader.set("fogNear", 0.25 * (cameraPos.z - cameraFocus.z) );
  fogTextShader.set("fogFar",  1.75 * (cameraPos.z - cameraFocus.z) );
  fogTextShader.set("fogColor", red(bgColor)/255, green(bgColor)/255, blue(bgColor)/255, 1.0);
  
  drawingHand = new PVector();
  drawingHandTransformed = new PVector();
  secondaryHand = new PVector();
  secondaryHandTransformed = new PVector();
  
  rotationStarted = new PVector();
  rotationEnded = new PVector();
  rotationCenter = new PVector( 0, 0, 1000 );
  oldRotation = new PVector();

  hint(DISABLE_DEPTH_MASK);

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
  if( up ) {
    rotation.x += rotationStep;
  }
  if( down ) {
    rotation.x -= rotationStep;
  }
  if( right ) {
      rotation.y += rotationStep;    
  }
  if( left ) {
      rotation.y -= rotationStep;
  }
  
  if (deviceReady) {
    kinect.update();
    skeleton.update( drawingHand );
    skeleton.getSecondaryHand( secondaryHand );
    updateDrawingHand();



    if( !cp5.isMouseOver() ) {
      if( drawingNow ) {
          d.addPoint( (float)millis() / 1000.0, drawingHandTransformed.x, drawingHandTransformed.y, drawingHandTransformed.z);
      }
      if( rotatingNow ) {
          rotationEnded.set(secondaryHand);
          stroke(255, 0,0);
          rotation.x = oldRotation.x + map( rotationStarted.y - rotationEnded.y, -1000, 1000, -PI/2, PI/2 );
          rotation.y = oldRotation.y + map( rotationStarted.x - rotationEnded.x, -1000, 1000, -PI/2, PI/2 );
          println( "Rotation: " + degrees(rotation.y) + "  Delta: " + degrees( map( rotationStarted.x - rotationEnded.x, -1000, 1000, -PI, PI )) 
            + "  x difference: " + (rotationStarted.x -rotationEnded.x) );        
      }
      if( moveDrawing ) {
        moveNow.set( secondaryHand );
        PVector.sub( moveNow, moveStart, moveDelta );
        moveDelta.set( moveDelta.x, moveDelta.y, moveDelta.z );
        inverseTransform.mult( moveDelta, moveModel );
        offset = PVector.add( oldOffset, moveModel );
      }
    }
    
  }

  /*************************************** DISPLAY **************************************/
  background(220);

  pushMatrix();
  
  camera( cameraPos.x, cameraPos.y, cameraPos.z, cameraFocus.x, cameraFocus.y, cameraFocus.z, 0, 1, 0);
  perspective();

  
  shader(fogShader, LINES);
  
  if ( deviceReady && displayUser) {
    pushMatrix();
    rotateX(PI);
    rotateY(PI);
    skeleton.display();
    popMatrix();
  }

 rotateX(rotation.x);
 rotateY(rotation.y);

 if ( displayOrigin ) {
    strokeWeight(3);
    stroke(255, 0, 0);
    line( 0, 0, 0, 0, 0, 500);
    stroke(0, 255, 0);
    line( 0, 0, 0, 0, -500, 0);
    stroke(0, 0, 255);
    line( 0, 0, 0, 500, 0, 0);    
  }

  shader(fogTextShader, LINES);
  
  translate(offset.x, offset.y, offset.z);
  d.display();

  popMatrix();
}


void mousePressed() {
  if(mouseButton==LEFT) {
    d.startStroke(new Brush( "", cp.getColorValue(), strokeWeight ) );
    drawingNow=true;
  }
  if(mouseButton==RIGHT) {
    rotationStarted.set(secondaryHand);
    oldRotation.set( rotation );
    rotatingNow=true;
  }
  if(mouseButton==CENTER) {
    moveDrawing=true;
    moveStart.set( secondaryHand );
    oldOffset.set( offset ); 
  }
}

void mouseReleased() {
  if(mouseButton==LEFT) {
    drawingNow=false;
    d.endStroke(); 
  }
  if(mouseButton==RIGHT)
    rotatingNow=false;
  if(mouseButton==CENTER)
    moveDrawing=false;
} 


void keyPressed() {
  if ( key == CODED ) {
    switch(keyCode) {
    case UP:
      up = true;
      break;
    case DOWN:
      down = true;
      break;
    case RIGHT:
      right = true;
      break;
    case LEFT:
      left = true;
      break;
    default:
    }
  } 
  else {
    switch(key) {
    case '0':
      offset.set( 0, 0, 0 );
      break;
    case 'b': case 'B':
      //Bottom view
      rotation.set(TAU / 4, 0, 0);
      break;
    case 'c': case 'C':
      d.clearStrokes();
      break;
    case 'f': case 'F':
      //Reset view rotation/translation
      rotation.set(0, 0, 0);
      break;
    case 'h': case 'H':
      skeleton.changeHand();
      break; 
    case 'l': case 'L':
      //Left view
      rotation.set(0, TAU / 4, 0);
      break; 
    case 'n': case 'N':
      skeleton.nextUser();
      break;
    case 'o': case 'O':
      //Hide the x, y, z axis
      displayOrigin = !displayOrigin;
      break;      
    case 'r': case 'R':
      //Right view
      rotation.set(0, -TAU / 4, 0);
      break;      
    case 's': case 'S':
      d.save("data/default.gml");
      break;
    case 't': case 'T':
      //Top view
      rotation.set(-TAU / 4, 0, 0);
      break;
    case 'u': case 'U':
      //Toggle user
      displayUser = !displayUser;
      break;
    case 'z': case 'Z':
      d.undoLastStroke();
      break;    
    }
  }
}

void keyReleased() {
  if ( key == CODED ) {
    switch(keyCode) {
    case UP:
      up = false;
      break;
    case DOWN:
      down = false;
      break;
    case RIGHT:
      right = false;
      break;
    case LEFT:
      left = false;
      break;
    default:
    }
  } 
}

boolean sketchFullScreen() {
  return true;
}

void stop() {
  
}

void updateDrawingHand() {
  //drawingHand.set( mouseX, mouseY, 0 );
  drawingHandTransformed.set( drawingHand );
  secondaryHandTransformed.set( secondaryHand );
  inverseTransform.reset();
  if( !moveDrawing ) {
    inverseTransform.translate( -offset.x, -offset.y, -offset.z );
  }
  inverseTransform.rotateY( PI - rotation.y );
  inverseTransform.rotateX( PI + rotation.x );

  inverseTransform.mult( drawingHand, drawingHandTransformed );
  inverseTransform.mult( secondaryHand, secondaryHandTransformed );
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
