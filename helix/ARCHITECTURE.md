Architecture
============
This file describes the "current" architecture of the C++ implementation of the
helix solver. Of course the docs will be older than the code. But at tagged
versions, at least, this should be up to date. The goal is for this document to
explain the structure and code flow enough that someone unfamiliar with the
project would jump and fix a bug, change optimization algorithms, etc. Things
that such a person _would_ need to be familiar include:

- C++ (I use a bit of Boost but it is documented here)
- OpenCV and computer vision in general (if not... why are you here?)

I don't know much about

- concurrency
- optimization algorithms

...so I'll write about my use of those things here, partly for rubber duck
debugging, partly so that someone more knowledgeable could read this and tell me
where I screwed up.

Overall architecture
====================
The various functions of the program called "acquire" are:

- reading images from a source
    - this can be a camera, a video (depending on platform; on OSX it is
      practically impossible to find a video format that OpenCV will read), or a
      sequence of image files with the frame index in the filename
    - input images are shown live on the screen
    - this is not optional; acquire has nothing to do if there is no input
- finding Aruco tags in the input
    - tags are also shown onscreen, next to the clean input
    - optional
- running the helix solver
    - obviously you need tags to have data for the solver
    - the solver is run on every pair of tracked points (i.e. tags)
        - in the future, there will be a heuristic so that unlikely connections
          will be thrown out (we will search for the minimum spanning tree, like
          in the Kinematic Arboretum).
        - in the case of success, the results are visualized onscreen
    - at present, solver output is not saved anywhere
        - the above is technically false. as a debugging "feature", the solver
          results for one tag pair are left over in the file test.mat in the
          current directory. this file can be loaded in Octave, and its
          parameters passed to draw.m, to get a better visualization
    - optional, triggered by keypress at runtime
- writing images somewhere
    - much like reading, this can be a video or a sequence of image files (also
      like reading, using actual video files is completely untested because of
      the aforementioned OSX issue)
    - two versions are written: "clean", which is a copy of the input, and
      "dirty", which has the tags marked
    - this is optional; in fact acquire runs much faster when writing is
      disabled

