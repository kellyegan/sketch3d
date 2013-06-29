
class Drawing {
  List<Stroke> strokes;
  Stroke currentStroke;
  
  Drawing() {
    strokes = new ArrayList<Stroke>();
  }
  
  Drawing( String filename ) {
    this();
    
    int pointCount = 0;
    int strokeCount = 0;
    
    XML gml = loadXML( filename );
    XML drawing = gml.getChild("tag/drawing"); 
    
    XML [] strokeNodes = drawing.getChildren("stroke");
    for( XML s : strokeNodes ) {
      Stroke stroke = new Stroke();
      XML [] ptNodes = s.getChildren("pt");
    
      for( XML pt : ptNodes ) { 
        try {     
          float lx = pt.getChild("x").getFloatContent();
          float ly = pt.getChild("y").getFloatContent();
          float lz = pt.getChild("z").getFloatContent(); 

        //Look for <t> node if it doesn't exist look for <time> node if it doesn't exist set time to 0
        XML t = pt.getChild("t");
        float time = 0.0;       
        if( t == null ) {
          t = pt.getChild("time");
          if(t != null) {
            time = t.getFloatContent();
          } else {
            System.err.println("ERROR: Couldn't find <t> or <time> node in \"" + filename + "\". Setting time to 0.0.");
          }
        }
                 
        stroke.add( new Point( time, lx, ly, lz ) );
        pointCount++;
          
        } catch( Exception e ) {
          System.err.println("ERROR: Location data missing from <pt> node in \"" + filename + "\". Couldn't create point."); 
        }
      }          
      strokes.add( stroke );
      strokeCount++;
    }
    
    println("Loaded \"" + filename + "\". " + strokeCount + " strokes and " + pointCount + " points.");
  }
  
/********************************************************************************

    points = new LinkedList<Point>();
    

  
********************************************************************************/

  
  //Start recording a new stroke
  void startStroke() {
    currentStroke = new Stroke();
    strokes.add( currentStroke );
  }
  
  //End the current stroke
  void endStroke() {
    currentStroke = null;
  }
  
  //Add a point to the current stroke
  void addPoint(float t, float x, float y, float z) {
    if( currentStroke != null ) {
      currentStroke.add( new Point(t, x, y, z) );
    } else {
      //Should this be an exception?
      //Should it just initiate a new stroke and then add?
      println("Error: No current stroke. Call startStroke before adding new point.");  
    }
  }
  
  //Creates or recreates a mesh from the stroke data
  //Is it efficient to just recreate or remove and readd individual strokes
  void createMesh() {
    
  }
  
  void list() {
    for( Stroke stroke : strokes ) {
      stroke.list();
    }
  }
  
  //Display the mesh
  void display() {
    
  }
  
  //Save the drawing
  void save() {
    
  }
  
  //Export an STL file of the mesh
  void export() {
    
  }
  
}
