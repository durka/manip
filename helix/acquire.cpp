#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <queue>
#include <cstdio>
#include <ctime>
#include <signal.h>
#include <boost/thread.hpp>
#include <boost/program_options.hpp>
#include "aruco/aruco.h"
#include "aruco/cvdrawingutils.h"

#include "acquire.h"
#include "flexvideo.h"
#include "concurrent_queue.h"
#include "packet.h"

#include "watcher.h"
#include "processor.h"
#include "graphics.h"
#include "fitter.h"
#include "writer.h"
#include "kinect.h"

using namespace std;
using namespace boost;
namespace opt = boost::program_options;
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
    opt::options_description desc("Manip acquisition utility\nAllowed options");
    desc.add_options()
        ("help,h",                                                                  "print short help")
        ("source,s",          opt::value<string>()->default_value("live"),          "video source: \"live\", video file, or filename pattern")
        ("outdir,d",          opt::value<string>()->default_value("."),             "output directory")
        ("outname,o",         opt::value<string>()->default_value(""),              "output filename prefix\n\tclean images: {dir}/{name}_clean_%d.jpg\n\tdirty images: {dir}/{name}_dirty_%d.jpg\n\tdata log: {dir}/{name}.txt\n\tempty string: no output")
        ("intrinsics,i",      opt::value<string>(),                                 "camera intrinsics (built-in model name)")
        ("intrinsics-file,f", opt::value<string>(),                                 "camera intrinsics (YAML/XML file)")
        ("marker-size,m",     opt::value<float>()->default_value(10),               "marker size in arbitrary units")
        ("markers,n",         opt::value<int>(),                                    "number of markers");

    opt::variables_map args;
    try {
        opt::store(opt::parse_command_line(argc, argv, desc), args);
        opt::notify(args);

        if (argc == 1 || args.count("help")) {
            cerr << desc << endl;
            return 0;
        }
        if (args.count("intrinsics") && args.count("intrinsics-file")) {
            cerr << "You passed both a camera model name and an intrinsics file. Pick one." << endl << desc << endl;
            return 1;
        }
    } catch (std::exception& e) {
        cerr << e.what() << endl << desc << endl;
        return 1;
    }
    bool kinect = args["source"].as<string>() == "kinect";

    // some queues
    QueueRaw qwp;
    QueueParfait qkp;
    QueueCooked qpg, qpw, qpf;
    QueueDigested qfg;
    vector<QueueCooked*> qps;
    qps.push_back(&qpg); qps.push_back(&qpw); qps.push_back(&qpf);

    // wire up the threads
    ofstream nope; // use an unopened ofstream as a null output
    WorkerThread *eagle, *intelinside;
    if (kinect) {
        eagle             = new KinectWatcher(nope, cerr, qkp);
        intelinside       = new KinectProcessor(cout, cerr, qkp, qps);
    } else {
        eagle             = new Watcher(nope, cerr, qwp);
        intelinside       = new Processor(nope, cerr, qwp, qps);
    }
    WorkerThread *tailor  = new Fitter(cout, cerr, qpf, qfg);
    WorkerThread *painter = new Graphics(cout, cerr, qpg, qfg);
    WorkerThread *scribe  = new Writer(nope, cerr, qpw);

    // read camera intrinsics
    CameraParameters intrinsics;
    string intrinsics_path;
    if (args.count("intrinsics-file")) {
        intrinsics_path = args["intrinsics-file"].as<string>();
    } else {
        if (args.count("intrinsics")) {
            intrinsics_path = SHARE_PREFIX + string("/") + args["intrinsics"].as<string>() + string(".yml");
        } else {
            if (kinect) {
                //intrinsics_path = SHARE_PREFIX + string("/kinect.yml");
                intrinsics_path = SHARE_PREFIX + string("/MacBookAir5,2.yml");
            } else {
                intrinsics_path = SHARE_PREFIX + string("/MacBookAir5,2.yml");
            }
        }
    }
    cout << "reading intrinscs from " << intrinsics_path << endl;
    intrinsics.readFromXMLFile(intrinsics_path); // notwithstanding it's actually YAML ...?
    // intrinsics.resize(image.size()); // let's see if we can get away with skipping this

    // setup input and output
    try {
        if (kinect) {
            if (!((KinectWatcher*)eagle)->setup()) return 1;
            if (!((KinectProcessor*)intelinside)->setup()) return 1;
        } else {
            if (!((Watcher*)eagle)->setup(args["source"].as<string>())) return 1;
            if (!((Processor*)intelinside)->setup(&intrinsics,
                                                  args.count("marker-size")
                                                      ? args["marker-size"].as<float>()
                                                      : -1)) return 1;
        }
        if (!((Fitter*)tailor)->setup(args["markers"].as<int>())) return 1;
        if (!((Graphics*)painter)->setup(args["markers"].as<int>(), &intrinsics, args["outname"].as<string>())) return 1;
        if (!((Writer*)scribe)->setup(args["outdir"].as<string>(), args["outname"].as<string>())) return 1;
    } catch (std::exception& e) {
        cerr << e.what() << endl;
        return 1;
    }

    // spin up some threads!
    eagle->start();
    intelinside->start();
    tailor->start();
    painter->start();
    scribe->start();

    // catch ctrl-c
    struct sigaction sigint_handler;
    sigint_handler.sa_handler = handle_sigint;
    sigemptyset(&sigint_handler.sa_mask);
    sigint_handler.sa_flags = 0;
    sigaction(SIGINT, &sigint_handler, NULL);

    // main loop
    while (!sigint && (   eagle->is_running()
                       && intelinside->is_running()
                       && tailor->is_running()
                       && painter->is_running()
                       && scribe->is_running())) { // capture until Ctrl-c, Esc, or end of video
        switch (waitKey(10))
        {
            case 27: // ESC
                sigint = true;
                break;
            case 'c':
                cout << "it never happened." << endl;
                qpg.signal(Graphics::CLEAR); // kick the graphics thread to clear the marker trails
                qpf.signal(Fitter::CLEAR); // kick the fitter thread to throw out its history
                break;
            case 'f':
                cout << "fit should start soon..." << endl;
                qpf.signal(Fitter::FIT); // kick the fitter thread to start a fit
                break;
            case 's':
                cout << "writing fits to file!" << endl;
                qpg.signal(Graphics::SAVE);
                break;
            case 'l':
                cout << "loading fits from file!" << endl;
                qpg.signal(Graphics::LOAD);
                break;
            default:
                break;
        }
    }
    
    cout << "waiting for threads..." << endl;
    eagle->kill();
    intelinside->kill();
    tailor->kill();
    painter->kill();
    scribe->kill();

    // the Kinect thread takes a really long time to exit
    // this is the nuclear option
    cout << "goodbye cruel world" << endl;
    raise(SIGQUIT);

    delete eagle;
    delete intelinside;
    delete tailor;
    delete painter;
    delete scribe;

    return 0;
}

