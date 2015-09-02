/*
		LCD Functions
*/


void sendLCDprompt(){
  display.clearDisplay();
  display.setTextColor(BLACK);
  display.setCursor(0,0);
  // 16 chars per line at default text size
  display.println();
  display.print(" play      wake ");
  display.println();
  display.println("     *");
  display.println();
  display.println("          *");
  display.println(" *");
  display.println("    heartbone");
  display.println();
  display.println("        *");
  display.print(" reset    sleep ");
  display.refresh();

}

void clearScreen(){
	display.spi.setSelect(HIGH);

	display.spi.transfer(CLEAR);	// send clear command
	display.spi.transfer(0x00);		// send trailer

	display.spi.setSelect(LOW);
}

void disableLCD(){
  digitalWrite(DISP,LOW);
}


void initLCD(){
  delay(50);  // waiting for something (power up?)
  clearScreen();
  digitalWrite(DISP,HIGH);
}


//	LCD gets data in little-endian
byte reverse(byte v) {
  v = ((v >> 1) & 0x55) | ((v & 0x55) << 1); /* swap odd/even bits */
  v = ((v >> 2) & 0x33) | ((v & 0x33) << 2); /* swap bit pairs */
  v = ((v >> 4) & 0x0F) | ((v & 0x0F) << 4); /* swap nibbles */
  return v;
}

// draws the contents of the sharpmem_buffer to screen
void drawMemBuff(){
  display.spi.setSelect(HIGH);
        int byteCounter = 0;
	display.spi.transfer(DYNAMIC);
	for(int i=1; i<=96; i++){   // send the line number, pixel data, trailer
	  byte line = reverse(i);	    // little-endian, please
	  display.spi.transfer(line);	    // send line number
	  for(int i=1; i<=12; i++){
	    display.spi.transfer(display.sharpmem_buffer[byteCounter]);   byteCounter++;  // send line data
	  }
	  display.spi.transfer(0x00);	    // send trailer
	}
	display.spi.transfer(0x00);	    // send final trailer

  display.spi.setSelect(LOW);
}

// draws the contents of frame buffer to screen
void drawFrame(){
  display.spi.setSelect(HIGH);
        int byteCounter = 0;
	display.spi.transfer(DYNAMIC);
	for(int i=1; i<=96; i++){   // send the line number, pixel data, trailer
	  byte line = reverse(i);	    // little-endian, please
	  display.spi.transfer(line);	    // send line number
	  for(int i=1; i<=12; i++){
	    display.spi.transfer(frame[byteCounter]);   byteCounter++;  // send line data
	  }
	  display.spi.transfer(0x00);	    // send trailer
	}
	display.spi.transfer(0x00);	    // send final trailer

  display.spi.setSelect(LOW);
}


// all black
//void blackScreen(){
//	display.spi.setSelect(HIGH);
//
//	display.spi.transfer(DYNAMIC);
//	for(int i=1; i<=96; i++){   // send the line number, pixel data, trailer
//	  byte line = reverse(i);	    // little-endian, please
//	  display.spi.transfer(line);	    // send line number
//	  for(int i=1; i<=12; i++){
//	    display.spi.transfer(0x00);     // send line data (96 bits of nothing)
//	  }
//	  display.spi.transfer(0x00);	    // send trailer
//	}
//	display.spi.transfer(0x00);	    // send final trailer
//
//	display.spi.setSelect(LOW);
//}
//
//// writes all bytes to the passed byte and displays on screen
//void writeLines(byte b){
//        display.spi.setSelect(HIGH);
//
//	display.spi.transfer(DYNAMIC);
//	for(int i=1; i<=96; i++){   // send the line number, pixel data, trailer
//	  byte line = reverse(i);	    // little-endian, please
//	  display.spi.transfer(line);	    // send line number
//	  for(int i=1; i<=12; i++){
//	    display.spi.transfer(b);     // send line data (96 bits of nothing)
//	  }
//	  display.spi.transfer(0x00);	    // send trailer
//	}
//	display.spi.transfer(0x00);	    // send final trailer
//
//	display.spi.setSelect(LOW);
//}


