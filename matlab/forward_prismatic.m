% in 2D and 3D
%   params{1} SE(n) is the offset from the from-object center to prismatic joint
%   params{2} R(n)  is the unit vector pointing in the direction of prismaticness
%   state     R     is the extension of the joint
function x = forward_prismatic(params, state)
    offset = params{1};
    u = params{2};
    pos = state;
    
    x = T(u*pos) * offset;
end
