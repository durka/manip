% in 2D and 3D
%   params{1} SE(n) is the offset from the from-object center to the to-object center
function [x, Dr, Dt] = forward_rigid(p, ~)
    if iscell(p)
        params = p;
    else
        [params, t, r] = unpack_rigid(p);
    end
    x = params{1};
    
    if nargout > 1
        if iscell(p)
            [t, r] = extract_SE(params{1});
        end
        if length(t) == 2
            Dr = [ 0 0 -sin(r) 0
                   0 0 -cos(r) 0
                   0 0  cos(r) 0
                   0 0 -sin(r) 0 ];
            Dt = [ 1 0 0 0
                   0 1 0 0 ];
        else
            Dr = [ 0, 0, 0,       -cos(r(1))*sin(r(3)) - cos(r(2))*cos(r(3))*sin(r(1)),      -cos(r(1))*cos(r(3))*sin(r(2)),       -cos(r(3))*sin(r(1)) - cos(r(1))*cos(r(2))*sin(r(3)),      0
                   0, 0, 0,       -sin(r(1))*sin(r(3)) + cos(r(1))*cos(r(2))*cos(r(3)),      -cos(r(3))*sin(r(1))*sin(r(2)),       -cos(r(2))*sin(r(1))*sin(r(3)) + cos(r(1))*cos(r(3)),      0
                   0, 0, 0,        0,                                                         cos(r(2))*cos(r(3)),                 -sin(r(2))*sin(r(3)),                                      0
                   0, 0, 0,       -cos(r(1))*cos(r(3)) + cos(r(2))*sin(r(1))*sin(r(3)),       cos(r(1))*sin(r(2))*sin(r(3)),        sin(r(1))*sin(r(3)) - cos(r(1))*cos(r(2))*cos(r(3)),      0
                   0, 0, 0,       -cos(r(3))*sin(r(1)) - cos(r(1))*cos(r(2))*sin(r(3)),       sin(r(1))*sin(r(2))*sin(r(3)),       -cos(r(1))*sin(r(3)) - cos(r(2))*cos(r(3))*sin(r(1)),      0
                   0, 0, 0,        0,                                                        -cos(r(2))*sin(r(3)),                 -cos(r(3))*sin(r(2)),                                      0
                   0, 0, 0,        sin(r(1))*sin(r(2)),                                      -cos(r(1))*cos(r(2)),                  0,                                                        0
                   0, 0, 0,       -cos(r(1))*sin(r(2)),                                      -cos(r(2))*sin(r(1)),                  0,                                                        0
                   0, 0, 0,        0,                                                        -sin(r(2)),                            0,                                                        0 ];
            Dt = [ 1 0 0    0 0 0   0
                   0 1 0    0 0 0   0
                   0 0 1    0 0 0   0 ];
        end
    end
end
