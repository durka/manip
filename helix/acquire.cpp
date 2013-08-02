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
        ("intrinsics,i",      opt::value<string>()->default_value("MacBookAir5,2"), "camera intrinsics (built-in model name)")
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

    // some queues
    QueueRaw qwp;
    QueueCooked qpg, qpw, qpf;
    QueueDigested qfg;

    // wire up the threads
    ofstream nope; // use an unopened ofstream as a null output
    Watcher eagle(nope, cerr, qwp);
    Processor intelinside(nope, cerr, qwp, qpg, qpw, qpf);
    Fitter tailor(cout, cerr, qpf, qfg);
    Graphics painter(nope, cerr, qpg, qfg);
    Writer scribe(nope, cerr, qpw);

    // read camera intrinsics
    CameraParameters intrinsics;
    string intrinsics_path = args.count("intrinsics-file")
                           ? args["intrinsics-file"].as<string>()
                           : SHARE_PREFIX + string("/") + args["intrinsics"].as<string>() + string(".yml");
    cout << "reading intrinscs from " << intrinsics_path << endl;
    intrinsics.readFromXMLFile(intrinsics_path); // notwithstanding it's actually YAML ...?
    // intrinsics.resize(image.size()); // let's see if we can get away with skipping this

    // setup input and output
    try {
        if (!eagle.setup(args["source"].as<string>())) return 1;
        if (!intelinside.setup(&intrinsics,
                               args.count("marker-size")
                                    ? args["marker-size"].as<float>()
                                    : -1)) return 1;
        if (!tailor.setup(args["markers"].as<int>())) return 1;
        if (!painter.setup(args["markers"].as<int>(), &intrinsics)) return 1;
        if (!scribe.setup(args["outdir"].as<string>(), args["outname"].as<string>())) return 1;
    } catch (std::exception& e) {
        cerr << e.what() << endl;
        return 1;
    }

    // spin up some threads!
    eagle.start();
    intelinside.start();
    tailor.start();
    painter.start();
    scribe.start();

    // catch ctrl-c
    struct sigaction sigint_handler;
    sigint_handler.sa_handler = handle_sigint;
    sigemptyset(&sigint_handler.sa_mask);
    sigint_handler.sa_flags = 0;
    sigaction(SIGINT, &sigint_handler, NULL);

    // main loop
    while (!sigint && (   eagle.is_running()
                       && intelinside.is_running()
                       && tailor.is_running()
                       && painter.is_running()
                       && scribe.is_running())) { // capture until Ctrl-c, Esc, or end of video
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
    eagle.kill();
    intelinside.kill();
    tailor.kill();
    painter.kill();
    scribe.kill();

    return 0;
}

