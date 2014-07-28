import controlP5.*;
import java.awt.Color;

class ColorToggleView implements ControllerView<Toggle> {
  public void display(PApplet p, Toggle t) {
    p.pushMatrix();
    
    
    p.fill(0);
    if( t.getState() ) {
      p.ellipse( t.getWidth() * 0.25 - t.getHeight() * 0.5, 0, t.getHeight(), t.getHeight());
    } else {
      p.rect( t.getWidth() * 0.75 - t.getHeight() * 0.5, 0, t.getHeight(), t.getHeight());
    }

    p.fill( t.getColor().getForeground() );
    p.ellipse( t.getWidth() * 0.25 - t.getHeight() * 0.5 + 5, 5, t.getHeight()- 10, t.getHeight()-10);
    p.fill( t.getColor().getBackground() );
    p.rect( t.getWidth() * 0.75 - t.getHeight() * 0.5 + 5, 5, t.getHeight() - 10, t.getHeight()-10);
    
    p.popMatrix();
  }
}

/*
 * Draws the hue, saturation and brightness sliders for the custom ColorChooserController
 */
class ColorChooserView implements ControllerView<ColorChooserController> {
  public void display(PApplet p, ColorChooserController colorChooser) {
    float barHeight = colorChooser.getHeight() / 4.0;
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
      p.line( i, barHeight * 1.5, i, barHeight * 2.5);
    
      p.stroke( h, s, (i / colorChooser.getWidth() ) * 255 );
      p.line( i, barHeight * 3, i, barHeight * 4);
    } 
    p.colorMode(RGB);
    p.stroke(0);
    p.strokeWeight(2);
    p.noFill();
    
    float radius = barHeight / 4.0;
    float offset = radius / 2.0;
    float center = barHeight / 2;
    
    //Hue point
    p.line( h_pos, -5.0, h_pos, center - offset);
    p.ellipse( h_pos - offset, center - offset, radius, radius );
    p.line( h_pos, center + offset, h_pos, barHeight + 5.0);
    
    //Saturation point
    p.translate(0, barHeight * 1.5);
    p.line( s_pos, -5.0, s_pos, center - offset);
    p.ellipse( s_pos - offset, center - offset, radius, radius );
    p.line( s_pos, center + offset, s_pos, barHeight + 5.0);
    
    //Saturation point
    p.translate(0, barHeight * 1.5);
    p.line( b_pos, -5.0, b_pos, center - offset);
    p.ellipse( b_pos - offset, center - offset, radius, radius );
    p.line( b_pos, center + offset, b_pos, barHeight + 5.0);
   
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
      float[] c = {0.0, 255.0, 255.0};
      setArrayValue( c );
      
      setView( new ColorChooserView() );
    }
    
    void onClick() {

    }
    
    void onPress() {
      Pointer p1 = getPointer();
      float [] valueArray = getArrayValue();
      if( p1.y() < getHeight() * 0.333333 ){
        index = 0;
      } else if ( p1.y() < getHeight() * 0.666666 ) {
        index = 1;
      } else {
        index = 2;
      }
      valueArray[index] = constrain( map( p1.x(), 0, getWidth(), 0, 255), 0, 255);
    }

    void onDrag() {
      float [] valueArray = getArrayValue();
      Pointer p1 = getPointer();
      valueArray[index] = constrain( map( p1.x(), 0, getWidth(), 0, 255), 0, 255);
    } 
 
    ColorChooserController setColorValue( int col ) {
      float[] valueArray = {hue(col), saturation(col), brightness(col)};
      setArrayValue( valueArray );
      return this;
    } 
 
    int getColorValue() {
      float [] valueArray = getArrayValue();
      return Color.HSBtoRGB(valueArray[0] / 255.0, valueArray[1] / 255.0, valueArray[2] / 255.0);
    } 
    
    float getHue() {
      return getArrayValue()[0];
    }
    float getSaturation() {
      return getArrayValue()[1];
    }
    float getBrightness() {
      return getArrayValue()[2];
    }
}

