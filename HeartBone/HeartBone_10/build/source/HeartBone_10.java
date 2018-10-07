import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import gifAnimation.*; 
import processing.serial.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class HeartBone_10 extends PApplet {

/*

  HEARTBONE WATCH INTERFACE PROGRAM

  NOTES:


 */

  // get the gif tools
  // get the serial com

int FRAME_LENGTH = 1152;  // number of bytes in each frame

PImage[] gifFrames;  // using PImage to hold current gif frame
Serial bone;         // name of the serial port

// FONT AND WATCH DATA FORMATTING
PFont font;
PFont boneFont;
int txtFill = 240;
int textLine = 20;
int lineHeight = 20;
int lineStart = 210;
int indent = 50;
int feedbackTextLine;
String boneString = " ";
boolean receivingFromBone = false;
String scrollString = " ";
boolean gotWatchData = false;

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
String serialPort;
String[] serialPorts = new String[Serial.list().length];
boolean serialPortFound = false;
Radio[] button = new Radio[Serial.list().length*2];
int numPorts = serialPorts.length;
boolean refreshPorts = false;

//  COLORS
int bgrnd = color(128,128,128);
boolean rinseScreen = false;

public void setup() {
  
  frameRate(60);
  font = loadFont("Monaco-16.vlw");
  textFont(font,16);

  loadGifs();  // get list of stored gifs from data file
  getCurrentGif(gifNumber);  // load th first gif to diplay on screen
  sendStartText();  // show prompts on console

  // START THE SHOW
  background(bgrnd);  // neutral grey background
  fill(txtFill);
  text("Select Your Serial Port",245,30);
  listAvailablePorts();

}


public void draw() {
if(serialPortFound){
  if(rinseScreen){ background(bgrnd); rinseScreen = false;}

  updateText();
  if(!gotWatchData){ getWatchData(); gotWatchData = true; }
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
        char test = PApplet.parseChar(bone.read());
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
      }//end of if
      delay(1);  // how small can this be?
      if(millis() - timeOut > 10000){return;}  // break out if connection is lost
    }// end of while
  }

  eventSerial();

} else { // SCAN BUTTONS TO FIND THE SERIAL PORT

  autoScanPorts();

  if(refreshPorts){
    refreshPorts = false;
    listAvailablePorts();
  }

  for(int i=0; i<numPorts+1; i++){
    button[i].overRadio(mouseX,mouseY);
    button[i].displayRadio();
  }

}

}  // end draw


public int[] getDelays(String filename, int numFrames){
   GifDecoder gifDecoder = new GifDecoder();
   gifDecoder.read(createInput(filename));  // openStream(filename));
  // int n = gifDecoder.getFrameCount();

  for(int i=0; i<numFrames; i++){
    delays[i] = gifDecoder.getDelay(i);
  }
  return delays;
}


