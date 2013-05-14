--- classes and functions for wrangling rigid motions.
-- TODO overload operators

local utils = require 'utils'

utils.module 'geometry'

--- class to represent a rigid motion in N dimensions.
-- @field n (int) number of dimensions (2 or 3)
-- @field m (tensor (n+1)x(n+1)) matrix representation
SE = {}

--- constructor.
-- @param n_or_m [n (int) number of dimensions] OR [m (tensor (n+1)x(n+1)) matrix representation]
function SE:new(n_or_m)
    if type(n_or_m) == 'number' then
        return setmetatable({n = n_or_m,
                             m = torch.eye(n_or_m+1)},
                            {__index = SE})
    else
        return setmetatable({n = n_or_m:size(1)-1,
                             m = n_or_m},
                            {__index = SE})
    end
end

--- reset to identity.
-- @return self
function SE:reset()
    self.m = torch.eye(self.n+1)
    return self
end

--- distance to another SE.
-- @param rhs (SE) the other SE
-- @param flag (bool) whether to do the gradient
-- @param DD (table) various jacobians
-- @return distance
-- @return gradient
function SE:dist(rhs, flag, DD)
    -- magic scale factors (see, e.g. Park 1995)
    local c = 2
    local d = 1

    local u = self.m
    local v = rhs.m

    local n = u:size(1)-1 -- n as in SE(n)
    
    local ut = u[{{1,n}, n+1}]
    local vt = v[{{1,n}, n+1}]
    local ur = u[{{1,n}, {1,n}}]
    local vr = v[{{1,n}, {1,n}}]
    
    --local dr = ur * vr:i()
    local dt = ut - vt
    --local L = logm_so3(dr)
    --local C = c*L:norm()^2
    local tr
    if n == 3 then
        tr = (ur[{1,1}]*ur[{2,2}]*vr[{3,3}] - ur[{1,1}]*ur[{2,3}]*vr[{3,2}] - ur[{1,1}]*ur[{3,2}]*vr[{2,3}] + ur[{1,1}]*ur[{3,3}]*vr[{2,2}] - ur[{1,2}]*ur[{2,1}]*vr[{3,3}] + ur[{1,2}]*ur[{2,3}]*vr[{3,1}] + ur[{1,2}]*ur[{3,1}]*vr[{2,3}] - ur[{1,2}]*ur[{3,3}]*vr[{2,1}] + ur[{1,3}]*ur[{2,1}]*vr[{3,2}] - ur[{1,3}]*ur[{2,2}]*vr[{3,1}] - ur[{1,3}]*ur[{3,1}]*vr[{2,2}] + ur[{1,3}]*ur[{3,2}]*vr[{2,1}] + ur[{2,1}]*ur[{3,2}]*vr[{1,3}] - ur[{2,1}]*ur[{3,3}]*vr[{1,2}] - ur[{2,2}]*ur[{3,1}]*vr[{1,3}] + ur[{2,2}]*ur[{3,3}]*vr[{1,1}] + ur[{2,3}]*ur[{3,1}]*vr[{1,2}] - ur[{2,3}]*ur[{3,2}]*vr[{1,1}])/(ur[{1,1}]*ur[{2,2}]*ur[{3,3}] - ur[{1,1}]*ur[{2,3}]*ur[{3,2}] - ur[{1,2}]*ur[{2,1}]*ur[{3,3}] + ur[{1,2}]*ur[{2,3}]*ur[{3,1}] + ur[{1,3}]*ur[{2,1}]*ur[{3,2}] - ur[{1,3}]*ur[{2,2}]*ur[{3,1}])
    else
        tr = (ur[{1,1}]*vr[{2,2}] - ur[{1,2}]*vr[{2,1}] - ur[{2,1}]*vr[{1,2}] + ur[{2,2}]*vr[{1,1}])/(ur[{1,1}]*ur[{2,2}] - ur[{1,2}]*ur[{2,1}])
    end
    local C = c*2*math.acos((tr-1)/2)^2 -- from http://en.wikipedia.org/wiki/Axis-angle_representation#Log_map_from_SO.283.29_to_so.283.29
    local D = d*dt:norm()^2
    local dist = C + D;

    if flag then
        if not DD then
            error('To calculate a gradient SE:dist needs gradient inputs')
        else
            --fprintf('SIZES: Dq[%d %d] Dr[%d %d] Dkr[%d %d] Dkt[%d %d] Dki[%d %d]\n', size(Dq(ur,vr),1),size(Dq(ur,vr),2), size(Dr(ut,vt),1),size(Dr(ut,vt),2), size(Dkr,1),size(Dkr,2), size(Dkt,1),size(Dkt,2), size(Dki,1),size(Dki,2));
            local toohigh = 100000
            local dkr = torch.max(torch.min(DD.kr, toohigh), -toohigh)
            local dkt = torch.max(torch.min(DD.kt, toohigh), -toohigh)
            local dki = torch.max(torch.min(DD.ki, toohigh), -toohigh)
            local dq = torch.max(torch.min(DD.q(ur,vr), toohigh), -toohigh)
            local dr = torch.max(torch.min(DD.r(ut,vt), toohigh), -toohigh)
            local grad = c*dq*dkr*dki + d*dr*dkt*dki
            return dist, grad
        end
    else
        return dist
    end
