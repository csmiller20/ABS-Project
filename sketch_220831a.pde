import processing.video.*;

String textRecieved;
String serial;
Capture video;
PImage prev;

float threshold = 250;
float colorThresh = 220;

float motionX = 0;
float motionY = 0;

float prevX = 0;
float prevY = 0;

float lerpX = 0;
float lerpY = 0;
color trackColor;

int total = 0;
String inString;

int throwCount = 0;
int strikeCount = 0;
boolean throwing = false;
boolean striking = false;
boolean lastPitchStrike = false;
boolean waitTrigger = false;
int motionDuration = 0;
int waitTime = 0;
PFont f;

void setup() {
   size(1280, 720);
   f = createFont("Arial",40,true);
  //printArray(Serial.list());
  //port = new Serial(this, Serial.list()[0], 9600);
  delay(2000);
  String[] cameras = Capture.list();
  printArray(cameras);
  video = new Capture(this, 1280, 720, cameras[0], 30);
  video.start();
  prev = createImage(1280, 720, RGB);
  // Start off tracking for red
  trackColor = color(255);
}

void mousePressed() {
  throwCount = 0;
  strikeCount = 0;
}

void captureEvent(Capture video) {
  
  prev.copy(video, 0, 0, video.width, video.height, 0, 0, prev.width, prev.height);
  prev.updatePixels();
  video.read();
}

void draw() {
  
  video.loadPixels();
  prev.loadPixels();
  image(video, 0, 0);
  
  //threshold = map(mouseX, 0, width, 0, 100);
  //threshold = 0;


  int count = 0;
  
  float avgX = 0;
  float avgY = 0;

  loadPixels();
  // Begin loop to walk through every pixel
  for(int x = 0; x < video.width; x++){
    for (int y = 0; y < video.height; y++ ) {
      if(x < 250 || x > 1030){
        int loc = x + y * video.width;
        pixels[loc] = color(0);
      }
    }
  }
  for (int x = 250; x < video.width-250; x++ ) {
    for (int y = 0; y < video.height; y++ ) {
      int loc = x + y * video.width;
      // What is current color
      if(waitTrigger && waitTime < 400){
        waitTime++;
        continue;
      }
      if(waitTime == 400){
        waitTrigger = false;
        waitTime = 0;
      }
      color currentColor = video.pixels[loc];
      float r1 = red(currentColor);
      float g1 = green(currentColor);
      float b1 = blue(currentColor);
      color prevColor = prev.pixels[loc];
      float r2 = red(prevColor);
      float g2 = green(prevColor);
      float b2 = blue(prevColor);

      float d = distSq(r1, g1, b1, r2, g2, b2); 
      
      
      if (d > threshold*threshold && r1 > colorThresh && g1 > colorThresh && b1 > colorThresh) {
        
        avgX += x;
        avgY += y;
        count++;
        pixels[loc] = color(0, 255, 0);
        
        
      } else {
        //pixels[loc] = color(0);
      }
    }
  }
  updatePixels();
  

  // We only consider the color found if its color distance is less than 10. 
  // This threshold of 10 is arbitrary and you can adjust this number depending on how accurate you require the tracking to be.
  if (count > 0) { 
    motionX = avgX / count;
    motionY = avgY / count;
    // Draw a circle at the tracked pixel
  }
  
  lerpX = lerp(lerpX, motionX, 0.1); 
  lerpY = lerp(lerpY, motionY, 0.1); 
  
  noFill();
  strokeWeight(2.0);
  
  rect(250, 0, 780, 720);
  stroke(255, 255, 0);
  rect(565, 360, 150, 220.5);
  
  fill(255);
  textFont(f, 40);
  text(throwCount + " Throws", 10, 30);
  text(strikeCount + " Strikes", 10, 90);
  text(throwCount - strikeCount + " Balls", 10, 150);
  
  float motion = distSqXY(lerpX, lerpY, prevX, prevY);
  
  //System.out.println(waitTime);
  
  
  
  if(!throwing){
    fill(255, 0, 0);
    stroke(255, 0, 0);
    ellipse(lerpX, lerpY, 28, 28);
    if(715 > lerpX && lerpX > 565 && 580.5 > lerpY && lerpY > 360){
      fill(0, 255, 0);
      stroke(0, 255, 0);
      ellipse(lerpX, lerpY, 28, 28);
      striking = true;
    }
    else{
     striking = false; 
    }
  }
  else{
    noFill();
    stroke(255, 0, 255);
    ellipse(lerpX, lerpY, 28, 28);
  }
  System.out.println(motionDuration);
  if(motionDuration == 10){
    waitTrigger = true;
    motionDuration = 0;
  }
  
  if(throwing && motion < 2){
    throwCount++;
    throwing = false;
    motionDuration = 0;
    waitTrigger = true;
    //delay(1000);
  }
  if(motion > 10){
    throwing = true;
    lastPitchStrike = false;
    motionDuration++;
     
  }
  if(striking && motion < 2 && !lastPitchStrike){
    lastPitchStrike = true;
    strikeCount++;
  }
  
  if(!striking && lastPitchStrike && motion < 2){
    lastPitchStrike = false;
    strikeCount--;
  }
  
  prevX = lerpX;
  prevY = lerpY;
}

float distSqXY(float x1, float y1, float x2, float y2){
  float d = (x2-x1)*(x2-x1)+(y2-y1)*(y2-y1);
  return d;
}
float distSq(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) +(z2-z1)*(z2-z1);
  return d;
}
