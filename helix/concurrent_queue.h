#ifndef _ACQUIRE_CONCURRENT_QUEUE_H_
#define _ACQUIRE_CONCURRENT_QUEUE_H_

#include <queue>
#include <boost/thread.hpp>

/* This code came from a blog post by Anthony Williams
 * URL: http://www.justsoftwaresolutions.co.uk/threading/implementing-a-thread-safe-queue-using-condition-variables.html
 * 
 * in the comments, "David" asked about licensing, and the reply was:
 * > Hi David,
 * >
 * > Yes, you can just copy the code presented here and use it for whatever you like. There won't be any licensing issues. I'm glad you find it helpful.
 * >
 * > by Anthony Williams at 10:05:40 on Friday, 05 September 2008
 *
 * So there.
 */

namespace acquire
{

    template<typename Data>
    class concurrent_queue
    {
        public:
            concurrent_queue() : the_signal(0) {}

            void push(Data const& data)
            {
                boost::mutex::scoped_lock lock(the_mutex);
                the_queue.push(data);
                lock.unlock();
                the_condition_variable.notify_one();
            }

            void signal(int signal)
            {
                boost::mutex::scoped_lock lock(the_mutex);
                the_signal |= signal;
            }

            void unsignal(int signal)
            {
                boost::mutex::scoped_lock lock(the_mutex);
                the_signal &= ~signal;
            }

            bool empty() const
            {
                boost::mutex::scoped_lock lock(the_mutex);
                return the_queue.empty();
            }

            size_t size() const
            {
                boost::mutex::scoped_lock lock(the_mutex);
                return the_queue.size();
            }

            bool try_pop(Data& popped_value)
            {
                boost::mutex::scoped_lock lock(the_mutex);
                if(the_queue.empty())
                {
                    return false;
                }

                popped_value=the_queue.front();
                the_queue.pop();
                return true;
            }

            int wait_and_pop(Data& popped_value)
            {
                boost::mutex::scoped_lock lock(the_mutex);
                while(the_queue.empty())
                {
                    the_condition_variable.wait(lock);
                }

                popped_value=the_queue.front();
                the_queue.pop();

                int signal = the_signal;
                the_signal = 0;
                return signal;
            }

        private:
            std::queue<Data> the_queue;
            mutable boost::mutex the_mutex;
            boost::condition_variable the_condition_variable;
            int the_signal;
    };

} // namespace acquire

#endif // _ACQUIRE_CONCURRENT_QUEUE_H_

