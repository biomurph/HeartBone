/*

  HEARTBONE WATCH CONTROL SOFTWARE BETA

 */

import gifAnimation.*;  // get the gif tools
import processing.serial.*;  // get the hardware com

PImage[] gifFrames;  // using PImage to hold gif frame series
Serial bone;   // name the serial port

PFont font;
int txtFill = 255;
int textLine = 20;
int lineHeight = 20;
int lineStart = 210;
int outdent = 50;
int feedbackTextLine;

int frameNum = 0;  // used to step through frames
int pixelZero;  // 
boolean getBgrndForEachFrame = false;
byte h = 0x00;  //

//PrintWriter imageFile;  // ?
int frameSize = 96*12;  // 96 vertical x 8*12 horizontal
byte[] picData = new byte [frameSize];  // array to hold the pixels[] data
int[] delays = new int [100];   // reserve max ints to hold individual frame delays for current frame
int startOfFrameMillis;  // holds the start time of current frame for playback

String boneString = " ";
boolean receivingFromBone = false;
boolean savingImage = false;
boolean sendingPage = false;
int byteCounter = 0;

boolean playingGif = false;  //  press 'p' to play the gif one time
boolean writingHalfPage = false;  // timing flag during EEPROM write session
boolean sendingFrame = false;  //
int halfPageCounter;  // timing flad during EEPROM write session
boolean nextFrame = false;  //
int availableFrames = 0;  // sourced from the watch

int LCDwidth = 96;
int LCDheight = 96;

int framesPerSecond = 60;  // changes to 200 during upload for speed's sake

StringList currentGif;
int  gifNumber = 0;  // the gif on display
String gifName;

boolean option = true;

int bgrnd = 50;
void setup() {
  size(900,500);
  frameRate(framesPerSecond);

  println("gifAnimation " + Gif.version()); // verbose version
  font = loadFont("Monaco-16.vlw");
  textFont(font, 16);

  currentGif = new StringList();
  currentGif.append("Tessellate.gif");
  currentGif.append("PlutoCharon.gif");
  currentGif.append("spiraltorustorso.gif");
  currentGif.append("snakeeyes.gif");
  currentGif.append("tubegoblin.gif");
  currentGif.append("braid-01.gif");
  currentGif.append("knot_01.gif");
  currentGif.append("spiral2.gif");
  currentGif.append("explode.gif");
  currentGif.append("fierceHeart_01.gif");
  currentGif.append("Koi.gif");
  currentGif.append("fiercingHeart.gif");
  //currentGif.append("");

  println(Serial.list());  // list the serial ports available
  bone = new Serial(this, Serial.list()[9], 115200);  // open port at baudrate


  getCurrentGif(gifNumber);

  sendStartText();  // show prompts on console
  background(bgrnd);  //
  updateText();    // print commands and currentGif info to screen
  bone.write('0');
  getWatchData();
}

void draw() {



  image(gifFrames[frameNum], 0, 0);  // reads from the data file in Sketch folder

  if(playingGif){
    if(millis() - startOfFrameMillis > delays[frameNum]){
      frameNum++;
      startOfFrameMillis = millis();

      if(frameNum == gifFrames.length){
        frameNum = 0;
//        playingGif = false;
      }
    }
  }

  if(nextFrame){    //
    bufferImage();  // load the frame into the frame buffer
    byteCounter = 0;
    bone.write('a');  // send the 'a' to then get a '!' and keep sending frames
    nextFrame = false;  // reset nextFrame flag
  }

  if(sendingFrame){
    bone.write(picData[byteCounter]);
    byteCounter++;
    if(byteCounter == 1){scroll();}
    if(byteCounter%128 == 0){
      println(byteCounter + " bytes sent");
      scroll();
    }
    if(byteCounter == picData.length){
      sendingFrame = false;
    }
  }

  eventSerial();

}  // end draw


int[] getDelays(String filename, int numFrames){
   GifDecoder gifDecoder = new GifDecoder();
   gifDecoder.read(openStream(filename));
  // int n = gifDecoder.getFrameCount();

  for(int i=0; i<numFrames; i++){
    delays[i] = gifDecoder.getDelay(i);
  }
  return delays;
}


void mousePressed() {

}



void bufferImage(){  // arrange bitmap for transfer
   loadPixels();  // loads 96x96 gif frame into pixel array
   int pix = 0;
   byte b;
   int byteCounter = 0;
   if(frameNum == 0){
     pixelZero = pixels[0];  // this grabs first pixel of first frame ONLY for background
   }
   if(getBgrndForEachFrame){
     pixelZero = pixels[0];  // this grabs first pixel of EACH frame for background
   }
//    println(pixelZero);  // verbose
     for (int i=0; i<LCDheight; i++){  // sort through the image area only
       for (int j=0; j<LCDwidth; j++){  // sort through the image area only
         if (pixels[pix] == pixelZero){  // follow the background
           b = 0x00;
           if(option){b = 0x01;}
//           print("0");   // verbose
         }else{    // test if the pixel is white or black
           b = 0x01;
           if(option){b = 0x00;}
//           print("1"); // verbose
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
  println("Press 'A' to initiate gif load pixel inverted");
  println("Contents of EEPROM:\n");
}

void updateText(){
  fill(txtFill);
  textLine = 20;
  gifName = currentGif.get(gifNumber);
  gifName = gifName.substring(0,gifName.length()-4);
  text(gifName,10,120);
  text("press 'p' to toggle gif animation on/off",lineStart,(textLine+=lineHeight));
  text("press 'l' to advance gif one frame with rollover",lineStart,(textLine+=lineHeight));
  text("Press 'a' to start gif xfer pixel True",lineStart,(textLine+=lineHeight));
  text("Press 'A' to start gif xfer pixel Inverted",lineStart,(textLine+=lineHeight));
  text("Press 'b' to start gif xfer with background set for each frame, pixel True",lineStart,(textLine+=lineHeight));
  text("Press 'B' to start gif xfer with background set for each frame, pixel Inverted",lineStart,(textLine+=lineHeight));
  text("Press 'E' to erase the EEPROM. No turning back.",lineStart,(textLine+=lineHeight));
  text("Press '1' - '9' to play stored gifs",lineStart,(textLine+=lineHeight));
  textLine+=lineHeight;  // add a space
  text("Gif " + (gifNumber+1) + " of " + currentGif.size() + " has "+gifFrames.length + " frames  Frame Rate: " + delays[0],outdent,textLine+=lineHeight);
  text("Use UP DOWN to select gif",outdent,(textLine+=lineHeight));

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
  feedbackTextLine = textLine+=lineHeight;
  text("Contents of EEPROM:",outdent,(feedbackTextLine+=lineHeight));
  bone.write('#');  // sending # makes watch barf eeprom contents 
}
