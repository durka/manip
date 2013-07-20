#include <iostream>
#include <vector>
#include <string>
#include <queue>
#include <cstdio>
#include <ctime>
#include <signal.h>
#include <boost/thread.hpp>
#include <boost/atomic.hpp>
#include "aruco/aruco.h"
#include "aruco/cvdrawingutils.h"

#include "acquire.h"
#include "flexvideo.h"
#include "concurrent_queue.h"
#include "packet.h"

#include "watcher.h"
#include "processor.h"
#include "graphics.h"
#include "writer.h"

using namespace std;
using namespace boost;
using namespace cv;
using namespace aruco;
using namespace acquire;

/*
 * acquire.cpp
 * Acquires images from camera (or video, or sequentially named image files)
 * and locates Aruco tags.
 * Output format is defined in FORMATS.txt
 *
 * Written by Alex Burka, January 2013 (previously aruco_tracker.cpp)
 * University of Pennsylvania, GRASP Lab
 */

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

    // some queues
    QueueRaw qwp;
    QueueCooked qpg, qpw;

    // wire up the threads
    Watcher eagle(cout, cerr, qwp);
    Processor intelinside(cout, cerr, qwp, qpg, qpw);
    Graphics painter(cout, cerr, qpg);
    Writer scribe(cout, cerr, qpw);

    // setup input and output
    if (!eagle.setup(argv[1])) return 1;
    if (!intelinside.setup(argv[5], argv[6])) return 1;
    if (!painter.setup()) return 1;
    if (!scribe.setup(argv[2], argv[3], argv[4])) return 1;

    // spin up some threads!
    eagle.start();
    intelinside.start();
    painter.start();
    scribe.start();

    // catch ctrl-c
    struct sigaction sigint_handler;
    sigint_handler.sa_handler = handle_sigint;
    sigemptyset(&sigint_handler.sa_mask);
    sigint_handler.sa_flags = 0;
    sigaction(SIGINT, &sigint_handler, NULL);

    // main loop
    while (!sigint) { // capture until ESC or end of video
        waitKey(10);
        usleep(1000);
    }
    
    cout << "waiting for threads..." << endl;
    eagle.kill();
    intelinside.kill();
    painter.kill();
    scribe.kill();

    return 0;
}

