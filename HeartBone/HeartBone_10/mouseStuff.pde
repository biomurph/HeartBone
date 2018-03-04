void mousePressed(){

  if(!serialBoneFound){
    for(int i=0; i<numBones; i++){
      if(button[i].pressRadio(mouseX,mouseY)){
        // if(i == numBones){
        //   if(Serial.list().length > numBones){
        //     println("New Ports Opened!");
        //     int diff = Serial.list().length - numBones;	// was serialPorts.length
        //     serialBones = expand(serialBones,diff);
        //     //button = (Radio[]) expand(button,diff);
        //     numBones = Serial.list().length;
        //   }else if(Serial.list().length < numBones){
        //     println("Some Ports Closed!");
        //     numBones = Serial.list().length;
        //   }else if(Serial.list().length == numBones){
        //     return;
        //   }
        //   refreshBones = true;
        //   return;
        // }else

        try{
          bone = new Serial(this, Serial.list()[i], 115200);  // make sure Arduino is talking serial at this baud rate
          delay(1000);
          println(bone.read());
          bone.clear();            // flush buffer
          bone.bufferUntil('\n');  // set buffer full flag on receipt of carriage return
          serialBoneFound = true;
        }
        catch(Exception e){
          println("Couldn't open port " + Serial.list()[i]);
          fill(255,0,0);
          text("Couldn't open port " + Serial.list()[i],200,400);
          fill(txtFill);
        }
      }
    }
  }
}

void mouseReleased(){

}
