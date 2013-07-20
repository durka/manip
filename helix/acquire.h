#ifndef _ACQUIRE_H_
#define _ACQUIRE_H_

#include "packet.h"
#include "concurrent_queue.h"

namespace acquire
{

    typedef concurrent_queue<acquire::RawPacket> QueueRaw;
    typedef concurrent_queue<acquire::CookedPacket> QueueCooked;

    class WorkerThread
    {
        public:
            WorkerThread(ostream& out_, ostream& err_, std::string prefix_)
                : out(out_),err(err_), prefix("[" + prefix_ + "] ") {}
            void start()
            {
                yarn = boost::thread(&WorkerThread::thread, this);
            }
            void kill()
            {
                if (yarn.joinable()) {
                    yarn.interrupt();
                    yarn.join();
                }
            }

        protected:
            virtual bool loop(bool lameduck) = 0;
            virtual void cleanup() = 0;
            void thread()
            {
                bool lameduck = false;
                time_t start = time(NULL);
                int iters = 0;
                while (true) {
                    try {
                        boost::this_thread::interruption_point();

                        ++iters;
                        if (!loop(lameduck))
                        {
                            terr() << "exiting" << endl;
                            break;
                        }
                    } catch (boost::thread_interrupted const&) {
                        terr() << "acknowledged interruption, finishing up" << endl;
                        lameduck = true;
                    }
                }
                terr() << "FPS: " << (float)iters/(time(NULL) - start) << endl;
                cleanup();
            }
            ostream& tout() { return out << prefix; }
            ostream& terr() { return err << prefix; }

            boost::thread yarn;
            std::string prefix;
            ostream& out;
            ostream& err;
    };

} // namespace acquire

#endif // _ACQUIRE_H_

