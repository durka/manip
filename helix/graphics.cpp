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

        imshow(prefix, pkt.dirty);
        waitKey(10);

        return true;
    }

    void Graphics::cleanup()
    {
        // nothing to do
    }

} // namespace acquire

