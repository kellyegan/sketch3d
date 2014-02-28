/*
 draw3d
 Copyright Kelly Egan 2013
 */

import controlP5.*;
import processing.core.PApplet;
import SimpleOpenNI.*;
import java.awt.Color;
import processing.dxf.*;

PFont font;

boolean drawingNow, moveDrawing, rotatingNow, pickingColor, pickingBackground;    //Current button states 
boolean up, down, left, right;

//Kinect
SimpleOpenNI kinect;
boolean deviceReady;
boolean handPicked;
Skeleton skeleton;
String kinectStatus, keyStatus;
int keyCount = 0;

//Drawing
Drawing d;
Brush defaultBrush;
float brushSize;
int brushColor, bgColor;
PVector brushColorHSB, bgColorHSB, oldBrushColorHSB, oldBgColorHSB;
boolean clickStarted;

int startMillis, logoDuration;

PImage bgImage;
boolean displayBackgroundImage;

//Exporting dxf
boolean exportDXF;

//View stuff
PVector cameraPos, cameraFocus;

PMatrix3D inverseTransform;
PVector offset, rotation;
PVector moveStart, moveNow, moveDelta, moveModel, oldOffset;

PVector drawingHand, drawingHandTransformed, secondaryHand, secondaryHandTransformed;
PVector rotationStarted, rotationEnded, oldRotation, rotationCenter;
PVector startPosition, currentPosition, positionDelta;
PShader fogShader, shader;
PImage brush;

boolean displayOrigin;  //Display the origin
boolean displaySkeleton;  //Display the origin

float rotationStep = TAU / 180;

void setup() {
  //size(1280, 768, P3D);
  size(displayWidth, displayHeight, P3D);

  smooth();

  //GUI
//  createControllers();
  font = createFont("Helvetica", 20);
  textFont(font, 20);
  
  displayOrigin = true;
  displaySkeleton = true;  
  
  drawingNow = false;
  moveDrawing = false;
  rotatingNow= false;
  pickingColor = false;
  pickingBackground = false;
  exportDXF = false;
  
  deviceReady = false;
  handPicked = false;
  
  //Kinect
  kinect = new SimpleOpenNI(this);
  kinectStatus = "Looking for Kinect...";
  keyStatus = "...";
  
  if ( SimpleOpenNI.deviceCount() > 0 ) {
    kinect.enableDepth();
    kinect.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
    kinectStatus = "Kinect found. Waiting for user...";
    println(kinectStatus);
    skeleton = new Skeleton(this, kinect, 1, Skeleton.RIGHT_HANDED );
    deviceReady = true;
  } 
  else {
    kinectStatus = "No Kinect found. ";
    println(kinectStatus);
  }
  
  //Drawing
  d = new Drawing(this, "default.gml");
  brushSize = 30.0;

  brushColorHSB = new PVector();
  oldBrushColorHSB = new PVector();
  brushColor = Color.HSBtoRGB( brushColorHSB.x, brushColorHSB.y, brushColorHSB.z);
  
  defaultBrush = new Brush("draw3d_default_00001", brushColor, brushSize);
  clickStarted = false;
  
  bgColorHSB = new PVector( 0.0, 0.0, 0.9 );
  oldBgColorHSB = new PVector();
  bgColor = Color.HSBtoRGB( bgColorHSB.x, bgColorHSB.y, bgColorHSB.z);
  
  bgImage = loadImage("data/testBackground.jpg");
  displayBackgroundImage = false;

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

  shader = loadShader("fogZLight_frag.glsl", "fogZLight_vert.glsl");
  shader.set("fogNear", cameraPos.z + 0.0 );
  shader.set("fogFar", cameraPos.z + 3500.0 );
  shader.set("fogColor", red(bgColor) / 255.0, green(bgColor) / 255.0, blue(bgColor) / 255.0, 1.0 );
  shader.set("zPlaneIndicatorOn", true);

  drawingHand = new PVector();
  drawingHandTransformed = new PVector();
  secondaryHand = new PVector();
  secondaryHandTransformed = new PVector();

  rotationStarted = new PVector();
  rotationEnded = new PVector();
  rotationCenter = new PVector( 0, 0, 1000 );
  oldRotation = new PVector();
  
  startPosition = new PVector();
  currentPosition = new PVector();
  positionDelta = new PVector();

  //hint(DISABLE_DEPTH_MASK);

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
  startMillis = millis();
  logoDuration = 10000; //10 seconds to display logo and pick hand.
  shader(shader);
}

