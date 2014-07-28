/**
 * MessageCenter lets you send message to the display, create logs and write to the console via one message.
 *
 * @author Kelly Egan
 * @version 0.1
 */
 
import processing.core.PApplet;

class  MessageCenter{
  String status;
  String log;
  
  PApplet app;
  
  MessageCenter(PApplet a) {
    log = "";
    status = "";
  }
  
  void updateStatus( String newStatus ) {
    status = newStatus;
    log += "\n" + hour() + ":" + nf(minute(), 2) + " - "  + status;
    println( status );
  }
  
  void display() {
    app.text( status, 0, 0 );
  }
}
