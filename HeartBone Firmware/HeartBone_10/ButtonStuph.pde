/*

  BUTTON 0 TURNS ON SLEEP MODE
  BUTTON 1 TURNS OFF SLEEP MODE
  
  SLEEP MODE ~1 SECOND DELAY BETWEEN FRAME ADVANCE
  
  IF YOU GET IN TROUBLE, PRESS RESET!  
x
*/


void readButtons(){
  
 for(int i=0; i<3; i++){
  buttonState[i] = digitalRead(button[i]);
  if(buttonState[i] != lastButtonState[i]){
    if(buttonState[i] == HIGH){
      buttonPressed[i] = true;
      Serial.print("pressed "); Serial.println(i);  // verbose
    }
    lastButtonState[i] = buttonState[i];
  }
 }
 
       if(buttonPressed[SLEEP]){   
         buttonPressed[SLEEP] = false;
         if(!sleepy){
           if(activeGif >= numberOfGifs){  
             sendLCDprompt();  // home screen LCD display
             display.print("    No Gifs"); display.refresh();
             delay(800);
             sendLCDprompt();  // home screen LCD display
             return;
           }
           activeGifFrameCounter = 0;
           sleepyBytes[0] = 0xAA;  // set the sleepy flag
           sleepyBytes[1] = activeGif;
           sleepyBytes[2] = activeGifFrameCounter;
           sendGifToLCD = false;  // if this flag is up, put it down.
           sleepy = true;
         }
       }
       
       if(buttonPressed[WAKE]){
         buttonPressed[WAKE] = false;
         sleepyBytes[0] = 0x88;  // clear the sleepy flag
         EEwriteSleepyBytes();
         Serial.println("#Clearing Sleepy Flag"); Serial.print("$");
         sendLCDprompt();  // home screen LCD display
//         display.print("  Not Sleeping"); display.refresh();  // verbose
//         delay(800);                                          // verbose
//         sendLCDprompt();  // home screen LCD display         // verbose
         sleepy = false;
         sendGifToLCD = false;
         getStoredGifInfo();
         printStoredGifInfo();
       }
       
       if(buttonPressed[PLAY]){          
         buttonPressed[PLAY] = false;
         if(!sleepy){  // only scroll available gifs if not sleepy
           if(hasGifs){
             // if gif is already on display, try to show the next one
             if(sendGifToLCD == true){  // if we're already on display
               activeGif++;  // fire up the next gif!
               if(activeGif >= numberOfGifs){  // if there are no more gifs
                 activeGif = 0;  // back to the beginning
                 printStoredGifInfo();
                 return;  // get outa here!
               }
               activeGifFrameCounter = 0;  // start from the top
             }else if(activeGif < numberOfGifs){  
               sendGifToLCD = true;
               printStoredGifInfo();
               return;
             }
           }else{
             sendLCDprompt();
             display.print("  No Gif At "); display.print(activeGif+1); display.refresh();
             delay(800);
             sendLCDprompt();  // home screen LCD display
             activeGif = 0;
             sendGifToLCD = false;
           }
         }
       }
       
  
}  // end readButtons()
