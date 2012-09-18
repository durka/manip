% simulates the motion of featuers

% inpust:
%   dims:      2 or 3, for 2D or 3D motion
%   n:         number of features
%   f:         number of frames
%   structure: optional feature grouping (cell array of vectors of features
%                                         that travel together)

% outputs:
%   X:         motion over time, f x dims*n matrix

function [X] = manip_simulate(dims, n, f, structure)
    if nargin == 3
        structure = cell(1, n);
        for i = 1:n
            structure(i) = {i};
        end
    end
    
    X = zeros(f, dims*n);
    X(1, :) = rand(1, dims*n)-.5; % randomly initialize positions
    for frame = 2:f
        % randomly nudge each object
        for object = 1:length(structure)
            delta = rand(1, dims)-.5;
            for feature = cell2mat(structure(object))
                r = ((feature-1)*dims+1):(feature*dims);
                X(frame, r) = X(frame-1, r) + delta;
            end
        end
    end     
end