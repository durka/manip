#include <iostream>
#include <boost/chrono.hpp>

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
        boost::this_thread::sleep_until(start + milliseconds(1000));
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
        static SURF private_eye;
        static vector<KeyPoint> newkeys, goodkeys;
        static vector<vector<int> > objects;
        static Mat olddescrs, newdescrs;
        static vector<DMatch> matches, good_matches;

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
        //cvtColor(parfait.rgb, bw, CV_RGB2GRAY);
        newkeys.clear();
        private_eye(parfait.rgb, mask, newkeys, newdescrs);

        /*Point arects[4][4] = { { Point(231,  12), Point(245,   7), Point(263,  48), Point(248,  57) },
                               { Point(294, 139), Point(351, 108), Point(355, 119), Point(299, 155) },
                               { Point(337, 166), Point(352, 167), Point(345, 246), Point(330, 246) },
                               { Point(230, 347), Point(333, 344), Point(333, 387), Point(233, 380) } };*/
        vector<vector<Point> > rects(4);
        rects[0] = vector<Point>(6);
        rects[0][0] = Point(128, 120);
        rects[0][1] = Point(128, 111);
        rects[0][2] = Point(133, 103);
        rects[0][3] = Point(164, 120);
        rects[0][4] = Point(178, 133);
        rects[0][5] = Point(171, 147);
        rects[1] = vector<Point>(11);
        rects[1][0] = Point(239, 177);
        rects[1][1] = Point(246, 161);
        rects[1][2] = Point(255, 162);
        rects[1][3] = Point(266, 141);
        rects[1][4] = Point(278, 125);
        rects[1][5] = Point(289, 120);
        rects[1][6] = Point(291, 128);
        rects[1][7] = Point(281, 150);
        rects[1][8] = Point(272, 164);
        rects[1][9] = Point(272, 176);
        rects[1][10] = Point(260, 193);
        rects[2] = vector<Point>(7);
        rects[2][0] = Point(298, 174);
        rects[2][1] = Point(311, 168);
        rects[2][2] = Point(347, 230);
        rects[2][3] = Point(355, 249);
        rects[2][4] = Point(356, 260);
        rects[2][5] = Point(346, 257);
        rects[2][6] = Point(298, 175);
        rects[3] = vector<Point>(6);
        rects[3][0] = Point(243, 345);
        rects[3][1] = Point(302, 352);
        rects[3][2] = Point(342, 345);
        rects[3][3] = Point(344, 366);
        rects[3][4] = Point(301, 383);
        rects[3][5] = Point(243, 372);
        for (int i = 0; i < 4; ++i) {
            //rects[i] = vector<Point>(4);
            //for (int j = 0; j < 4; ++j) { rects[i][j] = arects[i][j]; }
            polylines(parfait.rgb, rects[i], true, CV_RGB(255, 0, 0));
        }

        // prepare display
        if (cooked.index == 0) {
            // initialize the features we are tracking
            olddescrs = Mat::zeros(0, newdescrs.cols, newdescrs.type());
            objects.resize(4);
            for (int i = 0; i < 4; ++i) {
                for (int j = 0; j < newkeys.size(); ++j) {
                    if (pointPolygonTest(rects[i], newkeys[j].pt, false) == 1) {
                        tout() << "Including feature #" << j << "(" << newkeys[j].pt.x << ", " << newkeys[j].pt.y << ") in rect " << i << endl;
                        goodkeys.push_back(newkeys[j]);
                        objects[i].push_back(goodkeys.size()-1);
                        olddescrs.push_back(newdescrs.row(j).clone());
                    }
                }
            }

        } else {

            matches.clear();
            matchmaker.clear();
            Mat mask = Mat::zeros(olddescrs.rows, newdescrs.rows, CV_8UC1);
            for (int i = 0; i < olddescrs.rows; ++i) {
                for (int j = 0; j < newdescrs.rows; ++j) {
                    if (sqrt(pow(goodkeys[i].pt.x - newkeys[j].pt.x, 2) + pow(goodkeys[i].pt.y - newkeys[j].pt.y, 2)) <= 20) {
                        mask.at<uchar>(i,j) = 1;
                    }
                }
            }
            matchmaker.match(olddescrs, newdescrs, matches, mask);
            // keep the good matches as markers
            good_matches.clear();
            goodkeys.clear();
            //olddescrs = Mat::zeros(4, newdescrs.cols, newdescrs.type());
            for (int i = 0; i < matches.size(); ++i) {
                goodkeys.push_back(newkeys[matches[i].trainIdx]);
                if (matches[i].distance <= 0.05) {
                    newdescrs.row(matches[i].trainIdx).copyTo(olddescrs.row(i));
                }
            }
            Scalar color = Scalar::all(50);
            for (int i = 0; i < 4; ++i) {
                color = Scalar::all(color[0] + 50);
                aruco::Marker mean;
                mean.push_back(Point(0, 0));
                for (int j = 0; j < objects[i].size(); ++j) {
                    circle(parfait.rgb, goodkeys[objects[i][j]].pt, 3, color, -1);
                    mean[0].x += goodkeys[objects[i][j]].pt.x;
                    mean[0].y += goodkeys[objects[i][j]].pt.y;
                }
                mean[0].x /= objects[i].size();
                mean[0].y /= objects[i].size();
                circle(parfait.rgb, mean[0], 5, CV_RGB(255, 0, 0), -1);
                mean.Tvec.at<float>(0) = mean[0].x;
                mean.Tvec.at<float>(1) = mean[0].y;
                mean.Tvec.at<float>(2) = parfait.depth.at<uchar>(mean[0].x, mean[0].y);
                cooked.markers.push_back(mean);
            }

            cooked.dirty = parfait.rgb.clone();
            for (vector<QueueCooked*>::iterator qo = qos.begin(); qo != qos.end(); ++qo) {
                (*qo)->push(cooked);
            }
        }

        return true;
    }

    void KinectProcessor::cleanup()
    {
        // nothing to do
    }

}

