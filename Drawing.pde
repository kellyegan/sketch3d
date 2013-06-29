/**
 * A Drawing is a object that contains 3D drawing data.
 * The Drawing consists of a list of Strokes which consists of a series of 3D points
 * @author Kelly Egan
 * @version 0.1
 */
class Drawing {
  List<Stroke> strokes;
  Stroke currentStroke;
  PVector scale;
  
  /**
   * Creates an empty Drawing.
   * The currentStroke is set to null until drawing begins
   */
  Drawing() {
    strokes = new ArrayList<Stroke>();
    currentStroke = null;
    scale = new PVector(1,1,1);
  }

  /**
   * Creates a Drawing from a GML file.
   * @param filename The name of the GML(Graffiti Markup Language) file to load.
   */  
  Drawing( String filename ) {
    this();
    
    int pointCount = 0;
    int strokeCount = 0;
    
    XML gml = loadXML( filename );
    XML drawing = gml.getChild("tag/drawing"); 
    
    XML screenBounds = gml.getChild("tag/environment/screenBounds");
    
    
    try {
      float x = screenBounds.getChild("x").getFloatContent();
      float y = screenBounds.getChild("y").getFloatContent();
      float z = screenBounds.getChild("z").getFloatContent();
      scale.set( x, y, z );
    } catch( Exception e ) {
      System.err.println("ERROR: Could not load scale data from \"" + filename + "\". Points will not scale correctly.");
    }
    
    XML [] strokeNodes = drawing.getChildren("stroke");
    for( XML s : strokeNodes ) {
      Stroke stroke = new Stroke();
      XML [] ptNodes = s.getChildren("pt");
    
      for( XML pt : ptNodes ) { 
        try {     
          float lx = pt.getChild("x").getFloatContent() * scale.x;
          float ly = pt.getChild("y").getFloatContent() * scale.y;
          float lz = pt.getChild("z").getFloatContent() * scale.z; 

        //Look for <t> node if it doesn't exist look for <time> node if it doesn't exist set time to 0
        XML t = pt.getChild("t");
        float time = 0.0;       
        if( t == null ) {
          t = pt.getChild("time");
          if(t != null) {
            time = t.getFloatContent();
          } else {
            System.err.println("ERROR: Couldn't find <t> or <time> elements in \"" + filename + "\". Setting time to 0.0.");
          }
        }
                 
        stroke.add( new Point( time, lx, ly, lz ) );
        pointCount++;
          
        } catch( Exception e ) {
          System.err.println("ERROR: Location data missing from <pt> element in \"" + filename + "\". Couldn't create point."); 
        }
      }          
      
      //Check and see if there are actually points in stroke
      //If not don't bother adding to stroke
      if( stroke.points.size() > 0 ) {
        strokes.add( stroke );
        strokeCount++;
      } else {
        System.err.println("ERROR: No <pt> elements found in <stroke> element in \"" + filename + "\". Stroke not created.");
      }
    }
    
    println("Loaded \"" + filename + "\". " + strokeCount + " strokes and " + pointCount + " points. Scale: " + scale);
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
    
  }

  /** 
   * Save the drawing in GML format
   * @param filename Name of the GML file to save
   */  
  void save(String filename) {
    
  }

  /** 
   * Export an STL file of the mesh
   * @param filename Name of the STL file to export to
   */   
  void export(String filename) {
    
  }
  
}
