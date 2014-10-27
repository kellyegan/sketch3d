import processing.core.*;

/**
 * ArcBall is an interface for rotate 3D objects. It allows the rotation of a 3D 
 * object from a 2D input by simulating touching a sphere (arcball) that can be 
 * spun in any direction.
 * 
 * @author Kelly Egan
 *
 */
public class ArcBall implements PConstants{

  /**
   * Constants for calling specific views when using setViews
   */ 
  public final Quaternion FRONT = new Quaternion(1.0f, 0.0f, 0.0f, 0.0f);
  public final Quaternion TOP = new Quaternion(-PApplet.sqrt(2.0f)/2.0f, PApplet.sqrt(2.0f)/2.0f, 0, 0);
  public final Quaternion LEFT = new Quaternion(PApplet.sqrt(2.0f)/2.0f, 0, PApplet.sqrt(2.0f)/2.0f, 0);
  public final Quaternion RIGHT = new Quaternion(-PApplet.sqrt(2.0f) / 2.0f, 0f, PApplet.sqrt(2.0f) / 2.0f, 0f);
  public final Quaternion BOTTOM = new Quaternion(PApplet.sqrt(2.0f)/2.0f, PApplet.sqrt(2.0f)/2.0f, 0, 0);
  public final Quaternion BACK = new Quaternion(0.0f, 0.0f, 1.0f, 0.0f);

  private PApplet p;
  
  //Center position and radius of ArcBall
  private PVector center;
  private float radius;
  
  //Start and end point on ArcBall surface of rotation
  private PVector startPoint, endPoint;
  
  private boolean dragging;
  
  public Quaternion currentRotation, startRotation, deltaRotation;
  public Quaternion quaternion;
  
  /**
   * Construct an ArcBall given its center position and radius
   * 
   * @param p        parent PApplet
   * @param center_x x coordinate of the center of ArcBall
   * @param center_y y coordinate of the center of the ArcBall
   * @param radius   radius of the ArcBall
   */
  public ArcBall(PApplet p, float center_x, float center_y, float radius){
  this.p = p;
  
  center = new PVector(center_x, center_y);
  
    this.radius = radius;

    startPoint = new PVector();
    endPoint = new PVector();

    quaternion = new Quaternion();
    currentRotation = new Quaternion();
    startRotation = new Quaternion();
    deltaRotation = new Quaternion();
  }

  /**
   * Called when dragging of the ArcBall begins.
   * @param x screen position on x axis
   * @param y screen position on y axis
   */
  public void dragStart(float x, float y){
    startPoint = screenToArcball(x, y);
    startRotation.set(currentRotation);
    deltaRotation.setToIdentity();
    dragging = true;
  }

  /**
   * Called during dragging of ArcBall
   * @param x
   * @param y
   */
  public void dragging(float x, float y){
    endPoint = screenToArcball(x, y);
    quaternion.rotationBetween(startPoint, endPoint, deltaRotation);
  }
  
  /**
   * Called when draggin ends
   */
  public void dragEnd() {
    dragging = false;
  }

  /**
   * Update currentRotation with data from dragging
   */
  public void update(){
    if( dragging ) {
      currentRotation = quaternion.mult(deltaRotation, startRotation);
      
      if(frameCount % 3 == 0) {
        startRotation.set(currentRotation);
        deltaRotation.setToIdentity();
        startPoint.set(endPoint);
      }
    } else {
      currentRotation = quaternion.mult(deltaRotation, currentRotation);
      deltaRotation = deltaRotation.power(0.999f);      
    }
    applyRotation(currentRotation); 
  }
  
  /**
   * Project screen coordinates onto ArcBall sphere. If coordinate
   * is outside of the sphere treat as edge of sphere.
   * 
   * @param x
   * @param y
   * @return
   */
  public PVector screenToArcball(float x, float y){
    PVector result = new PVector();
    result.x = (x - center.x) / radius;
    result.y = (y - center.y) / radius;

    float mag = result.magSq();
    
    if (mag > 1.0f){
      result.normalize();
    } else {
      result.z = PApplet.sqrt(1.0f - mag);
    }

    return result;
  }
  
  /**
   * Set the view to one of six stand views
   * 
   * @param viewIndex
   */
  public void setView( Quaternion view ) {
    startRotation.set(view);
    deltaRotation.setToIdentity();
  }

  public void applyRotation(Quaternion q){
    float[] axisAngle = q.toAngleAxis();
    p.rotate(axisAngle[0], axisAngle[1], axisAngle[2], axisAngle[3]);
  }
  
  public float[] getRotation() {
    return currentRotation.toAngleAxis();
  }
  
  public float[] getInverseRotation() {
    return currentRotation.inverse().toAngleAxis();
  }
}
