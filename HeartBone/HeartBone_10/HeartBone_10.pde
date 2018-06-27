/*

  HEARTBONE WATCH INTERFACE PROGRAM

  NOTES:


 */

import gifAnimation.*;  // get the gif tools
import processing.serial.*;  // get the serial com

int FRAME_LENGTH = 1152;  // number of bytes in each frame

PImage[] gifFrames;  // using PImage to hold current gif frame
Serial bone;         // name of the serial port

// FONT AND WATCH DATA FORMATTING
PFont font;
int txtFill = 255;
int textLine = 20;
int lineHeight = 20;
int lineStart = 210;
int indent = 50;
int feedbackTextLine;
String bufferString = "";
String boneString = "";
boolean receivingFromBone = false;
String scrollString = "";

// FRAME STUFF
int frameNum = 0;  // used to step through frames
int frameSize = 96*12;  // 96 vertical x 8*12 horizontal
byte[] picData = new byte [frameSize];  // array to hold the pixels[] data
int[] delays = new int [100];   // reserve max ints to hold individual frame delays for current frame
int startOfFrameMillis;  // holds the start time of current frame for playback
int firstPixel;
char option;

//  GENERALLY USEFUL TO HAVE AROUND
int byteCounter = 0;
long timeOut;

boolean playingGif = false;  //  press 'p' to play the gif one time
//boolean writingHalfPage = false;  // timing flag during EEPROM write session
boolean sendingFrame = false;  // triggers sending of frame to watch
boolean nextFrame = false;  // true when watch asks for next frame and it's available to send
int availableFrames = 0;  // sourced from the watch EEPROM

int LCDwidth = 96;
int LCDheight = 96;


StringList currentGif;
int  gifNumber = 0;  // the gif on display
String gifName;

// SERIAL PORT STUFF TO HELP YOU FIND THE CORRECT SERIAL PORT
String serialBone;
String[] serialBones = new String[Serial.list().length];
boolean serialBoneFound = false;
boolean newBone = false;
Radio[] button = new Radio[Serial.list().length*2];
int numBones = serialBones.length;
boolean refreshBones = true;

int bgrnd = 50;
void setup() {
  size(800,500);
  frameRate(60);
  font = loadFont("Monaco-16.vlw");
  textFont(font, 16);
  textAlign(LEFT);

  loadGifs();  // get list of stored gifs from data file
  getCurrentGif(gifNumber);  // load th first gif to diplay on screen
  sendStartText();  // show prompts on console
  // background(bgrnd);  // neutral grey background

  // text("Select Your Serial Port",245,30);
  // listAvailableBones();

  // START THE SHOW

  // updateText();    // print commands and currentGif info to screen
  // getWatchData(); // formats to sketch window

}


void draw() {
  background(bgrnd);
    updateText();    // print commands and currentGif or serial port list info to screen

    image(gifFrames[frameNum], 0, 0);  // display 96x96 pix image from the data file in Sketch folder

    if(playingGif){
      if(millis() - startOfFrameMillis > delays[frameNum]){
        frameNum++;
        startOfFrameMillis = millis();

        if(frameNum == gifFrames.length){
          frameNum = 0;
  //        playingGif = false;  // just once please
        }
      }
    }

if(serialBoneFound){
    if(nextFrame){    //
      println("buffering");
      bufferImage();  // load the frame into the frame buffer
      byteCounter = 0;
      bone.write('a');  // send the 'a' to then get a '!' and keep sending frames
      nextFrame = false;  // reset nextFrame flag
    }

    if(sendingFrame == true){
      if(byteCounter == 0){
        bone.write(picData[byteCounter]);  // send the first byte
        byteCounter++;
        timeOut = millis();
      }

      while(sendingFrame == true){  //
        if(bone.available() > 0){
          char test = char(bone.read());
  //        print(test);  // verbose
          if(test == '*'){  // get a * from bone before sending next byte
            bone.write(picData[byteCounter]);  // send the next byte
            byteCounter++;
            if(byteCounter%256 == 0){
              println(byteCounter + " bytes sent");
            }
            if(byteCounter == FRAME_LENGTH){  //
              sendingFrame = false;
              byteCounter = 0;
            }
          }
        }//end of if bone.available
        delay(1);  // how small can this be?
        if(millis() - timeOut > 10000){return;}  // break out if connection is lost
      } // end of while sendingFrame
    }

    if(newBone){ newBone = false; getWatchData(); } // formats to sketch window
    writeBoneData();

    eventSerial();
  //  checkKeys();
  } else {
    autoScanBones();

    // if(refreshBones){
    //   refreshBones = false;
      listAvailableBones();
    // }

    for(int i=0; i<numBones; i++){  // add +1 to numBones if using 'Refresh Ports' button
      button[i].overRadio(mouseX,mouseY);
      button[i].displayRadio();
    }
  }
}  // end draw


int[] getDelays(String filename, int numFrames){
   GifDecoder gifDecoder = new GifDecoder();
   gifDecoder.read(createInput(filename));
  // int n = gifDecoder.getFrameCount();

  for(int i=0; i<numFrames; i++){
    delays[i] = gifDecoder.getDelay(i);
  }
  return delays;
}



