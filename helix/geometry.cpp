#include "geometry.h"

namespace acquire
{

    using namespace cv;

    Plane::Plane()
    {
        origin = Mat::zeros(1, 3, CV_64FC1);
        u = Mat::zeros(1, 3, CV_64FC1);
        v = Mat::zeros(1, 3, CV_64FC1);
        u.at<double>(0) = 1;
        v.at<double>(1) = 1;
    }

    Plane::Plane(Mat origin_, Mat normal_)
    {
        // origin is given
        origin = origin_;
        Mat normal = normal_.clone();
        normalize(normal, normal);

        // need a vector not collinear with the normal
        // it will be either [1 0 0] or [0 1 0]
        Mat v0 = Mat::eye(1, 3, CV_64FC1);
        if (norm(normal.cross(v0)) < 1e-14) {
            v0.at<double>(0) = 0;
            v0.at<double>(1) = 1;
        }

        // find the direction vectors
        u = normal.cross(v0);
        normalize(u, u);
        v = -u.cross(normal);
        normalize(v, v);
    }

    Mat Plane::project(Mat vecs)
    {
        Mat out(vecs.rows, vecs.cols, CV_64FC1);

        Mat normal = u.cross(v);

        for (int i = 0; i < vecs.rows; ++i) {
            // take a line parallel to the plane normal, going through the point
            // and intersect it with the plane
            out.row(i) = vecs.row(i) + normal.dot(origin - vecs.row(i))*normal;
        }

        return out;
    }

    Mat Plane::position(Mat vecs)
    {
        Mat out;
        switch (vecs.cols) {
            case 2:
                out.create(vecs.rows, 3, CV_64FC1);
                for (int i = 0; i < vecs.rows; ++i) {
                    Mat temp = origin + u*vecs.at<double>(i,0) + v*vecs.at<double>(i,1);
                    temp.copyTo(out.row(i));
                }
                break;
            case 3:
                out.create(vecs.rows, 2, CV_64FC1);
                for (int i = 0; i < vecs.rows; ++i) {
                    out.at<double>(i,0) = u.dot(vecs.row(i) - origin);
                    out.at<double>(i,1) = v.dot(vecs.row(i) - origin);
                }
                break;
        }

        return out;
    }

    Mat Plane::center(Mat vecs, double *radius, double *err)
    {
        // see circfit.m
        
        Mat A = Mat::ones(vecs.rows, 3, CV_64FC1);
        vecs.copyTo(A.colRange(0,2));
        
        Mat temp1(vecs.rows, vecs.cols, CV_64FC1);
        pow(vecs, 2, temp1);
        Mat b(vecs.rows, 1, CV_64FC1);
        reduce(temp1, b, 1, CV_REDUCE_SUM);

        Mat a = (A.t()*A).inv()*(A.t()*-b);
        Mat c = -0.5 * a.rowRange(0,2);

        if (radius != NULL) {
            *radius = sqrt( (pow(a.at<double>(0), 2) + pow(a.at<double>(1), 2))/4 - a.at<double>(2) );
            if (err != NULL) {
                Mat temp2 = vecs - repeat(c.t(), vecs.rows, 1);
                pow(temp2, 2, temp2);
                Mat temp3(vecs.rows, 1, CV_64FC1);
                reduce(temp2, temp3, 1, CV_REDUCE_SUM);
                sqrt(temp3, temp3);
                temp3 -= *radius;
                pow(temp3, 2, temp3);
                *err = sum(temp3)[0];
            }
        }

        return c.clone();
    }

    void Projection::init(Mat Y_, Mat normal, Mat *origin)
    {
        Y = Y_;
        normalize(normal, caxis);

        if (origin == NULL) {
            Mat mean(1, 3, CV_64FC1);
            reduce(Y, mean, 0, CV_REDUCE_AVG);
            plane = Plane(mean, normal);
        } else {
            plane = Plane(*origin, normal);
        }

        Y3 = plane.project(Y);    // 3-D world projected to 3-D plane coords
        Y2 = plane.position(Y3);  // 3-D plane translated into 2-D plane coords

        origin2.create(1, 2, CV_64FC1);
        origin2 = plane.center(Y2, &radius, &err);
        origin3 = plane.position(origin2.t()); // 2-D plane coords translated to 3-D plane coords

        // find the radius and "thickness"
        // radius    = mean( sqrt(sum( (Y2 - origin2).^2, 2) ))
        // thickness = std(  sqrt(sum( (Y2 - origin2).^2, 2) ))
        Mat temp1(Y2.rows, Y2.cols, CV_64FC1), temp2(Y2.rows, 1, CV_64FC1);
        Scalar s_radius, s_thickness;
        pow(Y2 - repeat(origin2.t(), Y2.rows, 1), 2, temp1);
        reduce(temp1, temp2, 1, CV_REDUCE_SUM);
        sqrt(temp2, temp2);
        meanStdDev(temp2, s_radius, s_thickness);
        radius = s_radius[0];
        thickness = s_thickness[0]*sqrt(Y.rows)/sqrt(Y.rows-1); // correct for biased STD
    }

    // copied out of the OpenCV source because they use floats and I want doubles dammit
    void double_polyfit(const Mat& src_x, const Mat& src_y, Mat& dst, int order)
    {
        CV_Assert((src_x.rows>0)&&(src_y.rows>0)&&(src_x.cols==1)&&(src_y.cols==1)
                &&(dst.cols==1)&&(dst.rows==(order+1))&&(order>=1));
        Mat X;
        X = Mat::zeros(src_x.rows, order+1,CV_64FC1); // <-- the only change right here
        Mat copy;
        for(int i = 0; i <=order;i++)
        {
            copy = src_x.clone();
            pow(copy,i,copy);
            Mat M1 = X.col(i);
            copy.col(0).copyTo(M1);
        }
        Mat X_t, X_inv;
        transpose(X,X_t);
        Mat temp = X_t*X;
        Mat temp2;
        invert (temp,temp2);
        Mat temp3 = temp2*X_t;
        Mat W = temp3*src_y;
        W.copyTo(dst);
    }

    void Projection::do_pitch()
    {
        theta.create(Y3.rows, 1, CV_64FC1);
        double fudge = 0;
        for (int i = 0; i < Y3.rows; ++i) {
            theta.at<double>(i) = atan2(Y2.at<double>(i,1) - origin2.at<double>(1),
                                        Y2.at<double>(i,0) - origin2.at<double>(0)) + fudge;
            if (i > 0) {
                if (theta.at<double>(i) - theta.at<double>(i-1) > M_PI) {
                    // this implementation of unwrap() is a little sketchy
                    double correction = ceil((theta.at<double>(i) - theta.at<double>(i-1))/M_PI)*M_PI;
                    theta.at<double>(i) -= correction;
                    fudge -= correction;
                } else if (theta.at<double>(i) - theta.at<double>(i-1) < -M_PI) {
                    double correction = ceil((theta.at<double>(i) - theta.at<double>(i-1))/-M_PI);
                    theta.at<double>(i) += correction;
                    fudge += correction;
                }
            }
        }
        Mat dst(2, 1, CV_64FC1);
        double_polyfit(theta, Y * caxis.t(), dst, 1);
        offset = dst.at<double>(0);
        pitch = dst.at<double>(1); // are these backwards? time will tell
    }

} // namespace acquire

