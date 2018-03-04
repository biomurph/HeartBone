

void eventSerial(){
  if(!sendingFrame){
  while(bone.available() > 0){
    char inChar = char(bone.read());
    print(inChar); 
    
    if(receivingFromBone){   // do this when we get a '#' as prefix      
      if(inChar == '\n'){    // TRY SWAPPING THE $ AND \n TO MAKE THE BONE CODE NICER
        writeBoneData();     // write the line when you get the '\n'
        boneString = " ";
      }else{
        boneString+=inChar;  // or, save the char to the string  
      }
      if(inChar == '$'){receivingFromBone = false; boneString = " ";}  // receiving is done 
//      return;  // this really slows it down...
    }
    else  // when not receiving data from watch look for command characters
    {
    switch(inChar){ 
      case '!':  // watch sends '!' to handshake request for the next frame
        sendingFrame = true;
        byteCounter = 0;
        println(" sending frame number "+frameNum);
        break;
      case '@':  // watch sends '@' to ask for the next frame
        byteCounter = 0;  // ??  FIND OUT WHERE THIS GETS SET AND DECIDE ON A PLACE
        frameNum++;
        scrollString = " ";
        nextFrame = true;
        if(frameNum == gifFrames.length){
          frameNum = 0;
          println("sent all frames");
          bone.write('x');  // tell watch that we're done
          nextFrame = false;
          clearTerm();
          return;
        }
        println("on frame " + frameNum);
        break;
      case '#':
        clearTerm();
        receivingFromBone = true; 
        break;
      case '=':
        while(bone.available() == 0){}
        availableFrames = int(bone.read());
        print(" " + availableFrames + " frames available");
        break;
      case '~':
        while(bone.available() == 0){}
        int activeGif = int(bone.read());
        println(" gif " + activeGif + " is active");
        break;
      default:
        break;
    }
    }
  }
 }// end if(!sendingFrame)
}



void writeBoneData(){
  fill(txtFill);
  text(boneString,indent,(feedbackTextLine+=lineHeight));
}

void scroll(){
  boneString += '>'; boneString += ' ';
  fill(txtFill);
  text(boneString,indent,(feedbackTextLine + lineHeight));
}