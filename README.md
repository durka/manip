Installation
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


Usage
=====
Acquisition
-----------
1. Get usage information:

    $ acquire
    $ acquire -h

2. Capture images from a camera with some generic settings:

    $ acquire -o capture -m 10

This outputs the clean and dirty images in the current directory (with a "capture\_" prefix), as well as the data log in capture.txt. The marker size is set to 10 (this doesn't affect anything if you don't have measurements anyway). The capture will run until you press Ctrl-C in the terminal, at which point the program will finish writing images to disk and then quit.

Helix fitting
-------------
1. Read in some data (ya gotta acquire it first)

    > X = read('data/capture.out')

2. Fit the data to a helix

Let's assume you're interested in the motion of the first feature, relative to the camera frame. (Relative motion between features will come later.)

    > f1 = figure; f2 = figure;
    > fit(squeeze(X(:,1,1:3,4)), f1, f2)

Hacking
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

Contributing
============
Contributions welcome, though I doubt anyone is really interested. The license is MIT. This documentation may be out of date depending on my academic career, conference schedules, and funding, so please [contact me](mailto:aburka@seas.upenn.edu) with questions.

References
==========
[Project website](http://www.alexburka.com/penn/manip.html)

