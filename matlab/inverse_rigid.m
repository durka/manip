% in 2D and 3D
%   params{1} SE(n) is the offset from the from-object center to the to-object center

function [state, D] = inverse_rigid(x, ~)
    state = 0; % rigid joints have no state
    
    if nargout > 1
        n = size(x,1)-1;
        d = n*(n+1)/2;
        D = vertcat(eye(d), zeros(1,d));
    end
end