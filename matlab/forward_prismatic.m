% in 2D and 3D
%   params{1} SE(n) is the offset from the from-object center to prismatic joint
%   params{2} R(n)  is the unit vector pointing in the direction of prismaticness
%   state     R     is the extension of the joint
function [x, Dr, Dt] = forward_prismatic(params, state)
    offset = params{1};
    u = params{2};
    pos = state;
    
    x = T(u*pos) * offset;
    
    if nargout > 1
        [t, r] = extract_SE(params{1});
        if length(t) == 2
            Dr = [ 0 0 -sin(r) 0 0 0
                   0 0  cos(r) 0 0 0
                   0 0 -cos(r) 0 0 0
                   0 0 -sin(r) 0 0 0 ];
            Dt = [ 1 0 0 pos 0   u(1)
                   0 1 0 0   pos u(2) ];
        else
            Dr = [ 0, 0, 0, -cos(r(1))*sin(r(3)) - cos(r(2))*cos(r(3))*sin(r(1)), -cos(r(1))*cos(r(3))*sin(r(2)), -cos(r(3))*sin(r(1)) - cos(r(1))*cos(r(2))*sin(r(3)), 0, 0, 0, 0
                   0, 0, 0,  cos(r(1))*cos(r(2))*cos(r(3)) - sin(r(1))*sin(r(3)), -cos(r(3))*sin(r(1))*sin(r(2)),  cos(r(1))*cos(r(3)) - cos(r(2))*sin(r(1))*sin(r(3)), 0, 0, 0, 0
                   0, 0, 0,  0,                                                    cos(r(2))*cos(r(3)),           -sin(r(2))*sin(r(3)),                                 0, 0, 0, 0
                   0, 0, 0,  cos(r(2))*sin(r(1))*sin(r(3)) - cos(r(1))*cos(r(3)),  cos(r(1))*sin(r(2))*sin(r(3)),  sin(r(1))*sin(r(3)) - cos(r(1))*cos(r(2))*cos(r(3)), 0, 0, 0, 0
                   0, 0, 0, -cos(r(3))*sin(r(1)) - cos(r(1))*cos(r(2))*sin(r(3)),  sin(r(1))*sin(r(2))*sin(r(3)), -cos(r(1))*sin(r(3)) - cos(r(2))*cos(r(3))*sin(r(1)), 0, 0, 0, 0
                   0, 0, 0,  0,                                                   -cos(r(2))*sin(r(3)),           -cos(r(3))*sin(r(2)),                                 0, 0, 0, 0
                   0, 0, 0,  sin(r(1))*sin(r(2)),                                 -cos(r(1))*cos(r(2)),            0,                                                   0, 0, 0, 0
                   0, 0, 0, -cos(r(1))*sin(r(2)),                                 -cos(r(2))*sin(r(1)),            0,                                                   0, 0, 0, 0
                   0, 0, 0,  0,                                                   -sin(r(2)),                      0,                                                   0, 0, 0, 0 ];
            Dt = [ 1 0 0 0 0 0 pos 0   0   u(1)
                   0 1 0 0 0 0 0   pos 0   u(2)
                   0 0 1 0 0 0 0   0   pos u(3) ];
        end
    end
end
