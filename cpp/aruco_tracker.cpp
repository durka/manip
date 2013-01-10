#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <cstdio>
#include "aruco.h"
#include "cvdrawingutils.h"

using namespace std;
using namespace cv;
using namespace aruco;

/*
 * aruco_tracker.c
 *
 * Written by Alex Burka, January 2013
 * University of Pennsylvania, GRASP Lab
 */

class FlexVideoCapture
{
    public:
        bool open(int device)
        {
            in_fmt = "";
            real_video = true;
            return vc.open(device);
        }

        bool open(const string& filename)
        {
            in_fmt = "";
            if (strstr(filename.c_str(), "%d") != NULL) {
                real_video = false;
                in_fmt = filename;
                index = 1;
                return true;
            } else {
                real_video = true;
                return vc.open(filename);
            }
        }

        bool isOpened()
        {
            if (real_video) {
                return vc.isOpened();
            } else {
                return true;
            }
        }

        bool grab()
        {
            if (real_video) {
                return vc.grab();
            } else {
                char *filename;
                asprintf(&filename, in_fmt.c_str(), index++);
                frame = imread(filename);
                free(filename);
                return frame.data != NULL;
            }
        }

        bool retrieve(Mat& image)
        {
            if (real_video) {
                return vc.retrieve(image);
            } else {
                image = frame;
                return true;
            }
        }

        FlexVideoCapture& operator>>(Mat& image)
        {
            if (grab()) {
                retrieve(image);
                return *this;
            }
        }

    private:
        VideoCapture vc;
        string in_fmt;
        int index;
        Mat frame;
        bool real_video;
};

int main(int argc, char *argv[])
{
    if (argc != 6) {
        cerr << "Invalid number of arguments" << endl;
        cerr << "Usage: " << argv[0] << " (in.avi|live) out_clean_%d.jpg out_dirty_%d.jpg intrinsics.yml marker_size" << endl;
        return 1;
    }

    // open video input
    FlexVideoCapture captor;
    if (strcmp(argv[1], "live") == 0) {
        captor.open(0);
    } else {
        captor.open(argv[1]);
    }
    if (!captor.isOpened()) {
        cerr << "Failed to open video capture " << argv[1] << "!" << endl;
        return 1;
    }

    // open video outputs
    string clean_fmt = argv[2], dirty_fmt = argv[3];
    // here we trust the user to give good format strings
    // this is obviously a security vulnerability
    
    // capture first image and get dimensions
    Mat image;
    captor >> image;
    float marker_size = atof(argv[5]);

    // read camera intrinsics
    CameraParameters intrinsics;
    intrinsics.readFromXMLFile(argv[4]); // notwithstanding it's actually YAML ...?
    intrinsics.resize(image.size());

    // GUI GUI GUI GUI
    namedWindow("aruco_tracker");

    // main loop
    vector<Marker> markers;
    char key = 0; // keypress
    int index = 0; // frame count
    char *filename;
    MarkerDetector detective;
    detective.setCornerRefinementMethod(MarkerDetector::LINES);
    while (key != 27 && captor.grab()) { // capture until ESC or end of video
        // get image
        captor.retrieve(image);
        ++index;

        // write clean image
        asprintf(&filename, clean_fmt.c_str(), index);
        imwrite(filename, image);
        free(filename);

        // detect markers
        detective.detect(image, markers, intrinsics, marker_size);
        cout << "Detected " << markers.size() << " markers!" << endl;

        // draw markers
        for (int i=0; i < markers.size(); i++) {
            CvDrawingUtils::draw3dCube(image, markers[i], intrinsics);
            CvDrawingUtils::draw3dAxis(image, markers[i], intrinsics);
        }
        
        // write marked-up image
        asprintf(&filename, dirty_fmt.c_str(), index);
        imwrite(filename, image);
        free(filename);

        // show image
        imshow("aruco_tracker", image);

        key = waitKey(10);
    }

    return 0;
}

