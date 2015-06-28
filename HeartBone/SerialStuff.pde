

void eventSerial(){
  while(bone.available() > 0){
    char inChar = char(bone.read());
    print(inChar);  // verbose
    if(receivingFromBone){
      if(inChar == '$'){receivingFromBone = false; boneString = " ";return;}
      if(inChar == '\n'){
        writeBoneData();
        boneString = " ";
        return;
      }else{
        boneString+=inChar;
      }
    }
    switch(inChar){ 
      case '!':  // watch sends '!' to handshake request for the next frame
        sendingFrame = true;
        println(" sending frame number "+frameNum);
        boneString = " ";
        break;
      case '@':  // watch sends '@' to ask for the next frame
        frameNum++;
        nextFrame = true;
        if(frameNum == gifFrames.length){
          frameNum = 0;
          println("sent all frames");
          bone.write('x');  // tell watch that we're done
          nextFrame = false;
          getBgrndForEachFrame = false;
          clearTerm();
          frameRate(60);
          return;
        }
      case '#':
        clearTerm();
        receivingFromBone = true; 
        break;
      case '=':
        while(bone.available() == 0){}
        availableFrames = int(bone.read());
        print("numFrames " + availableFrames);
        break;
      default:
        break;
    }
      
  }
  
  
}



void writeBoneData(){
  fill(txtFill);
  text(boneString,outdent,(feedbackTextLine+=lineHeight));
}

void scroll(){
  boneString += '>';
  text(boneString,outdent,(feedbackTextLine + lineHeight));
}


