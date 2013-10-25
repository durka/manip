#ifndef _ACQUIRE_PROCESSOR_H_
#define _ACQUIRE_PROCESSOR_H_

#include <vector>
#include "acquire.h"

namespace acquire
{

    class Processor : public WorkerThread
    {
        public:
            Processor(ostream& out_, ostream& err_, QueueRaw& qi_, std::vector<QueueCooked*> qos_)
                : WorkerThread(out_, err_, "processing thread"), qi(qi_), qos(qos_) {}
            bool setup(aruco::CameraParameters* intrinsics_, float marker_size_);

        private:
            bool loop(bool lameduck);
            void cleanup();
            QueueRaw &qi;
            std::vector<QueueCooked*> qos;
            float marker_size;
            aruco::CameraParameters* intrinsics;
            aruco::MarkerDetector detective;
    };

} // namespace acquire

#endif // _ACQUIRE_PROCESSOR_H_