end

--- extract the Lie algebra representation of this rigid motion.
-- @return t (tensor nx1) the translation components
-- @return r (tensor 1 or 3x1) the rotation component(s)
function SE:extract()
    if self.n == 2 then
        t = self.m[{ {1,2}, {3} }]:squeeze()
        r = torch.Tensor{math.atan2(self.m[{2,1}], self.m[{1,1}])}
    elseif self.n == 3 then
        t = self.m[{ {1,3}, {4} }]:squeeze()
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

--- set the translation components of the rigid motion.
-- ONLY 3D (TODO 2D)
-- @param t (tensor n, nx1 or numeric table(n)) the translation components
-- @return self
function SE:T(t)
    self.m[{ {1,self.n}, self.n+1 }] = torch.Tensor(t)
    return self
end

--- set the rotation components from a rotation matrix
-- @param r (tensor (n-1)x(n-1)) rotation matrix
-- @return self
function SE:R(r)
    self.m[{ {1,self.n-1}, {1,self.n-1} }] = r
    return self
end

--- set the rotation components from Euler angles.
-- @param euler (string) order of the Euler angles (e.g. 'XYZ')
-- @param r (tensor (#euler) or (#euler)x1 or numeric array(#euler)) the rotations (in radians)
-- @return self
function SE:R_euler(euler, r)
    Raxis = {
             X = function (theta) return torch.Tensor{{1,               0,                0              },
                                                      {0,               math.cos(theta), -math.sin(theta)},
                                                      {0,               math.sin(theta),  math.cos(theta)}} end,

             Y = function (theta) return torch.Tensor{{math.cos(theta), 0,               -math.sin(theta)},
                                                      {0,               1,                0              },
                                                      {math.sin(theta), 0,                math.cos(theta)}} end,

             Z = function (theta) return torch.Tensor{{math.cos(theta), -math.sin(theta), 0              },
                                                      {math.sin(theta),  math.cos(theta), 0              },
                                                      {0,                0,               1              }} end
            }
    r = torch.Tensor(r)
    for i = 1,r:size(1) do
        self.m[{ {1,3}, {1,3} }] = self.m[{ {1,3}, {1,3} }] * Raxis[string.sub(euler, i, i)](r[i])
    end
    return self
end

--- set the rotation component(s) from OpenCV Rodrigues/axis-angle abomination.
-- ONLY 3D (TODO 2D)
-- @param axis (tensor 3 or 3x1 or numeric array(3)) the rotation vector
-- @return self
function SE:R_axis(axis)
    angle = math.sqrt(torch.sum(torch.Tensor(axis):pow(2)))
    axis = torch.Tensor(axis)/angle
    self.m[{ {1,3}, {1,3} }] = torch.eye(3)                                      * math.cos(angle)
                             + torch.crossm(axis)                                * math.sin(angle)
                             + torch.reshape(axis, 3,1)*torch.reshape(axis, 1,3) * (1 - math.cos(angle))
    return self
end

if package.loaded.gnuplot then
    function SE:plot(title)
        gnuplot.quiver(torch.cat(self.m[{ {1,3},4 }]:clone():repeatTensor(3,1), self.m[{ {1,3},{1,3} }]:t()), title)
    end
end


--- class to represent a 3D plane, utilities for fitting and 
-- @field center (tensor 3) the origin of the plane coordinate system
-- @field x      (tensor 3) unit vector pointing along the plane X axis
-- @field y      (tensor 3) unit vector pointing along the plane Y axis
Plane = {}

--- constructor.
-- @see Plane
function Plane:new(center, x, y)
    return setmetatable({center = center,
                         x = x,
                         y = y},
                        {__index = Plane})
end

--- fit a plane from some 3D points.
-- translated from the geom3d Matlab library (fitPlane)
-- @param points (tensor Nx3) some 3D points
-- @return an instance of Plane
function Plane:fit(points)
    local center = points:mean(1)
    local U, S = points:cov():svd() -- PCA
    local y, i = torch.sort(S, 1, true) -- sort in descending order
    local x = torch.Tensor{U[{i[1],1}], U[{i[2],1}], U[{i[3],1}]}
    local y = torch.Tensor{U[{i[1],2}], U[{i[2],2}], U[{i[3],2}]}
    if x[1] < 0 then
        return Plane:new(center, -x, -y)
    else
        return Plane:new(center, x, y)
    end
end

--- project 3D points into a plane
-- translated from the geom3d Matlab library (planePosition)
-- @param points (tensor Nx3) some 3D points
-- @return (tensor Nx2) the projected points
function Plane:project(points)
    local n = points:size(1)
    local center = self.center:repeatTensor(n,1)
    return torch.cat((points - center) * self.x, (points - center) * self.y, 2)
end

--- get 3D coordinates of points in the plane
-- translated from the geom3d Matlab library (planePoint)
-- @param points (tensor Nx2) some 2D points
-- @return (tensor Nx3) the unprojected points
function Plane:unproject(points)
    local n = points:size(1)
    local output = torch.Tensor(n,3)
    for i = 1,n do
        output[i] = self.center + self.x*points[{i,1}] + self.y*points[{i,2}]
    end
    return output
end

return geometry

