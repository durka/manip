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

    bool Graphics::setup(int N_, CameraParameters *intrinsics_)
    {
        N = N_;
        intrinsics = intrinsics_;
        namedWindow(prefix);

        return true;
    }

    bool Graphics::loop(bool lameduck)
    {

        if (lameduck) return false;

        static vector<Joint> joints;

        CookedPacket cooked;
        DigestedPacket digested;
        int signal = q1.wait_and_pop(cooked);
        if (q2.try_pop(digested)) {
            joints = digested.joints;
        }

        // TODO
        // - support "scroll lock"

        static Mat history = Mat::zeros(cooked.dirty.rows, cooked.dirty.cols, cooked.dirty.type());
        if (signal & CLEAR) {
            history = 0.0;
            joints.clear();
        }

        // add markers to trails on history image
        for (vector<Marker>::iterator i = cooked.markers.begin(); i != cooked.markers.end(); ++i) {
            circle(history, i->getCenter(), 3, CV_RGB(0,0,255), -1);
        }

        if (cooked.markers.size() == N) {
            // draw joints on the dirty image
            // TODO could save time by drawing this image once, when the q2 packet comes in
            for (vector<Joint>::iterator i = joints.begin(); i != joints.end(); ++i) {
                // line from A to B
                line(cooked.dirty, cooked.markers[i->a].getCenter(),
                                   cooked.markers[i->b].getCenter(),
                                   CV_RGB(255,0,0), 2);
                // green circle marking B
                circle(cooked.dirty, cooked.markers[i->b].getCenter(),
                                     5, CV_RGB(0,255,0), -1);

                // FORWARD KINEMATICS OH BOY
                i->normal.convertTo(i->normal, CV_32FC1);
                i->origin.convertTo(i->origin, CV_32FC1);
                Mat z(1, 3, CV_32FC1);
                z.at<float>(0) = 0; z.at<float>(1) = 0; z.at<float>(2) = 1;
                Mat rotvec = z.cross(i->normal);
                normalize(rotvec, rotvec);
                float theta = acos(z.dot(i->normal));
                if (isnan(theta)) continue;
                Mat rot(3, 3, CV_32FC1);
                Rodrigues(rotvec*theta, rot);

                double th, james = M_PI/2;
                Mat x(1000, 3, CV_32FC1);
                for (int j = 0; j < 1000; ++j) {
                    th = j*2*M_PI/1000;
                    x.at<float>(j,0) = cos(th+james)*i->radius;
                    x.at<float>(j,1) = sin(th+james)*i->radius;
                    x.at<float>(j,2) = th*i->pitch + i->offset;
                }
                x = (rot*x.t()).t() + repeat(i->origin, 1000, 1);

                // project to image plane
                vector<Point2f> y(1000);
                projectPoints(x,
                              cooked.markers[i->a].Rvec,
                              cooked.markers[i->a].Tvec,
                              intrinsics->CameraMatrix,
                              intrinsics->Distorsion,
                              y);
                Mat pts(2, 3, CV_32FC1);
                pts.at<float>(0,0) = i->origin.at<float>(0) - 20*i->normal.at<float>(0);
                pts.at<float>(0,1) = i->origin.at<float>(1) - 20*i->normal.at<float>(1);
                pts.at<float>(0,2) = i->origin.at<float>(2) - 20*i->normal.at<float>(2);
                pts.at<float>(1,0) = i->origin.at<float>(0) + 20*i->normal.at<float>(0);
                pts.at<float>(1,1) = i->origin.at<float>(1) + 20*i->normal.at<float>(1);
                pts.at<float>(1,2) = i->origin.at<float>(2) + 20*i->normal.at<float>(2);
                for (vector<Point2f>::iterator j = y.begin(); j != y.end(); ++j) {
                    circle(cooked.dirty, *j, 1, CV_RGB(255,0,0), -1);
                }
                projectPoints(pts,
                              cooked.markers[i->a].Rvec,
                              cooked.markers[i->a].Tvec,
                              intrinsics->CameraMatrix,
                              intrinsics->Distorsion,
                              y);
                line(cooked.dirty, y[0], y[1], CV_RGB(255,0,0), 2);
            }
        }

        Mat image(cooked.dirty.rows/2, cooked.dirty.cols, cooked.dirty.type());
        resize(cooked.clean, Mat(image, Rect(0, 0, cooked.dirty.cols/2, cooked.dirty.rows/2)), Size(), 0.5, 0.5, CV_INTER_AREA);
        resize(cooked.dirty + history, Mat(image, Rect(cooked.dirty.cols/2, 0, cooked.dirty.cols/2, cooked.dirty.rows/2)), Size(), 0.5, 0.5, CV_INTER_AREA);

        // draw this thread's FPS on the image
        static double ticks = getTickCount(), fps = 0;
        if (cooked.index % 10 == 0) {
            fps = 10.0 / ( ((double)getTickCount() - ticks) / (double)getTickFrequency() );
            ticks = getTickCount();
        }
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

