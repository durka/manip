## define the joints on the arm

# read first to cache the positions
r

# base joint
J base 1 +

# the two joints that actually require coordination
J shoulder 2 + 3 -
J elbow 4 - 5 +

# last joint
J wrist 6 +

# TODO gripper not implemented for now (not plugged in)

# display the finished joints
J

