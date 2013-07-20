#ifndef _ACQUIRE_GRAPHICS_H_
#define _ACQUIRE_GRAPHICS_H_

#include "acquire.h"

namespace acquire
{

    class Graphics : public WorkerThread
    {
        public:
            Graphics(ostream& out_, ostream& err_, QueueCooked& q_)
                : WorkerThread(out_, err_, "graphics thread"), q(q_) {}
            bool setup();

        private:
            bool loop(bool lameduck);
            void cleanup();
            QueueCooked &q;
    };

} // namespace acquire

#endif // _ACQUIRE_GRAPHICS_H_

