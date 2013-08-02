#ifndef _ACQUIRE_PACKET_H_
#define _ACQUIRE_PACKET_H_

#include "aruco/cvdrawingutils.h"

namespace acquire
{

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

    struct Joint
    {
        int a, b;
        enum { J_RIGID, J_PRISMATIC, J_REVOLUTE, J_SCREW } type;
        cv::Mat origin;
        cv::Mat normal;
        cv::Mat param;
        double radius, pitch, offset;

        Joint() {}
        Joint(const Joint& rhs) // deep copy the matrices
        {
            type = rhs.type;
            a = rhs.a;
            b = rhs.b;
            origin = rhs.origin.clone();
            param = rhs.param.clone();
            switch (type)
            {
                case J_SCREW:
                    pitch = rhs.pitch;
                    offset = rhs.offset;
                    // fall through
                case J_REVOLUTE:
                    radius = rhs.radius;
                    // fall through
                case J_PRISMATIC:
                    normal = rhs.normal.clone();
                    break;
                default:
                    break;
            }
        }
    };

    struct DigestedPacket
    {
        int index;
        time_t time;
        vector<Joint> joints;
    };

} // namespace acquire

#endif // _ACQUIRE_PACKET_H_

