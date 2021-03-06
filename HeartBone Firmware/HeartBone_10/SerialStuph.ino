/*
    list ascii command set here

    needs option to 'reflect' the gif (run forwards, then backwards, etc) memory doubler!
*/

void serialEvent(){	// mpide uses eventSerial
  char requestedGifNumber;

  if(loadingFrameBuffer == false){
    if(Serial.available() > 0){
      char c = Serial.read();
      Serial.write(c);Serial.println();

      switch(c){
        case 'a':  // receive 'a' to load  the next frame
          sendGifToLCD = false;
          loadingFrameBuffer = true;
          frameByteCounter = 0;  // this counts 1152 bytes
          Serial.print("#Loading frame "); Serial.println(loadedFrameCounter+1,DEC); Serial.print('$');
          sendLCDprompt();
          display.print(" Loading "); display.print(loadedFrameCounter+1); display.refresh();
          Serial.print('!');  // handshake to initiate data xfer
          return;
          break;
        case 'x':  // no more frames to collect!
          lastFrameLoaded = true;  // button up the animation variables for sending to LCD
          sendLCDprompt();
          break;

        case 'E': // erase eeprom on chip for good !
          Serial.println("# erasing entire chip"); Serial.print("$");
          EEchipErase();
          sendGifToLCD = false;
          delay(100);
          getStoredGifInfo();
          printStoredGifInfo();
          sendLCDprompt();
          break;
//        case 'r':
//          // cool stuff here?
//          break;
        case '=':
          getStoredGifInfo();  // ask for details about what's on the EEPROM
          printStoredGifInfo();  // sends info back to serial port
          break;
        case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9':
          requestedGifNumber = c - '1';  // dont commit until you know it is legit
          if(requestedGifNumber < numberOfGifs){
            sendGifToLCD = true;
            activeGif = requestedGifNumber;
            activeGifFrameCounter = 0;
          }else{
            sendGifToLCD = false;
            sendLCDprompt();
            Serial.print("#No Gif at "); Serial.println(c);Serial.print("$");
            display.print("  No Gif at "); display.println(c); display.refresh();  // verbose
            delay(800);
            sendLCDprompt();  // reset LCD display
          }
          break;
        case '^':  // this is not used in program yet...
          Serial.write(totalFramesUsed);
          break;
        case '%':
          getStoredGifInfo();
          printStoredGifInfo();
          break;
        case '0':
          display.clearDisplay();
          sendGifToLCD = false; // stop sending the gif you're sending
          sendLCDprompt();
          break;
//        case 's':  // verbose testing
//          Serial.print("sleepyBytes ");
//          for(int i=0; i<numSleepyBytes; i++){
//            Serial.print(sleepyBytes[i],HEX); Serial.print("\t");
//          }
//          Serial.println();
//          Serial.print("metaData ");
//          break;
        default:
          break;
      }
//     return c;
    }// end if serialAvailable
  }
}


