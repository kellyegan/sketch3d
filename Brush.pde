class Brush {
  String strokeName;
  int strokeColor;
  int strokeWeight;
  
  Brush() {
    strokeName = "";
    strokeColor = color(0, 0, 0, 255);
    strokeWeight = 1;
  }
  
  Brush(String n, int c, int w) {
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
  
  int getWeight() {
    return strokeColor;
  }
   
  void setWeight( int w ) {
    strokeWeight = w;
  }
  
  void apply() {
    noFill();
    stroke( strokeColor );
    strokeWeight( strokeWeight );
  }
  
}
