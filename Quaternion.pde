
import processing.core.*;

public class Quaternion implements PConstants {
  public float w, x, y, z;

  /**
   * Contructs a new Quaternion and it set to the identity
   */
  public Quaternion() {
    setToIdentity();
  }

  public Quaternion(float w, float x, float y, float z) {
    set(w, x, y, z);
  }

  /**
   * Set the value of Quaternions components.
   * 
   * @param w scalar component
   * @param x vector components x value
   * @param y vector components y value
   * @param z vector components z value
   */
  public void set(float w, float x, float y, float z) {
    this.w = w;
    this.x = x;
    this.y = y;
    this.z = z;
  }
  
  /**
   * Set the value of a Quaternions components with the values of another Quaternion
   * @param q
   */
  public void set(Quaternion q) {
    this.set(q.w, q.x, q.y, q.z);
  }
  
  public void set(float s, PVector v) {
    set(s, v.x, v.y, v.z);
  }
  
  /**
   * Sets Quaternion to the identity Quaternion
   */
  public void setToIdentity() {
    set( 1.0f, 0.0f, 0.0f, 0.0f );
  }
  
  public void mult(Quaternion q1, Quaternion q2, Quaternion target) {
    float s = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z;
    float vx = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y;
    float vy = q1.w * q2.y + q1.y * q2.w + q1.z * q2.x - q1.x * q2.z;
    float vz = q1.w * q2.z + q1.z * q2.w + q1.x * q2.y - q1.y * q2.x;
    target.set(s, vx, vy, vz);
  }
  
  public Quaternion mult(Quaternion q1, Quaternion q2) {
    Quaternion result = new Quaternion();
    this.mult(q1, q2, result);
    return result;
  }
  
  public Quaternion mult(float s) { 
     return new Quaternion(w*s, x*s, y*s, z*s);
  }
  
  public void inverse(Quaternion source, Quaternion target) {
    target.set( source.w, -source.x, -source.y, -source.z );  
  }
  
  public Quaternion inverse() {
    return new Quaternion(this.w, -this.x, -this.y, -this.z);
  }
  
  /**
   * Computes the power of the quaternion, defined as follows: 
   * let Q=(cos(alpha), sin(alpha) u), 
     * then Q^t = (cos(t*alpha), sin(t*alpha)u).
     */
  public Quaternion power(float exponent) {
    float theta2 = PApplet.acos(w); 
    theta2 *= exponent;
    PVector U = new PVector(x,y,z);
    U.normalize();
    U.mult(PApplet.sin(theta2));
    return new Quaternion(PApplet.cos(theta2),U.x, U.y, U.z);
  }

  public String toString() {
    return "(" + w + ", " + x + ", " + y + ", " + z + ")";
  }
  
  /**
   * Set target Quaternion to the rotation between two unit vectors (shortest arc)
   * 
   * @param start normalized starting point on rotation
   * @param end   normalized ending point of rotation
   */
  public void rotationBetween( PVector start, PVector end, Quaternion target ) {
    float dot = PVector.dot(start, end);

    if( dot < -0.999999) {
      //Start and end vectors are opposites rotation should be 180 degrees
      PVector xAxis = new PVector(1, 0, 0);      
      PVector cross = xAxis.cross(start);
      //If cross product is zero rotate around Y instead of x
      if( cross.mag() > 0.000001) {
        target.set(0.0f, 1.0f, 0.0f, 0.0f); //180 degree rotation around the x-axis
      } else {
        target.set(0.0f, 0.0f, 1.0f, 0.0f); //180 degree rotation around y-axis
      }
      
    } else if ( dot > 0.999999) {
      //Start and end vectors are the same rotation should do nothing
      target.setToIdentity();
    } else {
      //Start and end vectors are not identical or opposite
      target.set( dot, start.cross(end) );
    }    
  }

  public void fromAngleAxis( float angle, PVector axis, Quaternion target) {
    float s = PApplet.sin(angle/2);
    target.set(PApplet.cos(angle/2), axis.x * s, axis.y * s, axis.z * s);
  }
  
  /**
   * Convert Quaternion to an angle and Axis pair
   * @return float array whos first value is angle and remaining values represent the axis
   */
  public float[] toAngleAxis() {
    float[] result = new float[4];

    float sa = (float) Math.sqrt(1.0f - w * w);
    if (sa < EPSILON) {
      sa = 1.0f;
    }

    result[0] = (float) Math.acos(w) * 2.0f;
    result[1] = x / sa;
    result[2] = y / sa;
    result[3] = z / sa;

    return result;
  }
}
