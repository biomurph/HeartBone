/*

Commands, acknowlegement, and data are sent between the WATCH and the PROGRAM

PROGRAM > Sends ascii numbers '1' - '9'
	WATCH > Plays numbered gif if available
				> Gifs numbered in order of loading
				> Feedback if no gif at that number

PROGRAM > Send ascii '0'
	Watch > Soft Reset
				> Stop playing gif
				> Set LCD to splash screen

PROGRAM > '='
	WATCH > Get details about EEPROM
					- Number of stored gifs
					- Address each gif starts at
					- Number of frames available
				> Print the data to PROGRAM
					- Format with START, \n, and STOP bytes [=,$]

PROGRAM > KEYPRESS = 'a' or 'A'
				> option true|false; clear byteCounter, frameNum; turn off gif;
				> Set nextFrame flag
			In draw()
				> bufferImage()
				> Send 'a' 
	WATCH > Stop playing gif
				> Set loadingFrameBuffer flag
				> Send feedback to PROGRAM; reset display with verbose
				> Send '!' to PROGRAM
PROGRAM > Set sendingFrame flag; verbosity to terminal
			In draw()
				> Send frame data byte by byte with verbosity
				> Wait to receive '*' before sending next byte of data
	WATCH > Save Frame To EEPROM
				> Set frameBufferLoaded flag
				> Writes frame to EEPROM
				> Sends '@' to PROGRAM to ask for next frame
PROGRAM > Increment frameNum with verbose
				> Set nextFrame flag[or clear if finished]
				> clearTerm (?legacy?)
			in draw()
				> SEE ABOVE LINE 27



*/




