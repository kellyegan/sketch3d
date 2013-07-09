class Brush {
  String strokeName;
  int strokeColor;
  float strokeWeight;
  
  Brush() {
    strokeName = "";
    strokeColor = color(0, 0, 0, 255);
    strokeWeight = 1;
  }
  
  Brush(String n, int c, float w) {
   strokeName = n;
   strokeColor = c;
   strokeWeight = w;
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
    return strokeWeight;
  }
   
  void setWeight( float w ) {
    strokeWeight = w;
  }
  
  void apply() {
    noFill();
    stroke( strokeColor );
    strokeWeight( strokeWeight );
  }
  
}
