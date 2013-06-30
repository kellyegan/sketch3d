/**
 * A Drawing is a object that contains 3D stroke data.
 * The Drawing consists of a list of Strokes which consists of a series of Points
 * @author Kelly Egan
 * @version 0.1
 */
class Drawing {
  List<Stroke> strokes;
  Stroke currentStroke;
  
  PVector screenBounds; 
  PVector realScale;
  PVector up;
  
  /**
   * Creates an empty Drawing.
   * The currentStroke is set to null until drawing begins
   */
  Drawing() {
    this("template.gml");
  }

  /**
   * Creates a Drawing from a GML file.
   * @param filepath The name of the GML(Graffiti Markup Language) file to load.
   */  
  Drawing( String filepath ) {
  }
  
  /**
   * Start recording a new stroke
   * Creates a new Stroke and assigns it to currentStroke
   */
  void startStroke() {
    currentStroke = new Stroke();
    strokes.add( currentStroke );
  }
  
  /** 
   * End the current stroke
   * Sets currentStroke to null
   */ 
  void endStroke() {
    currentStroke = null;
  }
  
  /**
   * Add a point to the current stroke
   * @param t Time value for new Point (probably current time)
   * @param lx X coordinate of points location.
   * @param ly Y coordinate of points location.
   * @param lz Z coordinate of points location.
   */
  void addPoint(float t, float lx, float ly, float lz) {
    if( currentStroke != null ) {
      currentStroke.add( new Point(t, lx, ly, lz) );
    } else {
      //Instead of an error message should it just initiate a new stroke and then add it?
      System.err.println("ERROR: No current stroke. Call startStroke before adding new point.");  
    }
  }
  
  /**
   * Creates or recreates a mesh from the stroke data
   */
  void createMesh() {
    
  }
  
  /** 
   * List strokes ( and points ) of the current drawing
   */
  void list() {
    for( Stroke stroke : strokes ) {
      stroke.list();
    }
  }
  
  //Display the mesh
  /** 
   * Display the mesh
   * Possibly add ability to display a simple path as well
   */
  void display() {
    for( Stroke stroke : strokes ) {
      stroke.display();
    }
  }

  /** 
   * Save the drawing in GML format
   * @param filepath Name of the GML file to save
   */  
  void save(String filepath) {
    
  }

  /** 
   * Export an STL file of the mesh
   * @param filepath Name of the STL file to export to
   */   
  void export(String filepath) {
    
  }
  
  /** 
   * Convert an XML node with x, y, z components to a PVector
   * @param node Node you want to convert
   * @return PVector with values or null if can't find coordinate data
   */
  PVector xmlToVector( XML element ) {
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
          z = 0.0;
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
  XML vectorToXml( String name, PVector vector ) {
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
  PVector convertToScreen( PVector point ) {
    PVector convertedPoint = new PVector();
    //X axis is up 
    if( abs( up.x ) == 1 ) {
      convertedPoint.x = point.y * screenBounds.x;
      convertedPoint.y = screenBounds.y - point.x * screenBounds.y;
      convertedPoint.z = point.z * screenBounds.z;
    //Y axis is up
    } else if( abs( up.y ) == 1 ) {
      convertedPoint.x = point.x * screenBounds.x;
      convertedPoint.y = screenBounds.y - point.y * screenBounds.y;
      convertedPoint.z = point.z * screenBounds.z;
    //Z axis is up  
    } else {
      convertedPoint.x = point.x * screenBounds.x;
      convertedPoint.y = screenBounds.y - point.z * screenBounds.y;
      convertedPoint.z = point.y * screenBounds.z;
    }
    
    return convertedPoint;
  }
  
}
