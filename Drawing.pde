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
  PVector up;
  PVector realScale;
  
  /**
   * Creates an empty Drawing from the "template.gml" file
   * The currentStroke is set to null until drawing begins
   * And there is no Stroke or Point data
   */
  Drawing() {
    this("template.gml");
  }

  /**
   * Creates a Drawing from a GML (Graffiti Markup Language) file.
   * @param filepath Path to the GML file.
   */  
  Drawing( String filepath ) {
    strokes = new ArrayList<Stroke>();
    loadGML( filepath );
  }
  
  /** 
   * Loads an GML (Graffiti Markup Language) file into the Drawing object
   * @param filepath Path to the GML file.
   */
  void loadGML(String filepath) {
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
      startStroke();
      
      //Load points
      for( XML ptElement : strokeElement.getChildren("pt") ) {
        PVector location = xmlToVector( ptElement );
        if( location != null ) {
          float time = 0.0;
          if( ptElement.getChild("t") != null ) {
            time = ptElement.getChild("t").getFloatContent();
          } else if( ptElement.getChild("time") != null ) {
            time = ptElement.getChild("time").getFloatContent();
          } else {
            System.err.println("ERROR: Couldn't find <t> or <time> elements in \"" + filename + "\". Setting time to 0.0.");
          }  
          addPoint( time, location );
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
  void saveGML( String filepath ) {
    
  }
  
  /**
   * Start recording a new stroke
   * Creates a new Stroke and assigns it to currentStroke
   */
  void startStroke() {
    if( currentStroke == null ) {
      currentStroke = new Stroke();
      strokes.add( currentStroke );
    } else {
      System.err.println("Already started stroke. Please endStroke before beginning new one");
    }
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
   * @param t Time value for new Point
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
   * Add a point to the current stroke
   * @param t Time value for new Point
   * @param location Vector representing the location of the point
   */
  void addPoint(float t, PVector location) {
    addPoint( t, location.x, location.y, location.z );
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