void draw() {
  /*************************************** UPDATE ***************************************/
  if ( !handPicked && (millis() - startMillis) > logoDuration) {
    handPicked = true;
    d.clearStrokes();
  }

  if ( up ) {
    rotation.x += rotationStep;
  }
  if ( down ) {
    rotation.x -= rotationStep;
  }
  if ( right ) {
    rotation.y += rotationStep;
  }
  if ( left ) {
    rotation.y -= rotationStep;
  }

  if (deviceReady) {
    kinect.update();
    skeleton.update( drawingHand );
    skeleton.getSecondaryHand( secondaryHand );
    updateDrawingHand();
    kinectStatus = "zPlane: " + (cameraPos.z - drawingHand.z);
    shader.set("zPlane", cameraPos.z - drawingHand.z );
    
    if ( !pickingColor && !pickingBackground ) {
      if ( drawingNow ) {
        d.addPoint( (float)millis() / 1000.0, drawingHandTransformed.x, drawingHandTransformed.y, drawingHandTransformed.z);
      }
      if ( rotatingNow ) {
        rotationEnded.set(secondaryHand);
        stroke(255, 0, 0);
        rotation.x = oldRotation.x + map( rotationStarted.y - rotationEnded.y, -1000, 1000, -PI/2, PI/2 );
        rotation.y = oldRotation.y + map( rotationStarted.x - rotationEnded.x, -1000, 1000, -PI/2, PI/2 );
      }
      if ( moveDrawing && !drawingNow ) {
        moveNow.set( secondaryHand );
        PVector.sub( moveNow, moveStart, moveDelta );
        moveDelta.set( moveDelta.x, moveDelta.y, moveDelta.z );
        inverseTransform.mult( moveDelta, moveModel );
        offset = PVector.add( oldOffset, moveModel );
      }
    } 
    else {
      //Picking color
      positionDelta = PVector.sub( drawingHand, startPosition );

      if ( pickingColor ) {
        brushColorHSB.x = (map( positionDelta.x, 0, 700, 0, 1.0 ) + oldBrushColorHSB.x) % 1.0;  //Hue
        brushColorHSB.x = brushColorHSB.x == 1.0 ? 0.0 : brushColorHSB.x;
        brushColorHSB.z = constrain( map( positionDelta.y, 0, 300, 0, 1.0 ) + oldBrushColorHSB.z, 0, 1.0);  //Brightness
        brushColorHSB.y = constrain( map( -positionDelta.z, 0, 400, 0, 1.0 ) + oldBrushColorHSB.y, 0, 1.0);  //Saturation
        brushColor = Color.HSBtoRGB( brushColorHSB.x, brushColorHSB.y, brushColorHSB.z );
      } 
      else {
        bgColorHSB.x = (map( positionDelta.x, 0, 700, 0, 1.0 ) + oldBgColorHSB.x) % 1.0;  //Hue
        bgColorHSB.x = bgColorHSB.x == 1.0 ? 0.0 : bgColorHSB.x;
        bgColorHSB.z = constrain( map( positionDelta.y, 0, 300, 0, 1.0 ) + oldBgColorHSB.z, 0, 1.0);  //Brightness
        bgColorHSB.y = constrain( map( -positionDelta.z, 0, 400, 0, 1.0 ) + oldBgColorHSB.y, 0, 1.0);  //Saturation
        bgColor = Color.HSBtoRGB( bgColorHSB.x, bgColorHSB.y, bgColorHSB.z );
      }
    }
  }

  /*************************************** DISPLAY **************************************/
  directionalLight(255, 255, 255, 0, 0.5, 0.5);
  
  if ( exportDXF ) {
    beginRaw( DXF, "frame-####.dxf");
  }
  background(bgColor);
  if ( displayBackgroundImage && !exportDXF) {
    image( bgImage, width/2-bgImage.width/2, height/2-bgImage.height/2 );
  }

  if ( !exportDXF ) {
    fill(100);
    text(keyStatus, 40, height - 80);
    text(kinectStatus, 40, height - 60);
    noFill();
  }

  pushMatrix();
  
  if( true ) {
    //lights();
  }
  camera( cameraPos.x, cameraPos.y, cameraPos.z, cameraFocus.x, cameraFocus.y, cameraFocus.z, 0, 1, 0);
  //perspective();
  
  if ( deviceReady && !exportDXF) {
    pushMatrix();
    rotateX(PI);
    rotateY(PI);
    skeleton.display(displaySkeleton, brushSize, brushColor);
    popMatrix();
  }
  
  rotateX(rotation.x);
  rotateY(rotation.y);
  
  if ( displayOrigin && !exportDXF) {
    strokeWeight(3);
    stroke(255, 0, 0);
    line( 0, 0, 0, 0, 0, 500);
    stroke(0, 255, 0);
    line( 0, 0, 0, 0, -500, 0);
    stroke(0, 0, 255);
    line( 0, 0, 0, 500, 0, 0);
  }
    
  translate(offset.x, offset.y, offset.z);
  d.display();
  
  popMatrix();
  
  if ( exportDXF ) {
    endRaw();
    exportDXF = false;
  }
  
  if ( pickingColor ) {
    noStroke();
    fill(brushColor);
    ellipse(  width/2, height/2, 400, 400);
  }
}

