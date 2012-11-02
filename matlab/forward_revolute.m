% in 2D and 3D
%   params{1} SE(n) is the center of rotation (WRT from-object center)
%   params{2} SE(n) is the offset from the center to the moving part at theta=0
%   state     R     is the angle around the circle
function x = forward_revolute(params, state)
    center = params{1};
    radius = params{2};
    theta = state;
    
    x = radius * R([0 0 theta]) * center;
end
