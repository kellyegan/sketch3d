import SimpleOpenNI.*;

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
    
  PVector drawingHand;
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
    
    userCalibrated = false;
  }
  
  boolean update(PVector c) {
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
  
  void display() {
    if( userCalibrated ) {
      
      noFill();
      strokeWeight(2);
      stroke( 0 );
      
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
          
      float neckLength = PVector.sub(neck, head).mag();
      
      //Draw a simple head
      pushMatrix();
      translate( head.x, head.y + (neckLength * -1) / 2, head.z );
      ellipse(0, 0, neckLength * 0.5, neckLength * 1 );
      popMatrix();
        
      //Draw the drawingHand
      fill(skeleton.getConfidence() * 200, 0, 0);
      noStroke();
      pushMatrix();
      translate(drawingHand.x, drawingHand.y, drawingHand.z);
      sphere( 20 );
      popMatrix();
    }
  }
  
  void changeHand() {
    handedness = !handedness; 
  }
  
  void line( PVector a, PVector b ) {
    applet.line( a.x, a.y, a.z, b.x, b.y, b.z ); 
  }
  
  void nextUser() {
    int numberOfUsers = kinect.getUsers().length; 
    if( numberOfUsers > 1 ) {
      userID = (userID + 1 ) % 10;
    }  
    println("Current users is " + userID);
  }
  
  PVector getDrawingHand() {
    return drawingHand;
  }
  
  void getDrawingHand(PVector target) {
    target.set(drawingHand);
  }
  
  void getSecondaryHand(PVector target) {
    if( handedness == LEFT_HANDED ) {
      target.set(handR);
    } else {
      target.set(handL);
    }
  }
  
  
  float getConfidence() {
    return confidence;
  }
  
}
