#include <iostream>
#include <fstream>
#include "acquire.h"

#include "writer.h"

namespace acquire
{

    using namespace std;
    using namespace cv;
    using namespace aruco;

    bool Writer::setup(string clean_fmt_, string dirty_fmt_, string data_path)
    {
        // open video outputs
        if (clean_fmt_.find("%d") == string::npos) {
            clean_fmt = "";
        } else {
            clean_fmt = clean_fmt_;
            tout() << "Writing clean images to " << clean_fmt << endl;
        }
        if (dirty_fmt.find("%d") == string::npos) {
            dirty_fmt_ = "";
        } else {
            dirty_fmt = dirty_fmt_;
            tout() << "Writing dirty images to " << dirty_fmt << endl;
        }
        // here we trust the user to give good format strings
        // this is obviously a security vulnerability

        // open text output
        if (data_path.length() > 0) {
            data.open(data_path.c_str());
            if (!data.is_open()) {
                terr() << "Failed to open text output " << data_path << "!" << endl;
                return false;
            } else {
                tout() << "Writing data to " << data_path << endl;
            }
        }

        return true;
    }

    bool Writer::loop(bool lameduck)
    {
        char *filename;
        CookedPacket pkt;

        if (q.empty() && lameduck) return false;

        q.wait_and_pop(pkt);
        tout() << "writing packet #" << pkt.index << "!" << endl;

        // write clean image
        if (clean_fmt.length() > 0) {
            asprintf(&filename, clean_fmt.c_str(), pkt.index);
            imwrite(filename, pkt.clean);
            free(filename);
        }
        // write marked-up image
        if (dirty_fmt.length() > 0) {
            asprintf(&filename, dirty_fmt.c_str(), pkt.index);
            imwrite(filename, pkt.dirty);
            free(filename);
        }
        // draw markers and write data
        if (data.is_open()) {
            data << pkt.index << " " << pkt.time << ": ";
            for (vector<Marker>::iterator i = pkt.markers.begin(); i != pkt.markers.end(); ++i) {
                data << i->id << " ";
                for (int j = 0; j < 3; ++j) {
                    data << i->Tvec.ptr<float>(0)[j] << " ";
                }
                for (int j = 0; j < 3; ++j) {
                    data << i->Rvec.ptr<float>(0)[j] << " ";
                }
                data << " | ";
            }
            data << endl;
        }

        return true;
    }

    void Writer::cleanup()
    {
        if (data.is_open()) data.close();
    }

} // namespace acquire

