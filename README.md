#READ ME

So, you found a Heart Bone...

The enclosed softawre connects with your Hear Bone via USB cable, and allows you to control the Heart Bone's functional capability. This document covers the installation of necessary software, and how to connect to and control the Heart Bone. Let's get started!

## Install Software

### FTDI Driver 

You need a Future Technology Devices (FTDI) driver on your computer if you don't already have one. This tool allows your computer to talk to the Heart Bone through a Virtual COM Port (VCP). Use [this](http://www.ftdichip.com/Drivers/VCP.htm) link the find the correct driver for your operating system, and install it now. It will take n minutes.


### Processing

Processing is a popular creative coding platform. The software that controls your Heart Bone runs a a Sketch in Processing. If you don't already have Processing on your computer, download it [here](https://processing.org/download/). It should take n minutes to download and install Processing.

### Heart Bone Software

The enclosed folder called HeartBone contains a Processing sketch and the current release of gifs engineered to run on the Heart Bone platform. Move the folder and it's entire contents to the location

		User/Documents/Processing

If the Processing folder has not been made yet, go ahead and make it.

##Connect To Your Heart Bone

There are 4 buttons on your Heart Bone, Refer to this image to find the locations of the buttons.

![ScreenShot](images/ScreenShot.jpg)

Start the Processing application, and open the Heart Bone program by clicking on 

		File->Sketchbook->HeartBone
		
It will open a window that looks like this

![image](images/HB-Open.png)

Plug your Heart Bone into the USB cable. If you see a red LED light up, you know the battery is being charged. 
**Make Sure The Heart Bone Is Awake** by pressing the wake button
Then, launch the program by pressing the play button in Processing

![playbutton](images/playButton.png)

###Connect to the right Serial Port!

This is where things get tedious, but it's a simple process. When you play the sketch in processing, one of the first things it does is to try to connect to the Heart Bone, if it can't connect, you will get an error that looks like this

![image](images/serialPortError.png)

If this happens, take a look at the white on black text at the bottom of the window. There is a list of all available ports on your computer. The Heart Bone is among them. Look for the port calle 

	/dev/tty.usbmodemXXXX
	
That is the port you want to connect to. Count the ports available starting from 0, and put that number in the highlighted code as shown below

![image](images/portNumber.png)

Even if the program starts up, if you may find your Heart Bone unresponsive, this is a good place to start debugging.













 