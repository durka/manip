% in 2D and 3D
%   params{1} SE(n) is the offset from the from-object center to prismatic joint
%   params{2} R(n)  is the unit vector pointing in the direction of prismaticness
%   state     R     is the extension of the joint
function [state, D] = inverse_prismatic(x, params)
    offset = params{1};
    u = params{2};
    n = length(u);
    
    if n == 3
        state = - (u(1)*(x(1,1)*offset(1,2)*offset(2,3)*offset(3,4) - x(1,1)*offset(1,2)*offset(2,4)*offset(3,3) - x(1,1)*offset(1,3)*offset(2,2)*offset(3,4) + x(1,1)*offset(1,3)*offset(2,4)*offset(3,2) + x(1,1)*offset(1,4)*offset(2,2)*offset(3,3) - x(1,1)*offset(1,4)*offset(2,3)*offset(3,2) - x(1,2)*offset(1,1)*offset(2,3)*offset(3,4) + x(1,2)*offset(1,1)*offset(2,4)*offset(3,3) + x(1,2)*offset(1,3)*offset(2,1)*offset(3,4) - x(1,2)*offset(1,3)*offset(2,4)*offset(3,1) - x(1,2)*offset(1,4)*offset(2,1)*offset(3,3) + x(1,2)*offset(1,4)*offset(2,3)*offset(3,1) + x(1,3)*offset(1,1)*offset(2,2)*offset(3,4) - x(1,3)*offset(1,1)*offset(2,4)*offset(3,2) - x(1,3)*offset(1,2)*offset(2,1)*offset(3,4) + x(1,3)*offset(1,2)*offset(2,4)*offset(3,1) + x(1,3)*offset(1,4)*offset(2,1)*offset(3,2) - x(1,3)*offset(1,4)*offset(2,2)*offset(3,1) - x(1,4)*offset(1,1)*offset(2,2)*offset(3,3) + x(1,4)*offset(1,1)*offset(2,3)*offset(3,2) + x(1,4)*offset(1,2)*offset(2,1)*offset(3,3) - x(1,4)*offset(1,2)*offset(2,3)*offset(3,1) - x(1,4)*offset(1,3)*offset(2,1)*offset(3,2) + x(1,4)*offset(1,3)*offset(2,2)*offset(3,1)))/(offset(1,1)*offset(2,2)*offset(3,3) - offset(1,1)*offset(2,3)*offset(3,2) - offset(1,2)*offset(2,1)*offset(3,3) + offset(1,2)*offset(2,3)*offset(3,1) + offset(1,3)*offset(2,1)*offset(3,2) - offset(1,3)*offset(2,2)*offset(3,1)) - (u(2)*(x(2,1)*offset(1,2)*offset(2,3)*offset(3,4) - x(2,1)*offset(1,2)*offset(2,4)*offset(3,3) - x(2,1)*offset(1,3)*offset(2,2)*offset(3,4) + x(2,1)*offset(1,3)*offset(2,4)*offset(3,2) + x(2,1)*offset(1,4)*offset(2,2)*offset(3,3) - x(2,1)*offset(1,4)*offset(2,3)*offset(3,2) - x(2,2)*offset(1,1)*offset(2,3)*offset(3,4) + x(2,2)*offset(1,1)*offset(2,4)*offset(3,3) + x(2,2)*offset(1,3)*offset(2,1)*offset(3,4) - x(2,2)*offset(1,3)*offset(2,4)*offset(3,1) - x(2,2)*offset(1,4)*offset(2,1)*offset(3,3) + x(2,2)*offset(1,4)*offset(2,3)*offset(3,1) + x(2,3)*offset(1,1)*offset(2,2)*offset(3,4) - x(2,3)*offset(1,1)*offset(2,4)*offset(3,2) - x(2,3)*offset(1,2)*offset(2,1)*offset(3,4) + x(2,3)*offset(1,2)*offset(2,4)*offset(3,1) + x(2,3)*offset(1,4)*offset(2,1)*offset(3,2) - x(2,3)*offset(1,4)*offset(2,2)*offset(3,1) - x(2,4)*offset(1,1)*offset(2,2)*offset(3,3) + x(2,4)*offset(1,1)*offset(2,3)*offset(3,2) + x(2,4)*offset(1,2)*offset(2,1)*offset(3,3) - x(2,4)*offset(1,2)*offset(2,3)*offset(3,1) - x(2,4)*offset(1,3)*offset(2,1)*offset(3,2) + x(2,4)*offset(1,3)*offset(2,2)*offset(3,1)))/(offset(1,1)*offset(2,2)*offset(3,3) - offset(1,1)*offset(2,3)*offset(3,2) - offset(1,2)*offset(2,1)*offset(3,3) + offset(1,2)*offset(2,3)*offset(3,1) + offset(1,3)*offset(2,1)*offset(3,2) - offset(1,3)*offset(2,2)*offset(3,1)) - (u(3)*(x(3,1)*offset(1,2)*offset(2,3)*offset(3,4) - x(3,1)*offset(1,2)*offset(2,4)*offset(3,3) - x(3,1)*offset(1,3)*offset(2,2)*offset(3,4) + x(3,1)*offset(1,3)*offset(2,4)*offset(3,2) + x(3,1)*offset(1,4)*offset(2,2)*offset(3,3) - x(3,1)*offset(1,4)*offset(2,3)*offset(3,2) - x(3,2)*offset(1,1)*offset(2,3)*offset(3,4) + x(3,2)*offset(1,1)*offset(2,4)*offset(3,3) + x(3,2)*offset(1,3)*offset(2,1)*offset(3,4) - x(3,2)*offset(1,3)*offset(2,4)*offset(3,1) - x(3,2)*offset(1,4)*offset(2,1)*offset(3,3) + x(3,2)*offset(1,4)*offset(2,3)*offset(3,1) + x(3,3)*offset(1,1)*offset(2,2)*offset(3,4) - x(3,3)*offset(1,1)*offset(2,4)*offset(3,2) - x(3,3)*offset(1,2)*offset(2,1)*offset(3,4) + x(3,3)*offset(1,2)*offset(2,4)*offset(3,1) + x(3,3)*offset(1,4)*offset(2,1)*offset(3,2) - x(3,3)*offset(1,4)*offset(2,2)*offset(3,1) - x(3,4)*offset(1,1)*offset(2,2)*offset(3,3) + x(3,4)*offset(1,1)*offset(2,3)*offset(3,2) + x(3,4)*offset(1,2)*offset(2,1)*offset(3,3) - x(3,4)*offset(1,2)*offset(2,3)*offset(3,1) - x(3,4)*offset(1,3)*offset(2,1)*offset(3,2) + x(3,4)*offset(1,3)*offset(2,2)*offset(3,1)))/(offset(1,1)*offset(2,2)*offset(3,3) - offset(1,1)*offset(2,3)*offset(3,2) - offset(1,2)*offset(2,1)*offset(3,3) + offset(1,2)*offset(2,3)*offset(3,1) + offset(1,3)*offset(2,1)*offset(3,2) - offset(1,3)*offset(2,2)*offset(3,1));
    else
        state = - u(1)*((x(1,2)*offset(2,3) - x(1,3)*offset(2,2))/offset(2,2) - ((x(1,1)*offset(2,2) - x(1,2)*offset(2,1))*(offset(1,2)*offset(2,3) - offset(1,3)*offset(2,2)))/(offset(2,2)*(offset(1,1)*offset(2,2) - offset(1,2)*offset(2,1)))) - u(2)*((x(2,2)*offset(2,3) - x(2,3)*offset(2,2))/offset(2,2) - ((x(2,1)*offset(2,2) - x(2,2)*offset(2,1))*(offset(1,2)*offset(2,3) - offset(1,3)*offset(2,2)))/(offset(2,2)*(offset(1,1)*offset(2,2) - offset(1,2)*offset(2,1))));
    end
    %state = dot(subsref(x/offset, struct('type','()', 'subs',{{1:d,d+1}})), u);
    
    if nargout > 1
        d = n*(n+1)/2;
        D = vertcat(eye(d+n), zeros([1 d+n]));
        [t, r] = extract_SE(offset);
        if n == 2
            D(end,:) = [ -u(1)*(x(1,1)*cos(r) - x(1,2)*sin(r)) - u(2)*(x(2,1)*cos(r) - x(2,2)*sin(r))
                         -x(1,2)*u(1)*cos(r) - x(2,2)*u(2)*cos(r) - x(1,1)*u(1)*sin(r) - x(2,1)*u(2)*sin(r)
                          x(1,2)*t(1)*u(1)*cos(r) - x(1,1)*t(2)*u(1)*cos(r) + x(2,2)*t(1)*u(2)*cos(r) - x(2,1)*t(2)*u(2)*cos(r) + x(1,1)*t(1)*u(1)*sin(r) + x(1,2)*t(2)*u(1)*sin(r) + x(2,1)*t(1)*u(2)*sin(r) + x(2,2)*t(2)*u(2)*sin(r)
                          x(1,3) - x(1,1)*t(1)*cos(r) - x(1,2)*t(2)*cos(r) + x(1,2)*t(1)*sin(r) - x(1,1)*t(2)*sin(r)
                          x(2,3) - x(2,1)*t(1)*cos(r) - x(2,2)*t(2)*cos(r) + x(2,2)*t(1)*sin(r) - x(2,1)*t(2)*sin(r)                                                                                                                      ];
        else
            D(end,:) = [ x(1,1)*u(1)*sin(r(1))*sin(r(3)) + x(2,1)*u(2)*sin(r(1))*sin(r(3)) + x(3,1)*u(3)*sin(r(1))*sin(r(3)) + x(1,2)*u(1)*cos(r(3))*sin(r(1)) + x(1,3)*u(1)*cos(r(1))*sin(r(2)) + x(2,2)*u(2)*cos(r(3))*sin(r(1)) + x(2,3)*u(2)*cos(r(1))*sin(r(2)) + x(3,2)*u(3)*cos(r(3))*sin(r(1)) + x(3,3)*u(3)*cos(r(1))*sin(r(2)) - x(1,1)*u(1)*cos(r(1))*cos(r(2))*cos(r(3)) - x(2,1)*u(2)*cos(r(1))*cos(r(2))*cos(r(3)) - x(3,1)*u(3)*cos(r(1))*cos(r(2))*cos(r(3)) + x(1,2)*u(1)*cos(r(1))*cos(r(2))*sin(r(3)) + x(2,2)*u(2)*cos(r(1))*cos(r(2))*sin(r(3)) + x(3,2)*u(3)*cos(r(1))*cos(r(2))*sin(r(3))
                         x(1,3)*u(1)*sin(r(1))*sin(r(2)) + x(2,3)*u(2)*sin(r(1))*sin(r(2)) + x(3,3)*u(3)*sin(r(1))*sin(r(2)) - x(1,2)*u(1)*cos(r(1))*cos(r(3)) - x(2,2)*u(2)*cos(r(1))*cos(r(3)) - x(3,2)*u(3)*cos(r(1))*cos(r(3)) - x(1,1)*u(1)*cos(r(1))*sin(r(3)) - x(2,1)*u(2)*cos(r(1))*sin(r(3)) - x(3,1)*u(3)*cos(r(1))*sin(r(3)) - x(1,1)*u(1)*cos(r(2))*cos(r(3))*sin(r(1)) - x(2,1)*u(2)*cos(r(2))*cos(r(3))*sin(r(1)) - x(3,1)*u(3)*cos(r(2))*cos(r(3))*sin(r(1)) + x(1,2)*u(1)*cos(r(2))*sin(r(1))*sin(r(3)) + x(2,2)*u(2)*cos(r(2))*sin(r(1))*sin(r(3)) + x(3,2)*u(3)*cos(r(2))*sin(r(1))*sin(r(3))
                         x(1,2)*u(1)*sin(r(2))*sin(r(3)) - x(2,3)*u(2)*cos(r(2)) - x(3,3)*u(3)*cos(r(2)) - x(1,3)*u(1)*cos(r(2)) + x(2,2)*u(2)*sin(r(2))*sin(r(3)) + x(3,2)*u(3)*sin(r(2))*sin(r(3)) - x(1,1)*u(1)*cos(r(3))*sin(r(2)) - x(2,1)*u(2)*cos(r(3))*sin(r(2)) - x(3,1)*u(3)*cos(r(3))*sin(r(2))
                         x(1,2)*t(1)*u(1)*cos(r(1))*cos(r(3)) + x(2,2)*t(1)*u(2)*cos(r(1))*cos(r(3)) + x(3,2)*t(1)*u(3)*cos(r(1))*cos(r(3)) + x(1,1)*t(1)*u(1)*cos(r(1))*sin(r(3)) + x(1,2)*t(2)*u(1)*cos(r(3))*sin(r(1)) + x(1,3)*t(2)*u(1)*cos(r(1))*sin(r(2)) + x(2,1)*t(1)*u(2)*cos(r(1))*sin(r(3)) + x(2,2)*t(2)*u(2)*cos(r(3))*sin(r(1)) + x(2,3)*t(2)*u(2)*cos(r(1))*sin(r(2)) + x(3,1)*t(1)*u(3)*cos(r(1))*sin(r(3)) + x(3,2)*t(2)*u(3)*cos(r(3))*sin(r(1)) + x(3,3)*t(2)*u(3)*cos(r(1))*sin(r(2)) - x(1,3)*t(1)*u(1)*sin(r(1))*sin(r(2)) + x(1,1)*t(2)*u(1)*sin(r(1))*sin(r(3)) - x(2,3)*t(1)*u(2)*sin(r(1))*sin(r(2)) + x(2,1)*t(2)*u(2)*sin(r(1))*sin(r(3)) - x(3,3)*t(1)*u(3)*sin(r(1))*sin(r(2)) + x(3,1)*t(2)*u(3)*sin(r(1))*sin(r(3)) - x(1,1)*t(2)*u(1)*cos(r(1))*cos(r(2))*cos(r(3)) - x(2,1)*t(2)*u(2)*cos(r(1))*cos(r(2))*cos(r(3)) - x(3,1)*t(2)*u(3)*cos(r(1))*cos(r(2))*cos(r(3)) + x(1,1)*t(1)*u(1)*cos(r(2))*cos(r(3))*sin(r(1)) + x(1,2)*t(2)*u(1)*cos(r(1))*cos(r(2))*sin(r(3)) + x(2,1)*t(1)*u(2)*cos(r(2))*cos(r(3))*sin(r(1)) + x(2,2)*t(2)*u(2)*cos(r(1))*cos(r(2))*sin(r(3)) + x(3,1)*t(1)*u(3)*cos(r(2))*cos(r(3))*sin(r(1)) + x(3,2)*t(2)*u(3)*cos(r(1))*cos(r(2))*sin(r(3)) - x(1,2)*t(1)*u(1)*cos(r(2))*sin(r(1))*sin(r(3)) - x(2,2)*t(1)*u(2)*cos(r(2))*sin(r(1))*sin(r(3)) - x(3,2)*t(1)*u(3)*cos(r(2))*sin(r(1))*sin(r(3))
                         x(1,3)*t(3)*u(1)*sin(r(2)) + x(2,3)*t(3)*u(2)*sin(r(2)) + x(3,3)*t(3)*u(3)*sin(r(2)) + x(1,3)*t(1)*u(1)*cos(r(1))*cos(r(2)) - x(1,1)*t(3)*u(1)*cos(r(2))*cos(r(3)) + x(2,3)*t(1)*u(2)*cos(r(1))*cos(r(2)) - x(2,1)*t(3)*u(2)*cos(r(2))*cos(r(3)) + x(3,3)*t(1)*u(3)*cos(r(1))*cos(r(2)) - x(3,1)*t(3)*u(3)*cos(r(2))*cos(r(3)) + x(1,3)*t(2)*u(1)*cos(r(2))*sin(r(1)) + x(1,2)*t(3)*u(1)*cos(r(2))*sin(r(3)) + x(2,3)*t(2)*u(2)*cos(r(2))*sin(r(1)) + x(2,2)*t(3)*u(2)*cos(r(2))*sin(r(3)) + x(3,3)*t(2)*u(3)*cos(r(2))*sin(r(1)) + x(3,2)*t(3)*u(3)*cos(r(2))*sin(r(3)) + x(1,1)*t(1)*u(1)*cos(r(1))*cos(r(3))*sin(r(2)) + x(2,1)*t(1)*u(2)*cos(r(1))*cos(r(3))*sin(r(2)) + x(3,1)*t(1)*u(3)*cos(r(1))*cos(r(3))*sin(r(2)) - x(1,2)*t(1)*u(1)*cos(r(1))*sin(r(2))*sin(r(3)) + x(1,1)*t(2)*u(1)*cos(r(3))*sin(r(1))*sin(r(2)) - x(2,2)*t(1)*u(2)*cos(r(1))*sin(r(2))*sin(r(3)) + x(2,1)*t(2)*u(2)*cos(r(3))*sin(r(1))*sin(r(2)) - x(3,2)*t(1)*u(3)*cos(r(1))*sin(r(2))*sin(r(3)) + x(3,1)*t(2)*u(3)*cos(r(3))*sin(r(1))*sin(r(2)) - x(1,2)*t(2)*u(1)*sin(r(1))*sin(r(2))*sin(r(3)) - x(2,2)*t(2)*u(2)*sin(r(1))*sin(r(2))*sin(r(3)) - x(3,2)*t(2)*u(3)*sin(r(1))*sin(r(2))*sin(r(3))
                         x(1,1)*t(1)*u(1)*cos(r(3))*sin(r(1)) - x(2,1)*t(2)*u(2)*cos(r(1))*cos(r(3)) - x(3,1)*t(2)*u(3)*cos(r(1))*cos(r(3)) - x(1,1)*t(2)*u(1)*cos(r(1))*cos(r(3)) + x(1,2)*t(2)*u(1)*cos(r(1))*sin(r(3)) + x(2,1)*t(1)*u(2)*cos(r(3))*sin(r(1)) + x(1,2)*t(3)*u(1)*cos(r(3))*sin(r(2)) + x(2,2)*t(2)*u(2)*cos(r(1))*sin(r(3)) + x(3,1)*t(1)*u(3)*cos(r(3))*sin(r(1)) + x(2,2)*t(3)*u(2)*cos(r(3))*sin(r(2)) + x(3,2)*t(2)*u(3)*cos(r(1))*sin(r(3)) + x(3,2)*t(3)*u(3)*cos(r(3))*sin(r(2)) - x(1,2)*t(1)*u(1)*sin(r(1))*sin(r(3)) + x(1,1)*t(3)*u(1)*sin(r(2))*sin(r(3)) - x(2,2)*t(1)*u(2)*sin(r(1))*sin(r(3)) + x(2,1)*t(3)*u(2)*sin(r(2))*sin(r(3)) - x(3,2)*t(1)*u(3)*sin(r(1))*sin(r(3)) + x(3,1)*t(3)*u(3)*sin(r(2))*sin(r(3)) + x(1,2)*t(1)*u(1)*cos(r(1))*cos(r(2))*cos(r(3)) + x(2,2)*t(1)*u(2)*cos(r(1))*cos(r(2))*cos(r(3)) + x(3,2)*t(1)*u(3)*cos(r(1))*cos(r(2))*cos(r(3)) + x(1,1)*t(1)*u(1)*cos(r(1))*cos(r(2))*sin(r(3)) + x(1,2)*t(2)*u(1)*cos(r(2))*cos(r(3))*sin(r(1)) + x(2,1)*t(1)*u(2)*cos(r(1))*cos(r(2))*sin(r(3)) + x(2,2)*t(2)*u(2)*cos(r(2))*cos(r(3))*sin(r(1)) + x(3,1)*t(1)*u(3)*cos(r(1))*cos(r(2))*sin(r(3)) + x(3,2)*t(2)*u(3)*cos(r(2))*cos(r(3))*sin(r(1)) + x(1,1)*t(2)*u(1)*cos(r(2))*sin(r(1))*sin(r(3)) + x(2,1)*t(2)*u(2)*cos(r(2))*sin(r(1))*sin(r(3)) + x(3,1)*t(2)*u(3)*cos(r(2))*sin(r(1))*sin(r(3))
                         x(1,4) - x(1,3)*t(3)*cos(r(2)) + x(1,1)*t(1)*sin(r(1))*sin(r(3)) + x(1,3)*t(2)*sin(r(1))*sin(r(2)) + x(1,2)*t(3)*sin(r(2))*sin(r(3)) - x(1,2)*t(2)*cos(r(1))*cos(r(3)) + x(1,2)*t(1)*cos(r(3))*sin(r(1)) + x(1,3)*t(1)*cos(r(1))*sin(r(2)) - x(1,1)*t(2)*cos(r(1))*sin(r(3)) - x(1,1)*t(3)*cos(r(3))*sin(r(2)) - x(1,1)*t(1)*cos(r(1))*cos(r(2))*cos(r(3)) + x(1,2)*t(1)*cos(r(1))*cos(r(2))*sin(r(3)) - x(1,1)*t(2)*cos(r(2))*cos(r(3))*sin(r(1)) + x(1,2)*t(2)*cos(r(2))*sin(r(1))*sin(r(3))
                         x(2,4) - x(2,3)*t(3)*cos(r(2)) + x(2,1)*t(1)*sin(r(1))*sin(r(3)) + x(2,3)*t(2)*sin(r(1))*sin(r(2)) + x(2,2)*t(3)*sin(r(2))*sin(r(3)) - x(2,2)*t(2)*cos(r(1))*cos(r(3)) + x(2,2)*t(1)*cos(r(3))*sin(r(1)) + x(2,3)*t(1)*cos(r(1))*sin(r(2)) - x(2,1)*t(2)*cos(r(1))*sin(r(3)) - x(2,1)*t(3)*cos(r(3))*sin(r(2)) - x(2,1)*t(1)*cos(r(1))*cos(r(2))*cos(r(3)) + x(2,2)*t(1)*cos(r(1))*cos(r(2))*sin(r(3)) - x(2,1)*t(2)*cos(r(2))*cos(r(3))*sin(r(1)) + x(2,2)*t(2)*cos(r(2))*sin(r(1))*sin(r(3))
                         x(3,4) - x(3,3)*t(3)*cos(r(2)) + x(3,1)*t(1)*sin(r(1))*sin(r(3)) + x(3,3)*t(2)*sin(r(1))*sin(r(2)) + x(3,2)*t(3)*sin(r(2))*sin(r(3)) - x(3,2)*t(2)*cos(r(1))*cos(r(3)) + x(3,2)*t(1)*cos(r(3))*sin(r(1)) + x(3,3)*t(1)*cos(r(1))*sin(r(2)) - x(3,1)*t(2)*cos(r(1))*sin(r(3)) - x(3,1)*t(3)*cos(r(3))*sin(r(2)) - x(3,1)*t(1)*cos(r(1))*cos(r(2))*cos(r(3)) + x(3,2)*t(1)*cos(r(1))*cos(r(2))*sin(r(3)) - x(3,1)*t(2)*cos(r(2))*cos(r(3))*sin(r(1)) + x(3,2)*t(2)*cos(r(2))*sin(r(1))*sin(r(3))                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ];

        end
    end
end