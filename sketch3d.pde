/*
 sketch3D
 Copyright 2013-14 Kelly Egan
 Full license contained in LICENSE.txt
 */

import controlP5.*;
import processing.core.PApplet;
import SimpleOpenNI.*;
import java.awt.Color;
import processing.dxf.*;
import processing.pdf.*;
import draw3D.geo.*;
import draw3D.drawing.*;
import draw3D.controller.*;


boolean drawingNow, moveDrawing, rotatingNow, pickingColor, changingPreferences, pickingBackground;    //Current button states 
boolean up, down, left, right;

//Kinect
SimpleOpenNI kinect;
boolean deviceReady;
boolean handPicked;
Skeleton skeleton;
String kinectStatus, keyStatus;
int keyCount = 0;

//Controller
ArcBall arcBall;

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

//Exporting
boolean exportDXF;
boolean exportPDF;
String dxfName, pdfName;

//View stuff
ControlP5 cp5;
ColorChooserController colorChooser;
Group colorGroup, preferenceMenu, fileMenu, helpMenu;
Toggle fgbgToggle;

PFont font;

public static int MENUS_OFF = 0;
public static int COLOR_MENU = 1;
public static int PREFERENCE_MENU = 2;
public static int FILE_MENU = 3;
public static int HELP_MENU = 4;

int menuState;

PFont uiFont;

PVector cameraPos, cameraFocus;

PMatrix3D inverseTransform;
PVector offset, rotation;
PVector moveStart, moveNow, moveDelta, moveModel, oldOffset;

PVector drawingHand, drawingHandTransformed, secondaryHand, secondaryHandTransformed, drawingHandScreen, secondaryHandScreen;
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

  //smooth();

  menuState = MENUS_OFF;

  drawingNow = false;
  moveDrawing = false;
  rotatingNow= false;
  pickingColor = false;
  changingPreferences = false;
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

    kinect.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);     //Version 0.27 of simpleOpenNI   
    //kinect.enableUser();                                //Version 1.9.6 of simpleOpenNI

    kinectStatus = "Kinect found. Waiting for user...";
    println(kinectStatus);
    skeleton = new Skeleton(this, kinect, 1, Skeleton.RIGHT_HANDED );
    deviceReady = true;
  } else {
    kinectStatus = "No Kinect found. ";
    println(kinectStatus);
  }

  //Drawing
  d = new Drawing(this, "default.gml");
  brushSize = 30.0;
  
  //Controller
  arcBall = new ArcBall(this, width/2, height/2, 300);

  brushColorHSB = new PVector(0.0, 0.0, 1.0);
  oldBrushColorHSB = new PVector();
  brushColor = Color.HSBtoRGB( brushColorHSB.x, brushColorHSB.y, brushColorHSB.z);

  defaultBrush = new Brush("draw3d_default_00001", brushColor, brushSize);
  clickStarted = false;

  bgColorHSB = new PVector( 0.0, 0.0, 0.2 );
  oldBgColorHSB = new PVector();
  bgColor = Color.HSBtoRGB( bgColorHSB.x, bgColorHSB.y, bgColorHSB.z);
  
  //GUI
  cp5 = new ControlP5(this);
  createControllers( cp5 );
  cp5.setAutoDraw(false);
  cp5.getPointer().enable();

  uiFont = createFont("Helvetica", 20);
  textFont(uiFont, 20);

  displayOrigin = true;
  displaySkeleton = true;  

  bgImage = loadImage("data/testBackground.jpg");
  displayBackgroundImage = false;

  //View
  cameraPos = new PVector( 0, 0, 3000 );
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
  shader.set("fogNear", cameraPos.z - 2000.0 );
  shader.set("fogFar", cameraPos.z + 0.0 );
  shader.set("fogColor", red(bgColor) / 255.0, green(bgColor) / 255.0, blue(bgColor) / 255.0, 1.0 );
  shader.set("zPlaneIndicatorOn", true);

  drawingHand = new PVector();
  drawingHandScreen = new PVector();
  secondaryHandScreen = new PVector();
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
  
}

