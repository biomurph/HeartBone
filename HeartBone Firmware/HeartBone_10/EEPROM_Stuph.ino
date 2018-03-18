/*
    1Mbit EEPROM
 128Kbytes
 500 pages	(page size = 256 bytes)
 1152 bytes in Frame
 4.5 pages per Frame
 100 Frames @ 5 pages per frame
 128 bytes available in each frame usable for metadata


 */



uint8_t EEreadStatus()
{
  uint8_t inByte;
  digitalWrite(EE_SS,LOW);
  display.spi.transfer(RDSR);
  inByte = display.spi.transfer(0x00);
  digitalWrite(EE_SS,HIGH);
  return inByte;
}

void EEwriteStatus(uint8_t outByte)
{
  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WRSR);
  display.spi.transfer(outByte);
  digitalWrite(EE_SS,HIGH);
}


uint8_t EEreadSignature()
{
  uint8_t inByte;
  digitalWrite(EE_SS,LOW);
  display.spi.transfer(RDID);
  display.spi.transfer(0x00);
  display.spi.transfer(0x00);
  display.spi.transfer(0x00);
  inByte = display.spi.transfer(0x00);
  digitalWrite(EE_SS,HIGH);
  return inByte;
}


void EEreadBytes(int address, int numBytes)
{
  digitalWrite(EE_SS,LOW);
  display.spi.transfer(READ_EE);
  for(int i=2; i>=0; i--){
    byte b = address>>(i*8);
    display.spi.transfer(b & 0xFF);  // send the address
  }
  for(int i=0; i<numBytes; i++){
    page[i] = display.spi.transfer(0x00);
  }

  digitalWrite(EE_SS,HIGH);
}

void EEreadSleepyBytes()
{
  digitalWrite(EE_SS,LOW);
  display.spi.transfer(READ_EE);
  for(int i=2; i>=0; i--){
    byte b = sleepyFlagEEdress>>(i*8);
    display.spi.transfer(b & 0xFF);  // send the address
  }
  for(int i=0; i<numSleepyBytes; i++){
    sleepyBytes[i] = display.spi.transfer(0x00);
  }

  digitalWrite(EE_SS,HIGH);
}

uint8_t EEreadByte(int address)
{
  uint8_t inByte;

  digitalWrite(EE_SS,LOW);
  display.spi.transfer(READ_EE);
  for(int i=2; i>=0; i--){
    byte b = address>>(i*8);
    display.spi.transfer(b & 0xFF);  // send the address
  }
  inByte = display.spi.transfer(0x00);

  digitalWrite(EE_SS,HIGH);
  return inByte;
}


void readFrame(int address)
{
  digitalWrite(EE_SS,LOW);
  display.spi.transfer(READ_EE);
  for(int i=2; i>=0; i--){
    byte b = address>>(i*8);
    display.spi.transfer(b & 0xFF);  // send the address
  }
  for(int i=0; i<1152; i++){	// 96X96/8 = 1152
    display.sharpmem_buffer[i] = display.spi.transfer(0x00);
  }
  digitalWrite(EE_SS,HIGH);
}



void getFrame(int startFrame, int numFrames)
{
  for(int i=0; i<numFrames; i++){
    readFrame(frameAddress[startFrame]);
  }
}



void EEwritePage(int address)  // write the entire page buffer starting at address
{
  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WREN);			// enable write
  digitalWrite(EE_SS,HIGH);

  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WRITE_EE);	// send write command
  for(int i=2; i>=0; i--){
    byte b = address>>(i*8);
    display.spi.transfer(b & 0xFF);  // send the address
  }
  for(int i=0; i<pageSize; i++){	// 256 bytes per page
    display.spi.transfer(page[i]);
  }
  digitalWrite(EE_SS,HIGH);

  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WRDI);			// disable write
  digitalWrite(EE_SS,HIGH);

  while((EEreadStatus()) && 0x02 > 0){
  }
}


