module(..., package.seeall)

require 'torch'
require 'utils'
require 'geometry'

--- kinematic joint definitions.
-- the class interface is:
--   new
--   unpack
--   forward
--   inverse
--   guess
--   reverse
--   move
-- TODO how to enforce interfaces in Lua

--- rigid joint class.
-- ONLY 3D (TODO 2D)
-- @field p (tensor 6) the joint parameters
Rigid = {}

--- constructor.
-- @param p (tensor 6 or numeric array(6)) the joint parameters
function Rigid:new(p)
    return setmetatable({p = torch.Tensor(p)}, {__index = Rigid})
end

--- unpack joint parameters.
-- @return table of { offset (SE) }
function Rigid:unpack()
    return {offset = SE:new(3)
                       :T(self.p[{ {1,3} }])
                       :R_euler('ZYZ', self.p[{ {4,6} }])}
end

--- forward kinematics.
-- @param state
-- @param jacobian non-nil if the Jacobians should be calculated
-- @return x
-- @return Dr (if jacobian is non-nil)
-- @return Dt (if jacobian is non-nil)
function Rigid:forward(state, jacobian)
    p = self:unpack()

    -- rigid forward kinematics: no-op
    x = p.offset.m

    if jacobian then
        t, r = p.offset:extract()
        if #t == 2 then
            Dr = torch.Tensor{{0, 0, -math.sin(r[1]), 0},
                              {0, 0, -math.cos(r[1]), 0},
                              {0, 0,  math.cos(r[1]), 0},
                              {0, 0, -math.sin(r[1]), 0}}
            Dt = torch.Tensor{{1, 0, 0, 0},
                              {0, 1, 0, 0}}
        else
            Dr = torch.Tensor{{0, 0, 0,       -math.cos(r[1])*math.sin(r[3]) - math.cos(r[2])*math.cos(r[3])*math.sin(r[1]),      -math.cos(r[1])*math.cos(r[3])*math.sin(r[2]),       -math.cos(r[3])*math.sin(r[1]) - math.cos(r[1])*math.cos(r[2])*math.sin(r[3]),      0},
                              {0, 0, 0,       -math.sin(r[1])*math.sin(r[3]) + math.cos(r[1])*math.cos(r[2])*math.cos(r[3]),      -math.cos(r[3])*math.sin(r[1])*math.sin(r[2]),       -math.cos(r[2])*math.sin(r[1])*math.sin(r[3]) + math.cos(r[1])*math.cos(r[3]),      0},
                              {0, 0, 0,        0,                                                                                  math.cos(r[2])*math.cos(r[3]),                      -math.sin(r[2])*math.sin(r[3]),                                                     0},
                              {0, 0, 0,       -math.cos(r[1])*math.cos(r[3]) + math.cos(r[2])*math.sin(r[1])*math.sin(r[3]),       math.cos(r[1])*math.sin(r[2])*math.sin(r[3]),        math.sin(r[1])*math.sin(r[3]) - math.cos(r[1])*math.cos(r[2])*math.cos(r[3]),      0},
                              {0, 0, 0,       -math.cos(r[3])*math.sin(r[1]) - math.cos(r[1])*math.cos(r[2])*math.sin(r[3]),       math.sin(r[1])*math.sin(r[2])*math.sin(r[3]),       -math.cos(r[1])*math.sin(r[3]) - math.cos(r[2])*math.cos(r[3])*math.sin(r[1]),      0},
                              {0, 0, 0,        0,                                                                                 -math.cos(r[2])*math.sin(r[3]),                      -math.cos(r[3])*math.sin(r[2]),                                                     0},
                              {0, 0, 0,        math.sin(r[1])*math.sin(r[2]),                                                     -math.cos(r[1])*math.cos(r[2]),                       0,                                                                                 0},
                              {0, 0, 0,       -math.cos(r[1])*math.sin(r[2]),                                                     -math.cos(r[2])*math.sin(r[1]),                       0,                                                                                 0},
                              {0, 0, 0,        0,                                                                                 -math.sin(r[2]),                                      0,                                                                                 0}}
            Dt = torch.Tensor{{1, 0, 0,    0, 0, 0,   0},
                              {0, 1, 0,    0, 0, 0,   0},
                              {0, 0, 1,    0, 0, 0,   0}}
        end
        return x, Dr, Dt
    else
        return x
    end
end

--- inverse kinematics.
-- @param x
-- @param jacobian (non-nil if Jacobian should be calculated)
-- @return state
-- @return D (if jacobian is non-nil)
function Rigid:inverse(x, jacobian)
    state = 0; -- rigid joints have no state

    if jacobian then
        n = x:size(1)-1
        d = n*(n+1)/2
        D = torch.cat(torch.eye(d), torch.zeros(1,d), 1)
        return state, D
    else
        return state
    end
end

--- guess parameters from data.
-- @param deltas
-- @param t1
-- @param r1
-- @param t2
-- @param r2
-- @param t3
-- @param r3
-- @return (tensor 6) guessed parameters
function Rigid:guess(deltas, t1, r1, t2, r2, t3, r3)
    return torch.cat(t1, r1)
end

