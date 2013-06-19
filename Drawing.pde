
class Drawing {
  List<Stroke> strokes;
  
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
  
  void display() {
    
  }
  
  void save() {
    
  }
  
  void export() {
    
  }
  
}
