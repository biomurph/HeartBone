void mousePressed(){

  if(!serialPortFound){
    for(int i=0; i<=numPorts; i++){
      if(button[i].pressRadio(mouseX,mouseY)){
        if(i == numPorts){
          if(Serial.list().length > numPorts){
            println("New Ports Opened!");
            int diff = Serial.list().length - numPorts;	// was serialPorts.length
            serialPorts = expand(serialPorts,diff);
            //button = (Radio[]) expand(button,diff);
            numPorts = Serial.list().length;
          }else if(Serial.list().length < numPorts){
            println("Some Ports Closed!");
            numPorts = Serial.list().length;
          }else if(Serial.list().length == numPorts){
            return;
          }
          refreshPorts = true;
          return;
        }else

        try{
          bone = new Serial(this, Serial.list()[i], 115200);  // make sure Arduino is talking serial at this baud rate
          delay(1000);
          println(bone.read());
          bone.clear();            // flush buffer
          bone.bufferUntil('\n');  // set buffer full flag on receipt of carriage return
          serialPortFound = true;
					rinseScreen = true;
        }
        catch(Exception e){
          println("Couldn't open port " + Serial.list()[i]);
          fill(255,0,0);
          text("Couldn't open port " + Serial.list()[i],60,70);

        }
      }
    }
  }
}

void keyPressed() {
  char token = key;
  switch(token){

    case 'l':
      frameNum++;
      if (frameNum > gifFrames.length-1) {
        frameNum = 0;
      }
      break;

    case 'a': case 'A': case 'c': // Serial back and forth to trigger frame sending
      if(!enoughMemory()){return;}
      setOption(token);
      break;

//    case 'A':   // invert the pixel values
//      if(!enoughMemory()){return;}
//      option = 2;
//      byteCounter = 0;
//      frameNum = 0;
//      playingGif = false;
//      nextFrame = true;
//      break;


    case 'P':  // 'P' prints the frame to the IDE terminal in 1s and 0s for fun
      loadPixels();  // this grabs the entire pixel array
      option = 'a';
      printPixels();
      break;
    case 'p':
      playingGif = !playingGif;  // toggle the boolean?
      break;
    case '=':
      getWatchData();
      break;
    case '0': case '1': case'2': case'3': case'4': case'5': case'6': case'7': case'8': case'9':
//    The gif number is sent to the watch
      bone.write(token);
      getWatchData();
      break;
    case 'E':
      bone.write(token);  // ERASE EEPROM ON WATCH!
      break;
    default:
      break;
  }

 if(token == CODED){
    switch(keyCode){
      case UP:
        gifNumber++;
        if(gifNumber == currentGif.size()){
//          gifNumber--;
          gifNumber = 0;  // rollover
        }
        getCurrentGif(gifNumber);
        frameNum = 0;
        background(bgrnd);
        updateText();
        // getWatchData();
        break;
      case DOWN:
        gifNumber--;
          if(gifNumber < 0){
//            gifNumber++;
            gifNumber = currentGif.size()-1;
          }
        getCurrentGif(gifNumber);
        frameNum = 0;
        background(bgrnd);
        updateText();
        // getWatchData();
        break;
      default:
        break;
    }
  }
}// end of keyPressed


void setOption(char o){
  option = o;
  byteCounter = 0;
  frameNum = 0;
  playingGif = false;
  nextFrame = true;
}

void clearTerm(){
  noStroke();
  fill(bgrnd);
  rect(0,textLine+lineHeight,width,height);
  fill(txtFill);
  feedbackTextLine = textLine+lineHeight;
  boneString = " ";
}




void printPixels(){
  println("Starting Pixels Dump");
  int pix = 0;   // pixel counter
    for (int i=0; i<LCDheight; i++){  // sort through the image area only
      for (int j=0; j<LCDwidth; j++){  // sort through the image area only
        if(pix == 0) {println(pixels[pix]);}  //  print out the  background value for reference
        if (pixels[pix] == pixels[0]){  // follow the background (this is important for resolving the image)
//          if (pixels[pix] == -16777216){  // -16777216 appears to be black??
          print('0');
        }else{  // option will invert the pixel value
          print('1');
        }
        pix++;
      }
      pix += width-LCDwidth;  // go directly to next line
      println();
    }
    println("\n");  // dismount
  }


boolean enoughMemory(){
   boolean is = false;
  if(availableFrames >= gifFrames.length){
    is = true;
  }else{
    print("not enough memory");
    text("not enough memory for " + gifName,indent,(feedbackTextLine + lineHeight));
  }
  return is;
}
