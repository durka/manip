--- Kinematics.
-- the main package: learning kinematics from feature trajectories

local utils = require 'utils'
import 'optim'

utils.module 'kinematics'
utils.import('geometry', 'SE')
utils.import 'joints'
utils.import 'data'

--- calculate the relative trajectory between two features
-- @param X (tensor FxNx4x4) trajectory matrix
-- @param a (int) first feature
-- @param b (int) second feature
-- @return deltas (tensor Fx4x4) relative trajectory
-- @return t1, r1, t2, r2, t3, r3
function calc_deltas(X, a, b)
    local deltas = torch.Tensor(X:size(1), X:size(3), X:size(4))
    for i = 1,X:size(1) do
        deltas[i] = X[{i,b}] * torch.inverse(X[{i,a}])
    end
    local t1, r1 = SE:new(deltas[1]):extract()
    local t2, r2 = SE:new(deltas[deltas:size(1)/2]):extract()
    local t3, r3 = SE:new(deltas[deltas:size(1)]):extract()
    return deltas, t1, r1, t2, r2, t3, r3
end

local function learn_joint(X, pair)
    local deltas, t1, r1, t2, r2, t3, r3 = calc_deltas(X, unpack(pair))

    print(string.format('\t%d-%d', pair[1], pair[2]))

    local params = {}
    for _,J in pairs(joints.types) do
        print(string.format('\t\t%s', J.name))
        local p = J:guess(deltas, t1, r1, t2, r2, t3, r3)
        print(string.format('\t\t\t#p = %d', p:size(1)))
    end

    return {a = pair[1], b = pair[2], params = 'ENOIMPL'}
end

--- learn a kinematic tree from a trajectory matrix
-- @param X (tensor FxNx4x4) trajectory matrix
-- @return kinematic tree
function learn(X, specifics)
    local S = {}

    local n = X:size(2)

    if specifics then
        print 'Fitting all models to given joints...'
        for _,pair in pairs(specifics) do
            table.insert(S, learn_joint(X, pair))
        end
    else
        print 'Fitting all models to all possible joints...'
        for a = 1,n do
            for b = a+1,n do
                table.insert(S, learn_joint(X, {a,b}))
            end
        end
    end

    print 'Fixing up the indices...'

    print 'Finding minimum spanning tree...'

    print 'Removing rigid subclusters...'

    print 'Fixing up the indices again...'

    print 'Done learning!'
    return S
end

return kinematics

