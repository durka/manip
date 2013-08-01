#ifndef _ACQUIRE_PROCESSOR_H_
#define _ACQUIRE_PROCESSOR_H_

#include "acquire.h"

namespace acquire
{

    class Processor : public WorkerThread
    {
        public:
            Processor(ostream& out_, ostream& err_, QueueRaw& qi_, QueueCooked& qo1_, QueueCooked& qo2_, QueueCooked& qo3_)
                : WorkerThread(out_, err_, "processing thread"), qi(qi_), qo1(qo1_), qo2(qo2_), qo3(qo3_) {}
            bool setup(aruco::CameraParameters* intrinsics_, float marker_size_);

        private:
            bool loop(bool lameduck);
            void cleanup();
            void fit();
            QueueRaw &qi;
            QueueCooked &qo1;
            QueueCooked &qo2;
            QueueCooked &qo3;
            float marker_size;
            aruco::CameraParameters* intrinsics;
            aruco::MarkerDetector detective;
    };

} // namespace acquire

#endif // _ACQUIRE_PROCESSOR_H_