void draw() {
  shader(shader);
  update();
  /*************************************** DISPLAY **************************************/

  pushMatrix();
  
  if ( exportDXF ) {    
    beginRaw( DXF, dxfName + ".dxf");
  }
  if ( exportPDF ) {
    beginRaw( PDF, pdfName + ".pdf");
  }
  
  directionalLight(255, 255, 255, 0, 0.5, 0.5);

  background(bgColor);
  if( exportPDF ) {
    noStroke();
    fill(bgColor);
    rect(0, 0, width, height);
  }
  if ( displayBackgroundImage && !exportDXF && !exportPDF) {
    image( bgImage, width/2-bgImage.width/2, height/2-bgImage.height/2 );
  }

  if ( !exportDXF && !exportPDF) {
    fill(0);
    text(kinectStatus, 40, height - 60);
    noFill();
  }
  camera( cameraPos.x, cameraPos.y, cameraPos.z, cameraFocus.x, cameraFocus.y, cameraFocus.z, 0, 1, 0);

  drawingHandScreen.set( width - screenX( drawingHand.x, drawingHand.y, drawingHand.z), height - screenY( drawingHand.x, drawingHand.y, drawingHand.z) );
  secondaryHandScreen.set( width - screenX( secondaryHand.x, secondaryHand.y, secondaryHand.z), height - screenY( secondaryHand.x, secondaryHand.y, secondaryHand.z) );

  //Set the cursor for the menus
  if( menuState != FILE_MENU ) {
    cp5.getPointer().set( (int)drawingHandScreen.x, (int)drawingHandScreen.y );
  } else {
    cp5.getPointer().set( mouseX, mouseY );    
  }

  if ( deviceReady && !exportDXF && !exportPDF) {
    pushMatrix();
    rotateX(PI);
    rotateY(PI);
    skeleton.display(displaySkeleton, brushSize, brushColor);
    popMatrix();
  }

  if( exportDXF ) {
    //Adjust output to easily fit in Blender window
    translate(cameraPos.x, cameraPos.y, cameraPos.z);
    rotateX( TAU / 4 );
    scale( 0.001, -0.001, 0.001 ); 
  }

  //ROTATION
  arcBall.update( );

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

  camera();
  noLights();

  //Draw the user face 
  //This is manually drawn so that the custom pointer will be seen.
  fileMenu.setVisible( menuState == FILE_MENU );
  colorGroup.setVisible( menuState == COLOR_MENU );
  preferenceMenu.setVisible( menuState == PREFERENCE_MENU );
  helpMenu.setVisible( menuState == HELP_MENU );
  
  cp5.draw();
  
  if ( menuState == COLOR_MENU ) {
    if ( currentColor == FOREGROUND ) {
      brushColor = colorChooser.getColorValue();
      fgbgToggle.setColorForeground(brushColor);
    } else {
      bgColor = colorChooser.getColorValue();
      shader.set("fogColor", red(bgColor) / 255.0, green(bgColor) / 255.0, blue(bgColor) / 255.0, 1.0 );
      fgbgToggle.setColorBackground(bgColor);
    }

  }
  
  
  if( menuState != MENUS_OFF && menuState != FILE_MENU ) {
    //Draw cursor
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

//  if ( up ) {
//    rotation.x += rotationStep;
//  }
//  if ( down ) {
//    rotation.x -= rotationStep;
//  }
//  if ( right ) {
//    rotation.y += rotationStep;
//  }
//  if ( left ) {
//    rotation.y -= rotationStep;
//  }

  if (deviceReady) {
    kinect.update();
    skeleton.update( drawingHand );
    skeleton.getSecondaryHand( secondaryHand );
    updateDrawingHand();


    //kinectStatus = "zPlane: " + (cameraPos.z - drawingHand.z);
    shader.set("zPlane", cameraPos.z - drawingHand.z );


    if ( drawingNow ) {
      d.addPoint( (float)millis() / 1000.0, drawingHandTransformed.x, drawingHandTransformed.y, drawingHandTransformed.z);
    }
    if ( rotatingNow ) {
      //arcBall.dragging( mouseX, mouseY );
      arcBall.dragging(secondaryHandScreen.x, secondaryHandScreen.y );       
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
  if ( menuState != MENUS_OFF) {
      cp5.getPointer().pressed();
  } else {
    if (mouseButton==LEFT) {
      println( red(brushColor));
      d.startStroke(new Brush( "", brushColor, brushSize ) );
      drawingNow=true;
      keyStatus += " Left mouse.";
    }
    if (mouseButton==RIGHT) {
      //arcBall.dragStart(mouseX, mouseY);
      arcBall.dragStart(secondaryHandScreen.x, secondaryHandScreen.y);
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

void mouseDragged() {
  arcBall.dragging(mouseX, mouseY);
}

void mouseReleased() {
  if ( menuState != MENUS_OFF ) {
    cp5.getPointer().released();
  } 
  else {
    if (mouseButton==LEFT) {
      drawingNow=false;
      d.endStroke();
    }
    if (mouseButton==RIGHT) {
      rotatingNow=false;
      arcBall.dragEnd(); 
    }
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
        if( menuState != COLOR_MENU ) {
          menuState = COLOR_MENU;
        } else {
          menuState = MENUS_OFF;
        }
        
//        pickingColor = !pickingColor;
//        colorGroup.setVisible( pickingColor );
        break;
      case 'd': 
      case 'D':
        cp5.getPointer().pressed(); 
        d.startStroke(new Brush( "", brushColor, brushSize ) );
        drawingNow=true;
        break;
      case 'f': 
      case 'F':
        if( menuState != FILE_MENU ) {
          menuState = FILE_MENU;
        } else {
          menuState = MENUS_OFF;
        }
        break;
      case 'h':
      case 'H':
        //Home rotation and translation
        rotation.set(0, 0, 0);
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
      case 'p':
      case 'P': 
        if( menuState != PREFERENCE_MENU ) {
          menuState = PREFERENCE_MENU;
        } else {
          menuState = MENUS_OFF;
        }
        break;
      case 'r': 
      case 'R':
        arcBall.dragStart(secondaryHandScreen.x, secondaryHandScreen.y);
        rotatingNow=true;     
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
      case '1':
        arcBall.setView( ArcBall.FRONT );
        break;
      case '2':
        break;
      case '3':
        arcBall.setView( ArcBall.RIGHT );
        break;
      case '4':
        break;
      case '5':
        break;
      case '6':
        break;
      case '7':
        arcBall.setView( ArcBall.TOP );
        break;
      case '8': 
        break;     
      case '-': 
      case '_':
        brushSize -= 5;
        break;
      case '=': 
      case '+':
        brushSize += 5;
        break;
      case '?':
        if( menuState != HELP_MENU ) {
          menuState = HELP_MENU;
        } else {
          menuState = MENUS_OFF;
        }
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
//
//boolean sketchFullScreen() {
//  return true;
//}

void stop() {
}

void openDrawing( File f ) {
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
      println(f.getAbsolutePath());
    } 
    catch (Exception e) {
      e.printStackTrace();
    }
  }
}

void exportPDF(File f) {
  pdfName = f.getAbsolutePath();
  exportPDF= true;
}

void exportDXF(File f) {
  dxfName = f.getAbsolutePath();
  exportDXF= true;
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
  //
  
  drawingHandTransformed.set( drawingHand );
  secondaryHandTransformed.set( secondaryHand );
  inverseTransform.reset();
  if ( !moveDrawing ) {
    inverseTransform.translate( -offset.x, -offset.y, -offset.z );
  }

  
  float[] inverseRotation = arcBall.getInverseRotation();
  inverseTransform.rotate( inverseRotation[0], inverseRotation[1], inverseRotation[2], inverseRotation[3] );
  
  inverseTransform.rotateY( PI );
  inverseTransform.rotateX( PI );
 
//  //Pre-arcball rotation 
//  inverseTransform.rotateY( PI - rotation.y );
//  inverseTransform.rotateX( PI + rotation.x );

  inverseTransform.mult( drawingHand, drawingHandTransformed );
  inverseTransform.mult( secondaryHand, secondaryHandTransformed );
}

void createControllers(ControlP5 cp5) {

  currentColor = FOREGROUND;
  //brushColor = color(0);
  //bgColor = color(255);
  
  int fontSize = 18;
  PFont pfont = createFont("Arial", fontSize, true); // use true/false for smooth/no-smooth
  ControlFont font = new ControlFont(pfont,fontSize);

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
    .setColorValue( brushColor )
    ;
    
  //Preference menu  
  int menuWidth = 300;
  int margin = 10;
  int spacing = 5;
  int barHeight = 30;
  int menuHeight = 2 * margin + (spacing + barHeight) * 4;
  
  preferenceMenu = cp5.addGroup("preferences")
    .setPosition( (width - menuWidth) / 2, 50 + (height - menuHeight) / 2 )
    .setSize( menuWidth, menuHeight )
    .setBackgroundColor( color(240, 240, 240, 128) )
    .setLabel("")
    .hide();
    ;
    
  cp5.addButton("toggleHand")
    .setLabel("Draw with left hand")
    .setGroup("preferences")
    .setPosition( margin, margin)
    .setSize( menuWidth - margin * 2, barHeight )
    .getCaptionLabel()
    .setFont(font)
    .setSize(fontSize)
    ;
    
  cp5.addButton("toggleOrigin")
    .setLabel("Hide origin")
    .setGroup("preferences")
    .setPosition( margin, margin + (spacing + barHeight))
    .setSize( menuWidth - margin * 2, barHeight )
    .getCaptionLabel()
    .setFont(font)
    .setSize(fontSize)
    ;
    
  cp5.addButton("toggleSkeleton")
    .setLabel("Hide skeleton")
    .setGroup("preferences")
    .setPosition( margin, margin + (spacing + barHeight) * 2)
    .setSize( menuWidth - margin * 2, barHeight )
    .getCaptionLabel()
    .setFont(font)
    .setSize(fontSize)
    ;
    
  cp5.addButton("toggleBackgroundImage")
    .setLabel("Hide background image")
    .setGroup("preferences")
    .setPosition( margin, margin + (spacing + barHeight) * 3)
    .setSize( menuWidth - margin * 2, barHeight )
    .getCaptionLabel()
    .setFont(font)
    .setSize(fontSize)
    ;
    
    
  //File menu
  menuHeight = 2 * margin + (spacing + barHeight) * 5;
  
  fileMenu = cp5.addGroup("file")
    .setPosition( (width - menuWidth) / 2, 50 + (height - menuHeight) / 2 )
    .setSize( menuWidth, menuHeight )
    .setBackgroundColor( color(240, 240, 240, 128) )
    .setLabel("")
    .hide();
    ;  
  
  cp5.addButton("openDrawingPressed")
    .setLabel("Open drawing")
    .setGroup("file")
    .setPosition( margin, margin)
    .setSize( menuWidth - margin * 2, barHeight )
    .getCaptionLabel()
    .setFont(font)
    .setSize(fontSize)
    ;
    
  cp5.addButton("saveDrawingPressed")
    .setLabel("Save drawing")
    .setGroup("file")
    .setPosition( margin, margin + (spacing + barHeight))
    .setSize( menuWidth - margin * 2, barHeight )
    .getCaptionLabel()
    .setFont(font)
    .setSize(fontSize)
    ;
  
  cp5.addButton("exportPDFPressed")
    .setLabel("Export PDF (2D)")
    .setGroup("file")
    .setPosition( margin, margin + (spacing + barHeight) * 2)
    .setSize( menuWidth - margin * 2, barHeight )
    .getCaptionLabel()
    .setFont(font)
    .setSize(fontSize)
    ;
    
  cp5.addButton("exportDXFPressed")
    .setLabel("Export DXF (3D)")
    .setGroup("file")
    .setPosition( margin, margin + (spacing + barHeight) * 3)
    .setSize( menuWidth - margin * 2, barHeight )
    .getCaptionLabel()
    .setFont(font)
    .setSize(fontSize)
    ;
     
  cp5.addButton("loadBackgroundImage")
    .setLabel("Load background image")
    .setGroup("file")
    .setPosition( margin, margin + (spacing + barHeight) * 4)
    .setSize( menuWidth - margin * 2, barHeight )
    .getCaptionLabel()
    .setFont(font)
    .setSize(fontSize)
    ;
    
  menuWidth = 400; 
  menuHeight = 500;
  
  String [] helpItems = {
    "D    Draw",
    "R    Rotate",
    "M    Move",
    "Z    Undo",
    "X    Clear strokes",
    "+/-  Change stroke size",
    "H    Reset rotation",
    "C    Color picker",
    "P    Preference menu",
    "F    File save, open and export",
    "?    This help menu",
    "Q    Exit sketch3D"
  };
  
     
  helpMenu = cp5.addGroup("help")
    .setPosition( (width - menuWidth) / 2, (height - menuHeight) / 2 )
    .setSize( menuWidth, menuHeight )
    .setBackgroundColor( color(240, 240, 240, 200) )
    .setLabel("")
    .hide();
    ;
  
  int index = 0;
  for( String item : helpItems ) {
     cp5.addTextlabel("Help" + index)
      .setText(item)
      .setGroup("help")
      .setPosition( margin, margin + (spacing + barHeight) * index )
      .setFont(font)
      .setColorValue(0xff000000)
      ;
      index++;
  }

    
}

/************************************** controlP5 callbacks **************************************/

void toggleHand(ControlEvent theEvent) {
  skeleton.changeHand();
  theEvent.getController().setLabel( skeleton.getHand() ? "Draw with left hand" : "Draw with right hand" );
}

void toggleOrigin(ControlEvent theEvent) {
  displayOrigin = !displayOrigin;
  theEvent.getController().setLabel( displayOrigin ? "Hide origin" : "Show origin" );
}

void toggleSkeleton(ControlEvent theEvent) {
  displaySkeleton = !displaySkeleton;
}

void openDrawingPressed() {
  selectInput("Please select a drawing to open", "openDrawing" );
  menuState = MENUS_OFF;
}

void saveDrawingPressed() {
  selectOutput("Save drawing:", "saveDrawing");
  menuState = MENUS_OFF;
}

void exportPDFPressed() {
  selectOutput("Export PDF:", "exportPDF");
  menuState = MENUS_OFF;

}

void exportDXFPressed() {
  selectOutput("Export DXF:", "exportDXF");
  menuState = MENUS_OFF;
}

void loadBackgroundImage() {
  selectInput("Please select a background image", "loadBackground" );
}

void toggleBackgroundImage(ControlEvent theEvent) {
  displayBackgroundImage = !displayBackgroundImage;
  theEvent.getController().setLabel( displayBackgroundImage ? "Hide background image" : "Show background image" );
}



/************************************** SimpleOpenNI callbacks **************************************/

/*************** For version 1.9.6 of simpleOpenNi ***************/
//void onNewUser(SimpleOpenNI kinect, int userId) {
//  kinectStatus = "User " + userId + " found.  Please assume Psi pose.";
//  println( kinectStatus );
//  kinect.startTrackingSkeleton(userId);
//}

/*************** For version 0.27 of simpleOpenNI ***************/
void onNewUser(int userId) {
  kinectStatus = "User " + userId + " found.  Please assume Psi pose.";
  println( kinectStatus );
  kinect.startPoseDetection("Psi", userId);
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

