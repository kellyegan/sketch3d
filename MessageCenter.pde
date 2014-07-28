/**
 * MessageCenter lets you send message to the display, create logs and write to the console via one message.
 *
 * @author Kelly Egan
 * @version 0.1
 */

import processing.core.PApplet;

class  MessageCenter {
  String status;
  StringList log;

  PApplet app;

  MessageCenter(PApplet a) {
    app = a;
    log = new StringList();
    status = "";
  }

  void updateStatus( String newStatus ) {
    status = newStatus;
    this.updateLog( "- STATUS - "  + status );
  }

  void updateLog( String newLog ) {
    String logEntry = hour() + ":" + nf(minute(), 2) + ":" + nf(second(), 2) + " " + newLog;
    println( logEntry );
    log.append( logEntry );
  }

  void saveLog() {
    saveStrings("log.txt", log.array() );
  }

  void display() {
    app.text( status, 25, 25 );
  }
}

void keyPressed() {
  mc.saveLog(); 
}

