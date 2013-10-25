#ifndef _ACQUIRE_KINECT_H_
#define _ACQUIRE_KINECT_H_

#include <libfreenect.hpp>
#include <cv.h>
#include <opencv2/nonfree/features2d.hpp>
#include <vector>
#include "acquire.h"


namespace kinect
{

    using namespace cv;

    class Mutex
    {
        public:
            Mutex() {
                pthread_mutex_init( &m_mutex, NULL );
            }
            void lock() {
                pthread_mutex_lock( &m_mutex );
            }
            void unlock() {
                pthread_mutex_unlock( &m_mutex );
            }
        private:
            pthread_mutex_t m_mutex;
    };

    class AcquireFreenectDevice : public Freenect::FreenectDevice
    {
        public:
            AcquireFreenectDevice(freenect_context *_ctx, int _index)
                : Freenect::FreenectDevice(_ctx, _index), m_buffer_depth(FREENECT_DEPTH_11BIT),m_buffer_rgb(FREENECT_VIDEO_RGB), m_gamma(2048), m_new_rgb_frame(false), m_new_depth_frame(false),
                depthMat(Size(640,480),CV_16UC1), rgbMat(Size(640,480),CV_8UC3,Scalar(0)), ownMat(Size(640,480),CV_8UC3,Scalar(0))
            {
                for( unsigned int i = 0 ; i < 2048 ; i++) {
                    float v = i/2048.0;
                    v = std::pow(v, 3)* 6;
                    m_gamma[i] = v*6*256;
                }
            }

            // Do not call directly even in child
            void VideoCallback(void* _rgb, uint32_t timestamp) {
                //std::cout << "RGB callback" << std::endl;
                m_rgb_mutex.lock();
                uint8_t* rgb = static_cast<uint8_t*>(_rgb);
                rgbMat.data = rgb;
                m_new_rgb_frame = true;
                m_rgb_mutex.unlock();
            };
            // Do not call directly even in child
            void DepthCallback(void* _depth, uint32_t timestamp) {
                //std::cout << "Depth callback" << std::endl;
                m_depth_mutex.lock();
                uint16_t* depth = static_cast<uint16_t*>(_depth);
                depthMat.data = (uchar*) depth;
                m_new_depth_frame = true;
                m_depth_mutex.unlock();
            }

            bool getVideo(Mat& output) {
                m_rgb_mutex.lock();
                if(m_new_rgb_frame) {
                    cv::cvtColor(rgbMat, output, CV_RGB2BGR);
                    m_new_rgb_frame = false;
                    m_rgb_mutex.unlock();
                    return true;
                } else {
                    m_rgb_mutex.unlock();
                    return false;
                }
            }

            bool getDepth(Mat& output) {
                m_depth_mutex.lock();
                if(m_new_depth_frame) {
                    depthMat.copyTo(output);
                    m_new_depth_frame = false;
                    m_depth_mutex.unlock();
                    return true;
                } else {
                    m_depth_mutex.unlock();
                    return false;
                }
            }

        private:
            std::vector<uint8_t> m_buffer_depth;
            std::vector<uint8_t> m_buffer_rgb;
            std::vector<uint16_t> m_gamma;
            Mat depthMat;
            Mat rgbMat;
            Mat ownMat;
            Mutex m_rgb_mutex;
            Mutex m_depth_mutex;
            bool m_new_rgb_frame;
            bool m_new_depth_frame;
    };
}

namespace acquire
{

    class KinectWatcher : public WorkerThread
    {
        public:
            KinectWatcher(ostream& out_, ostream& err_, QueueParfait& q_)
                : WorkerThread(out_, err_, "kinect thread"), q(q_) {}
            bool setup();

        private:
            bool loop(bool lameduck);
            void cleanup();
            QueueParfait& q;
            Freenect::Freenect freenect;
            kinect::AcquireFreenectDevice *device;
    };

    class KinectProcessor : public WorkerThread
    {
        public:
            KinectProcessor(ostream& out_, ostream& err_, QueueParfait& qi_, std::vector<QueueCooked*> qos_)
                : WorkerThread(out_, err_, "processor thread"), qi(qi_), qos(qos_) {}
            bool setup();

        private:
            bool loop(bool lameduck);
            void cleanup();
            QueueParfait& qi;
            std::vector<QueueCooked*> qos;
    };

}

#endif // _ACQUIRE_KINECT_H_

