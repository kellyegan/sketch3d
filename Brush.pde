class Brush {
  String strokeName;
  int strokeColor;
  float brushSize;
  
  Brush() {
    strokeName = "";
    strokeColor = color(0, 0, 0, 255);
    brushSize = 1;
  }
  
  Brush(String n, int c, float w) {
   strokeName = n;
   strokeColor = c;
   brushSize = w;
  }
  
  String getName() {
    return strokeName;
  }
  
  void setName( String n ) {
    strokeName = n;
  }
  
  int getColor() {
    return strokeColor;
  }
  
  void setColor( int c ) {
    strokeColor = c;
  }
  
  float getWeight() {
    return brushSize;
  }
   
  void setWeight( float w ) {
    brushSize = w;
  }
  
  void apply() {
    noFill();
    stroke( strokeColor );
    strokeWeight  ( brushSize );
  }
  
}
