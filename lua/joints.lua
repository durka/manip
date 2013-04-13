require 'torch'
require 'utils'
require 'geometry'

Rigid = {}

function Rigid:new(p)
    return setmetatable({p = torch.Tensor(p)}, {__index = Rigid})
end

function Rigid:unpack()
    return {offset = SE:new(3)
                       :T(self.p[{ {1,3} }])
                       :R_euler('ZYZ', self.p[{ {4,6} }])}
end

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

function Rigid:guess(deltas, t1, r1, t2, r2, t3, r3)
    return {t = t1, r = r1}
end

