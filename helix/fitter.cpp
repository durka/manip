#include <iostream>
#include <boost/graph/graph_traits.hpp>
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/prim_minimum_spanning_tree.hpp>
#include "acquire.h"
#include "flexvideo.h"
#include "aruco/cvdrawingutils.h"

#include "fitter.h"
#include "geometry.h"
#include "nlopt.hpp"
#include "matio.h"

namespace acquire
{
    using namespace std;
    using namespace cv;
    using namespace boost;

    bool Fitter::setup(int N_)
    {
        N = N_;

        deltas = new Mat*[N];
        for (int a = 0; a < N; ++a) {
            deltas[a] = new Mat[N];
            for (int b = a+1; b < N; ++b) {
                //deltas[a][b].create(380, 3, CV_64FC1);
                //deltas[a][b].create(1276, 3, CV_64FC1);
                deltas[a][b].create(10000, 3, CV_64FC1);
            }
        }

        return true;
    }

    bool Fitter::loop(bool lameduck)
    {
        if (lameduck) return false;

        static int counter = 0;

        CookedPacket cooked;
        int signal = qi.wait_and_pop(cooked);

        if (signal & CLEAR) {
            counter = 0;
        }

        if (cooked.markers.size() != N) {
            //tout() << "dropping frame " << cooked.index << " (not enough markers)" << endl;
        } else {
            if (!(signal & FIT) && counter < deltas[0][1].rows) {
                for (int a = 0; a < N; ++a) {
                    for (int b = a+1; b < N; ++b) {
                        // matlab syntax is so much more compact :(
                        // deltas{i,j}(counter,:) = delta(1:3,4)'
                        Mat d = delta(cooked.markers[a], cooked.markers[b]);
                        deltas[a][b].at<double>(counter,0) = d.at<double>(0,3);
                        deltas[a][b].at<double>(counter,1) = d.at<double>(1,3);
                        deltas[a][b].at<double>(counter,2) = d.at<double>(2,3);
                    }
                }
                ++counter;
                //tout() << "calculated deltas for frame " << cooked.index << " (row " << counter << ")" << endl;
            } else {
                static int pkt_counter = 0;
                DigestedPacket pkt;
                pkt.index = pkt_counter++;

                for (int a = 0; a < N; ++a) {
                    for (int b = a+1; b < N; ++b) {
                        tout() << "\tFitting " << a << "->" << b << endl;

                        // new matrix to reference only the rows we have captured
                        Mat del(deltas[a][b].rowRange(0, counter));

                        // step 1: cylinder axis and radius, from PCA
                        PCA pca(del, Mat(), CV_PCA_DATA_AS_ROW);
                        Projection candidates[3];
                        double min_err = 1.0/0.0;
                        int best_h = -1;
                        for (int h = 0; h < 3; ++h) { // try each principal axis
                            candidates[h].init(del, pca.eigenvectors.row(h));
                            if (candidates[h].err < min_err) {
                                min_err = candidates[h].err;
                                best_h = h;
                            }
                        }
                        tout() << "\t\tchose axis #" << best_h << ": " << proj.caxis << endl;
                        proj = candidates[best_h];

                        // step 2: helix pitch
                        // (FIXME useless, since we do it again later anyway...)
                        proj.do_pitch();
                        tout() << "\t\tfound helix pitch = " << proj.pitch << ", offset = " << proj.offset << endl;

                        // step 3: NONLINEAR MINIMIZATION
                        nlopt::opt opt(nlopt::LN_COBYLA, 6);
                        vector<double> lb(6), ub(6), x(6);
                            lb[0] = -100; ub[0] = 100; x[0] = proj.origin3.at<double>(0);
                            lb[1] = -100; ub[1] = 100; x[1] = proj.origin3.at<double>(1);
                            lb[2] = -100; ub[2] = 100; x[2] = proj.origin3.at<double>(2);
                            lb[3] = -1;   ub[3] = 1;   x[3] = proj.caxis.at<double>(0);
                            lb[4] = -1;   ub[4] = 1;   x[4] = proj.caxis.at<double>(1);
                            lb[5] = -1;   ub[5] = 1;   x[5] = proj.caxis.at<double>(2);
                        opt.set_lower_bounds(lb);
                        opt.set_upper_bounds(ub);
                        opt.set_min_objective(Fitter::objective_thunk, this);
                        opt.add_equality_constraint(Fitter::constraint_thunk, this, 1e-8);
                        opt.set_xtol_rel(1e-2);
                        opt.set_maxtime(1); // 1 second max
                        double minf;

                        tout() << "\t\tfitting..." << endl;
                        tout() << "\t\t\torigin = " << proj.origin3 << endl;
                        tout() << "\t\t\tcaxis  = " << proj.caxis << endl;

                        try
                        {
                            nlopt::result res = opt.optimize(x, minf);
                        } catch (std::exception& e) {
                            terr() << "OPTIMIZATION FAILED: " << e.what() << endl;
                        }

                        proj.origin3.at<double>(0) = x[0];
                        proj.origin3.at<double>(1) = x[1];
                        proj.origin3.at<double>(2) = x[2];
                        proj.caxis.at<double>(0)   = x[3];
                        proj.caxis.at<double>(1)   = x[4];
                        proj.caxis.at<double>(2)   = x[5];
                        tout() << "\t\tdone fitting! minf=" << minf << endl;
                        tout() << "\t\t\torigin = " << proj.origin3 << endl;
                        tout() << "\t\t\tcaxis  = " << proj.caxis << endl;

                        proj.init(proj.Y, proj.caxis, &proj.origin3);

                        // step 4: recalculate the stuff and slide the origin
                        // origin += caxis*min((Y - origin)*caxis)
                        tout() << "sliding from " << proj.origin3 << endl;
                        Mat temp1, minval(1, 1, CV_64FC1), temp2, origin;
                        temp2 = (proj.Y - repeat(proj.origin3, proj.Y.rows, 1));
                        temp1 = temp2*proj.caxis.t();
                        min(temp1, minval);
                        origin = proj.origin3 + minval*proj.caxis; // FIXME sign error?
                        proj.init(proj.Y, proj.caxis, &origin);
                        tout() << "slid to " << proj.origin3 << endl;

                        proj.do_pitch();

                        tout() << "\t\tRESULT" << endl;
                        tout() << "\t\t\tcaxis: " << proj.caxis << endl;
                        tout() << "\t\t\torigin: " << proj.origin3 << endl;
                        tout() << "\t\t\tplane: " << proj.plane.origin << ", " << proj.plane.u << ", " << proj.plane.v << endl;
                        tout() << "\t\t\tradius: " << proj.radius << endl;
                        tout() << "\t\t\tpitch: " << proj.pitch << endl;

                        // write to file
                        Mat arrt;
                        mat_t *mat;
                        matvar_t *matvar;
                        size_t dims[2];
                        mat = Mat_Open("test.mat", MAT_ACC_RDWR);

#define WRITE(addr, str) \
                        matvar = Mat_VarCreate(str, MAT_C_DOUBLE, MAT_T_DOUBLE, 2, dims, addr, 0); \
                        Mat_VarWrite(mat, matvar, MAT_COMPRESSION_NONE); \
                        Mat_VarFree(matvar)

#define WRITEm(arr, name) \
                        dims[0] = arr.rows; \
                        dims[1] = arr.cols; \
                        arrt = arr.t(); \
                        WRITE(arrt.data, #name)

#define WRITEd(d, name) \
                        dims[0] = 1; \
                        dims[1] = 1; \
                        WRITE(&d, #name)

                        WRITEm(proj.Y,            Y);
                        WRITEm(proj.Y3,           Y_p3);
                        WRITEm(proj.Y2,           Y_p2);
                        WRITEm(proj.origin3,      origin);
                        WRITEm(proj.caxis,        caxis);
                        WRITEm(proj.plane.origin, plane_o);
                        WRITEm(proj.plane.u,      plane_u);
                        WRITEm(proj.plane.v,      plane_v);
                        WRITEm(proj.theta,        theta);
                        WRITEd(proj.radius,       radius);
                        WRITEd(proj.pitch,        pitch);
                        WRITEd(proj.offset,       offset);

#undef WRITE
#undef WRITEm
#undef WRITEd

                        Mat_Close(mat);

                        // send to graphics thread
                        Joint joint;
                        joint.a      = a;
                        joint.b      = b;
                        joint.type   = Joint::J_SCREW;
                        joint.origin = proj.origin3;
                        joint.normal = proj.caxis;
                        joint.radius = proj.radius;
                        joint.pitch  = proj.pitch;
                        joint.offset = proj.offset;
                        joint.param  = proj.theta;
                        joint.score  = minf;
                        pkt.joints.push_back(joint);
                    }
                }

                if (!pkt.joints.empty()) {
                    // minimum spanning tree
                    typedef std::pair<int, int> edge;
                    typedef adjacency_list<vecS, vecS, undirectedS, no_property, property<edge_weight_t, double> > graph;
                    typedef graph_traits<graph>::vertex_descriptor vertex;
                    
                    tout() << "computing minimum spanning tree..." << endl;
                    graph g(N);
                    vector<vertex> v(N);
                    for (vector<Joint>::iterator i = pkt.joints.begin(); i != pkt.joints.end(); ++i) {
                        tout() << "\tbefore: " << i->a << "->" << i->b << " (" << i->score << ")" << endl;
                        add_edge(i->a, i->b, i->score, g);
                    }
                    tout() << "\tcrunch..." << endl;
                    try {
                        prim_minimum_spanning_tree(g, &v[0]);
                    } catch (std::exception& e) {
                        terr() << "MST error: " << e.what() << endl;
                    }
                    for (vector<Joint>::iterator i = pkt.joints.begin(); i != pkt.joints.end(); /* no increment */) {
                        if (v[i->a] == i->b || v[i->b] == i->a) {
                            tout() << "\tafter: " << i->a << "->" << i->b << endl;
                            ++i;
                        } else {
                            i = pkt.joints.erase(i);
                        }
                    }

                    pkt.time = time(NULL);
                    qo.push(pkt);
                }
            }
        }

        return true;
    }

    double Fitter::objective(unsigned n, const double *x, double *grad)
    {
        static int iter = 0;

        Mat center(1, 3, CV_64FC1),
            normal(1, 3, CV_64FC1);
        center.at<double>(0) = x[0];
        center.at<double>(1) = x[1];
        center.at<double>(2) = x[2];
        normal.at<double>(0) = x[3];
        normal.at<double>(1) = x[4];
        normal.at<double>(2) = x[5];

        Plane plane(center, normal);
        Mat Y3 = plane.project(proj.Y);
        Mat Y2 = plane.position(Y3);
        Mat origin = plane.center(Y2, NULL, NULL);

        // return std(sqrt(sum((Y2 - o).^2, 2)))
        Mat temp1, temp2, radii;
        Scalar the_mean, the_std;
        pow(Y2 - repeat(origin.t(), Y2.rows, 1), 2, temp1);
        reduce(temp1, temp2, 1, CV_REDUCE_SUM);
        sqrt(temp2, radii);
        meanStdDev(radii, the_mean, the_std);

        // estimate the pitch to use as a prior
        Projection projection;
        projection.init(proj.Y, normal, &center);
        projection.do_pitch();
        //double pitch_estimate = mean(abs((proj.Y - repeat(origin.t(), proj.Y.rows, 1)) * normal.t()))[0];
        double value = the_std[0] * pow(fabs(projection.pitch), 3);

        tout() << "\t\t\titeration #" << setw(4) << iter++ << ": ";
        for (int j = 0; j < 6; ++j) out << x[j] << " ";
        out << " = " << value << ", ";
        double mintheta, maxtheta;
        minMaxLoc(projection.theta, &mintheta, &maxtheta);
        out << "theta from " << mintheta << " to " << maxtheta << endl;

        return value;
    }

    double Fitter::constraint(unsigned n, const double *x, double *grad)
    {
        Mat normal(1, 3, CV_64FC1);
        normal.at<double>(0) = x[3];
        normal.at<double>(1) = x[4];
        normal.at<double>(2) = x[5];

        // return norm(x(4:6)) - 1
        return norm(normal) - 1;
    }

    double Fitter::objective_thunk(unsigned n, const double *x, double *grad, void *data)
    {
        return ((Fitter*)data)->objective(n, x, grad);
    }

    double Fitter::constraint_thunk(unsigned n, const double *x, double *grad, void *data)
    {
        return ((Fitter*)data)->constraint(n, x, grad);
    }

    void Fitter::cleanup()
    {
        // nothing to do
    }

    Mat Fitter::delta(aruco::Marker a, aruco::Marker b)
    {
        Mat ta = read(a),
                tb = read(b);

        return ta.inv() * tb;
    }

    Mat Fitter::read(aruco::Marker m)
    {
        Mat t(4, 4, CV_64FC1);
        t.row(3) = 0.0;
        t.at<double>(3,3) = 1.0;

        // translation component
        // t(1:3,4) = m.Tvec
        t.at<double>(0,3) = m.Tvec.at<float>(0);
        t.at<double>(1,3) = m.Tvec.at<float>(1);
        t.at<double>(2,3) = m.Tvec.at<float>(2);

        // rotation component
        // t(1:3,1:3) = rotvec2mat(m.Rvec)
        // it's silly... Aruco called Rodrigues to do the reverse and here we are undoing it
        m.Rvec.convertTo(m.Rvec, CV_64FC1);
        Rodrigues(m.Rvec, t.colRange(0,3).rowRange(0,3));

        return t;
    }

} // namespace acquire

