#include <iostream>
#include <boost/chrono.hpp>

#include "slic.h"

#include "kinect.h"

namespace acquire
{

    using namespace std;
    using namespace cv;
    using namespace boost::chrono;
    using namespace kinect;

    bool KinectWatcher::setup()
    {
        // TODO document the change to libfreenect.hpp to make this compile: https://github.com/OpenKinect/libfreenect/issues/339
        device = &freenect.createDevice<AcquireFreenectDevice>(0);
        device->startVideo();
        device->startDepth();
        return true; // if the kinect doesn't open, libfreenect writes to stderr and kills the process
    }

    bool KinectWatcher::loop(bool lameduck)
    {
        static int index = 0;

        if (lameduck) return false;

        steady_clock::time_point start = steady_clock::now();

        ParfaitPacket pkt;
        device->getVideo(pkt.rgb);
        device->getDepth(pkt.depth);
        pkt.index = index++;
        pkt.time = time(NULL);
        q.push(pkt);
        boost::this_thread::sleep_until(start + milliseconds(100));
        return true; // if the kinect is unplugged, the program crashes with an uncaught exception
    }

    void KinectWatcher::cleanup()
    {
        if (device) {
            device->stopVideo();
            device->stopDepth();
            freenect.deleteDevice(0);
        }
    }


    bool KinectProcessor::setup()
    {
        // nothing to do? FIXME do we need intrinsics?
        return true;
    }

    bool KinectProcessor::loop(bool lameduck) // TODO this is mostly copied from Processor::loop. perhaps they should be merged
    {
        static BFMatcher matchmaker;
        static BRISK private_eye;
        static vector<KeyPoint> newkeys, goodkeys;
        static Mat olddescrs, newdescrs;
        static vector<DMatch> matches, good_matches;
        static Slic slic;

        ParfaitPacket parfait;
        CookedPacket cooked;

        if (qi.empty() && lameduck) return false;

        qi.wait_and_pop(parfait);
        tout() << "processing packet #" << parfait.index << "!" << endl;

        cooked.index = parfait.index;
        cooked.time = time(NULL);
        cooked.clean = parfait.rgb.clone();
        //cvtColor(parfait.depth, depth, CV_GRAY2RGB);

        // detect "markers"
        Mat bw(parfait.rgb.size(), CV_8UC1), mask = Mat::ones(parfait.rgb.size(), CV_8UC1);
        cvtColor(parfait.rgb, bw, CV_RGB2GRAY);
        private_eye(bw, mask, newkeys, newdescrs);

        // superpixels
        double min, max;
        minMaxLoc(parfait.depth, &min, &max);
        printf("depth min=%g, max=%g\n", min, max);
        Mat depth = (parfait.depth-500)/(2047.0-500)*255.0;
        minMaxLoc(depth, &min, &max);
        printf("depth min=%g, max=%g\n", min, max);
        IplImage img(parfait.rgb), depthimg(depth);
        slic.generate_superpixels(&img, sqrt((parfait.rgb.cols * parfait.rgb.rows) / 200.0), 40);
        slic.create_connectivity(&img);
        slic.colour_with_cluster_means(&img, &depthimg);
        slic.display_contours(&img, CV_RGB(255, 0, 0));

        // prepare display
        if (cooked.index > 1) {
            matchmaker.match(olddescrs, newdescrs, matches);
            double min_dist = 1.0/0.0;
            if (cooked.index % 5) {
                good_matches.clear();
                goodkeys.clear();
            }
            for (vector<DMatch>::iterator i = matches.begin(); i != matches.end(); ++i) {
                // keep the good matches as markers
                if (i->distance < 50) {
                    good_matches.push_back(*i);
                    goodkeys.push_back(newkeys[i->trainIdx]);
                }
            }
            //drawKeypoints(parfait.rgb, newkeys, parfait.rgb);

            cooked.dirty = parfait.rgb.clone();
            for (vector<QueueCooked*>::iterator qo = qos.begin(); qo != qos.end(); ++qo) {
                (*qo)->push(cooked);
            }
        }
        olddescrs = newdescrs;

        return true;
    }

    void KinectProcessor::cleanup()
    {
        // nothing to do
    }

}

