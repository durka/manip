require 'torch'

SE = {}

function SE:new(n)
    return setmetatable({n = n,
                         m = torch.eye(n+1)},
                        {__index = SE})
end

function SE:reset()
    self.m = torch.eye(self.n+1)
    return self
end

function SE:extract()
    if self.n == 2 then
        t = self.m[{ {1,2}, {3} }]
        r = torch.Tensor{math.atan2(self.m[{2,1}], self.m[{1,1}])}
    elseif self.n == 3 then
        t = self.m[{ {1,3}, {4} }]
        -- 3-1-3 Euler Angles http://en.wikipedia.org/wiki/Rotation_formalisms_in_three_dimensions#Conversion_formulae_between_formalisms
        if math.abs(self.m[{3,3}] - 1) <= math.eps then -- i.e. sin(b) = 0
            r = torch.Tensor{0, 0, math.atan2(-self.m[{1,2}], self.m[{1,1}])}
        else
            r = torch.Tensor{0, 0, 0};
            r[2] = math.atan2(math.sqrt(self.m[{1,3}]^2+self.m[{2,3}]^2), self.m[{3,3}])
            if r[2] < 0 then
                r[1] = math.atan2(self.m[{2,3}], self.m[{1,3}])
                r[3] = math.atan2(self.m[{3,2}], self.m[{3,1}]);
            else
                r[1] = math.atan2(-self.m[{2,3}], -self.m[{1,3}]);
                r[3] = math.atan2(-self.m[{3,2}],  self.m[{3,1}]);
            end
        end
    end
    return t, r
end

function SE:T(t)
    self.m[{ {1,self.n}, self.n+1 }] = torch.Tensor(t)
    return self
end

function SE:R_euler(euler, r)
    Raxis = {
             X = function (theta) return torch.Tensor{{1, 0,                0},
                                                      {0, math.cos(theta), -math.sin(theta)},
                                                      {0, math.sin(theta),  math.cos(theta)}} end,
             Y = function (theta) return torch.Tensor{{math.cos(theta), 0, -math.sin(theta)},
                                                      {0,               1,  0},
                                                      {math.sin(theta), 0,  math.cos(theta)}} end,
             Z = function (theta) return torch.Tensor{{math.cos(theta), -math.sin(theta), 0},
                                                      {math.sin(theta),  math.cos(theta), 0},
                                                      {0,                0,               1}} end
            }
    for i = 1,r:size(1) do
        self.m[{ {1,3}, {1,3} }] = self.m[{ {1,3}, {1,3} }] * Raxis[string.sub(euler, i, i)](r[i])
    end
    return self
end

function SE:R_axis(axis)
    angle = math.sqrt(torch.sum(torch.Tensor(axis):pow(2)))
    axis = torch.Tensor(axis)/angle
    self.m[{ {1,3}, {1,3} }] = torch.eye(3)*math.cos(angle) + torch.crossm(axis)*math.sin(angle) + torch.reshape(axis, 3,1)*torch.reshape(axis, 1,3)*(1 - math.cos(angle))
    return self
end

