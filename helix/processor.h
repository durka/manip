#ifndef _ACQUIRE_PROCESSOR_H_
#define _ACQUIRE_PROCESSOR_H_

#include "acquire.h"

namespace acquire
{

    class Processor : public WorkerThread
    {
        public:
            Processor(ostream& out_, ostream& err_, QueueRaw& qi_, QueueCooked& qo_)
                : WorkerThread(out_, err_, "processing thread"), qi(qi_), qo(qo_) {}
            bool setup(string intrinsics_, string marker_size_);

        private:
            bool loop(bool lameduck);
            void cleanup();
            QueueRaw &qi;
            QueueCooked &qo;
            float marker_size;
            aruco::CameraParameters intrinsics;
            aruco::MarkerDetector detective;
    };

} // namespace acquire

#endif // _ACQUIRE_Processor_H_

