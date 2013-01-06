% in 2D and 3D
%   params{1} SE(n) is the center of rotation (WRT from-object center)
%   params{2} SE(n) is the offset from the center to the moving part at theta=0
function params = reverse_revolute(params)
    params{1} = inv(params{2});
    params{2} = inv(params{1});
end
