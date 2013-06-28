
class Drawing {
  List<Stroke> strokes;
  Stroke currentStroke;
  
  Drawing() {
    strokes = new ArrayList<Stroke>();
  }
  
  Drawing( String filename ) {
    XML gml = loadXML( filename );
    
    XML drawing = gml.getChild("tag/drawing");
    
    for( XML stroke : drawing.getChildren("stroke") ) {
      strokes.add( new Stroke( stroke ) );
    }
    
  }
  
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
    }
  }
  
  //Creates or recreates a mesh from the stroke data
  void createMesh() {
    
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
