#include <iostream>
#include "acquire.h"
#include "flexvideo.h"
#include "aruco/cvdrawingutils.h"

#include "graphics.h"
#include "matio.h"

namespace acquire
{
    using namespace std;
    using namespace cv;
    using namespace aruco;

    bool Graphics::setup(int N_, CameraParameters *intrinsics_, string outname_)
    {
        N = N_;
        outname = outname_;
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
        if (signal & SAVE) {
            // write to file
            Mat arrt;
            mat_t *mat;
            matvar_t *matvar;
            size_t dims[2];
            char vname[20];
            mat = Mat_Open((outname + "_fits.mat").c_str(), MAT_ACC_RDWR);
            for (vector<Joint>::iterator i = joints.begin(); i != joints.end(); ++i) {

#define WRITE(addr, str, t) \
                sprintf(vname, str "_%d_%d", i->a, i->b); \
                matvar = Mat_VarCreate(vname, MAT_C_##t, MAT_T_##t, 2, dims, addr, 0); \
                Mat_VarWrite(mat, matvar, MAT_COMPRESSION_NONE); \
                Mat_VarFree(matvar)

#define WRITEm(arr, name) \
                dims[0] = arr.rows; \
                dims[1] = arr.cols; \
                arrt = arr.t(); \
                WRITE(arrt.data, #name, SINGLE)

#define WRITEd(d, name) \
                dims[0] = 1; \
                dims[1] = 1; \
                WRITE(&d, #name, DOUBLE)

                WRITEd(i->type,   type);
                WRITEm(i->origin, origin);
                WRITEm(i->normal, normal);
                i->param.convertTo(i->param, CV_32FC1);
                WRITEm(i->param,  param);
                WRITEd(i->radius, radius);
                WRITEd(i->pitch,  pitch);
                WRITEd(i->offset, offset);

#undef WRITE
#undef WRITEm
#undef WRITEd
            }
            Mat_Close(mat);
        }
        if (signal & LOAD) {
            // load from file
            Mat arrt;
            mat_t *mat;
            matvar_t *matvar;
            size_t dims[2];
            char vname[20];
            mat = Mat_Open((outname + "_fits.mat").c_str(), MAT_ACC_RDONLY);
            
            joints.clear();
            for (int a = 0; a < N; ++a) {
                for (int b = a+1; b < N; ++b) {

#define READ(str, dst) \
                    sprintf(vname, str "_%d_%d", a, b); \
                    matvar = Mat_VarRead(mat, vname)

#define READd(name, dst) \
                    READ(#name, dst); \
                    memcpy(&dst, matvar->data, sizeof dst); \
                    Mat_VarFree(matvar)

#define READm(name, dst) \
                    READ(#name, dst); \
                    arrt = Mat(matvar->dims[1], matvar->dims[0], CV_32FC1, matvar->data); \
                    dst = Mat(arrt.t()); \
                    Mat_VarFree(matvar)

                    Joint joint;
                    joint.a = a;
                    joint.b = b;
                    READd(type,   joint.type);
                    READm(origin, joint.origin);
                    READm(normal, joint.normal);
                    READm(param,  joint.param);
                    READd(radius, joint.radius);
                    READd(pitch,  joint.pitch);
                    READd(offset, joint.offset);
                    joints.push_back(joint);

#undef READ
#undef READm
#undef READd
                }
            }
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
                double high, low;
                minMaxLoc(i->param, &low, &high);
                //high += M_PI;
                //low -= M_PI;
                low = -2*M_PI;
                high = 4*M_PI;
                Mat x(1000, 3, CV_32FC1);
                for (int j = 0; j < x.rows; ++j) {
                    th = j*high/x.rows + low;
                    x.at<float>(j,0) = cos(th+james)*i->radius;
                    x.at<float>(j,1) = sin(th+james)*i->radius;
                    x.at<float>(j,2) = th*i->pitch + i->offset;
                }
                x = (rot*x.t()).t() + repeat(i->origin, x.rows, 1);

                // project to image plane
                vector<Point2f> y(x.rows);
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

