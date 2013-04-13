module(..., package.seeall)

require 'torch'

require 'utils'
require 'geometry'
require 'joints'
require 'data'

--- the main package: learning kinematics from computer vision.

--- calculate the relative trajectory between two features
-- @param X (tensor FxNx4x4) trajectory matrix
-- @param a (int) first feature
-- @param b (int) second feature
-- @return deltas (tensor Fx4x4) relative trajectory
local function calc_deltas(X, a, b)
end

--- learn a kinematic tree from a trajectory matrix
-- @param X (tensor FxNx4x4) trajectory matrix
-- @return kinematic tree
function learn(X)
end