void mousePressed() {
  if (mouseButton==LEFT) {
    println( red(brushColor));
    d.startStroke(new Brush( "", brushColor, brushSize ) );
    drawingNow=true;
    keyStatus += " Left mouse.";
  }
  if (mouseButton==RIGHT) {
    rotationStarted.set(secondaryHand);
    oldRotation.set( rotation );
    rotatingNow=true;
    keyStatus += " Right mouse.";
  }
  if (mouseButton==CENTER) {
    moveDrawing=true;
    moveStart.set( secondaryHand );
    oldOffset.set( offset );
    keyStatus += " Center mouse.";
  }
}

void mouseReleased() {
  if (mouseButton==LEFT) {
    drawingNow=false;
    d.endStroke();
  }
  if (mouseButton==RIGHT)
    rotatingNow=false;
  if (mouseButton==CENTER)
    moveDrawing=false;
} 

void keyPressed() {
  keyCount++;  
  keyStatus = " pressed. " + keyCount + " keys pressed";
  if ( handPicked ) {
    if ( key == CODED ) {
      switch(keyCode) {
      case UP:
        up = true;
        keyStatus = "'UP'" + keyStatus;
        break;
      case DOWN:
        down = true;
        keyStatus = "'DOWN'" + keyStatus;
        break;
      case RIGHT:
        right = true;
        keyStatus = "'RIGHT'" + keyStatus;
        break;
      case LEFT:
        left = true;
        keyStatus = "'LEFT'" + keyStatus;
        break;
      default:
      }
    } 
    else {
      keyStatus = key + keyStatus;
      switch(key) {
      case 'g': 
      case 'G':
        offset.set( 0, 0, 0 );
        break;
      case 'a': 
      case 'A':
        //Hide the x, y, z axis
        displayOrigin = !displayOrigin;
        break; 
      case 'b':  
      case 'B':
        //Change background color
        pickingBackground = true;
        oldBgColorHSB.set( bgColorHSB );
        startPosition.set( drawingHand );
        break;
      case 'c': 
      case 'C':
        //Change stroke color
        pickingColor = true;
        oldBrushColorHSB.set( brushColorHSB );
        startPosition.set( drawingHand );
        break;
      case 'd': 
      case 'D':
        d.startStroke(new Brush( "", brushColor, brushSize ) );
        drawingNow=true;
        break;
      case 'e': 
      case 'E':
        exportDXF = true;
        break;
      case 'f': 
      case 'F':
        //Reset view rotation/translation
        rotation.set(0, 0, 0);
        break;
      case 'h':  
      case 'H':
        skeleton.changeHand();
        break; 
      case 'i':  
      case 'I':
        displayBackgroundImage = !displayBackgroundImage;
        break;
      case 'l':  
      case 'L':
        selectInput("Please select a background image", "loadBackground" );
        //Left view
        //      rotation.set(0, TAU / 4, 0);
        break; 
      case 'm': 
      case 'M':
        moveDrawing=true;
        moveStart.set( secondaryHand );
        oldOffset.set( offset );
        break;
      case 'n': 
      case 'N':
        skeleton.reset();
        kinect.init();
        setup();
        break;
      case 'o': 
      case 'O':
        //Open a file
        selectInput("Please select a drawing to load", "loadDrawing" );
      case 'r': 
      case 'R':
        rotationStarted.set(secondaryHand);
        oldRotation.set( rotation );
        rotatingNow=true;      
        //Right view
        //rotation.set(0, -TAU / 4, 0);
        break;     
      case 's': 
      case 'S':
        selectOutput("Save drawing:", "saveDrawing");
        //      String timestamp = year() + nf(month(),2) + nf(day(),2) + "-"  + nf(hour(),2) + nf(minute(),2) + nf(second(),2);
        //      d.save( "makerfaire/mf_" + timestamp + ".gml");
        break;
      case 't': 
      case 'T':
        //Top view
        rotation.set(-TAU / 4, 0, 0);
        break;
      case 'u': 
      case 'U':
        //Toggle user
        displaySkeleton = !displaySkeleton;
        break;
      case 'q': 
      case 'Q':
        exit();
        break;
      case 'x': 
      case 'X':
        d.clearStrokes();
        break;
      case 'z': 
      case 'Z':
        d.undoLastStroke();
        break; 
      case '-': 
      case '_':
        brushSize -= 5;
        println("Brush decreased: " + brushSize);
        break;
      case '=': 
      case '+':
        brushSize += 5;
        println("Brush increased: " + brushSize);
      case '0':
        break;
      case '1':
        break;
      case '2':
        break;
      case '3':
        break;
      case '4':
        break;
      case '5':
        rotation.set(TAU / 4, 0, 0);
        break;
      case '6':
        break;
      case '7':
        break;
      case '8':
        break;
      case '9':
        break;
      }
    }
  } 
  else {
    if ( key == CODED && keyCode == LEFT) {
      skeleton.setHand( Skeleton.LEFT_HANDED );
    } 
    else {
      skeleton.setHand( Skeleton.RIGHT_HANDED );
    }
    handPicked = true;
    d.clearStrokes();
  }
}

