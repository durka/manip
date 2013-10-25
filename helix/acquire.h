#ifndef _ACQUIRE_H_
#define _ACQUIRE_H_

#include "packet.h"
#include "concurrent_queue.h"

namespace acquire
{

    typedef concurrent_queue<acquire::RawPacket> QueueRaw;
    typedef concurrent_queue<acquire::CookedPacket> QueueCooked;
    typedef concurrent_queue<acquire::ParfaitPacket> QueueParfait;
    typedef concurrent_queue<acquire::DigestedPacket> QueueDigested;
    template<typename T> struct pthreadfunc { typedef int (*type)(pthread_attr_t*, T); };

    class WorkerThread
    {
        public:
            WorkerThread(ostream& out_, ostream& err_, std::string prefix_)
                : out(out_), err(err_), prefix("[" + prefix_ + "] "), running(false) {}
            virtual ~WorkerThread() {}

            void start()
            {
                start(boost::thread::attributes());
            }
            template<typename T, int N> void start(typename pthreadfunc<T>::type func[N], T param[N])
            {
                boost::thread::attributes attrs;
                for (int i = 0; i < N; ++i)
                {
                    func[i](attrs.native_handle(), param[i]);
                }
                start(attrs);
            }
            void start(boost::thread::attributes attrs)
            {
                yarn = boost::thread(attrs, boost::bind(&WorkerThread::thread, this));
                running = true;
            }
            void kill()
            {
                if (running) {
                    yarn.interrupt();
                    yarn.join();
                    running = false;
                }
            }
            bool is_running() { return running; }

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
                running = false;
            }
            ostream& tout() { return out << prefix; }
            ostream& terr() { return err << prefix; }

            boost::thread yarn;
            std::string prefix;
            ostream& out;
            ostream& err;
            bool running;
    };

} // namespace acquire

#endif // _ACQUIRE_H_

