import os
import dynamixel
import time
import random
import sys
import subprocess
import functools
import pprint


def cmd_help(command):
    print """
Dynamixel Control Interface

Commands:
    h               print this help message
    q               quit
                    repeat last command (just press enter)
    r [id]*         read positions (if no arguments, read all)
    g [id]*         show goal positions (if no arguments, read all)

    S               EMERGENCY STOP (all motors)

    s [id goal]*    set positions
                      no arguments: set all to zero
                      one argument: set all
                      otherwise, set motors to given values
                        e.g. 's 1 512 2 256'
    a [id rgoal]+   set relative positions
                      DANGER be careful that you don't make the motors fight each other!

    J [name [id sign]*]    set up a joint (do a read just before)
                             no arguments: list all joints
                             one argument: show that joint
                             otherwise, define a joint
                               e.g. 'J base 1 +' or 'J shoulder 2 + 3 -'

    H [name]*              re-home joint(s) (do a read just before)

    j [name rgoal?]*       set joint positions
                             no arguments: set all joints to home
    k [name rgoal?]*       set relative joint positions
                             no arguments: set all joints to home

    z [seconds]?    sleep (no argument: 1 second)
    m [speed]?      set speed (default 20)

    L filename      load script
"""

def cmd_read(command, **opts):
    if not command:
        targets = [[aid] for aid in actuator_ids]
    else:
        targets = check(command, [int, actuator_ids])
    net.synchronize()
    for aid in targets:
        net[aid[0]].read_all()
        time.sleep(0.01)
    for aid in targets:
        if opts['goal']:
            print net[aid[0]].cache[dynamixel.defs.REGISTER['Id']], net[aid[0]].cache[dynamixel.defs.REGISTER['GoalPosition']]
        else:
            print net[aid[0]].cache[dynamixel.defs.REGISTER['Id']], net[aid[0]].cache[dynamixel.defs.REGISTER['CurrentPosition']]

def cmd_stop(command):
    for aid in actuator_ids:
        net[aid].stop()
    net.synchronize()

def cmd_move(command, **opts):
    if not command:
        cmds = [[aid, 0] for aid in actuator_ids]
    elif len(command) == 1:
        cmds = [[aid, int(command[0])] for aid in actuator_ids]
    else:
        cmds = check(command, [int, actuator_ids], [int, xrange(-1023, 1024)])
    net.synchronize()
    for aid, goal in cmds:
        net[aid].moving_speed = MOVING_SPEED
        if opts['relative']:
            net[aid].goal_position += goal
        else:
            net[aid].goal_position = goal
    net.synchronize()


def cmd_makejoint(command):
    if not command:
        pprint.pprint(joints)
    elif len(command) == 1:
        pprint.pprint(joints[command[0]])
    else:
        joints[command[0]] = []
        for aid, sign in check(command[1:], [int, actuator_ids], [str, ['+', '-']]):
            net[aid].read_all()
            time.sleep(0.01)
            joints[command[0]].append({
                'id': aid,
                'home': net[aid].cache[dynamixel.defs.REGISTER['CurrentPosition']],
                'sign': sign})

def cmd_homejoint(command):
    if not command:
        cmds = [[n] for n in joints.keys()]
    else:
        cmds = check(command, [str, joints.keys()])

    for cmd in cmds:
        for motor in joints[cmd[0]]:
            motor['home'] = net[motor['id']].cache[dynamixel.defs.REGISTER['CurrentPosition']]

def cmd_movejoint(command, **opts):
    if not command:
        cmds = [[k, 0] for k in joints.keys()]
    elif len(command) == 1:
        cmds = [[command[0], 0]]
    else:
        cmds = check(command, [str, joints.keys()], [int, xrange(-1023, 1024)])

    print cmds, MOVING_SPEED
    net.synchronize()
    for cmd in cmds:
        for actuator in joints[cmd[0]]:
            net[actuator['id']].moving_speed = MOVING_SPEED
            if opts['relative']:
                net[actuator['id']].goal_position += {'+':1, '-':-1}[actuator['sign']] * cmd[1]
            else:
                net[actuator['id']].goal_position = actuator['home'] + {'+':1, '-':-1}[actuator['sign']] * cmd[1]
    net.synchronize()


