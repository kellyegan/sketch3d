/**
 * A Drawing is a object that contains 3D stroke data.
 * The Drawing consists of a list of Strokes which consists of a series of Points
 * @author Kelly Egan
 * @version 0.1
 */

import processing.core.PApplet;
 
class Drawing {
  List<Stroke> strokes;
  List<Stroke> undos;
  Stroke currentStroke;
  
  float minimumDistance;
  
  PVector screenBounds; 
  PVector up;
  PVector realScale;
  
  PApplet app;
  
  /**
   * Creates an empty Drawing from the "template.gml" file
   * The currentStroke is set to null until drawing begins
   * And there is no Stroke or Point data
   */
  Drawing(PApplet a) {
    this(a, "template.gml");
  }

  /**
   * Creates a Drawing from a GML (Graffiti Markup Language) file.
   * @param filepath Path to the GML file.
   */  
  Drawing(PApplet a, String filepath ) {
    app = a;
    strokes = new ArrayList<Stroke>();
    undos = new ArrayList<Stroke>();
    minimumDistance = 10;
    load( filepath );
  }
  
  /** 
   * Loads an GML (Graffiti Markup Language) file into the Drawing object
   * @param filepath Path to the GML file.
   */
  void load(String filepath) {
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
      Brush brushStyle = new Brush();
      
      if( strokeElement.getChild("brush") != null ) {
        //Check if there is a uniqueStyleID value and if so apply it to Brush
        try {
          brushStyle.setName( strokeElement.getChild("brush/uniqueStyleID").getContent() );
        } catch( Exception e ) {
          System.err.println("ERROR: uniqueStyleID data not found for Brush.");
        }
        
        //Check if there is a width value and if so apply it to Brush strokeWeight
        try {
          brushStyle.setWeight( strokeElement.getChild("brush/width").getIntContent() );
        } catch( Exception e ) {
          System.err.println("ERROR: Width data not found for Brush.");
        }
        
        //Check if there are r, g, and b color values and if so apply it to Brush color
        try {
          int r = strokeElement.getChild("brush/color/r").getIntContent();
          int g = strokeElement.getChild("brush/color/g").getIntContent();
          int b = strokeElement.getChild("brush/color/b").getIntContent();
          int a = strokeElement.getChild("brush/color/a").getIntContent();
          brushStyle.setColor( color(r,g,b,a) );
        } catch( Exception e ) {
          System.err.println("ERROR: Color data not found for Brush.");
        }       
      }
      
      startStroke( brushStyle );
        
      //Load points
      for( XML ptElement : strokeElement.getChildren("pt") ) {
        PVector location = xmlToVector( ptElement );
        
        if( location != null ) {
          location = scaleToScreen( location );
          float time = 0.0;
          if( ptElement.getChild("t") != null ) {
            time = ptElement.getChild("t").getFloatContent();
          } else if( ptElement.getChild("time") != null ) {
            time = ptElement.getChild("time").getFloatContent();
          } else {
            System.err.println("ERROR: Couldn't find <t> or <time> elements in \"" + filename + "\". Setting time to 0.0.");
          }  
          addPoint( time, location, true );   //Ignore minimum distance and just reads in points as they are stored.
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
  void save( String filepath ) {
    XML gml = loadXML("template.gml");
    XML drawing = gml.getChild("tag/drawing");
    
    XML screenBoundsElement = gml.getChild("tag/header/environment/screenBounds");
    screenBoundsElement.getChild("x").setFloatContent( screenBounds.x );
    screenBoundsElement.getChild("y").setFloatContent( screenBounds.y );
    screenBoundsElement.getChild("z").setFloatContent( screenBounds.z );
    
    //up vector follows processing convention (0, -1, 0)
    
    XML realScaleElement = gml.getChild("tag/header/environment/realScale");
    realScaleElement.getChild("x").setFloatContent( realScale.x );
    realScaleElement.getChild("y").setFloatContent( realScale.y );
    realScaleElement.getChild("z").setFloatContent( realScale.z );
    
    for( Stroke stroke : strokes ) {
      if( stroke.points.size() > 0 ) {
        XML strokeElement = drawing.addChild("stroke");
        
        //Add Brush data
        XML brushElement = strokeElement.addChild("brush");
        brushElement.addChild("uniqueStyleID").setContent( stroke.style.getName() );
        brushElement.addChild("width").setFloatContent( stroke.style.getWeight() );
        XML brushColor = brushElement.addChild("color");
        brushColor.addChild("r").setIntContent( (int)red( stroke.style.getColor() ) );
        brushColor.addChild("g").setIntContent( (int)green( stroke.style.getColor() ) );
        brushColor.addChild("b").setIntContent( (int)blue( stroke.style.getColor() ) );
        brushColor.addChild("a").setIntContent( (int)alpha( stroke.style.getColor() ) );
        
        for( Point point : stroke.points ) {
          XML ptElement = vectorToXml("pt", scaleToGML(point.location));
          ptElement.addChild("t").setFloatContent(point.time);
          strokeElement.addChild(ptElement);
        }
      }
    }
    
    saveXML( gml, filepath );
  }
  
  /**
   * Start recording a new stroke
   * Creates a new Stroke and assigns it to currentStroke
   * @param brushStyle Brush to apply to this new stroke
   */
  void startStroke(Brush brushStyle) {
    undos.clear();
    if( currentStroke == null ) {
      currentStroke = new Stroke( app, brushStyle );
      strokes.add( currentStroke );
    } else {
      System.err.println("Already started stroke. Please endStroke before beginning new one");
    }
  }

  /**
   * Start recording a new stroke
   * Creates a new Stroke and assigns it to currentStroke
   * @param name Name of the Brush
   * @param c Color of the Brush
   * @param w Weight of the Brush stroke
   */
  void startStroke(String n, int c, int w) {
    startStroke( new Brush( n, c, w ) );
  }
  
  /**
   * Start recording a new stroke
   * Creates a new Stroke and assigns it to currentStroke
   */
  void startStroke() {
    startStroke( new Brush() );
  }
  
  /** 
   * End the current stroke
   * Sets currentStroke to null
   */ 
  void endStroke() {
    currentStroke.createMesh();
    currentStroke = null;
  }
  
  /**
   * Add a point to the current stroke
   * @param t Time value for new Point
   * @param lx X coordinate of points location.
   * @param ly Y coordinate of points location.
   * @param lz Z coordinate of points location.
   * @param ignoreMinimumDistance If set will record new point even if under minimum distance from last point
   */
  void addPoint(float t, float lx, float ly, float lz, boolean ignoreMinimumDistance) {
    if( currentStroke != null ) {
      float distance = currentStroke.distanceToLast(lx, ly, lz);
      //Make sure new points are a minimum distance from other points

      
      if( currentStroke.points.size() == 0 || ignoreMinimumDistance || distance > minimumDistance || distance < 0) {
        currentStroke.add( new Point(t, lx, ly, lz) );
      }
    } else {
      //Instead of an error message should it just initiate a new stroke and then add it?
      System.err.println("ERROR: No current stroke. Call startStroke before adding new point.");  
    }
  }
  
  /**
   * Add a point to the current stroke
   * @param t Time value for new Point
   * @param lx X coordinate of points location.
   * @param ly Y coordinate of points location.
   * @param lz Z coordinate of points location.
   */ 
  void addPoint(float t, float lx, float ly, float lz) {
    addPoint( t, lx, ly, lz, false);
  }
  
  /**
   * Add a point to the current stroke
   * @param t Time value for new Point
   * @param location Vector representing the location of the point
   */
  void addPoint(float t, PVector location) {
    addPoint( t, location.x, location.y, location.z, false );
  }
  
  /**
   * Add a point to the current stroke
   * @param t Time value for new Point
   * @param location Vector representing the location of the point
   */
  void addPoint(float t, PVector location, boolean ignoreMinimumDistance) {
    addPoint( t, location.x, location.y, location.z, ignoreMinimumDistance );
  }
  
  /**
   * Creates or recreates a mesh from the stroke data
   */
  void createMesh() {
    for( Stroke s : strokes ) {
      s.createMesh();
    }
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
   * Reset the Drawing object to the template file
   */
  void reset() {
    load("template.gml");
  }
  
  /**
   * Remove all Stroke data from the Drawing object
   */
  void clearStrokes() {
    strokes.clear(); 
  }
  
  /**
   * Removes the last stroke from the Drawing object
   */
  void undoLastStroke() {
    if( !strokes.isEmpty() ) {
      undos.add( strokes.remove(strokes.size() - 1) );
    }
  }
  
  /**
   * Add last stroke removed from Drawing object back.
   */
  void redoLastStroke() {
    if( !undos.isEmpty() ) {
      strokes.add( undos.remove(undos.size() - 1 ) );
    }
  }
  
  /**
   * Setter for minimum distance variable.
   */
  void setMinimumDistance(float distance ){
    minimumDistance = distance;
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
  PVector scaleToScreen( PVector vector ) {
    vector.sub( new PVector( 0.5, 0.5, 0.5 ) );

    PVector scaledVector = new PVector();
    //X axis is up 
    if( abs( up.x ) == 1 ) {
      scaledVector.x = vector.y * screenBounds.x;
      if( up.x > 0 ) {
        scaledVector.y = screenBounds.y - vector.x * screenBounds.y;
      } else {
        scaledVector.y = vector.x * screenBounds.y;
      }
      scaledVector.z = vector.z * screenBounds.z;
    //Y axis is up
    } else if( abs( up.y ) == 1 ) {
      scaledVector.x = vector.x * screenBounds.x;
      if( up.y > 0 ) {
        scaledVector.y = screenBounds.y - vector.y * screenBounds.y;
      } else {
        scaledVector.y = vector.y * screenBounds.y;
      }
      scaledVector.z = vector.z * screenBounds.z;
    //Z axis is up  
    } else {
      scaledVector.x = vector.x * screenBounds.x;
      if( up.z > 0 ) {
        scaledVector.y = screenBounds.y - vector.z * screenBounds.y;
      } else {
        scaledVector.y = vector.z * screenBounds.y;
      }
      scaledVector.z = vector.y * screenBounds.z;
    }
    
    return scaledVector;
  }
  
  /**
   * Scale screen coordinates to GML (0 to 1) based on screenBounds)
   * @param vector Vector to scale
   * @return PVector scaled to 1 to 0
   */
  PVector scaleToGML( PVector vector ) {
    PVector scaledVector = new PVector( vector.x / screenBounds.x, vector.y / screenBounds.y, vector.z / screenBounds.z);
    scaledVector.add( new PVector( 0.5, 0.5, 0.5 ) );
    return scaledVector;
  }
  
}
