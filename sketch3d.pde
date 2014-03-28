/*
 draw3d
 Copyright Kelly Egan 2013
 */

import controlP5.*;
import processing.core.PApplet;
import SimpleOpenNI.*;
import java.awt.Color;
import processing.dxf.*;
import processing.pdf.*;

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
PVector brushColorHSB, bgColorHSB, oldBrushColorHSB, oldBgColorHSB;
boolean clickStarted;

int brushColor, bgColor;
boolean currentColor;
boolean FOREGROUND = true;
boolean BACKGROUND = false;

int startMillis, logoDuration;

PImage bgImage;
boolean displayBackgroundImage;

//Exporting dxf
boolean exportDXF;
boolean exportPDF;

//View stuff
ControlP5 cp5;
ColorChooserController colorChooser;
Group colorGroup;
Toggle fgbgToggle;

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
  size(1280, 768, P3D);
  //size(displayWidth, displayHeight, P3D);

  //smooth();

  //GUI
  cp5 = new ControlP5(this);
  createControllers( cp5 );
  cp5.setAutoDraw(false);
  cp5.getPointer().enable();

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
  exportPDF = false;

  deviceReady = false;
  handPicked = false;

  //Kinect
  kinect = new SimpleOpenNI(this);
  kinectStatus = "Looking for Kinect...";
  keyStatus = "...";

  if ( SimpleOpenNI.deviceCount() > 0 ) {
    kinect.enableDepth();

    //    kinect.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);     //Older Version of simpleOpenNI   
    kinect.enableUser();                                //Version 1.9.6 of simpleOpenNI

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

  brushColorHSB = new PVector(0.0, 0.0, 1.0);
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
  cameraPos = new PVector( 0, 0, 3500 );
  cameraFocus = new PVector();
  inverseTransform = new PMatrix3D();
  offset = new PVector( 0, 0, 0 );
  moveStart = new PVector();
  moveNow = new PVector();
  moveDelta = new PVector();
  moveModel = new PVector();
  oldOffset = new PVector();

  rotation = new PVector();

  shader = loadShader("fogZLight_frag.glsl", "fogZLight_vert.glsl");
  shader.set("fogNear", cameraPos.z - 1500.0 );
  shader.set("fogFar", cameraPos.z + 0.0 );
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
  update();

  /*************************************** DISPLAY **************************************/

  hint(ENABLE_DEPTH_TEST);
  pushMatrix();

  directionalLight(255, 255, 255, 0, 0.5, 0.5);

  if ( exportDXF ) {    
    beginRaw( DXF, "frame-####.dxf");
  }
  if ( exportPDF ) {
    beginRaw( PDF, "frame-####.pdf");
  }

  background(bgColor);
  if ( displayBackgroundImage && !exportDXF && !exportPDF) {
    image( bgImage, width/2-bgImage.width/2, height/2-bgImage.height/2 );
  }

  if ( !exportDXF && !exportPDF) {
    fill(100);
    text(keyStatus, 40, height - 80);
    text(kinectStatus, 40, height - 60);
    noFill();
  }

  if ( true ) {
    //lights();
  }
  camera( cameraPos.x, cameraPos.y, cameraPos.z, cameraFocus.x, cameraFocus.y, cameraFocus.z, 0, 1, 0);
  //perspective();

  //Set the cursor for the menus
  cp5.getPointer().set( width-(int)screenX( drawingHand.x, drawingHand.y, drawingHand.z), height-(int)screenY( drawingHand.x, drawingHand.y, drawingHand.z) );


  if ( deviceReady && !exportDXF && !exportPDF) {
    pushMatrix();
    rotateX(PI);
    rotateY(PI);
    skeleton.display(displaySkeleton, brushSize, brushColor);
    popMatrix();
  }

  rotateX(rotation.x);
  rotateY(rotation.y);

  if ( displayOrigin && !exportDXF  && !exportPDF) {
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

  if ( exportDXF || exportPDF ) {
    endRaw();
    exportDXF = false;
    exportPDF = false;
  }

  hint(DISABLE_DEPTH_TEST);
  camera();
  noLights();

  //Draw the user face 
  //This is manually drawn so that the custom pointer will be seen.
  cp5.draw();

  if ( pickingColor ) {
    if ( currentColor == FOREGROUND ) {
      brushColor = colorChooser.getColorValue();
      fgbgToggle.setColorForeground(brushColor);
    } 
    else {
      bgColor = colorChooser.getColorValue();
      shader.set("fogColor", red(bgColor) / 255.0, green(bgColor) / 255.0, blue(bgColor) / 255.0, 1.0 );
      fgbgToggle.setColorBackground(bgColor);
    }

    stroke( 255 );
    float x = cp5.getPointer().getX();
    float y = cp5.getPointer().getY();
    line( x, y - 10, x, y + 10 );
    line( x - 10, y, x + 10, y );
  }
}


/*************************************** UPDATE ***************************************/
void update() {
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
}

void mousePressed() {
  if ( pickingColor ) {
    cp5.getPointer().pressed();
  } 
  else {
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
}

void mouseReleased() {
  if ( pickingColor ) {
    cp5.getPointer().released();
  } 
  else {
    if (mouseButton==LEFT) {
      drawingNow=false;
      d.endStroke();
    }
    if (mouseButton==RIGHT)
      rotatingNow=false;
    if (mouseButton==CENTER)
      moveDrawing=false;
  }
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
      case 'c': 
      case 'C':
        //Change stroke color
        pickingColor = !pickingColor;
        colorGroup.setVisible( pickingColor );
        break;
      case 'd': 
      case 'D':
        cp5.getPointer().pressed(); 
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
        selectInput("Please select a drawing to open", "loadDrawing" );
        break;
      case 'p': 
      case 'P':
        exportPDF = true;
        break;
      case 'r': 
      case 'R':
        rotationStarted.set(secondaryHand);
        oldRotation.set( rotation );
        rotatingNow=true;      
        break;     
      case 's': 
      case 'S':
        selectOutput("Save drawing:", "saveDrawing");
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
        break;
      case '=': 
      case '+':
        brushSize += 5;
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
    case 'd': 
    case 'D':
      cp5.getPointer().released();
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

void exportPDF(File f) {
  if ( f != null ) {
    try {
      d.save( f.getAbsolutePath() );
    } 
    catch (Exception e) {
      e.printStackTrace();
    }
  }
}

void exportDXF(File f) {
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

void createControllers(ControlP5 cp5) {

  currentColor = FOREGROUND;
  brushColor = color(0);
  bgColor = color(255);

  colorGroup = cp5.addGroup("colorChooserGroup")
    .setPosition( width / 2 - 200, height / 2 - 200 )
      .setSize( 400, 460 )
        .setBackgroundColor( color(100, 100, 100, 128) )
          .setColor( new CColor(0xFFFFFF00, 0xFFFFFF00, 0xFFFFFF00, 0xFFFFFF00, 0xFFFFFF00) )
            .setLabel("")
              .hide()
                ; 

  fgbgToggle = cp5.addToggle("currentColor")
    .setGroup(colorGroup)
      .setPosition( 20, 20 )
        .setSize(360, 160)
          .setView(new ColorToggleView())
            .setState( FOREGROUND )
              .setColorBackground( bgColor )
                .setColorForeground( brushColor )
                  ;

  colorChooser = new ColorChooserController( cp5, "colorChooser")
    .setGroup(colorGroup)
      .setPosition(20, 200)
        .setSize(360, 240)
          .setColorValue( brushColor );
  ;
}

/************************************** SimpleOpenNI callbacks **************************************/

/*************** For version 1.9.6 of simpleOpenNi ***************/
void onNewUser(SimpleOpenNI kinect, int userId) {
  kinectStatus = "User " + userId + " found.  Please assume Psi pose.";
  println( kinectStatus );
  kinect.startTrackingSkeleton(userId);
}

/*************** For version 0.27 of simpleOpenNI ***************/
//void onNewUser(int userId) {
//  kinectStatus = "User " + userId + " found.  Please assume Psi pose.";
//  println( kinectStatus );
//  kinect.startPoseDetection("Psi", userId);
//}
//
//void onStartPose(String pose, int userId) {
//  kinectStatus = pose + " pose detected for user " + userId + ". Requesting calibration skeleton.";
//  println( kinectStatus);
//  kinect.stopPoseDetection(userId); 
//  kinect.requestCalibrationSkeleton(userId, true);
//}
//
//void onEndCalibration(int userId, boolean successful) {
//  if (successful) { 
//    kinectStatus = "Calibration ended successfully for user " + userId + " Tracking user.";
//    println( kinectStatus );
//    kinect.startTrackingSkeleton(userId);
//    skeleton.setUser(userId);
//  } 
//  else { 
//    kinectStatus = "Calibration failed starting pose detection.";
//    kinect.startPoseDetection("Psi", userId);
//  }
//}

/*************** Common to both versions of simpleOpenNI ***************/
void onLostUser(int userId) {
  kinectStatus = "User " + userId + " lost.";
  println( kinectStatus);
}

void controlEvent(ControlEvent theEvent) {
  if ( theEvent.isFrom( fgbgToggle ) ) {
    if ( currentColor == FOREGROUND ) {
      colorChooser.setColorValue( brushColor );
    } 
    else {
      colorChooser.setColorValue( bgColor );
    }
  }
}