// THIS NEEDS VARIANT TO SELECT ARBITRARY PIXEL IN FRAME
// THIS NEEDS VARIANT TO SELECT PIXEL IN EACH INDIVIDUAL FRAME
void bufferImage(){
   loadPixels();  // loads 96x96 gif frame into pixel array
     int pix = 0;
     byte b;

       if(frameNum == 0){  // lock the backgound color
         switch(option){
           case 'a': case 'A':
             firstPixel = pixels[0];
             break;
           case 'c':  // THIS IS NOT WORKING YET...
             firstPixel = pixels[((LCDheight/2)*width) + (LCDwidth/2)]; // select the center of the image
             break;
           default:
             break;
         }
         println("first pixel = " + firstPixel);
       }
     byteCounter = 0;
     for (int i=0; i<LCDheight; i++){  // sort through the image area only
       for (int j=0; j<LCDwidth; j++){  // sort through the image area only
         // if(pix == 0) {println(pixels[pix]);}  //  print out the color of the background, if you like
           if (pixels[pix] == firstPixel){  // follow the first pixel of the first frame
             if(option >= 'a'){b = 0x00;}else{b = 0x01;}
           }else{    // test if the pixel is white or black
             if(option <= 'a'){b = 0x01;}else{b = 0x00;}
           }
         pix++;
         picData[byteCounter] <<= 1;
         picData[byteCounter] += b;    // log the pixel in the byte array
         if((j+1)%8 == 0){
           byteCounter++;
         }
       }
       pix += width-LCDwidth;  // go directly to next line
     }
}


void sendStartText(){
  println("GIF has "+gifFrames.length + " frames");
  println("press 'p' to toggle gif animation on/off");
  println("press 'l' to advance one frame with rollover");
  println("press 'P' to print the frame displayed to console in 1s and 0s");
  println("Press 'a' to initiate gif load pixel True");
  println("Press 'E' to erase the EEPROM");
  println("Press 'bb' to initiate gif load pixel inverted");
  println("Press 'E' to erase entire contents of EEPROM. No turning back!");
}

void updateText(){
  fill(txtFill);
  textLine = 20;
  gifName = currentGif.get(gifNumber);
  gifName = gifName.substring(0,gifName.length()-4);
  text(gifName,10,120);
  text("Gif " + (gifNumber+1) + " of " + currentGif.size() + " has "+gifFrames.length + " frames  Frame Rate: " + delays[0],lineStart,textLine+=lineHeight);
  text("Use UP DOWN to select gif",lineStart,(textLine+=lineHeight));
  textLine+=lineHeight;
  text("press 'p' to toggle gif animation on/off",lineStart,(textLine+=lineHeight));
  text("press 'P' to print frame in 1s & 0s to terminal",lineStart,(textLine+=lineHeight));
  text("press 'l' to advance gif one frame with rollover",lineStart,(textLine+=lineHeight));
  if(serialBoneFound){
    text("Press 'a' to initiate gif load pixel true",lineStart,(textLine+=lineHeight));
    text("Press 'A' to initiate gif load pixel inverted",lineStart,(textLine+=lineHeight));
    text("Press 'E' to erase the EEPROM. No turning back!",lineStart,(textLine+=lineHeight));
    text("Press '1' -- '9' to play stored gifs listed below",lineStart,(textLine+=lineHeight));
  }
  // textLine +=lineHeight*3;  // add a space
  // text("Gif " + (gifNumber+1) + " of " + currentGif.size() + " has "+gifFrames.length + " frames  Frame Rate: " + delays[0],indent,textLine+=lineHeight);
  // text("Use UP DOWN to select gif",indent,(textLine+=lineHeight));

  feedbackTextLine = textLine + lineHeight;  // advance the line, expecting to write watch data soon

}


// create the PImage array for the gif
void getCurrentGif(int name){
//  String Gif = currentGif.get(3);
  gifFrames = Gif.getPImages(this, currentGif.get(name));    // file is read into PImage[] from sketch folder
  getDelays(currentGif.get(name), int(gifFrames.length)); //  each frame delay into delays[]
  print("Current gif: "); println(currentGif.get(name));
  print("is gif "); print(name); print(" of "); println(currentGif.size());
  println("Frame Delays: ");
  for(int i=0; i<gifFrames.length; i++){
    println("["+i+"] "+delays[i]);
  }
  println();

}


void getWatchData(){
  fill(txtFill);
//  feedbackTextLine = textLine+=lineHeight;
//  text("Contents of EEPROM:",indent,(feedbackTextLine+=lineHeight));
  bone.write('=');  // sending = makes watch barf eeprom contents
}

void listAvailableBones(){
  // println(Serial.list());    // print a list of available serial ports to the console
  serialBones = Serial.list();
  fill(250,0,250);
  feedbackTextLine += 50;
  text("Select Your Serial Port",245,feedbackTextLine);
  feedbackTextLine+=25;
  fill(txtFill);
  int yPos = 0;
  int xPos = 35;
  for(int i=serialBones.length-1; i>=0; i--){
    button[i] = new Radio(xPos, feedbackTextLine+(yPos*20),12,color(180),color(80),color(255),i,button);
    text(serialBones[i],xPos+15, feedbackTextLine+5+(yPos*20));

    yPos++;
    if(yPos > height-30){
      yPos = 0; xPos+=200;
    }
  }
  // int p = numBones;
  //  fill(233,0,0);
  // button[p] = new Radio(35, feedbackTextLine+(yPos*20),12,color(180),color(80),color(255),p,button);
  //   text("Refresh Serial Port List",50, feedbackTextLine+5+(yPos*20));

}

void autoScanBones(){
  if(Serial.list().length != numBones){
    if(Serial.list().length > numBones){
      println("New Ports Opened!");
      int diff = Serial.list().length - numBones;	// was serialPorts.length
      serialBones = expand(serialBones,diff);
      numBones = Serial.list().length;
    }else if(Serial.list().length < numBones){
      println("Some Ports Closed!");
      numBones = Serial.list().length;
    }
    refreshBones = true;
    return;
  }
}
