/*
 * A simple implementation of marching cube algorithm in Processing.
 * This program is based on the code written by Written by Paul Bourke.
 * [original URL: http://paulbourke.net/geometry/polygonise/]
 *
 * The scalar field is [0,1]*[0,1]*[0,1] space divided into N*N*N grid
 */

import java.util.*;

// rendering with normal interpolation
boolean norm_interpolation = true;

// grid division
int N = 80; 

// isosurface threshold
float threshold = 0.5;

// scalar field to be visualized
float[][][] field = new float[N][N][N];

// normal vectors at each grid point
PVector[][][] normals = new PVector[N][N][N];

int triangle_count;

void setup() {
  size(800, 800, P3D);
  frameRate(30);

  for (int i=0; i<N; i++) {
    for (int j=0; j<N; j++) {
      for (int k=0; k<N; k++) {
        field[i][j][k] = 0;
      }
    }
  }

}

// example of dynamic field
void computeField() {
  float omega = TWO_PI * 0.5;
  float[] px = {0.5, 0.5, 0.5, 0.5, 0.5, 0.5};
  float[] py = {0.5, 0.5, 0.5, 0.5, 0.5, 0.5};
  float[] pz = {0.5, 0.5, 0.5, 0.5, 0.5, 0.5};
  px[0] = 0.5 + 0.25 * cos(millis() / 1000.0 * omega);
  px[1] = 0.5 - 0.25 * cos(millis() / 1000.0 * omega + PI/6);
  py[2] = 0.5 + 0.25 * cos(millis() / 1000.0 * omega + 2*PI/6);
  py[3] = 0.5 - 0.25 * cos(millis() / 1000.0 * omega + 3*PI/6);
  pz[4] = 0.5 + 0.25 * cos(millis() / 1000.0 * omega + 4*PI/6);
  pz[5] = 0.5 - 0.25 * cos(millis() / 1000.0 * omega + 5*PI/6);
  
  for (int i=0; i<N; i++) {
    for (int j=0; j<N; j++) {
      for (int k=0; k<N; k++) {
        float x = 1.0 / N * i;
        float y = 1.0 / N * j;
        float z = 1.0 / N * k;
        field[i][j][k] = 0;
        for (int l=0; l<px.length; l++) {
          float r = sqrt(sq(x-px[l]) + sq(y-py[l]) + sq(z-pz[l]));
          field[i][j][k] += 0.015/r;
        }
      }
    }
  }
}

// calculates gradient of scalar field for normal interpolation
void computeNormals() {
  for (int i=0; i<N; i++) {
    for (int j=0; j<N; j++) {
      for (int k=0; k<N; k++) {
        float h = 1.0 / (N-1);
        float dudx = 0, dudy = 0, dudz = 0;
        if (i == 0) dudx = (field[i+1][j][k] - field[i][j][k]) / h;
        else if (i == N-1) dudx = (field[i][j][k] - field[i-1][j][k]) / h;
        else dudx = (field[i+1][j][k] - field[i-1][j][k]) / (2*h);
        if (j == 0) dudy = (field[i][j+1][k] - field[i][j][k]) / h;
        else if (j == N-1) dudy = (field[i][j][k] - field[i][j-1][k]) / h;
        else dudy = (field[i][j+1][k] - field[i][j-1][k]) / (2*h);
        if (k == 0) dudz = (field[i][j][k+1] - field[i][j][k]) / h;
        else if (k == N-1) dudz = (field[i][j][k] - field[i][j][k-1]) / h;
        else dudz = (field[i][j][k+1] - field[i][j][k-1]) / (2*h);
        normals[i][j][k] = new PVector(-dudx, -dudy, -dudz);
        normals[i][j][k].normalize();
      }
    }
  }
}

void draw() {
  computeField(); 
  computeNormals();
  
  long ta = millis();
  background(255);

  // camera setup
  float fov = PI/3.0;
  perspective(fov, float(width)/float(height), 
    0.1, 1000);

  float cam_r = N*1.5;
  float cam_theta = PI/4;
  float cam_phi = TWO_PI / 1000 * frameCount ;
  camera(cam_r * sin(cam_theta) * cos(cam_phi),
         cam_r * sin(cam_theta) * sin(cam_phi),
         cam_r * cos(cam_theta),
         0, 0, 0,
         0, 0, -1);

  directionalLight(161, 161, 161, -0.2, 0.3, -0.5);

  // x-y-z axes
  stroke(255, 0, 0);
  line(0, 0, 0, 100, 0, 0);
  stroke(0, 255, 0);
  line(0, 0, 0, 0, 100, 0);
  stroke(0, 0, 255);
  line(0, 0, 0, 0, 0, 100);
  
  translate(-0.5*N, -0.5*N, -0.5*N);

  // field visualization
  /*
  noStroke();
  fill(255, 255, 255, 10);
  for (int i=0; i<N; i++) {
    for (int j=0; j<N; j++) {
      for (int k=0; k<N; k++) {
        pushMatrix();
        translate(i, j, k);
        box(field[i][j][k]);
        popMatrix();
      }
    }
  }
//  */

  // marching-cube
  stroke(0,0,0);
  strokeWeight(0.5);
  noStroke();
  fill(191,255,255);
  beginShape(TRIANGLES);
  triangle_count = 0;
  ArrayList<Triangle> tri_buf = new ArrayList<Triangle>();
  for (int i=0; i<N-1; i++) {
    for (int j=0; j<N-1; j++) {
      for (int k=0; k<N-1; k++) {
        Triangle[] tris = Polygonise(i, j, k);
        tri_buf.addAll(Arrays.asList(tris));
        for (Triangle tri : tris) {
          for (int l=0; l<3; l++) {
            if (norm_interpolation) {
              normal(tri.ns[l].x, tri.ns[l].y, tri.ns[l].z);
            }
            vertex(tri.ps[l].x, tri.ps[l].y, tri.ps[l].z);
          }
        }
      }
    }
  }
  endShape();

  // collapsed time
  long tb = millis();
  if (frameCount % 100 == 0) {
    println("computation time: ", tb - ta);
    println("triangles: " + triangle_count);
  }
}