def cmd_setspeed(command):
    global MOVING_SPEED

    if not command:
        speed = MOVING_SPEED
    else:
        speed = check(command, [int, xrange(0, 100)])[0][0]

    MOVING_SPEED = speed


def cmd_sleep(command):
    if not command:
        t = 1
    else:
        t = check(command, [int, xrange(0, 100)])[0][0]

    time.sleep(t)


def check(command, *spec):
    if len(command) % len(spec):
        raise Exception('wrong number of arguments: %d is not a multiple of %d' % (len(command), len(spec)))

    cmds = []
    for i in range(0, len(command), len(spec)):
        cmd = [None]*len(spec)
        for j in range(len(spec)):
            try:
                cmd[j] = spec[j][0](command[i+j])
            except Exception, e:
                raise Exception('bad argument "%s": %s' % (str(command[i+j]), e))
            if cmd[j] not in spec[j][1]:
                raise Exception('bad argument "%s": not in %s' % (str(cmd[j]), str(spec[j][1])))
        cmds.append(cmd)
    
    return cmds


def interpret(command):
    try:
        {
                'h': cmd_help,
                'r': functools.partial(cmd_read, goal=False),
                'g': functools.partial(cmd_read, goal=True),
                'S': cmd_stop,
                's': functools.partial(cmd_move, relative=False),
                'a': functools.partial(cmd_move, relative=True),
                'J': cmd_makejoint,
                'H': cmd_homejoint,
                'j': functools.partial(cmd_movejoint, relative=False),
                'k': functools.partial(cmd_movejoint, relative=True),
                'm': cmd_setspeed,
                'z': cmd_sleep,
        }[command[0]](command[1:])
    except Exception, e:
        print 'Bad command!', e


def main():
    global net, joints, actuator_ids, MOVING_SPEED

    ###############################################################################
    # The end point of the servos we will scan for.
    #
    # If you have servos with ids 3, 12, and 15 this value should be 15.
    # This will scan at approximately one servo id a second so don't worry if it
    # takes a little bit.
    lastServoId = 6

    ###############################################################################
    # The motor speed
    MOVING_SPEED = 20

    # Set your serial port accordingly.
    if os.name == "posix":
      portName = '/dev/tty.usbserial-A600cUyC'
      if not portName:
        print ('You will need to edit this example and set a value for "portName".\n'
              'Here are a few possible ports you might want to try if you do not\n'
              'know exactly where your USB2Dynamixel is attached:')
        # Get a list of ports that mention USB
        possiblePorts = subprocess.check_output('ls /dev/*usb*', shell=True).split()
        for port in possiblePorts:
          print '\t' + port
        sys.exit(1)
    else:
        portName = "COM11"

    # Default baud rate of the USB2Dynamixel device.
    baudRate = 1000000

    serial = dynamixel.SerialStream( port=portName, baudrate=baudRate, timeout=1)
    net = dynamixel.DynamixelNetwork( serial )

    print "Scanning for Dynamixels... (~16 seconds)"
    actuator_ids = []
    net.scan( 1, lastServoId )
    for dyn in net.get_dynamixels():
        print dyn.id
        actuator_ids.append(dyn.id)

    print "...Done"

    for actuator in net.get_dynamixels():
        actuator.moving_speed = MOVING_SPEED
        actuator.synchronized = True
        actuator.torque_enable = True
        actuator.torque_limit = 800
        actuator.max_torque = 800

    prev_command = ['q']
    joints = {}

    while True:
        command = raw_input('Command: ').split()
        if not command:
            print 'Re-send:', ' '.join(prev_command)
            command = prev_command
        if command[0] == 'q':
            break
        elif command[0] == 'L':
            for line in open(command[1], 'r').readlines():
                cmd = line.split('#')[0] # strip comments
                cmd = cmd.split()
                if not (len(cmd) == 0 or cmd[0][0] == '#'):
                    print 'Sending:', ' '.join(cmd)
                    interpret(cmd)
        else:
            interpret(command)

        prev_command = command


if __name__ == '__main__':
    main()


