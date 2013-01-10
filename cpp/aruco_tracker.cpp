#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include "aruco.h"

using namespace std;
using namespace cv;
using namespace aruco;

/*
 * aruco_tracker.c
 *
 * Written by Alex Burka, January 2013
 * University of Pennsylvania, GRASP Lab
 */

int main(int argc, char *argv[])
{
    if (argc != 5) {
        cerr << "Invalid number of arguments" << endl;
        cerr << "Usage: " << argv[0] << " (in.avi|live) out.avi intrinsics.yml marker_size" << endl;
        return 1;
    }

    // open video input
    VideoCapture captor;
    if (strcmp(argv[1], "live") == 0) {
        captor.open(0);
    } else {
        captor.open(argv[1]);
    }
    if (!captor.isOpened()) {
        cerr << "Failed to open video capture " << argv[1] << "!" << endl;
        return 1;
    }

    // open video output
    
    // capture first image and get dimensions
    Mat image;
    captor >> image;
    float marker_size = atof(argv[4]);

    // read camera intrinsics
    CameraParameters intrinsics;
    intrinsics.readFromXMLFile(argv[3]); // notwithstanding it's actually YAML ...?
    intrinsics.resize(image.size());

    // GUI GUI GUI GUI
    namedWindow("aruco_tracker");

    // main loop
    vector<Marker> markers;
    char key = 0; // keypress
    MarkerDetector detective;
    detective.setCornerRefinementMethod(MarkerDetector::LINES);
    while (key != 27 && captor.grab()) { // capture until ESC or end of video
        // get image
        captor.retrieve(image);

        // detect markers
        detective.detect(image, markers, intrinsics, marker_size);
        cout << "Detected " << markers.size() << " markers!" << endl;

        // draw markers
        // TODO
        
        // write image
        // TODO

        // show image
        imshow("aruco_tracker", image);

        key = waitKey(10);
    }

    return 0;
}

