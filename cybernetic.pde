import java.util.*; //<>//
import java.awt.Rectangle;
import org.openkinect.processing.*; //<>// //<>// //<>// //<>// //<>//
import gab.opencv.*;
import org.openkinect.freenect.*;
import org.openkinect.freenect2.*;

// depends on projector's resolution
int pWidth = 960;
int pHeight = 540; 

//kinect related
String calibFile ="/Users/joshuarain/Documents/Processing/libraries/KinectProjectorToolkit/examples/CALIBRATION/data/calibration.txt";
Kinect2 kinect2;
OpenCV opencv;
PVector [] depthMap;
int projectorSize;
PImage stream;
PImage registered;
float[] projectorMatrix;
ArrayList<Contour> contours;
ArrayList<PVector> center;
int contourSize = 30;

//vector field related
Vector[][] vectors;
Vector[][] vectorRef;
ArrayList<PVector> vecChange = new ArrayList<PVector>();
Actor[] a;
int numPoints = pWidth * pHeight/30;
int speed = 1;
float vecImpact = 0.01;
int ageCounter = 0;
int defaultAge = 200;
float contourT = 0.0001;
float sigma=0.95;

void setup() {
  size(800, 800);
  surface.setSize(pWidth, pHeight);
  strokeWeight(0.1);
  stroke(255);
  noiseSeed(int(random(0, 1000)));
  noiseDetail(3);    
  vectors = new Vector[pWidth][pHeight];
  vectorRef = new Vector[pWidth][pHeight];
  for (int i = 0; i < pWidth; i++) {
    for (int j = 0; j < pHeight; j++) {
      vectors[i][j] = new Vector(i, j);
      vectorRef[i][j] = new Vector(i,j);
    }
  }
  int numPts1D = floor(sqrt(numPoints));
  a = new Actor[numPoints];
  for (int i = 0; i < numPoints; i++) {
    float x = (i % numPts1D) * (pWidth/numPts1D);
    float y = (int(i / numPts1D)) * (pHeight/numPts1D);
    a[i] = new Actor(vectors, x, y);
  }
  //arrayCopy(vectors,vectors_backup);
  //background(255);

  //kinect setting
  kinect2 = new Kinect2(this);
  kinect2.initDepth(); 
  //kinect2.initVideo();
  kinect2.initRegistered();
  //kinect2.initIR();
  kinect2.initDevice();
  projectorSize = kinect2.depthWidth*kinect2.depthHeight;
  depthMap = new PVector[projectorSize];
  opencv = new OpenCV(this, kinect2.depthWidth, kinect2.depthHeight);
  loadCalibration(calibFile);
  center = new ArrayList<PVector>();
}

void draw() {

  background(255);
  //get image from Kinect
  depthMap = depthMapRealWorld();
  stream = kinect2.getDepthImage();
  registered = kinect2.getRegisteredImage();
  
  //mirror();

  opencv.loadImage(stream);
  opencv.erode();
  opencv.gray();
  //opencv.threshold(50);
  //image(opencv.getOutput(),800,0);
  //image(stream,0,0);


  //opticalflow();
  contour();

  //mouseUpdate();
  //comment out to see vector lines
  //for (int i = 0; i < pWidth; i+= 20) {
  //  for (int j = 0; j < pHeight; j+=20) {
  //    strokeWeight(1);
  //    stroke(0);
  //    line(i,j,(i+vectors[i][j].x*10),(j+vectors[i][j].y*10));
  //  }
  //}
  
  // update the points
  ageCounter++;
  for (int i = 0; i < numPoints; i++) {
    a[i].update();
  }
  if (ageCounter % 40 == 0) {
    resetVec();
  }
  //println("xpos: "+a[1000].xpos+"; ypos: "+ a[1000].ypos);
  //println("v.x: "+vectors[30][30].x+"; v.y: "+ vectors[30][30].y);
}

void keyPressed() {
  if (key == ' ') {
    noiseSeed(int(random(0,1000)));
    for (int i = 0; i < pWidth; i++) {
      for (int j = 0; j < pHeight; j++) {
        vectors[i][j].x = (noise((i/100)+pWidth,(j/100)+pHeight)-0.5)*speed;
        vectors[i][j].y = (noise((i/100),(j/100))-0.5)*speed;
      }
    }
  }
}

void mouseUpdate() {
  int kernalSize = 20;
  int mX = mouseX;
  int mY = mouseY;
  for (int i = -kernalSize; i <= kernalSize; i++) {
    for (int j = -kernalSize; j <= kernalSize; j++) {
      if (mX+i >= 0 && mX+i < pWidth && mY+j >= 0 && mY+j < pHeight) {
       vectors[mX+i][mY+j].x = (-i/kernalSize);
       vectors[mX+i][mY+j].y = (-j/kernalSize);
       vecChange.add(new PVector(mX+i,mY+j));
      }
    }
  }
}