void keyReleased() {
  keyCount--;
  keyStatus = " released. " + keyCount + " keys pressed";

  if ( key == CODED ) {
    switch(keyCode) {
    case UP:
      up = false;
      keyStatus = "'UP'" + keyStatus;
      break;
    case DOWN:
      down = false;
      keyStatus = "'DOWN'" + keyStatus;
      break;
    case RIGHT:
      right = false;
      keyStatus = "'RIGHT'" + keyStatus;
      break;
    case LEFT:
      left = false;
      keyStatus = "'LEFT'" + keyStatus;
      break;
    default:
    }
  } 
  else {
    keyStatus = key + keyStatus;
    switch(key) {
    case 'b': 
    case 'B':
      pickingBackground = false;
      break;
    case 'c': 
    case 'C':
      pickingColor = false;
      break;
    case 'd': 
    case 'D':
      drawingNow=false;
      d.endStroke();
      break;
    case 'm': 
    case 'M':
      moveDrawing=false;
      break;
    case 'r': 
    case 'R':
      rotatingNow=false;
      break;
    }
  }
}

//boolean sketchFullScreen() {
//  return true;
//}

void stop() {
}

void loadDrawing( File f ) {
  if ( f != null ) {
    try {
      d.clearStrokes();
      d.load( f.getAbsolutePath() );
    } 
    catch (Exception e) {
      e.printStackTrace();
    }
  }
}

