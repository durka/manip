#include "flexvideo.h"

namespace flex
{

    bool VideoCapture::open(int device)
    {
        in_fmt = "";
        real_video = true;
        return vc.open(device);
    }

    bool VideoCapture::open(const std::string& filename)
    {
        in_fmt = "";
        if (strstr(filename.c_str(), "%d") != NULL) {
            real_video = false;
            in_fmt = filename;
            index = 1;
            return true;
        } else {
            real_video = true;
            return vc.open(filename);
        }
    }

    bool VideoCapture::isOpened()
    {
        if (real_video) {
            return vc.isOpened();
        } else {
            return true;
        }
    }

    bool VideoCapture::grab()
    {
        if (real_video) {
            return vc.grab();
        } else {
            char *filename;
            asprintf(&filename, in_fmt.c_str(), index++);
            frame = cv::imread(filename);
            free(filename);
            return frame.data != NULL;
        }
    }

    bool VideoCapture::retrieve(cv::Mat& image)
    {
        if (real_video) {
            return vc.retrieve(image);
        } else {
            image = frame;
            return true;
        }
    }

    VideoCapture& VideoCapture::operator>>(cv::Mat& image)
    {
        if (grab()) {
            retrieve(image);
        }
        return *this;
    }

} // namespace flex

