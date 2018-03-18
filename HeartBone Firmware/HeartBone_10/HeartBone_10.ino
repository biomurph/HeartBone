  /*

    HEARTBONE CODE USED TO DRIVE THE HEARTBONE WATCH

    Super beta version of the first real prototype of the HeartBone watch.
    Made by Joel Murphy in the Spring in 2015 between SXSW and the 4th of July.

    This targets a DP32 embedded in custom hardware to control a SarpMem 96x96 LCD
    I used http://embeddedartists.com/products/displays/lcd_135_memory.php
    Also available from the good people at https://www.adafruit.com/products/1393

    Also in hardware is MCP25LC1024 1.024Mbit EEPROM: Store up to 100 frames

    Keeps track of stored gifs and will playback on command
      ASCII control via Serial
      4 Buttons in hardware: 0, 1, 2, RESET
      See readme for details
    Accepts gif data over Serial with dedicated software

    In software is:
    Bootloader chipKIT-DP32.hex https://github.com/chipKIT32/PIC32-avrdude-bootloader
    DSPI library for getting on the SPI bus
    Watchdog library by Majenko https://github.com/MajenkoLibraries/Watchdog
      In low-power sleep mode, the watch refreshes the screen about once every 1.024 seconds
      I took out this line in the Watchdog::sleep() function
        // enableIdleMode();
      and it seemed to work better|more
      Estimated current draw in sleep mode is ~2mA
    Adafruit_GFX https://github.com/adafruit/Adafruit-GFX-Library
      Only used for interface control in ascii
      Could be implemented for algorithmic animation or ascii art
    HeartBoneWatch
      portage of Adafruit_SharpMem library to DP_32
    MCP_EEPROM
      Writes and reads with the MCP25L1024

  NEEDS
    a way to 'reflect' play frames forward and backward.

  UPDATED March of 2017 to work with Arduino IDE by Joel Murphy

 */

#include <DSPI.h>
#include <Adafruit_GFX.h>
#include <HeartBone_Watch.h>
#include "MCP_EEPROM.h"  // used to store the gif frames MCP25LC1024 1,024,000-ish bits of EEPROM
#include <Watchdog.h>    // used to sleep the PIC

//  Create the display (Slave Select Pin, Display Enable Pin)
HeartBone_Watch display(LCD_SS, DISP);
#define SLEEP  0
#define WAKE   1
#define PLAY   2
#define FRAME_LENGTH  1152
// Each frame takes up 1152 bits, 144 bytes, 4.5 pages of EEPROM
// Reserve 5 pages per frame
// EEPROM = 1,048,216 bits, 131,072 bytes, 512 pages, 102.4 frames
// const int frameLength = 96*12;  // 96x96 pixels stored in bytes
byte frame[FRAME_LENGTH];   // incoming frame buffer array
const int pageSize = 256;  // EEPROM page is 256 bytes long
byte page[pageSize];       // used to load byte data for EEwriteBytes()
boolean loadingFrameBuffer = false;  // set when 'a' is received
boolean frameBufferLoaded = false;   // set when frameBuffer is loaded with a frame
boolean lastFrameLoaded = false;     // boolean set when last frame of gif is loaded

uint32_t benchTimer;  // general purpose benchmark timer
uint32_t bench;       // general purpose benchmark timer

const int totalFramesAvailable = 100;  // should be a define?
int framesAvailable = 0;  // is what it says
unsigned int frameAddress[totalFramesAvailable];      // address of each frame in memory 0,256,512,768,1024....
int totalFramesUsed = 0;
int frameByteCounter = 0;   // counts up to 1152 bytes per frame
int loadedFrameCounter = 0; // keep track of the number of frames loaded to serial or screen
// metaData is stored information about gifs: total gifs stored, number of frames in each gif,,,
unsigned int metaDataStartEEdress = pageSize*5*101;  // metaData kept away from frame data.
uint8_t numberOfGifs;          // number of gif stored in eeprom
uint8_t framesInGif[9];      // save up to 9 gifs
boolean hasGifs = false;       // boolean set when gifs are in eeprom
int gifStartAddress[9];  // save the start address of up to 9 gifs
boolean coldReadFrame = false;  // verbose?

boolean sendGifToLCD = false; // sends the activeGif to LCD
int activeGif = 0;
int activeGifFrameCounter = 0;

