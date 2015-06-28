


void keyPressed() {
  char token = key;
  if(safeToken(token)){bone.write(token);};  // verbose serial to bone but not the special chars
  switch(token){
    
    case 'l':
      frameNum++;
      if (frameNum > gifFrames.length-1) {
        frameNum = 0;
      }
      break;
    case 'a':  // Serial back and forth to trigger frame sending
      if(!enoughMemory()){return;}
      playingGif = false;
      frameNum = 0;
      option = true;  // effects bufferImage()
      bufferImage();  // load the frame into the frame buffer
      byteCounter = 0;
      getBgrndForEachFrame = false;
      bone.write('a');  // send the 'a' to then get a '!' to start sending the frame
      frameRate(200);
      break;
    case 'A':
      if(!enoughMemory()){return;}
      playingGif = false;
      frameNum = 0;
      option = false;
      bufferImage();  // load the frame into the frame buffer
      byteCounter = 0;
      getBgrndForEachFrame = false;
      bone.write('a');  // send the 'a' to then get a '!' to start sending the frame
      frameRate(200);
      break;
    case 'b':  // Serial back and forth to trigger frame sending
      if(!enoughMemory()){return;}
      playingGif = false;
      frameNum = 0;
      option = true;
      bufferImage();  // load the frame into the frame buffer
      byteCounter = 0;
      getBgrndForEachFrame = true;
      bone.write('a');  // send the 'a' to then get a '!' to start sending the frame
      frameRate(200);
      break;
    case 'B':
      if(!enoughMemory()){return;}
      playingGif = false;
      frameNum = 0;
      option = false;
      bufferImage();  // load the frame into the frame buffer
      byteCounter = 0;
      getBgrndForEachFrame = true;
      bone.write('a');  // send the 'a' to then get a '!' to start sending the frame
      frameRate(200);
      break;
    case 'P':  // 'P' prints the frame to the IDE terminal in 1s and 0s for fun
      loadPixels();  // this grabs the entire pixel array
      option = true;
      printPixels();
      break;
    case 'p':
      playingGif = !playingGif;  // toggle the boolean?
      break;
//    case 'r':  // 'p' plays the gif one time through at the current frame rate
//      playingGif = true;
//      startOfFrameMillis = millis();
//      break;
    case '#':
      bone.write('#');
      break;
    case'E':  // erase the eeprom
      bone.write('%');
      break;
    case '0': case '1': case'2': case'3': case'4': case'5': case'6': case'7': case'8': case'9':
//      clearTerm();
//      bone.write('#');
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
        background(50);
        updateText();
        getWatchData();
        break;
      case DOWN:
        gifNumber--;
          if(gifNumber < 0){
//            gifNumber++;
            gifNumber = currentGif.size()-1;
          }
        getCurrentGif(gifNumber);
        frameNum = 0;
        background(50);
        updateText();
        getWatchData();
        break;
      default:
        break;
    }
  }
}

void clearTerm(){
  noStroke();
  fill(bgrnd);
  rect(0,textLine,width,height);
  fill(txtFill);
  feedbackTextLine = textLine+lineHeight*2;
  text("Contents of EEPROM:",outdent,(feedbackTextLine));
  boneString = " ";
}

boolean safeToken(char t){
  boolean safe = true;
  switch(t){
    case 'a': safe = false; break;
    case 'A': safe = false; break;
    case 'x': safe = false; break;
    case '#': safe = false; break;
    default:
    break;
  }
  return safe;
}


void printPixels(){
  println("Starting Pixels Dump");
  int pix = 0;   // pixel counter
    for (int i=0; i<LCDheight; i++){  // sort through the image area only
      for (int j=0; j<LCDwidth; j++){  // sort through the image area only
        if(pix == 0) {println(pixels[pix]);}  //  print out the  of the background, if you like
//          print(pixels[pix]);
        if (pixels[pix] == pixels[0]){  // follow the background (add param to flip)
//          if (pixels[pix] == -16777216){  // -16777216 appears to be black
          if(option){print('0');}else{print('1');}
        }else{
          if(option){print('1');}else{print('0');}
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
    print("error: not enough memory");
    text("error: not enough memory for " + gifName,outdent,(feedbackTextLine + lineHeight));
  }
  return is;
}
