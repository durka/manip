#include <iostream>
#include <boost/chrono.hpp>
#include "acquire.h"
#include "flexvideo.h"
#include "aruco/cvdrawingutils.h"

#include "watcher.h"

namespace acquire
{
    using namespace std;
    using namespace cv;
    using namespace boost::chrono;

    bool Watcher::setup(string path)
    {
        // open video input
        if (path == "live") {
            captor.open(0);
        } else {
            captor.open(path);
        }
        if (!captor.isOpened()) {
            err << "Failed to open video capture " << path << "!" << endl;
            return false;
        }

        return true;
    }

    bool Watcher::loop(bool lameduck)
    {
        static int index = 0;

        if (lameduck) return false;

        steady_clock::time_point start = steady_clock::now();

        if (!captor.grab()) {
            return false;
        } else {
            RawPacket pkt;
            pkt.index = index++;
            pkt.time = time(NULL);
            captor.retrieve(pkt.image);
            resize(pkt.image, pkt.image, Size(0, 0), 0.5, 0.5);
            q.push(pkt);
            boost::this_thread::sleep_until(start + milliseconds(50));
            return true;
        }
    }

    void Watcher::cleanup()
    {
        // the VideoCapture is released in its destructor
    }

} // namespace acquire