// >>>>  BUTTON STUFF  <<<<
volatile int button[3] = {6,1,17};  // button pins
volatile int buttonState[3];  //  read button states into this array
volatile int lastButtonState[3];  // remember button state with this array
volatile  boolean buttonPressed[3];  // rising edge flags

//  >>>>  SLEEPY STUFF  <<<<  have to store the sleepy state in EEPROM 'cause wakey is restart-ish...
Watchdog dog;
boolean sleepy = false;  // remember if we are supposed to sleep
//byte rememberedState;  //
unsigned int sleepyFlagEEdress = pageSize*5*102; // place to store sleep info on EEPROM
const int numSleepyBytes = 3;  // 0=sleep/!sleep, 1=activeGif, 2=currentFrame
byte sleepyBytes[numSleepyBytes];  // array to hold sleep data

void setup(){  // here we go
  Serial.begin(115200);  // TRY HIGHER DATA RATES TO MAXIMIZE SPEED
  delay(30); // DON'T STARTLE THE SLEEPY (this seems to help?? test it)

// >>>>    EEPROM STUFF  <<<<
  pinMode(EE_SS,OUTPUT);
  digitalWrite(EE_SS,HIGH);
  pinMode(WP,OUTPUT);
  digitalWrite(WP,LOW);	// protect status reg
  pinMode(10,OUTPUT);
  digitalWrite(10,HIGH);

  for(int i=0; i<totalFramesAvailable; i++){ // room for 100 frames in EEPROM
    frameAddress[i] = (i*5)*256;	// store the start address for each frame
  }

  // CHECK SLEEPY STATE
  feelSleepyState();
  // SETUP BUTTON STUFF button0 = sleepy; button1 = !sleepy; button2 = scroll stored gifs
  initButtons();  // set pin direction and take inital reading of buttons
  getStoredGifInfo(); // read metaData in EEPROM

  if(!sleepy){
    display.begin();
    display.setRotation(0);
    sendLCDprompt();
    Serial.println("\nHeartBone");
    printStoredGifInfo();  // print metaData to Serial
  }

}


void loop(){

      if(sleepy){
        drawNextFrameOfActiveGif(activeGifFrameCounter);
        activeGifFrameCounter++;  // advance to the next frame
        // only play frames from this gif
        if(activeGifFrameCounter == framesInGif[activeGif]){activeGifFrameCounter = 0;}
        sleepyBytes[2] = activeGifFrameCounter;  // remember the frame we're on
        EEwriteSleepyBytes();  // really, remember it
        delay(10);
        dog.sleep();  // 1.024 Seconds-ish
        // sleeping
        delay(10);  // how does this help?
        // TEST PUTTING readButtons HERE
        feelSleepyState();  // readButtons happens at end of loop and will trigger a wake up
      }


  if(sendGifToLCD){    // plays the acitveGif at a default frame rate

//      if(eventSerial() > 0){return;}  // break out of playback??
      drawNextFrameOfActiveGif(activeGifFrameCounter);
      activeGifFrameCounter++;
      if(activeGifFrameCounter == framesInGif[activeGif]){activeGifFrameCounter = 0;}
      delay(120);  // needs delay derived from gif
      readButtons();  // check for sleepy state
      if(sleepy){return;}  // break out of this playback

  }

  if(loadingFrameBuffer){  // receive 'a' and send '!' to start this process
    while(Serial.available() > 0){  // changed from while??
      frame[frameByteCounter] = Serial.read();  // load the entire frame into frame buffer
      frameByteCounter++;
      Serial.print('*');  // ask for the next byte, please
      if(frameByteCounter == FRAME_LENGTH){  // frameByteCounter counts from 1 to 1152
        loadingFrameBuffer = false;  // the frame is loaded
        frameByteCounter = 0;  // reset for writing to eeprom
        frameBufferLoaded = true;    // trigger the EEPROM write
//      }else{
//        Serial.print("*");  // ask for the next byte, please
      }
    }
  }


  if(frameBufferLoaded){  // write a frame in four 256 byte pages + one 128 byte page
    // Serial.println("#writing latest frame to the eeprom"); Serial.print("$");  // verbose
    totalFramesUsed = getTotalFramesUsed();
    totalFramesUsed+= loadedFrameCounter;
    for(int i=0; i<256*4; i+=256){
      EEwriteFrameBytes(frameAddress[totalFramesUsed]+i,256);    // write 256 bytes of frame
    }
    EEwriteFrameBytes(frameAddress[totalFramesUsed]+256*4,128);  // write the last 128 bytes of frame
    loadedFrameCounter++;  // keep track of the number of frames we are collecting
    frameBufferLoaded = false;
    Serial.print("@");  // ask for next frame if there is one
  }

  if(lastFrameLoaded){
    numberOfGifs++;
    // Serial.println("#Storing gif metaData"); Serial.print("$"); // verbose
    // need to set up page array with the right data and do EEwriteBytes(ADDRESS,NUMBYTES)(metaDataStartEEdress,numberOfGifs+1)
    framesInGif[numberOfGifs-1] = loadedFrameCounter;
    page[0] = numberOfGifs;  // 1 indexed
    for(int i=1; i<=numberOfGifs; i++){
      page[i] = framesInGif[i-1];  // fIG [0 indexed] storage starts after the mDSE
    }
    EEwriteBytes(metaDataStartEEdress,numberOfGifs+1);  // store the updated number of gifs

    loadedFrameCounter = 0;  // reset for next time
    lastFrameLoaded = false;
    getStoredGifInfo();
    printStoredGifInfo();
  }


  if(!loadingFrameBuffer){  // don't get interrupted when you're loading a frame
    readButtons();  // button0 = sleepy, button1 = wake, button2 = play
    eventSerial();
  }



}  // end of loop


