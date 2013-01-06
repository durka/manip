% in 2D and 3D
%   params{1} SE(n) is the offset from the from-object center to prismatic joint
%   params{2} R(n)  is the unit vector pointing in the direction of prismaticness
function params = reverse_prismatic(params)
    dims = size(params{1}, 1) - 1;
    params{1} = inv(params{1});
    params{2} = params{1}(1:dims,1:dims)*params{2};
end
