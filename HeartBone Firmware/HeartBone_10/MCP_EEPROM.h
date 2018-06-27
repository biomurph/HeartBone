//  MCP25LC1024  

//  >> EEPROM STUFF <<
#define READ_EE	0x03	// read data from memory
#define WRITE_EE	0x02	// write data to memory
#define WREN	0x06	// set the write eneable latch (enable write)
#define WRDI	0x04	// reset write enable latch (disable write)
#define RDSR	0x05	// read status register
#define WRSR	0x01	// write status register
#define PE	0x42	// page erase (256 bytes)
#define SE	0xD8	// sector erase
#define CE	0xC7	// chip erase
#define RDID	0xAB	// release from deep power down (reads electronic signiture)
#define DPD	0xB9	// deep power down

//#define WP     6	// write protect pin 
#define EE_SS  11 // EEPROM Slave Select pin

uint8_t STATUS;     // EEPROM status reg
uint8_t SIGNATURE;  // EEPROM device signature. should be 0x29

// pin definitions
#define LCD_SS  12       // Slave Select pin for LCD 
#define DISP    8       // Display pin LOW = off, HIGH = on
// #define BLACK 0
// #define WHITE 1

#define PROG_BUTTON 17    // hold after reset to enter bootloader
#define BUTTON_0  6       // button attached  switch as needed
#define BUTTON_1  1       // button attached
#define BUTTON_2 17       // button attached
