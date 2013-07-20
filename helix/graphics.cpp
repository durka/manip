#include <iostream>
#include "acquire.h"
#include "flexvideo.h"
#include "aruco/cvdrawingutils.h"

#include "graphics.h"

namespace acquire
{
    using namespace std;
    using namespace cv;

    bool Graphics::setup()
    {
        namedWindow(prefix);

        return true;
    }

    bool Graphics::loop(bool lameduck)
    {

        if (lameduck) return false;

        CookedPacket pkt;
        q.wait_and_pop(pkt);

        // TODO
        // - scale down and show both images
        // - support "scroll lock"

        static double ticks = getTickCount(), fps = 0;
        if (pkt.index % 10 == 0) {
            fps = 10.0 / ( ((double)getTickCount() - ticks) / (double)getTickFrequency() );
            ticks = getTickCount();
        }

        ostringstream fps_str;
        fps_str << "FPS: " << fps;
        putText(pkt.dirty, fps_str.str(), cvPoint(50, 50), FONT_HERSHEY_PLAIN, 1, cvScalar(255,0,0));
        
        imshow(prefix, pkt.dirty);
        waitKey(10);

        return true;
    }

    void Graphics::cleanup()
    {
        // nothing to do
    }

} // namespace acquire

