#include <iostream>
#include "acquire.h"
#include "flexvideo.h"
#include "aruco/cvdrawingutils.h"

#include "watcher.h"

namespace acquire
{
    using namespace std;
    using namespace cv;

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

        if (!captor.grab()) {
            return false;
        } else {
            RawPacket pkt;
            pkt.index = index++;
            pkt.time = time(NULL);
            captor.retrieve(pkt.image);
            q.push(pkt);
            usleep(33333);
            return true;
        }
    }

    void Watcher::cleanup()
    {
        // the VideoCapture is released in its destructor
    }

} // namespace acquire

