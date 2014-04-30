import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import controlP5.*; 
import processing.core.PApplet; 
import SimpleOpenNI.*; 
import java.awt.Color; 
import processing.dxf.*; 
import processing.pdf.*; 
import java.awt.Color; 
import processing.core.PApplet; 
import SimpleOpenNI.*; 
import java.util.*; 
import processing.core.PApplet; 
import shapes3d.utils.*; 
import shapes3d.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class sketch3d extends PApplet {

/*
 draw3d
 Copyright Kelly Egan 2013
 */








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

public void setup() {
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
//    kinect.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
    kinect.enableUser();
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
  brushSize = 30.0f;

  brushColorHSB = new PVector(0.0f, 0.0f, 0.2f);
  oldBrushColorHSB = new PVector();
  brushColor = Color.HSBtoRGB( brushColorHSB.x, brushColorHSB.y, brushColorHSB.z);
  
  defaultBrush = new Brush("draw3d_default_00001", brushColor, brushSize);
  clickStarted = false;
  
  bgColorHSB = new PVector( 0.0f, 0.0f, 0.9f );
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
  shader.set("fogNear", cameraPos.z - 1500.0f );
  shader.set("fogFar", cameraPos.z + 0.0f );
  shader.set("fogColor", red(bgColor) / 255.0f, green(bgColor) / 255.0f, blue(bgColor) / 255.0f, 1.0f );
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

public void draw() {
  update();

  /*************************************** DISPLAY **************************************/

  hint(ENABLE_DEPTH_TEST);
  pushMatrix();
  
  directionalLight(255, 255, 255, 0, 0.5f, 0.5f);
  
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
 
  if( true ) {
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
    if( currentColor == FOREGROUND ) {
      brushColor = colorChooser.getColorValue();
      fgbgToggle.setColorForeground(brushColor);
    } else {
      bgColor = colorChooser.getColorValue();
      shader.set("fogColor", red(bgColor) / 255.0f, green(bgColor) / 255.0f, blue(bgColor) / 255.0f, 1.0f );
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
public void update() {
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
      d.addPoint( (float)millis() / 1000.0f, drawingHandTransformed.x, drawingHandTransformed.y, drawingHandTransformed.z);
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

public void mousePressed() {
  if( pickingColor ) {
    cp5.getPointer().pressed();
  } else {
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

public void mouseReleased() {
  if( pickingColor ) {
    cp5.getPointer().released();    
  } else {
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

public void keyPressed() {
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
        selectInput("Please select a drawing to load", "loadDrawing" );
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

public void keyReleased() {
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

public void stop() {
}

public void loadDrawing( File f ) {
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

public void saveDrawing(File f) {
  if ( f != null ) {
    try {
      d.save( f.getAbsolutePath() );
    } 
    catch (Exception e) {
      e.printStackTrace();
    }
  }
}

public void loadBackground( File f ) {
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

public void updateDrawingHand() {
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

public void createControllers(ControlP5 cp5) {

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

//void onNewUser(int userId) {
//  kinectStatus = "User " + userId + " found.  Please assume Psi pose.";
//  println( kinectStatus );
//  kinect.startPoseDetection("Psi", userId);
//}

public void onNewUser(SimpleOpenNI kinect,int userId) {
  kinectStatus = "User " + userId + " found.  Please assume Psi pose.";
  println( kinectStatus );
  kinect.startTrackingSkeleton(userId);
}

public void onLostUser(int userId) {
  kinectStatus = "User " + userId + " lost.";
  println( kinectStatus);
}

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

public void controlEvent(ControlEvent theEvent) {
  if( theEvent.isFrom( fgbgToggle ) ) {
    if( currentColor == FOREGROUND ) {
      colorChooser.setColorValue( brushColor );
    } else {
      colorChooser.setColorValue( bgColor );
    }
  }
}


class Brush {
  String strokeName;
  int strokeColor;
  float brushSize;
  
  Brush() {
    strokeName = "";
    strokeColor = color(0, 0, 0, 255);
    brushSize = 1;
  }
  
  Brush(String n, int c, float w) {
   strokeName = n;
   strokeColor = c;
   brushSize = w;
  }
  
  public String getName() {
    return strokeName;
  }
  
  public void setName( String n ) {
    strokeName = n;
  }
  
  public int getColor() {
    return strokeColor;
  }
  
  public void setColor( int c ) {
    strokeColor = c;
  }
  
  public float getWeight() {
    return brushSize;
  }
   
  public void setWeight( float w ) {
    brushSize = w;
  }
  
  public void apply() {
    noFill();
    stroke( strokeColor );
    strokeWeight  ( brushSize / 2 );
  }
  
}


class ColorToggleView implements ControllerView<Toggle> {
  public void display(PApplet p, Toggle t) {
    p.pushMatrix();
    
    
    p.fill(0);
    if( t.getState() ) {
      p.ellipse( t.getWidth() * 0.25f - t.getHeight() * 0.5f, 0, t.getHeight(), t.getHeight());
    } else {
      p.rect( t.getWidth() * 0.75f - t.getHeight() * 0.5f, 0, t.getHeight(), t.getHeight());
    }

    p.fill( t.getColor().getForeground() );
    p.ellipse( t.getWidth() * 0.25f - t.getHeight() * 0.5f + 5, 5, t.getHeight()- 10, t.getHeight()-10);
    p.fill( t.getColor().getBackground() );
    p.rect( t.getWidth() * 0.75f - t.getHeight() * 0.5f + 5, 5, t.getHeight() - 10, t.getHeight()-10);
    
    p.popMatrix();
  }
}

/*
 * Draws the hue, saturation and brightness sliders for the custom ColorChooserController
 */
class ColorChooserView implements ControllerView<ColorChooserController> {
  public void display(PApplet p, ColorChooserController colorChooser) {
    float barHeight = colorChooser.getHeight() / 4.0f;
    float h = colorChooser.getHue();
    float s = colorChooser.getSaturation();
    float b = colorChooser.getBrightness();
    float h_pos = map( h, 0, 255, 0, colorChooser.getWidth() );
    float s_pos = map(s, 0, 255, 0, colorChooser.getWidth() );
    float b_pos = map( b, 0, 255, 0, colorChooser.getWidth() );
        
    p.pushMatrix();
    p.colorMode(HSB);
    for(float i = 0; i < colorChooser.getWidth(); i++) {  
      p.stroke( (i / colorChooser.getWidth() ) * 255, 255, 255 ); 
      p.line( i, 0, i, barHeight);
      
      p.stroke( h, (i / colorChooser.getWidth() ) * 255, b ); 
      p.line( i, barHeight * 1.5f, i, barHeight * 2.5f);
    
      p.stroke( h, s, (i / colorChooser.getWidth() ) * 255 );
      p.line( i, barHeight * 3, i, barHeight * 4);
    } 
    p.colorMode(RGB);
    p.stroke(0);
    p.strokeWeight(2);
    p.noFill();
    
    float radius = barHeight / 4.0f;
    float offset = radius / 2.0f;
    float center = barHeight / 2;
    
    //Hue point
    p.line( h_pos, -5.0f, h_pos, center - offset);
    p.ellipse( h_pos - offset, center - offset, radius, radius );
    p.line( h_pos, center + offset, h_pos, barHeight + 5.0f);
    
    //Saturation point
    p.translate(0, barHeight * 1.5f);
    p.line( s_pos, -5.0f, s_pos, center - offset);
    p.ellipse( s_pos - offset, center - offset, radius, radius );
    p.line( s_pos, center + offset, s_pos, barHeight + 5.0f);
    
    //Saturation point
    p.translate(0, barHeight * 1.5f);
    p.line( b_pos, -5.0f, b_pos, center - offset);
    p.ellipse( b_pos - offset, center - offset, radius, radius );
    p.line( b_pos, center + offset, b_pos, barHeight + 5.0f);
   
    p.popMatrix(); 
    p.noStroke();    
  }
}

/*
 * Creates a custom controller for selecting a color
 */
class ColorChooserController extends Controller<ColorChooserController> {
    int index;
  
    ColorChooserController(ControlP5 cp5, String theName) {
      super(cp5, theName);
      setBroadcast(true);
      float[] c = {0.0f, 255.0f, 255.0f};
      setArrayValue( c );
      
      setView( new ColorChooserView() );
    }
    
    public void onClick() {

    }
    
    public void onPress() {
      Pointer p1 = getPointer();
      float [] valueArray = getArrayValue();
      if( p1.y() < getHeight() * 0.333333f ){
        index = 0;
      } else if ( p1.y() < getHeight() * 0.666666f ) {
        index = 1;
      } else {
        index = 2;
      }
      valueArray[index] = constrain( map( p1.x(), 0, getWidth(), 0, 255), 0, 255);
    }

    public void onDrag() {
      float [] valueArray = getArrayValue();
      Pointer p1 = getPointer();
      valueArray[index] = constrain( map( p1.x(), 0, getWidth(), 0, 255), 0, 255);
    } 
 
    public ColorChooserController setColorValue( int col ) {
      float[] valueArray = {hue(col), saturation(col), brightness(col)};
      setArrayValue( valueArray );
      return this;
    } 
 
    public int getColorValue() {
      float [] valueArray = getArrayValue();
      return Color.HSBtoRGB(valueArray[0] / 255.0f, valueArray[1] / 255.0f, valueArray[2] / 255.0f);
    } 
    
    public float getHue() {
      return getArrayValue()[0];
    }
    public float getSaturation() {
      return getArrayValue()[1];
    }
    public float getBrightness() {
      return getArrayValue()[2];
    }
}

/**
 * A Drawing is a object that contains 3D stroke data.
 * The Drawing consists of a list of Strokes which consists of a series of Points
 * @author Kelly Egan
 * @version 0.1
 */


 
class Drawing {
  List<Stroke> strokes;
  Stroke currentStroke;
  
  float minimumDistance;
  
  PVector screenBounds; 
  PVector up;
  PVector realScale;
  
  PApplet app;
  
  /**
   * Creates an empty Drawing from the "template.gml" file
   * The currentStroke is set to null until drawing begins
   * And there is no Stroke or Point data
   */
  Drawing(PApplet a) {
    this(a, "template.gml");
  }

  /**
   * Creates a Drawing from a GML (Graffiti Markup Language) file.
   * @param filepath Path to the GML file.
   */  
  Drawing(PApplet a, String filepath ) {
    app = a;
    strokes = new ArrayList<Stroke>();
    minimumDistance = 10;
    load( filepath );
  }
  
  /** 
   * Loads an GML (Graffiti Markup Language) file into the Drawing object
   * @param filepath Path to the GML file.
   */
  public void load(String filepath) {
    String filename = new File(filepath).getName();
    println("Loading " + filename + "...");
    
    int pointCount = 0;
    int strokeCount = 0;
    
    XML gml = loadXML( filepath );
    XML drawing = gml.getChild("tag/drawing");
    
    //Set up environmental data (screenBounds, up and realScale)
    if( gml.getChild("tag/header/environment/screenBounds") != null ) {
      screenBounds = xmlToVector( gml.getChild("tag/header/environment/screenBounds") );
    } else {
      screenBounds = new PVector(width, height, max(width, height) );
    }
    
    if( gml.getChild("tag/header/environment/up") != null ) {
      up = xmlToVector( gml.getChild("tag/header/environment/up") );
    } else {
      up = new PVector(0, -1, 0);
    }
    
    if( gml.getChild("tag/header/environment/realScale") != null ) {
      realScale = xmlToVector( gml.getChild("tag/header/environment/realScale") );
    } else {
      realScale = new PVector(200, 200, 200);
    }

    //Load strokes
    for( XML strokeElement : drawing.getChildren("stroke") ) {
      Brush brushStyle = new Brush();
      
      if( strokeElement.getChild("brush") != null ) {
        //Check if there is a uniqueStyleID value and if so apply it to Brush
        try {
          brushStyle.setName( strokeElement.getChild("brush/uniqueStyleID").getContent() );
        } catch( Exception e ) {
          System.err.println("ERROR: uniqueStyleID data not found for Brush.");
        }
        
        //Check if there is a width value and if so apply it to Brush strokeWeight
        try {
          brushStyle.setWeight( strokeElement.getChild("brush/width").getIntContent() );
        } catch( Exception e ) {
          System.err.println("ERROR: Width data not found for Brush.");
        }
        
        //Check if there are r, g, and b color values and if so apply it to Brush color
        try {
          int r = strokeElement.getChild("brush/color/r").getIntContent();
          int g = strokeElement.getChild("brush/color/g").getIntContent();
          int b = strokeElement.getChild("brush/color/b").getIntContent();
          int a = strokeElement.getChild("brush/color/a").getIntContent();
          brushStyle.setColor( color(r,g,b,a) );
        } catch( Exception e ) {
          System.err.println("ERROR: Color data not found for Brush.");
        }       
      }
      
      startStroke( brushStyle );
        
      //Load points
      for( XML ptElement : strokeElement.getChildren("pt") ) {
        PVector location = xmlToVector( ptElement );
        
        if( location != null ) {
          location = scaleToScreen( location );
          float time = 0.0f;
          if( ptElement.getChild("t") != null ) {
            time = ptElement.getChild("t").getFloatContent();
          } else if( ptElement.getChild("time") != null ) {
            time = ptElement.getChild("time").getFloatContent();
          } else {
            System.err.println("ERROR: Couldn't find <t> or <time> elements in \"" + filename + "\". Setting time to 0.0.");
          }  
          addPoint( time, location, true );   //Ignore minimum distance and just reads in points as they are stored.
          pointCount++;
        } else {
          System.err.println("ERROR: <pt> element coordinates not valid in \"" + filename + "\". Couldn't create point.");
        }
      
      }
      
      endStroke();
      strokeCount++;
    }
    
    println("Loaded " + pointCount + " points and " + strokeCount + " strokes.");
    println("screenBounds: " + screenBounds + "  up: " + up + "  realScale: " + realScale);
  }
  
  /**
   * Save Drawing object to GML file
   * @param filepath Location to save GML file
   */
  public void save( String filepath ) {
    XML gml = loadXML("template.gml");
    XML drawing = gml.getChild("tag/drawing");
    
    XML screenBoundsElement = gml.getChild("tag/header/environment/screenBounds");
    screenBoundsElement.getChild("x").setFloatContent( screenBounds.x );
    screenBoundsElement.getChild("y").setFloatContent( screenBounds.y );
    screenBoundsElement.getChild("z").setFloatContent( screenBounds.z );
    
    //up vector follows processing convention (0, -1, 0)
    
    XML realScaleElement = gml.getChild("tag/header/environment/realScale");
    realScaleElement.getChild("x").setFloatContent( realScale.x );
    realScaleElement.getChild("y").setFloatContent( realScale.y );
    realScaleElement.getChild("z").setFloatContent( realScale.z );
    
    for( Stroke stroke : strokes ) {
      if( stroke.points.size() > 0 ) {
        XML strokeElement = drawing.addChild("stroke");
        
        //Add Brush data
        XML brushElement = strokeElement.addChild("brush");
        brushElement.addChild("uniqueStyleID").setContent( stroke.style.getName() );
        brushElement.addChild("width").setFloatContent( stroke.style.getWeight() );
        XML brushColor = brushElement.addChild("color");
        brushColor.addChild("r").setIntContent( (int)red( stroke.style.getColor() ) );
        brushColor.addChild("g").setIntContent( (int)green( stroke.style.getColor() ) );
        brushColor.addChild("b").setIntContent( (int)blue( stroke.style.getColor() ) );
        brushColor.addChild("a").setIntContent( (int)alpha( stroke.style.getColor() ) );
        
        for( Point point : stroke.points ) {
          XML ptElement = vectorToXml("pt", scaleToGML(point.location));
          ptElement.addChild("t").setFloatContent(point.time);
          strokeElement.addChild(ptElement);
        }
      }
    }
    
    saveXML( gml, filepath );
  }
  
  /**
   * Start recording a new stroke
   * Creates a new Stroke and assigns it to currentStroke
   * @param brushStyle Brush to apply to this new stroke
   */
  public void startStroke(Brush brushStyle) {
    if( currentStroke == null ) {
      currentStroke = new Stroke( app, brushStyle );
      strokes.add( currentStroke );
    } else {
      System.err.println("Already started stroke. Please endStroke before beginning new one");
    }
  }

  /**
   * Start recording a new stroke
   * Creates a new Stroke and assigns it to currentStroke
   * @param name Name of the Brush
   * @param c Color of the Brush
   * @param w Weight of the Brush stroke
   */
  public void startStroke(String n, int c, int w) {
    startStroke( new Brush( n, c, w ) );
  }
  
  /**
   * Start recording a new stroke
   * Creates a new Stroke and assigns it to currentStroke
   */
  public void startStroke() {
    startStroke( new Brush() );
  }
  
  /** 
   * End the current stroke
   * Sets currentStroke to null
   */ 
  public void endStroke() {
    currentStroke.createMesh();
    currentStroke = null;
  }
  
  /**
   * Add a point to the current stroke
   * @param t Time value for new Point
   * @param lx X coordinate of points location.
   * @param ly Y coordinate of points location.
   * @param lz Z coordinate of points location.
   * @param ignoreMinimumDistance If set will record new point even if under minimum distance from last point
   */
  public void addPoint(float t, float lx, float ly, float lz, boolean ignoreMinimumDistance) {
    if( currentStroke != null ) {
      float distance = currentStroke.distanceToLast(lx, ly, lz);
      //Make sure new points are a minimum distance from other points

      
      if( currentStroke.points.size() == 0 || ignoreMinimumDistance || distance > minimumDistance || distance < 0) {
        currentStroke.add( new Point(t, lx, ly, lz) );
      }
    } else {
      //Instead of an error message should it just initiate a new stroke and then add it?
      System.err.println("ERROR: No current stroke. Call startStroke before adding new point.");  
    }
  }
  
  /**
   * Add a point to the current stroke
   * @param t Time value for new Point
   * @param lx X coordinate of points location.
   * @param ly Y coordinate of points location.
   * @param lz Z coordinate of points location.
   */ 
  public void addPoint(float t, float lx, float ly, float lz) {
    addPoint( t, lx, ly, lz, false);
  }
  
  /**
   * Add a point to the current stroke
   * @param t Time value for new Point
   * @param location Vector representing the location of the point
   */
  public void addPoint(float t, PVector location) {
    addPoint( t, location.x, location.y, location.z, false );
  }
  
  /**
   * Add a point to the current stroke
   * @param t Time value for new Point
   * @param location Vector representing the location of the point
   */
  public void addPoint(float t, PVector location, boolean ignoreMinimumDistance) {
    addPoint( t, location.x, location.y, location.z, ignoreMinimumDistance );
  }
  
  /**
   * Creates or recreates a mesh from the stroke data
   */
  public void createMesh() {
    for( Stroke s : strokes ) {
      s.createMesh();
    }
  }
  
  /** 
   * List strokes ( and points ) of the current drawing
   */
  public void list() {
    for( Stroke stroke : strokes ) {
      stroke.list();
    }
  }
  
  //Display the mesh
  /** 
   * Display the mesh
   * Possibly add ability to display a simple path as well
   */
  public void display() {
    for( Stroke stroke : strokes ) {
      stroke.display();
    }
  }
  
  /**
   * Reset the Drawing object to the template file
   */
  public void reset() {
    load("template.gml");
  }
  
  /**
   * Remove all Stroke data from the Drawing object
   */
  public void clearStrokes() {
    strokes = new ArrayList<Stroke>(); 
  }
  
  /**
   * Removes the last stroke from the Drawing object
   */
  public void undoLastStroke() {
    if( !strokes.isEmpty() ) {
      strokes.remove(strokes.size() - 1);
    }
  }
  
  /**
   * Setter for minimum distance variable.
   */
  public void setMinimumDistance(float distance ){
    minimumDistance = distance;
  }

  /** 
   * Export an STL file of the mesh
   * @param filepath Name of the STL file to export to
   */   
  public void export(String filepath) {
    
  }
  
  /** 
   * Convert an XML node with x, y, z components to a PVector
   * @param node Node you want to convert
   * @return PVector with values or null if can't find coordinate data
   */
  public PVector xmlToVector( XML element ) {
    if( element != null ) {
      XML xElement = element.getChild("x");
      XML yElement = element.getChild("y");
      XML zElement = element.getChild("z");
      float x, y, z;
      
      if( xElement != null && yElement != null ) {
        x = xElement.getFloatContent();
        y = yElement.getFloatContent();
        if( zElement != null ) {
          z = zElement.getFloatContent();
        } else {
          z = 0.0f;
        }
        return new PVector(x, y, z);
      } else {
        System.err.println("ERROR: Element doesn't contain x or y coordinates.");
        return null; 
      }
    } else {
      System.err.println("ERROR: Element is null.");
      return null;
    }
  }
  
  /**
   * Converts a PVector into an XML element with x, y, z components
   * @param name The name of the new element
   * @param vector The PVector to convert
   * @return A new XML element
   */
  public XML vectorToXml( String name, PVector vector ) {
    if( vector != null ) {
      XML newElement =  new XML(name);
      newElement.addChild("x").setFloatContent(vector.x);
      newElement.addChild("y").setFloatContent(vector.y);
      newElement.addChild("z").setFloatContent(vector.z);
      return newElement;
    } else {
      System.err.println("ERROR: PVector is null.");
      return null;
    }
  }
 
  /**
   * Convert a GML pt element value to screen coordinates for Processing
   * PVector to convert
   */
  public PVector scaleToScreen( PVector vector ) {
    vector.sub( new PVector( 0.5f, 0.5f, 0.5f ) );

    PVector scaledVector = new PVector();
    //X axis is up 
    if( abs( up.x ) == 1 ) {
      scaledVector.x = vector.y * screenBounds.x;
      if( up.x > 0 ) {
        scaledVector.y = screenBounds.y - vector.x * screenBounds.y;
      } else {
        scaledVector.y = vector.x * screenBounds.y;
      }
      scaledVector.z = vector.z * screenBounds.z;
    //Y axis is up
    } else if( abs( up.y ) == 1 ) {
      scaledVector.x = vector.x * screenBounds.x;
      if( up.y > 0 ) {
        scaledVector.y = screenBounds.y - vector.y * screenBounds.y;
      } else {
        scaledVector.y = vector.y * screenBounds.y;
      }
      scaledVector.z = vector.z * screenBounds.z;
    //Z axis is up  
    } else {
      scaledVector.x = vector.x * screenBounds.x;
      if( up.z > 0 ) {
        scaledVector.y = screenBounds.y - vector.z * screenBounds.y;
      } else {
        scaledVector.y = vector.z * screenBounds.y;
      }
      scaledVector.z = vector.y * screenBounds.z;
    }
    
    return scaledVector;
  }
  
  /**
   * Scale screen coordinates to GML (0 to 1) based on screenBounds)
   * @param vector Vector to scale
   * @return PVector scaled to 1 to 0
   */
  public PVector scaleToGML( PVector vector ) {
    PVector scaledVector = new PVector( vector.x / screenBounds.x, vector.y / screenBounds.y, vector.z / screenBounds.z);
    scaledVector.add( new PVector( 0.5f, 0.5f, 0.5f ) );
    return scaledVector;
  }
  
}
/**
 * A Point contains information about a single location in a stroke
 * In addition to location in also contains, time, pressure, direction of the stroke at that point.
 * @author Kelly Egan
 * @version 0.1
 */
 
class Point {
  PVector location, direction;
  float time;
  float pressure;
  float rotation;
    
  /**
   * Create a point at (0, 0, 0)
   */
  Point() {
    this( 0, 0, 0, 0, 0, 0, 0, 1, 0 );
  }
  
  /**
   * Create a point with given location and time
   * @param t Time value (as flaot of the current point
   * @param lx X coordinate of point location
   * @param ly Y coordinate of point location
   * @param lz Z coordinate of point location
   */
  Point( float t, float lx, float ly, float lz ) {
    this( t, lx, ly, lz, 0, 0, 0, 1, 0 );
  }
  
  /**
   * Create a point with given location, time, direction, pressure and rotation values
   * @param t Time value (as flaot of the current point
   * @param lx X coordinate of point location
   * @param ly Y coordinate of point location
   * @param lz Z coordinate of point location
   * @param dx X coordinate of point direction
   * @param dy Y coordinate of point direction
   * @param dz Z coordinate of point direction
   * @param p Pressure value of point
   * @param r Rotation value of point
   */
  Point( float t, float lx, float ly, float lz, float dx, float dy, float dz, float p, float r ) {
    time = t;
    location = new PVector( lx, ly, lz );
    direction = new PVector( dx, dy, dz );
    pressure = p;
    rotation = r;
  }
  
  /**
    * Print out the values of the point
    */
  public void list() {
    println( time + " - " + location.x + ", " + location.y + ", " + location.y ); 
  }
  
  /**
   * Compare a point to another based on time value
   * Useful for sorting points in a List object
   * @param a First point to compare
   * @param b Second point to compare
   * @return returns -1 if a < b, 1 if a > b and 0 if they are equal
   */
  public int Compare( Point a, Point b ) {
    if(a.time < b.time) {
      return -1;
    } else if( a.time > b.time ) {
      return 1;
    } else {
      return 0;
    }
  }
  
}



class Skeleton {
  PApplet applet;
  SimpleOpenNI kinect;
  int userID;
  boolean handedness;
  boolean userCalibrated;
  float confidence;
  
  final static boolean LEFT_HANDED = true;
  final static boolean RIGHT_HANDED = false;
  
  PVector head, neck, torso, shoulderL, shoulderR, elbowL, elbowR, handL, handR, hipL, hipR;
  PVector [] joints;
    
  PVector drawingHand, secondaryHand;
  PVector offset, flip;
  
  /**
   * Create a new User
   * @param k Kinect to get user data from
   * @param u User ID 
   * @param h Which hand to use for drawing
   */
  Skeleton( PApplet p, SimpleOpenNI k, int u, boolean h ) {
    applet = p;
    kinect = k;
    userID = u;
    handedness = h;  
    
    joints = new PVector[11];
    
    head = new PVector();
    neck = new PVector();
    torso = new PVector();
    shoulderL = new PVector();
    shoulderR = new PVector();
    elbowL = new PVector();
    elbowR = new PVector();
    handL = new PVector();
    handR = new PVector();
    hipL = new PVector();
    hipR = new PVector();
    
    drawingHand = new PVector();
    secondaryHand = new PVector();
    
    userCalibrated = false;
  }
  
  public boolean update(PVector c) {
    if (kinect.isTrackingSkeleton( userID )) {
      kinect.getJointPositionSkeleton(userID, SimpleOpenNI.SKEL_HEAD, head);
      kinect.getJointPositionSkeleton(userID, SimpleOpenNI.SKEL_NECK, neck);
      kinect.getJointPositionSkeleton(userID, SimpleOpenNI.SKEL_TORSO, torso);
      kinect.getJointPositionSkeleton(userID, SimpleOpenNI.SKEL_RIGHT_SHOULDER, shoulderL);
      kinect.getJointPositionSkeleton(userID, SimpleOpenNI.SKEL_LEFT_SHOULDER, shoulderR);
      kinect.getJointPositionSkeleton(userID, SimpleOpenNI.SKEL_RIGHT_ELBOW, elbowL);
      kinect.getJointPositionSkeleton(userID, SimpleOpenNI.SKEL_LEFT_ELBOW, elbowR);
      float confidenceL = kinect.getJointPositionSkeleton(userID, SimpleOpenNI.SKEL_RIGHT_HAND, handL);
      float confidenceR = kinect.getJointPositionSkeleton(userID, SimpleOpenNI.SKEL_LEFT_HAND, handR);
      kinect.getJointPositionSkeleton(userID, SimpleOpenNI.SKEL_RIGHT_HIP, hipL);
      kinect.getJointPositionSkeleton(userID, SimpleOpenNI.SKEL_LEFT_HIP, hipR);
      
      //Based on hand setting choose where to draw the drawingHand
      if( handedness == LEFT_HANDED ) {
        drawingHand.set( handL );
        secondaryHand.set( handR );
        confidence = confidenceL;
      } else {
        drawingHand.set( handR );
        secondaryHand.set( handL );
        confidence = confidenceR;
      }
      userCalibrated = true;
    } else {
      userCalibrated = false;
    }
    c.set(drawingHand);
    return userCalibrated;
  }
  
  public void display() {
    display( true, 20, 0 ); 
  }
  
  public void display(boolean showSkeleton, float cursorSize, int cursorColor) {
    if( userCalibrated ) {
      
      noFill();
      strokeWeight(2);
      stroke( 0 );

      if( showSkeleton ) {
        //Head
//      line( head, neck );
        
        //Body square
        line( shoulderL, shoulderR );
        line( shoulderR, hipR );
        line( hipR, hipL );
        line( hipL, shoulderL );
        
        //Arms
        line( shoulderL, elbowL );
        line( elbowL, handL );
        line( shoulderR, elbowR );
        line( elbowR, handR );
            
        float shoulderWidth = PVector.sub(shoulderL, shoulderR).mag();
        
        //Draw a simple head
        pushMatrix();
        translate( head.x, head.y + (shoulderWidth * -0.5f) / 2, head.z );
        ellipse(0, 0, shoulderWidth * 0.5f, shoulderWidth * 0.5f );
        popMatrix();
      }
        
      //Draw hands
      //fill(skeleton.getConfidence() * 200, 0, 0);
      fill(cursorColor);
      noStroke();
      pushMatrix();
      translate(drawingHand.x, drawingHand.y, drawingHand.z);
      sphere( 20 );
      popMatrix();
      fill( 150 );
      pushMatrix();
      translate(secondaryHand.x, secondaryHand.y, secondaryHand.z);
      sphere( 20 );
      popMatrix();
    }
  }
  
  public void changeHand() {
    handedness = !handedness; 
  }
  
  public void setHand( boolean hand ) {
    handedness = hand;
  }
  
  public void line( PVector a, PVector b ) {
    applet.line( a.x, a.y, a.z, b.x, b.y, b.z ); 
  }
  
  public void setUser(int u ) {
    userID = u; 
  }
  
  public void nextUser() {
    int numberOfUsers = kinect.getUsers().length; 
    if( numberOfUsers > 1 ) {
      userID = (userID + 1 ) % 10;
    }  
    println("Current users is " + userID);
  }
  
  public PVector getDrawingHand() {
    return drawingHand;
  }
  
  public void getDrawingHand(PVector target) {
    target.set(drawingHand);
  }
  
  public void getSecondaryHand(PVector target) {
    if( handedness == LEFT_HANDED ) {
      target.set(handR);
    } else {
      target.set(handL);
    }
  }
  
  public void reset() {
    kinect.stopTrackingSkeleton(userID);
   
  }
  
  
  public float getConfidence() {
    return confidence;
  }
  
}
/**
 * A Stroke represents a curve in 3D space over time
 * @author Kelly Egan
 * @version 0.1
 */






class Stroke implements I_PathGen {
  List<Point> points;
  int strokeColor;
  float strokeWeight;
  Point lastPoint;
  
  Brush style;
 
  PApplet app; 
  PathTube mesh;
  boolean meshCreated;
  
  /**
   * Create an empty Stroke with a specific Brush
   * @param b Brush to attach to this Stroke
   */
  Stroke(PApplet a, Brush b) {
    app = a;
    points = new LinkedList<Point>();
    style = b;
    lastPoint = null;
    meshCreated = false;
  }
  
  /**
   * Create an empty Stroke and a new Brush
   * @param n Name of the new Brush
   * @param w Width of the Stroke
   * @param c Color of the new Stroke
   */
  Stroke(PApplet a, String n, int c, int w) {
    this(a, new Brush(n, c, w));
  }
  
  /**
   * Create an empty Stroke with a default Brush
   */  
  Stroke(PApplet a) {
    this( a, new Brush() );
  }
  
  /**
   * Add a point to the Stroke.
   * @param Point to add
   */
  public void add(Point p) {
    points.add(p);
    lastPoint = p;
    createMesh();
  }
  
  /** Creates a mesh for the given stroke
   *  Not sure if this is needed or should just be implemented for the drawing class
   */
  public void createMesh() {
    if( points != null && points.size() >= 2) {
      PVector[] pts = new PVector[points.size()];
      
      for( int i = 0; i < points.size(); i++ ) {
        pts[i] = points.get(i).location; 
      }
      
      mesh = new PathTube( app, this, style.getWeight(), points.size(), 6, false );
      mesh.drawMode( Shape3D.SOLID );
      mesh.fill( style.getColor() );
      mesh.fill( style.getColor(), Tube.BOTH_CAP );
      meshCreated = true;
    }
  }
  
  /**
   * Display the stroke
   */
  public void display() { 
    if( meshCreated ) {
      mesh.draw();
    } else {
      style.apply();
      beginShape();
      for( Point point : points ) {
        vertex( point.location.x, point.location.y, point.location.z );
      }
      endShape();
    }
  }
  
  /**
   * List the points within the Stroke
   */
  public void list() {
    for( Point point : points ) {
      point.list();
    }
    println();
  }
  
  public Point getLastPoint() {
    return lastPoint; 
  }
  
  public float distanceToLast( float x, float y, float z ) {
    if( lastPoint != null ) {
      return dist( lastPoint.location.x, lastPoint.location.y, lastPoint.location.z, x, y, z );
    } else {
      return -1;
    }
  }
  
  /**
   * Return x position along stroke length
   */
  public float x( float t ) {
    float xPos = 0;
    if( t < 1.0f ) {
      float pathPos = t * (points.size() - 1);
      int startPt = floor(pathPos);
      int endPt = startPt + 1;
      float amt = pathPos - startPt;
      xPos = lerp( points.get( startPt ).location.x, points.get( endPt ).location.x, amt );
    } else { 
      xPos =  points.get( points.size() - 1 ).location.x;
    }    
    return xPos;
  }
  
  /**
   * Return x position along stroke
   */
  public float y( float t ) {
    float yPos = 0;
    if( t < 1.0f ) {
      float pathPos = t * (points.size() - 1);
      int startPt = floor(pathPos);
      int endPt = startPt + 1;
      float amt = pathPos - startPt;
      yPos = lerp( points.get( startPt ).location.y, points.get( endPt ).location.y, amt );
    } else { 
      yPos =  points.get( points.size() - 1 ).location.y;
    }    
    return yPos;
  }
  
  /**
   * Return x position along stroke
   */
  public float z( float t ) {
    float zPos = 0;
    if( t < 1.0f ) {
      float pathPos = t * (points.size() - 1);
      int startPt = floor(pathPos);
      int endPt = startPt + 1;
      float amt = pathPos - startPt;
      zPos = lerp( points.get( startPt ).location.z, points.get( endPt ).location.z, amt );
    } else { 
      zPos =  points.get( points.size() - 1 ).location.z;
    }    
    return zPos;
  }
   
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "sketch3d" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
