#ifndef _ACQUIRE_GEOMETRY_H_
#define _ACQUIRE_GEOMETRY_H_

#include "acquire.h"

namespace acquire
{
    using namespace cv;

    struct Plane
    {
        Plane();                                 // default: x-y plane at origin
        Plane(Mat center_, Mat normal_); // plane from origin and normal (both 1x3)

        Mat project(Mat vecs);     // vecs is Nx3: project 3D points onto plane (output is Nx3)
        Mat position(Mat vecs);    // translate points that are already on the plane (use project!) in/out of plane-local coordinates: Nx3 <=> Nx2
        Mat center(Mat vecs, double *radius, double *err); // vec is Nx2, finds circumcenter. output center is 1x2. optional outputs radius and err (std) can be NULL (if radius is NULL then err must be NULL).

        Mat origin, u, v;
    };

    struct Projection
    {
        void init(Mat Y_, Mat up) { init(Y_, up, NULL); }
        void init(Mat Y_, Mat up, Mat *origin);
        void do_pitch();

        // filled by init()
        Plane plane;
        Mat Y, Y3, Y2, caxis, origin3, origin2;
        double err, radius, thickness;

        // filled by do_pitch()
        Mat theta;
        double pitch, offset;
    };

} // namespace acquire

#endif // _ACQUIRE_GEOMETRY_H_

