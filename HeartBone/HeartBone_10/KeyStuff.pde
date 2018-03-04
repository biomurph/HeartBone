

//void checkKeys(){
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
      if(serialBoneFound){
        setOption(token);
      } else {
        println("No Bone Connected!");
      }
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
      if(serialBoneFound){
        getWatchData();
      } else {
        println("No Bone Connected!");
      }
      break;
    case '0': case '1': case'2': case'3': case'4': case'5': case'6': case'7': case'8': case'9':
      if(serialBoneFound){
        //    The gif number is sent to the watch
        bone.write(token);
        getWatchData();
      } else {
        println("No Bone Connected!");
      }
      break;
    case 'E':
      if(serialBoneFound){
        bone.write(token);  // ERASE EEPROM ON WATCH!
      } else {
        println("No Bone Connected!");
      }
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
        refreshBones = true;
        updateText();
        if(serialBoneFound){
          getWatchData();
        }
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
        refreshBones = true;
        updateText();
        if(serialBoneFound){
          getWatchData();
        }
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
