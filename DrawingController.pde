import processing.core.*;
import draw3D.drawing.*;
import draw3D.geo.*;
import draw3D.controller.*;

public class DrawingController implements PConstants {
  PApplet p;
  
  /**
   * Current location of primary cursor in world, view and screen (2D) coordinates
   */
  PVector cursor3DWorld;
  PVector cursor3dView;
  PVector cursorScreen;
  
  /**
   * Current location of secondary cursor in world, view and screen (2D) coordinates
   */
  PVector second3DWorld;
  PVector second3dView;
  PVector secondScreen;
  
  /**
   * Matrix for converting the current view cursor to the matrix.
   */
  PMatrix3D viewToWorldMatrix;
 
  /**
   * Drawing states
   */
  boolean drawing, moving, rotating;
  
  Brush currentBrush; 
  
  DrawingController(PApplet p) {
    this.p = p;
    
    cursor3DWorld = new PVector();
    cursor3dView = new PVector();
    cursorScreen = new PVector();
    
    second3DWorld = new PVector();
    second3dView = new PVector();
    secondScreen = new PVector();
    
    
    
    drawing = false;
    moving = false;
    rotating = false;
  }
  
  void update() {
    //Set the world cursors to view cursors
    cursor3DWorld.set( cursor3dView );
    second3DWorld.set( second3dView );
    
    viewToWorldMatrix.reset;
    if( moving ) {
      
    }
    
  }
  
  
  
}


//void updateDrawingHand() {
//  //drawingHand.set( mouseX, mouseY, 0 );
//  drawingHandTransformed.set( drawingHand );
//  secondaryHandTransformed.set( secondaryHand );
//  inverseTransform.reset();
//  if ( !moveDrawing ) {
//    inverseTransform.translate( -offset.x, -offset.y, -offset.z );
//  }
//  inverseTransform.rotateY( PI - rotation.y );
//  inverseTransform.rotateX( PI + rotation.x );
//
//  inverseTransform.mult( drawingHand, drawingHandTransformed );
//  inverseTransform.mult( secondaryHand, secondaryHandTransformed );
//}
