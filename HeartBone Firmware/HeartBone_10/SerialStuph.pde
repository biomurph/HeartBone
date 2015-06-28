/*
    list ascii command set here
  
*/

char eventSerial(){
  char requestedGifNumber;
  
  if(!loadingFrameBuffer || !sleepy){
    if(Serial.available()>0){
      char c = Serial.read();
      
      switch(c){
        case 'a':  // receive 'a' to load  the next frame
          loadingFrameBuffer = true; sendGifToLCD = false; 
          frameByteCounter = 0;  // this counts 1152 bytes 
          Serial.print('!');  // handshake to initiate data xfer
          Serial.print("#Loading frame "); Serial.println(loadedFrameCounter+1,DEC); Serial.print('$');
          sendLCDprompt();
          display.print(" Loading "); display.print(loadedFrameCounter+1); display.refresh();
          break;
        case 'x':  // no more frames to collect!
          lastFrameLoaded = true;  // button up the animation variables for sending to LCD
          sendLCDprompt();
          break;
        case 'u': // print all the frames from all the animations ?
          printEEframes_Hex();
          break;
        case 'E': // erase eeprom on chip for good ! erasing still blanks the frame
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
        case '#':
          getStoredGifInfo();  // ask for details about what's on the EEPROM
          printStoredGifInfo();  // sends info back to serial port
          break;
        case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9':
          requestedGifNumber = c - '1';  // dont commit until you know it is legit
          if(requestedGifNumber < numberOfGifs && activeGif >= 0){
            sendGifToLCD = true;
            activeGif = requestedGifNumber;
            activeGifFrameCounter = 0;
            printStoredGifInfo();
          }else{
            sendGifToLCD = false;
            sendLCDprompt();
            Serial.print("#No Gif at "); Serial.println(c);Serial.print("$");
//            display.print("  No Gif at "); display.println(c); display.refresh();  // verbose
            delay(800);
//            sendLCDprompt();  // reset LCD display
            printStoredGifInfo();
          }
          break;
        case '%':
          getStoredGifInfo();  
          printStoredGifInfo();
          break;
        case '^':
          Serial.print(totalFramesUsed,BYTE);  
          break;
        case '0':
          display.clearDisplay();
          sendGifToLCD = false; // stop sending the gif you're sending
          sendLCDprompt();
          printStoredGifInfo();
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
      return c;
    }// end while serialAvailable
  } 
}

//  some chars cannot be used verbosely. too powerful  //  not sure this is necessary...
//boolean safeToken(char t){
//  boolean safe = true;
//  switch(t){
//    case 'a': safe = false;
//    break;
//    case 'x': safe = false;
//    break;
//    case '#': safe = false;
//    break;
//    
//    default:
//    break;
//  }
//  return safe;
//}
