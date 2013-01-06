% in 2D and 3D
%   params{1} SE(n) is the offset from the from-object center to the to-object center
function params = reverse_rigid(params)
    params{1} = inv(params{1});
end
