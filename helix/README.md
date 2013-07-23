INSTALLATION
============
Helix can be installed on OSX or Linux. I am working on creating a VM that will have all the dependencies set up already.

Dependencies are: (`setup.sh` takes care of everything this list)
- CMake
- OpenCV (developed with 2.4.5) (recommend installing with homebrew)
- Boost (developed with 1.54.0)
- Aruco, the augmented reality tags library (developed with 1.2.4)
- Octave (developed with 3.6.4) (recommend installing with homebrew)
    - two fixes to Octave:
        - on OSX, use a newer compiler: edit `/usr/local/bin/mkoctfile-3.6.4` and change all instances of `cc`, `c++`, etc to point at a newer version of GCC (for example, you can install gcc-4.8 from homebrew-versions). Otherwise, some of the packages below don't compile. I had to change lines 73 (cc -> gcc-4.8), and 76, 88, 108 (c++ -> g++-4.8).
        - fix [bug #39552](https://savannah.gnu.org/bugs/?39552), if the Octave folks haven't done it yet, by editing `/usr/local/share/octave/3.6.4/m/plot/private/__quiver__.m` and changing > to >= on line 108.
    - from Octave-Forge, install:
        - general          (prereq)
        - io               (prereq)
        - miscellaneous    (prereq)
        - struct           (prereq)
        - statistics       (for PCA)
        - geometry         (for plane fitting)
        - optim            (for nonlinear function optimization)


USAGE
=====
Acquisition
-----------

Helix fitting
-------------


HACKING
=======
The code here is written in C++ and Octave (originally it was written in Matlab, and very easily ported to Octave).

You'll find a clear separation between the acquisition part (C++) and all the machine learning parts (Octave).
- Acquisition
    - Headers
        | acquire.h | common header for everything; defines WorkerThread base class
        | watcher.h | worker thread that grabs images from the camera (or file)
        | processor.h | worker thread that looks for Aruco tags in image frames
        | graphics.h | worker thread that shows the live video on the screen
        | writer.h | worker thread that writes frames to disk
        | packet.h | defines structs that are passed between threads
        | flexvideo.h | drop-in wrapper for OpenCV VideoCapture, but can read from sequentially numbered image files as well as cameras
        | concurrent_queue.h | a thread-safe queue I found on the internet
    - Sources
        | acquire.cpp | the main program, does nothing much except parse the command line and launch worker threads
        | watcher.cpp | see above
        | processor.cpp | see above
        | graphics.cpp | see above
        | writer.cpp | see above
        | flexvideo.cpp | see above
    - Misc
        | CMakeLists.txt | the build script; the lines you might want to change are 17-19 where the targets are defined
        | MacBookAir5,2.yml | camera calibration matrix for my camera (see [Usage/Acquisition](#acquisition) above for how to DIY)
- Learning
    | fit.m | fits a helix from data (see [Theory](#theory) above)
    | read.m | reads in a data file created by the acquisition program (see [Hacking/Formats](#formats) below)
    | makehelix.m | generates a helix, given parameters, for testing
    | R.m, T.m, crossm.m | little math functions that I wrote
    | find\_center.m, circfit.m, circfitrobust.m | circle fitting (see [Theory](#theory) above)
    | laprnd.m, planePoint.m | functions from the File Exchange

CONTRIBUTING
============
Contributions welcome, though I doubt anyone is really interested. The project is not on Github (I committed some multi-GB datasets and they got annoyed, and I haven't gotten around to cleaning that out) so email is the way to go. This documentation may be out of date depending on my academic career, conference schedules, and funding, so please [contact me](mailto:aburka@seas.upenn.edu) with questions.

REFERENCES
==========
[Project website](http://www.alexburka.com/penn/manip.html)