void saveDrawing(File f) {
  if ( f != null ) {
    try {
      d.save( f.getAbsolutePath() );
    } 
    catch (Exception e) {
      e.printStackTrace();
    }
  }
}

void loadBackground( File f ) {
  if ( f != null ) {
    try {
      bgImage = loadImage( f.getAbsolutePath() );
      displayBackgroundImage = true;
    } 
    catch (Exception e) {
      e.printStackTrace();
    }
  }
}

void updateDrawingHand() {
  //drawingHand.set( mouseX, mouseY, 0 );
  drawingHandTransformed.set( drawingHand );
  secondaryHandTransformed.set( secondaryHand );
  inverseTransform.reset();
  if ( !moveDrawing ) {
    inverseTransform.translate( -offset.x, -offset.y, -offset.z );
  }
  inverseTransform.rotateY( PI - rotation.y );
  inverseTransform.rotateX( PI + rotation.x );

  inverseTransform.mult( drawingHand, drawingHandTransformed );
  inverseTransform.mult( secondaryHand, secondaryHandTransformed );
}

//void createControllers() {
//  //GUI
//  cp5 = new ControlP5(this);
//
//  Group brushCtrl = cp5.addGroup("Brush")
//    .setPosition(width- (270 + 25), 150)
//    .setBackgroundHeight(100)
//    .setBackgroundColor(color(100, 100))
//    .setSize(270, 125)
//    ;
//
//  cp5.addSlider("brushSize")
//    .setGroup(brushCtrl)
//      .setRange(1, 50)
//        .setPosition(5, 20)
//          .setSize(200, 20)
//            .setValue(1)
//              .setLabel("Stroke weight")
//              ;
//
//  cp = cp5.addColorPicker("brushColor")
//    .setPosition(5, 50)
//      .setColorValue(color(0, 0, 0, 255))
//        .setGroup(brushCtrl)
//          ;
//
//  // reposition the Label for controller 'slider'
//  cp5.getController("brushSize")
//    .getValueLabel()
//      .align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE)
//        .setPaddingX(0)
//          ;
//  cp5.getController("brushSize")
//    .getCaptionLabel()
//      .align(ControlP5.RIGHT, ControlP5.TOP_OUTSIDE)
//        .setPaddingX(0)
//          ;
//}


/************************************** SimpleOpenNI callbacks **************************************/

void onNewUser(int userId) {
  kinectStatus = "User " + userId + " found.  Please assume Psi pose.";
  println( kinectStatus );
  kinect.startPoseDetection("Psi", userId);
}

void onLostUser(int userId) {
  kinectStatus = "User " + userId + " lost.";
  println( kinectStatus);
}

void onStartPose(String pose, int userId) {
  kinectStatus = pose + " pose detected for user " + userId + ". Requesting calibration skeleton.";
  println( kinectStatus);
  kinect.stopPoseDetection(userId); 
  kinect.requestCalibrationSkeleton(userId, true);
}

void onEndCalibration(int userId, boolean successful) {
  if (successful) { 
    kinectStatus = "Calibration ended successfully for user " + userId + " Tracking user.";
    println( kinectStatus );
    kinect.startTrackingSkeleton(userId);
    skeleton.setUser(userId);
  } 
  else { 
    kinectStatus = "Calibration failed starting pose detection.";
    kinect.startPoseDetection("Psi", userId);
  }
}

