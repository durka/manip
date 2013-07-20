#ifndef _ACQUIRE_WRITER_H_
#define _ACQUIRE_WRITER_H_

#include <fstream>
#include "acquire.h"

namespace acquire
{

    class Writer : public WorkerThread
    {
        public:
            Writer(ostream& out_, ostream& err_, QueueCooked& q_)
                : WorkerThread(out_, err_, "writer thread"), q(q_) {}
            bool setup(string outdir, string outname);

        private:
            bool loop(bool lameduck);
            void cleanup();
            QueueCooked &q;
            string clean_fmt, dirty_fmt;
            ofstream data;
    };

} // namespace acquire

#endif // _ACQUIRE_WRITER_H_

