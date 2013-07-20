#include <iostream>
#include "acquire.h"
#include "flexvideo.h"
#include "aruco/cvdrawingutils.h"

#include "processor.h"

namespace acquire
{
    using namespace std;
    using namespace aruco;

    bool Processor::setup(string intrinsics_, string marker_size_)
    {
        // read camera intrinsics
        intrinsics.readFromXMLFile(intrinsics_); // notwithstanding it's actually YAML ...?
        // intrinsics.resize(image.size()); // let's see if we can get away with skipping this

        // marker size, maybe
        if (marker_size_.length() > 0) {
            marker_size = atof(marker_size_.c_str());
        } else {
            marker_size = -1;
        }

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

        cooked.index = raw.index;
        cooked.time = time(NULL);
        cooked.clean = raw.image.clone();

        if (marker_size != -1) {
            // detect markers
            detective.detect(raw.image, cooked.markers, intrinsics, marker_size);
            //cvtColor(detective.getThresholdedImage(), image, CV_GRAY2RGB);
            tout() << "Detected " << cooked.markers.size() << " markers!" << endl;

            // draw markers and write data
            for (vector<Marker>::iterator i = cooked.markers.begin(); i != cooked.markers.end(); ++i) {
                CvDrawingUtils::draw3dCube(raw.image, *i, intrinsics);
                CvDrawingUtils::draw3dAxis(raw.image, *i, intrinsics);
            }

            cooked.dirty = raw.image.clone();
        }

        qo.push(cooked);
        return true;
    }

    void Processor::cleanup()
    {
        // nothing to do
    }

} // namespace acquire