void drawNextFrameOfActiveGif(int frameNum){
  int f = gifStartAddress[activeGif] + ((pageSize*5)*frameNum);
  readFrame(f);
  drawMemBuff();
}

int getTotalFramesUsed(){
  totalFramesUsed = 0;  // reset before counting
  for(int i=0; i< numberOfGifs; i++){ // count the number of total frames to find the start address of this frame
    totalFramesUsed+= framesInGif[i];  // build the totalFramesUsednumber
  }
  return totalFramesUsed;
}


void getStoredGifInfo(){
  numberOfGifs = EEreadByte(metaDataStartEEdress);
  if(numberOfGifs > 0 && numberOfGifs < 9){
    hasGifs = true;
  }
  else{
    numberOfGifs = 0;
    EEwriteByte(metaDataStartEEdress,numberOfGifs);

  }
  if(hasGifs){
    for(int i=0; i<numberOfGifs; i++){
      framesInGif[i] = EEreadByte(metaDataStartEEdress+1+i);
      if(i == 0){
        gifStartAddress[i] = 0;
      }else{
        gifStartAddress[i] = framesInGif[i-1]*pageSize*5 + gifStartAddress[i-1];
      }
    }
  }
  framesAvailable = totalFramesAvailable - getTotalFramesUsed();
}

void printStoredGifInfo(){
  Serial.print("#Watch has ");  // send '#' to tell program string is starting
  Serial.print(numberOfGifs,DEC);
  Serial.println(" Stored Gif(s)");
  if(hasGifs){
    for(int i=0; i<numberOfGifs; i++){
      Serial.print("Gif ");
      Serial.print(i+1);
      Serial.print(" has ");
      Serial.print(framesInGif[i],DEC);
      Serial.print(" frames");  // starting at page ");
//      Serial.print(gifStartAddress[i]);
      Serial.println();
    }
  }
  Serial.print(framesAvailable);
  Serial.println(" frames available");
  if(sendGifToLCD){
    Serial.print("Playing ");
    Serial.println(activeGif+1,DEC);
  }else{
    Serial.println("No gif playing");
  }
  Serial.print("$");  // send '$' to end string
  Serial.print("\n="); Serial.write(framesAvailable);  // moving this \n will help to make the code nicer!
  Serial.print("\n~"); Serial.write(activeGif);  // hold it together

}

void initButtons(){
  for(int i=0;i<3;i++){
    pinMode(button[i],INPUT);
    buttonPressed[i] = false;
  }
  readButtons();
}

void feelSleepyState(){
  EEreadSleepyBytes();
  if(sleepyBytes[0] == 0xAA){  // flag was set in button_0 press
    sleepy = true;
    activeGif = sleepyBytes[1];  // this was stored in button_0 press
    activeGifFrameCounter = sleepyBytes[2];
  }else{
    sleepy = false;
  }
}