void EEwriteByte(int address, uint8_t outByte)  // write a single byte
{
  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WREN);			// enable write
  digitalWrite(EE_SS,HIGH);

  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WRITE_EE);
  for(int i=2; i>=0; i--){
    byte b = address>>(i*8);
    display.spi.transfer(b & 0xFF);  // send the address
  }
  display.spi.transfer(outByte);                  // send the lonley byte
  digitalWrite(EE_SS,HIGH);

  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WRDI);			// disable write
  digitalWrite(EE_SS,HIGH);

  while((EEreadStatus()) && 0x02 > 0){
  }

}


void EEwriteBytes(int address, int numBytes)  // write numBytes starting at address
{
  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WREN);			// enable write
  digitalWrite(EE_SS,HIGH);

  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WRITE_EE);
  for(int i=2; i>=0; i--){
    byte b = address>>(i*8);
    display.spi.transfer(b & 0xFF);  // send the address
  }
  for(int i=0; i<numBytes; i++){	// 256 bytes per page
    display.spi.transfer(page[i]);
  }
  digitalWrite(EE_SS,HIGH);

  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WRDI);			// disable write
  digitalWrite(EE_SS,HIGH);


  while((EEreadStatus() && 0x02) > 0){
  }

}

void EEwriteSleepyBytes()  // write numBytes starting at address
{
  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WREN);			// enable write
  digitalWrite(EE_SS,HIGH);

  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WRITE_EE);
  for(int i=2; i>=0; i--){
    byte b = sleepyFlagEEdress>>(i*8);
    display.spi.transfer(b & 0xFF);	// send the address
  }
  for(int i=0; i<numSleepyBytes; i++){	// sleepyFlag, activeGif, activeGifFrameCounter
    display.spi.transfer(sleepyBytes[i]);
  }
  digitalWrite(EE_SS,HIGH);

  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WRDI);			// disable write
  digitalWrite(EE_SS,HIGH);


  while((EEreadStatus() && 0x02) > 0){
  }

}

void EEwriteFrameBytes(int address, int numBytes)  // write numBytes starting at address
{
  EEpageErase(address);  // erase the page to clear any glitches?

  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WREN);			// enable write
  digitalWrite(EE_SS,HIGH);

  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WRITE_EE);
  for(int i=2; i>=0; i--){
    display.spi.transfer((address>>(i*8)) & 0xFF);	// send the address
  }
  for(int i=0; i<numBytes; i++){	// 256 bytes per page
    display.spi.transfer(frame[frameByteCounter]);
    frameByteCounter++;
  }
  digitalWrite(EE_SS,HIGH);

  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WRDI);	// disable write
  digitalWrite(EE_SS,HIGH);


  while((EEreadStatus()) && 0x02 > 0){
  }

}


void EEpageErase(int address)	// any address inside the page will do
{
  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WREN);			// enable write
  digitalWrite(EE_SS,HIGH);

  digitalWrite(EE_SS,LOW);
  display.spi.transfer(PE);
  for(int i=2; i>=0; i--){
    display.spi.transfer((address>>(i*8)) & 0xFF);	// send the address
  }
  digitalWrite(EE_SS,HIGH);

  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WRDI);			// disable write
  digitalWrite(EE_SS,HIGH);
  delay(50);
}


void EEchipErase()  // erase the entire chip
{
  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WREN);			// enable write
  digitalWrite(EE_SS,HIGH);

  digitalWrite(EE_SS,LOW);
  display.spi.transfer(CE);			// erase the whole thing
  digitalWrite(EE_SS,HIGH);

  digitalWrite(EE_SS,LOW);
  display.spi.transfer(WRDI);			// disable write
  digitalWrite(EE_SS,HIGH);

  delay(50);
}


//void printPage()
//{
//  for(int i=0;i<pageSize; i++){
//    Serial.print(page[i],HEX);
//    if((i+1)%32 == 0){
//      Serial.print("\n");
//    }
//    else{
//      Serial.print(",");
//    }
//  }
//  Serial.println();
//}

//void writePageBuffer()
//{
//  Serial.println("Writing index to page buffer");
//  for(int i=0;i<pageSize; i++){
//    page[i] = uint8_t(i);
//  }
//}

//void writePageBuffer(uint8_t b)  // pass the variable b to the entire page buffer
//{
//  Serial.print("Writing ");
//  Serial.print(b,HEX);
//  Serial.println(" to page buffer");
//  for(int i=0;i<pageSize; i++){
//    page[i] = b;
//  }
//}

