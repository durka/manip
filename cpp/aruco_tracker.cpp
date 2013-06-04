#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <queue>
#include <cstdio>
#include <ctime>
#include <signal.h>
#include <boost/thread.hpp>
#include "aruco.h"
#include "cvdrawingutils.h"

using namespace std;
using namespace boost;
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
            }
            return *this;
        }

    private:
        VideoCapture vc;
        string in_fmt;
        int index;
        Mat frame;
        bool real_video;
};

class Packet
{
    public:
        int index;
        time_t time;
        Mat clean, dirty;
        vector<Marker> markers;

        Packet() {}
        Packet(const Packet& rhs) // deep copy the matrices
        {
            index = rhs.index;
            time = rhs.time;
            clean = rhs.clean.clone();
            dirty = rhs.dirty.clone();
            markers = rhs.markers;
        }
};

// http://www.justsoftwaresolutions.co.uk/threading/implementing-a-thread-safe-queue-using-condition-variables.html
template<typename Data>
class concurrent_queue
{
    public:
        void push(Data const& data)
        {
            mutex::scoped_lock lock(the_mutex);
            the_queue.push(data);
            lock.unlock();
            the_condition_variable.notify_one();
        }

        bool empty() const
        {
            mutex::scoped_lock lock(the_mutex);
            return the_queue.empty();
        }

        bool try_pop(Data& popped_value)
        {
            mutex::scoped_lock lock(the_mutex);
            if(the_queue.empty())
            {
                return false;
            }

            popped_value=the_queue.front();
            the_queue.pop();
            return true;
        }

        void wait_and_pop(Data& popped_value)
        {
            mutex::scoped_lock lock(the_mutex);
            while(the_queue.empty())
            {
                the_condition_variable.wait(lock);
            }

            popped_value=the_queue.front();
            the_queue.pop();
        }

    private:
        queue<Data> the_queue;
        mutable mutex the_mutex;
        condition_variable the_condition_variable;
};

void writer_thread(concurrent_queue<Packet>* Q, string clean_fmt, string dirty_fmt, string out)
{
    char *filename;

    // open video outputs
    if (clean_fmt.find("%d") == string::npos) {
        clean_fmt = "";
    } else {
        cout << "Writing clean images to " << clean_fmt << endl;
    }
    if (dirty_fmt.find("%d") == string::npos) {
        dirty_fmt = "";
    } else {
        cout << "Writing dirty images to " << dirty_fmt << endl;
    }
    // here we trust the user to give good format strings
    // this is obviously a security vulnerability

    // open text output
    ofstream data;
    if (out.length() > 0) {
        data.open(out.c_str());
        if (!data.is_open()) {
            cerr << "Failed to open text output " << out << "!" << endl;
            return;
        } else {
            cout << "Writing data to " << out << endl;
        }
    }

    bool keep_going_if_empty = true;
    Packet pkt;
    while (true) {
        // take an image out of the queue and write it
        try {
            this_thread::interruption_point();

            if (Q->empty() && !keep_going_if_empty) break;

            Q->wait_and_pop(pkt);
            cout << "writing packet #" << pkt.index << "!" << endl;

            // write clean image
            if (clean_fmt.length() > 0) {
                asprintf(&filename, clean_fmt.c_str(), pkt.index);
                imwrite(filename, pkt.clean);
                free(filename);
            }
            // write marked-up image
            if (dirty_fmt.length() > 0) {
                asprintf(&filename, dirty_fmt.c_str(), pkt.index);
                imwrite(filename, pkt.dirty);
                free(filename);
            }
            // draw markers and write data
            if (data.is_open()) {
                data << pkt.index << " " << pkt.time << ": ";
                for (vector<Marker>::iterator i = pkt.markers.begin(); i != pkt.markers.end(); ++i) {
                    data << i->id << " ";
                    for (int j = 0; j < 3; ++j) {
                        data << i->Tvec.ptr<float>(0)[j] << " ";
                    }
                    for (int j = 0; j < 3; ++j) {
                        data << i->Rvec.ptr<float>(0)[j] << " ";
                    }
                    data << " | ";
                }
                data << endl;
            }
        } catch (thread_interrupted const&) {
            cout << "[scribe] acknowledged interruption, emptying queue" << endl;
            keep_going_if_empty = false;
        }
    }
    if (data.is_open()) data.close();
}

bool sigint = false;
void handle_sigint(int s)
{
    cout << "caught SIGINT" << endl;
    sigint = true;
}

int main(int argc, char *argv[])
{
    if (argc != 7) {
        cerr << "Invalid number of arguments" << endl;
        cerr << "Usage: " << argv[0] << " (in.avi|live) out_clean_%d.jpg out_dirty_%d.jpg out.txt intrinsics.yml marker_size" << endl;
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
        return 2;
    }

    // launch writer thread
    concurrent_queue<Packet> Q;
    thread scribe(writer_thread, &Q, argv[2], argv[3], argv[4]);

    // capture first image and get dimensions
    Mat image;
    captor >> image;
    float marker_size = -1;
    if (strlen(argv[6]) > 0) {
        marker_size = atof(argv[6]);
    }

    // read camera intrinsics
    CameraParameters intrinsics;
    intrinsics.readFromXMLFile(argv[5]); // notwithstanding it's actually YAML ...?
    intrinsics.resize(image.size());

    // GUI GUI GUI GUI
    namedWindow("aruco_tracker");

    // catch ctrl-c
    struct sigaction sigint_handler;
    sigint_handler.sa_handler = handle_sigint;
    sigemptyset(&sigint_handler.sa_mask);
    sigint_handler.sa_flags = 0;
    sigaction(SIGINT, &sigint_handler, NULL);

    // main loop
    Packet pkt;
    vector<Marker> markers;
    char key = 0; // keypress
    int index = 0; // frame count
    MarkerDetector detective;
    detective.setCornerRefinementMethod(MarkerDetector::SUBPIX);
    detective.setThresholdParams(7, 7);
    double ticks = getTickCount(), fps = 0;
    while (!sigint && key != 27 && captor.grab()) { // capture until ESC or end of video
        // get image
        captor.retrieve(image);
        ++index;
        pkt.index = index;
        pkt.time = time(NULL);
        pkt.clean = image.clone();

        if (index % 5 == 0) {
            fps = 5.0 / (((double)getTickCount() - ticks)/(double)getTickFrequency());
            ticks = getTickCount();
        }

        if (marker_size != -1) {
            // detect markers
            detective.detect(image, markers, intrinsics, marker_size);
            //cvtColor(detective.getThresholdedImage(), image, CV_GRAY2RGB);
            cout << "Detected " << markers.size() << " markers!" << endl;
            pkt.markers = markers;

            // draw markers and write data
            for (vector<Marker>::iterator i = markers.begin(); i != markers.end(); ++i) {
                CvDrawingUtils::draw3dCube(image, *i, intrinsics);
                CvDrawingUtils::draw3dAxis(image, *i, intrinsics);
            }
        }
        
        // show image
        ostringstream fps_str;
        fps_str << "FPS: " << fps;
        putText(image, fps_str.str(), cvPoint(50, 50), FONT_HERSHEY_PLAIN, 1, cvScalar(255,0,0));
        pkt.dirty = image.clone();
        imshow("aruco_tracker", image);
        cout << "posting packet #" << pkt.index << "..." << endl;
        Q.push(pkt);

        key = waitKey(10);
    }
    
    cout << "waiting for scribe thread..." << endl;
    scribe.interrupt();
    scribe.join();

    return 0;
}