// THIS NEEDS VARIANT TO SELECT ARBITRARY PIXEL IN FRAME
// THIS NEEDS VARIANT TO SELECT PIXEL IN EACH INDIVIDUAL FRAME
public void bufferImage(){
   loadPixels();  // loads 96x96 gif frame into pixel array
     int pix = 0;
     byte b;

       if(frameNum == 0){  // lock the value of first pixel as backgound color
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


public void sendStartText(){
  println("GIF has "+gifFrames.length + " frames");
  println("press 'p' to toggle gif animation on/off");
  println("press 'l' to advance one frame with rollover");
  println("press 'P' to print the frame displayed to console in 1s and 0s");
  println("Press 'a' to initiate gif load pixel True");
  println("Press 'E' to erase the EEPROM");
  println("Press 'bb' to initiate gif load pixel inverted");
  println("Press 'E' to erase entire contents of EEPROM. No turning back!");
	println("Press '=' to read stored data on watch");
}

public void updateText(){
  fill(txtFill);
  textLine = 20;
  gifName = currentGif.get(gifNumber);
  gifName = gifName.substring(0,gifName.length()-4);
  text(gifName,10,120);
  // println("lineStart " + lineStart);
  text("press 'p' to toggle gif animation on/off",lineStart,(textLine+=lineHeight));
  text("press 'P' to print frame in 1s & 0s to terminal",lineStart,(textLine+=lineHeight));
  text("press 'l' to advance gif one frame with rollover",lineStart,(textLine+=lineHeight));
  text("Press 'a' to initiate gif load pixel true",lineStart,(textLine+=lineHeight));
  text("Press 'A' to initiate gif load pixel inverted",lineStart,(textLine+=lineHeight));
  text("Press 'E' to erase the EEPROM. No turning back!",lineStart,(textLine+=lineHeight));
	text("Press '=' to read stored data on watch",lineStart,(textLine+=lineHeight));
  textLine+=lineHeight;  // add a space
  text("Gif " + (gifNumber+1) + " of " + currentGif.size() + " has "+gifFrames.length + " frames  Frame Rate: " + delays[0],indent,textLine+=lineHeight);
  text("Use UP DOWN to select gif",indent,(textLine+=lineHeight));

  feedbackTextLine = textLine + lineHeight;  // advance the line, expecting to write watch data soon

}


// create the PImage array for the gif
public void getCurrentGif(int name){
//  String Gif = currentGif.get(3);
  gifFrames = Gif.getPImages(this, currentGif.get(name));    // file is read into PImage[] from sketch folder
  getDelays(currentGif.get(name), PApplet.parseInt(gifFrames.length)); //  each frame delay into delays[]
  print("Current gif: "); println(currentGif.get(name));
  print("is gif "); print(name); print(" of "); println(currentGif.size());
  println("Frame Delays: ");
  for(int i=0; i<gifFrames.length; i++){
    println("["+i+"] "+delays[i]);
  }
  println();

}


public void getWatchData(){
  if(serialPortFound){
		// gotWatchData = true;
    fill(txtFill);
    feedbackTextLine = textLine+=lineHeight;
    text("Contents of EEPROM:",indent,(feedbackTextLine+=lineHeight));
    bone.write('=');  // sending = makes watch barf eeprom contents
  } else {
    println("Error: Couldn't getWatcData 'cause no serialPortFound");
  }
}


public void listAvailablePorts(){
  println(Serial.list());    // print a list of available serial ports to the console
  serialPorts = Serial.list();
  fill(0);
  // textFont(font);
  textAlign(LEFT);
  // set a counter to list the ports backwards
  int yPos = 0;
  int xPos = 35;
  for(int i=serialPorts.length-1; i>=0; i--){
    button[i] = new Radio(xPos, 95+(yPos*20),12,color(180),color(80),color(255),i,button);
    text(serialPorts[i],xPos+15, 100+(yPos*20));

    yPos++;
    if(yPos > height-30){
      yPos = 0; xPos+=200;
    }
  }
  int p = numPorts;
   fill(txtFill);
   button[p] = new Radio(35, 95+(yPos*20),12,color(180),color(80),color(255),p,button);
   text("Refresh Serial Ports List",50, 100+(yPos*20));

}

public void autoScanPorts(){
  if(Serial.list().length != numPorts){
    if(Serial.list().length > numPorts){
      println("New Ports Opened!");
      int diff = Serial.list().length - numPorts;	// was serialPorts.length
      serialPorts = expand(serialPorts,diff);
      numPorts = Serial.list().length;
    }else if(Serial.list().length < numPorts){
      println("Some Ports Closed!");
      numPorts = Serial.list().length;
    }
    refreshPorts = true;
    return;
  }
}
public void mousePressed(){

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

public void keyPressed() {
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


public void setOption(char o){
  option = o;
  byteCounter = 0;
  frameNum = 0;
  playingGif = false;
  nextFrame = true;
}

public void clearTerm(){
  noStroke();
  fill(bgrnd);
  rect(0,textLine+lineHeight,width,height);
  fill(txtFill);
  feedbackTextLine = textLine+lineHeight;
  boneString = " ";
}




public void printPixels(){
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


public boolean enoughMemory(){
   boolean is = false;
  if(availableFrames >= gifFrames.length){
    is = true;
  }else{
    print("not enough memory");
    text("not enough memory for " + gifName,indent,(feedbackTextLine + lineHeight));
  }
  return is;
}


public void eventSerial(){
  if(!sendingFrame){
  while(bone.available() > 0){
    char inChar = PApplet.parseChar(bone.read());
    print(inChar);

    if(receivingFromBone){   // do this when we get a '#' as prefix
      if(inChar == '\n'){    // TRY SWAPPING THE $ AND \n TO MAKE THE BONE CODE NICER
        writeBoneData();     // write the line when you get the '\n'
        boneString = " ";
      }else{
        boneString+=inChar;  // or, save the char to the string
      }
      if(inChar == '$'){receivingFromBone = false;   boneString = " ";}  // receiving is done
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
        availableFrames = PApplet.parseInt(bone.read());
        print(" " + availableFrames + " frames available");
        break;
      case '~':
        while(bone.available() == 0){}
        int activeGif = PApplet.parseInt(bone.read());
        println(" gif " + activeGif + " is active");
        break;
      default:
        break;
    }
    }
  }
 }// end if(!sendingFrame)
}



public void writeBoneData(){
  fill(txtFill);
  text(boneString,indent,(feedbackTextLine+=lineHeight));
}

public void scroll(){
  boneString += '>'; boneString += ' ';
  fill(txtFill);
  text(boneString,indent,(feedbackTextLine + lineHeight));
}

// add more gifs to the library by placing in the data folder and appending here

public void loadGifs(){
  currentGif = new StringList();
  currentGif.append("Tessellate.gif");
  currentGif.append("PlutoCharon.gif");
  currentGif.append("spiraltorustorso.gif");
  currentGif.append("snakeeyes.gif");
  currentGif.append("tubegoblin.gif");
  currentGif.append("braid-01.gif");
  currentGif.append("spiral2.gif");
  currentGif.append("explode.gif");
  currentGif.append("fierceHeart_01.gif");
  currentGif.append("Koi.gif");
  currentGif.append("fiercingHeart.gif");
  currentGif.append("hyperCube.gif");
  currentGif.append("coldFusion.gif");
  currentGif.append("MoireySlide.gif");
  currentGif.append("starTurn2.gif");
  currentGif.append("lockDown.gif");
  currentGif.append("drop.gif");
  currentGif.append("earth.gif");
  //currentGif.append("");

}
class Radio {
  int _x,_y;
  int size, dotSize;
  int baseColor, overColor, pressedColor;
  boolean over, pressed;
  int me;
  Radio[] radios;

  Radio(int xp, int yp, int s, int b, int o, int p, int m, Radio[] r) {
    _x = xp;
    _y = yp;
    size = s;
    dotSize = size - size/3;
    baseColor = b;
    overColor = o;
    pressedColor = p;
    radios = r;
    me = m;
  }

  public boolean pressRadio(float mx, float my){
    if (dist(_x, _y, mx, my) < size/2){
      pressed = true;
      for(int i=0; i<numPorts+1; i++){
        if(i != me){ radios[i].pressed = false; }
      }
      return true;
    } else {
      return false;
    }
  }

  public boolean overRadio(float mx, float my){
    if (dist(_x, _y, mx, my) < size/2){
      over = true;
      for(int i=0; i<numPorts+1; i++){
        if(i != me){ radios[i].over = false; }
      }
      return true;
    } else {
      over = false;
      return false;
    }
  }

  public void displayRadio(){
    noStroke();
    fill(baseColor);
    ellipse(_x,_y,size,size);
    if(over){
      fill(overColor);
      ellipse(_x,_y,dotSize,dotSize);
    }
    if(pressed){
      fill(pressedColor);
      ellipse(_x,_y,dotSize,dotSize);
    }
  }
}
  public void settings() {  size(800,500); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "HeartBone_10" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
