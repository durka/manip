module(..., package.seeall)

require 'torch'

require 'utils'
require 'geometry' local SE = geometry.SE
require 'joints'
require 'data'

--- the main package: learning kinematics from computer vision.

--- calculate the relative trajectory between two features
-- @param X (tensor FxNx4x4) trajectory matrix
-- @param a (int) first feature
-- @param b (int) second feature
-- @return deltas (tensor Fx4x4) relative trajectory
-- @return t1, r1, t2, r2, t3, r3
--[[local--]] function calc_deltas(X, a, b)
    local deltas = torch.Tensor(X:size(1), X:size(3), X:size(4))
    for i = 1,X:size(1) do
        deltas[i] = X[{i,b}] * torch.inverse(X[{i,a}])
    end
    t1, r1 = SE:new(deltas[1]):extract()
    t2, r2 = SE:new(deltas[deltas:size(1)/2]):extract()
    t3, r3 = SE:new(deltas[deltas:size(1)]):extract()
    return deltas, t1, r2, t2, r2, t3, r3
end

--- learn a kinematic tree from a trajectory matrix
-- @param X (tensor FxNx4x4) trajectory matrix
-- @return kinematic tree
function learn(X)
end