Concurrency Model
=================
I make heavy use of threads so that the various phases of computation do not
slow each other down when they don't have to. At present the program runs in six
threads: one main thread which does setup, launches the others and handles
keypresses, and five worker threads which do various things. My thread base
class is `WorkerThread` and it is defined in `acquire.h` (really should move
that out of the header, so that changing it doesn't trigger a full rebuild). It
mostly wraps a `boost::thread`, with some conveniences:

- The public interface consists of:
    - a `setup()` method which must be called before starting the thread; this
      function actually does not appear in `WorkerThread`, but the derived
      classes all implement it, with various parameters. **note**: `setup()`
      runs on the _main thread_!
    - a `start()` method which starts the thread. you can theoretically have it
      set thread attributes, by passing an array of function pointers to
      `pthread_attr_setX` and another array of their integer parameters. I
      intended to use this to set thread priorities, but ended up not doing
      that, so that part is rather untested. It compiles, though.
    - a `kill()` method which tells the thread to hurry up and quit. it then
      runs `cleanup()` (see below) and returns.
    - `is_running()` which just checks whether you're in between `start()` and
      `kill()`
- Internally, the model for derived worker thread classes is inspired by the
  Arduino environment. The child must implement `setup()` (optional), `loop()`,
  and `cleanup()` (required, but may do nothing). As the names suggest, `loop()`
  is called continuously until the thread wants to quit or someone else
  interrupts it (calls `kill()`), and `cleanup()` is called after the final call
  to `loop()`. As covered above, `setup()` should be called on the main thread
  before the worker thread is started.
    - `loop()` returns a boolean; if it is false, `cleanup()` is called and the
      thread terminates
    - `loop()` takes a boolean parameter, "lameduck". If it is true, then
      someone has interrupted the thread and the worker thread should be
      finishing up. **note**: the thread does not actually exit until `loop()`
      return false!
    - `WorkerThread` calcultes the FPS of the `loop()` function and prints it as
      the thread is exiting
    - `cout` and `cerr` should be passed to the `WorkerThread` constructor.
      Derived classes will also pass a string prefix such as "worker thread" to
      the base constructor. The protected methods `tout()` and `terr()` can be
      called internally and used like `cout` and `cerr`, except they prepend
      "[worker thread]".
         - In theory, these streams might not be line-buffered and writing to
           them from many threads at once could be a Bad Idea. In practice, it
           works on my machine.
         - It is often desirable to turn off output from one or more threads.
           This can be accomplished by creating an ofstream and passing it to
           the `WorkerThread` constructor, _without opening any file_. As long
           as the thread does not look too hard at what the stream objects
           actually are, writes to the unopened ofstream will simply evaporate.

Inter-thread communication is handled by a maze of thread-safe queues. The
`concurrent_queue` implementation is one that I found online and modified
slightly.

   - Each queue holds objects of one type only. I have defined several types of
     packets in `packet.h`, with a culinary metaphor.
   - Threads that construct packets call `concurrent_queue::push`.
   - Threads that consume packets usually call
     `concurrent_queue::wait_and_pop`, which blocks, or sometimes
     `concurrent_queue::try_pop`, which does not block. Currently I only use
     the latter on the graphics thread, which needs to listen on two queues at
     once.
   - I needed a way to send out-of-band commands (not full packets) from the
     main thread to the worker threads. This is because the main thread
     receives keypresses (because GUIs are annoying) and has to tell the
     graphics and fitter threads what to do. So I bolted "signaling" onto the
     queue implementation. Setting a signal is synchronized in the same way as
     a push, but the signal state (an integer) is tracked separately. New
     signals are ORed together with the ones already there (so the signals
     should be flags, like 1, 2, 4, 8, ...). When the queue consumer gets
     around to calling `wait_and_pop`, the signal state is returned and cleared
     (`try_pop` is not included in this scheme!).
   - I need to move to a thread communication model that does not involve n*m
     queues, where n is the number of message types and m is the number of
     threads. For one, that's too many queues; for another, there's no good way
     to `wait_and_pop` on more than one queue (see the graphics thread); and
     lastly, the signaling hack is required for communicating from the main
     thread to worker threads. What I am thinking is streamlining all the
     message types into one kind of variant packet, and then every thread will
     have one input queue and one output queue. The commands that now use
     signals would be just a type of message. You'd have to have all threads'
     queues available to everyone, and each thread would have to know which
     threads it was communicating with, which seems worse than the current
     state, where all they have is a reference to a comms channel (hmm... port
     to Go?). Or it could be more of an RPC model where different message types
     invoke different member functions on the thread class. Still thinking...

Here is a picture of all the threads, courtesy of Asciiflow.

      +-----------+
      |main thread|
      +-----------+

      +-------------+    qwp    +----------------+    qpw    +-------------+
      |camera thread|+--------->|processor thread|+--------->|writer thread|
      +-------------+           +----------------+           +-------------+
                                        +     +
                                        |     |     qpg
                                     qpf|     +--------------+
                                        |                    |
                                        v                    v
                                 +-------------+          +---------------+
                                 |fitter thread|+-------->|graphics thread|
                                 +-------------+   qfg    +---------------+


- The main thread parses the command line, sets everything up including the mess
  of queues shown in the diagram, and starts all the threads. If Ctrl-c or Esc
  is pressed, it kills all the threads. When certain other keys are pressed, it
  signals certain threads.
- The camera thread (watcher.cpp) gathers clean images from the camera and posts
  them on a queue. It does absolutely nothing else, so that the frame rate
  should not be affected by variable processing delays in other threads. In fact
  it goes so fast doing this that it has to throttle itself.
- The processor thread takes clean images from the camera and finds Aruco tags
  in them. It draws the spiffy 3D boxes and axes on the tags, making a dirty
  image. Then it pushes out the clean/dirty pair to the other three threads for
  further processing.
- The writer threads writes images to disk. This is slow and tends to drag down
  the rest of the program, too. (This is where I had hoped to use thread
  priorities, but it seemed complicated and non-portable so I gave up.) The
  writer thread has the archetypical use of "lameduck": the thread only stops
  looping when the queue is empty _and_ lameduck is true. The queue could be
  empty if the writer thread gets ahead of the camera and processing threads (if
  you see this happen, you should quit CV to work full time on your hard drive
  business) then the queue could be empty, but the thread should keep waiting
  for images. On the other hand, even after the user has pressed Ctrl-c or Esc,
  the writer thread needs to finish flushing the queue to disk.
- The fitter thread runs the helix solver. Most of the time it just sits around
  recording tag positions into a big Nx3 matrix (signal Fitter::CLEAR resets
  this matrix), but when it gets signaled with a Fitter::FIT then it runs the
  helix solver. Results are passed onto the graphics thread.
- The graphics thread draws stuff on the screen. It slaps the clean and dirty
  images side-by-side. Also, trails are drawn showing the previous positions of
  all the tags, and visualizations of the fitted joints, if any arrive from the
  fitter thread (Graphics::CLEAR erases both). The graphics thread remembers the
  most recent set of fits so that it can draw it on top of every dirty frame.
  For the purpose of cheating during demos, the graphics thread responds to
  Graphics::SAVE to dump those fits to a file, and Graphics::LOAD to load them,
  ignoring the current data. The graphics thread is only one that needs to wait
  on two queues, and it's clumsy. `wait_and_pop` is used with qpg, because it
  sends a packet for every image, and only in between frames does it check qfg.
  Also of note: the graphics thread calls `cv::imshow` to put an image on the
  screen. Usually you have to call `cv::waitKey` right after that to make the
  window update, because highgui is a piece of shit. But since OSX is also quite
  finicky, calling `cv::waitKey` on a background thread is a Terrible Idea.
  Therefore, the main thread assumes this job.

Computer Vision
===============
There is actually not a whole lot of hardcore computer vision in the project at
this time. We are sidestepping the entire issue of object detection and tracking
by instrumenting the environment. For this we use Aruco tags (mostly because of
the author's initial ignorance of APRIL tags) which come with a library that
does robust, relatively fast detection and provides 6DOF localization of the
tags with only a 2D image. In the future, of course, we will use a Kinect and
magical feature tracking to eliminate the need to instrument the environment.
Yeah. For now, the tags.

There is an API (that's the new trendy word for a dynamic URL, right?) at
http://alexburka.com/aruco to get tags for printing. The parameters are _n_, a
comma-separated list of tag numbers from 0-1023, and optional _w_, the width of
the tags, e.g. http://alexburka.com/aruco/?n=3,4,5,6&w=75.

Optimization
============
The steps of the optimization are:

1. Given: an Nx3 array of relative translations between two tags.
2. Run PCA on the rows to determine the three principal axes of the data. These
   will be our three starting candidates for the helix axis.
3. For each candidate, initialize a Projection with that axis. This creates a
   plane normal to the axis, projects the helix onto the plane, and evaluates
   the circularity of the projected points.
4. Choose the candidate with the most circular projected point cloud.
5. Run nonlinear optimization to refine the axis and the origin, with
   circularity of projected point cloud as the objective function.
6. Now we (hopefully) have a good axis, so we slide the origin to the "bottom"
   of the helix along that axis.
7. Calculate the helix pitch and radius.

