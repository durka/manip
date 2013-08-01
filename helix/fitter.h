#ifndef _ACQUIRE_FITTER_H_
#define _ACQUIRE_FITTER_H_

#include "acquire.h"
#include "geometry.h"

namespace acquire
{

    class Fitter : public WorkerThread
    {
        public:
            Fitter(ostream& out_, ostream& err_, QueueCooked& qi_, QueueDigested& qo_)
                : WorkerThread(out_, err_, "fitter thread"), qi(qi_), qo(qo_) {}
            bool setup(int N_);

            static const int CLEAR = 1,
                             FIT   = 2;

        private:
            bool loop(bool lameduck);
            void cleanup();

            Mat delta(aruco::Marker a, aruco::Marker b);
            Mat read(aruco::Marker m);
            static double objective_thunk(unsigned n, const double *x, double *grad, void *data);
            static double constraint_thunk(unsigned n, const double *x, double *grad, void *data);
            double objective(unsigned n, const double *x, double *grad);
            double constraint(unsigned n, const double *x, double *grad);

            QueueCooked &qi;
            QueueDigested &qo;
            int N;
            Mat **deltas;
            Projection proj;
    };

} // namespace acquire

#endif // _ACQUIRE_FITTER_H_

