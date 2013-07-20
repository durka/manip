#ifndef _ACQUIRE_WATCHER_H_
#define _ACQUIRE_WATCHER_H_

#include "acquire.h"

namespace acquire
{

    class Watcher : public WorkerThread
    {
        public:
            Watcher(ostream& out_, ostream& err_, QueueRaw& q_)
                : WorkerThread(out_, err_, "camera thread"), q(q_) {}
            bool setup(string path);

        private:
            bool loop(bool lameduck);
            void cleanup();
            QueueRaw &q;
            flex::VideoCapture captor;
    };

} // namespace acquire

#endif // _ACQUIRE_WATCHER_H_

