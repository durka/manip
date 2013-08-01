#include <iostream>
#include "acquire.h"
#include "flexvideo.h"
#include "aruco/cvdrawingutils.h"

#include "processor.h"

namespace acquire
{
    using namespace std;
    using namespace cv;
    using namespace aruco;

    bool Processor::setup(CameraParameters *intrinsics_, float marker_size_)
    {
        intrinsics = intrinsics_;

        tout() << "detecting markers of size " << marker_size_ << " (-1 means no detection)" << endl;
        marker_size = marker_size_;

        // some parameters
        detective.setCornerRefinementMethod(MarkerDetector::SUBPIX);
        detective.setThresholdParams(7, 7);

        return true;
    }

    bool Processor::loop(bool lameduck)
    {
        RawPacket raw;
        CookedPacket cooked;

        if (qi.empty() && lameduck) return false;

        qi.wait_and_pop(raw);
        tout() << "processing packet #" << raw.index << "!" << endl;

        if (raw.index == 0) {
            intrinsics->resize(raw.image.size());
        }

        cooked.index = raw.index;
        cooked.time = time(NULL);
        cooked.clean = raw.image.clone();

        if (marker_size != -1) {
            // detect markers
            detective.detect(raw.image, cooked.markers, *intrinsics, marker_size);
            //cvtColor(detective.getThresholdedImage(), image, CV_GRAY2RGB);
            tout() << "Detected " << cooked.markers.size() << " markers!" << endl;

            // draw markers and write data
            for (vector<Marker>::iterator i = cooked.markers.begin(); i != cooked.markers.end(); ++i) {
                CvDrawingUtils::draw3dCube(raw.image, *i, *intrinsics);
                CvDrawingUtils::draw3dAxis(raw.image, *i, *intrinsics);
            }

            cooked.dirty = raw.image.clone();
        }

        qo1.push(cooked);
        qo2.push(cooked);
        qo3.push(cooked);
        return true;
    }

    void Processor::cleanup()
    {
        // nothing to do
    }

} // namespace acquire

