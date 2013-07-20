#ifndef _ACQUIRE_PACKET_H_
#define _ACQUIRE_PACKET_H_

#include "aruco/cvdrawingutils.h"

namespace acquire
{

    struct CookedPacket
    {
            int index;
            time_t time;
            cv::Mat clean, dirty;
            vector<aruco::Marker> markers;

            CookedPacket() {}
            CookedPacket(const CookedPacket& rhs) // deep copy the matrices
            {
                index = rhs.index;
                time = rhs.time;
                clean = rhs.clean.clone();
                dirty = rhs.dirty.clone();
                markers = rhs.markers;
            }
    };

    struct RawPacket
    {
            int index;
            time_t time;
            cv::Mat image;

            RawPacket() {}
            RawPacket(const RawPacket& rhs) // deep copy the matrices
            {
                index = rhs.index;
                image = rhs.image.clone();
            }
    };

} // namespace acquire

#endif // _ACQUIRE_PACKET_H_

