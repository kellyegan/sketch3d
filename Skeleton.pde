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
    
  PVector cursor;
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
    
    cursor = new PVector();
    
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
      
      //Based on hand setting choose where to draw the cursor
      if( handedness == LEFT_HANDED ) {
        cursor.set( handL );
        confidence = confidenceL;
      } else {
        cursor.set( handR );
        confidence = confidenceR;
      }
      userCalibrated = true;
    } else {
      userCalibrated = false;
    }
    c.set(cursor);
    return userCalibrated;
  }
  
  void display() {
    if( userCalibrated ) {
      
      noFill();
      strokeWeight(3);
      stroke( 128 );
      
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
        
      //Draw the cursor
      fill(skeleton.getConfidence() * 200, 0, 0);
      noStroke();
      pushMatrix();
      translate(cursor.x, cursor.y, cursor.z);
      sphere( 20 );
      popMatrix();
    }
  }
  
  void line( PVector a, PVector b ) {
    applet.line( a.x, a.y, a.z, b.x, b.y, b.z ); 
  }
  
  PVector getCursor() {
    return cursor;
  }
  
  void getCursor(PVector target) {
    target.set(cursor);
  }
  
  float getConfidence() {
    return confidence;
  }
  
}
