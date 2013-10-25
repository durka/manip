#ifndef _ACQUIRE_GRAPHICS_H_
#define _ACQUIRE_GRAPHICS_H_

#include "acquire.h"

namespace acquire
{

    using namespace cv;

    class Graphics : public WorkerThread
    {
        public:
            Graphics(ostream& out_, ostream& err_, QueueCooked& q1_, QueueDigested& q2_)
                : WorkerThread(out_, err_, "graphics thread"), q1(q1_), q2(q2_) {}
            bool setup(int N_, aruco::CameraParameters* intrinsics_, string outname_);

            static const int CLEAR = 1,
                             SAVE  = 2,
                             LOAD  = 4,
                             PRINT = 8;

        private:
            bool loop(bool lameduck);
            void cleanup();
            void mouse(int event, int x, int y, int flags);
            static void mouse_thunk(int event, int x, int y, int flags, void* that);
            int N;
            string outname;
            aruco::CameraParameters* intrinsics;
            vector<Point> clicks;
            QueueCooked &q1;
            QueueDigested &q2;
    };

} // namespace acquire

#endif // _ACQUIRE_GRAPHICS_H_

