#include <iostream>
#include "acquire.h"
#include "flexvideo.h"
#include "aruco/cvdrawingutils.h"

#include "graphics.h"

namespace acquire
{
    using namespace std;
    using namespace cv;
    using namespace aruco;

    bool Graphics::setup()
    {
        namedWindow(prefix);

        return true;
    }

    bool Graphics::loop(bool lameduck)
    {

        if (lameduck) return false;

        CookedPacket pkt;
        q1.wait_and_pop(pkt);

        // TODO
        // - support "scroll lock"

        static Mat history = Mat::zeros(pkt.dirty.rows, pkt.dirty.cols, pkt.dirty.type());

        for (vector<Marker>::iterator i = pkt.markers.begin(); i != pkt.markers.end(); ++i) {
            circle(history, i->getCenter(), 3, CV_RGB(0,0,255), -1);
        }

        static double ticks = getTickCount(), fps = 0;
        if (pkt.index % 10 == 0) {
            fps = 10.0 / ( ((double)getTickCount() - ticks) / (double)getTickFrequency() );
            ticks = getTickCount();
        }

        Mat image(pkt.dirty.rows/2, pkt.dirty.cols, pkt.dirty.type());
        resize(pkt.clean, Mat(image, Rect(0, 0, pkt.dirty.cols/2, pkt.dirty.rows/2)), Size(), 0.5, 0.5, CV_INTER_AREA);
        resize(pkt.dirty + history, Mat(image, Rect(pkt.dirty.cols/2, 0, pkt.dirty.cols/2, pkt.dirty.rows/2)), Size(), 0.5, 0.5, CV_INTER_AREA);

        ostringstream fps_str;
        fps_str << "FPS: " << fps;
        putText(image, fps_str.str(), cvPoint(50, 50), FONT_HERSHEY_PLAIN, 1, cvScalar(255,0,0));
        
        imshow(prefix, image);
        return true; // waitKey has to be called on the main thread
    }

    void Graphics::cleanup()
    {
        // nothing to do
    }

} // namespace acquire

