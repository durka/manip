#ifndef _ACQUIRE_GRAPHICS_H_
#define _ACQUIRE_GRAPHICS_H_

#include "acquire.h"

namespace acquire
{

    class Graphics : public WorkerThread
    {
        public:
            Graphics(ostream& out_, ostream& err_, QueueCooked& q1_, QueueDigested& q2_)
                : WorkerThread(out_, err_, "graphics thread"), q1(q1_), q2(q2_) {}
            bool setup();

        private:
            bool loop(bool lameduck);
            void cleanup();
            QueueCooked &q1;
            QueueDigested &q2;
    };

} // namespace acquire

#endif // _ACQUIRE_GRAPHICS_H_

