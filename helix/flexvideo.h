#ifndef _FLEX_VIDEO_H_
#define _FLEX_VIDEO_H_

#include <string>
#include "aruco/cvdrawingutils.h"

namespace flex
{

    class VideoCapture
    {
        public:
            bool open(int device);
            bool open(const std::string& filename);

            bool isOpened();

            bool grab();

            bool retrieve(cv::Mat& image);

            VideoCapture& operator>>(cv::Mat& image);

        private:
            cv::VideoCapture vc;
            string in_fmt;
            int index;
            cv::Mat frame;
            bool real_video;
    };

} // namespace flex

#endif // _FLEX_VIDEO_H_

