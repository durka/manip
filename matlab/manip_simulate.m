% simulates the motion of featuers

% inpust:
%   dims:      2 or 3, for 2D or 3D motion
%   n:         number of features
%   f:         number of frames
%   T:         kinematic tree edges (feature 1 is always the root)
%               e.g. if dims=2 and n=3
%                 [ struct('links', [1 2], ...
%                          'joint', 'prismatic', ...
%                          'params', [0.1 0.2, pi], ...
%                          'state', [0], ...
%                          'bounds', [0; 3]), ...
%                       (offset=[.1 .2], dir=pi, max=3, start=0)
%                   struct('links', [2 3], ...
%                          'joint', 'revolute', ...
%                          'params', [1 1, 0.75], ...
%                          'state', [pi/4], ...
%                          'bounds', [0; pi]) ]
%                       (c=[1 1], r=0.75, min=0, max=pi], start=pi/4)

% outputs:
%   X:         motion over time, f x dims*n matrix

function X = manip_simulate(dims, n, f, T)
    X = zeros(f, n, dims);
    X(1, 1, :) = unifrnd(-5, 5, dims, 1); % randomly initialize root
    
    % turn the joint types into function pointers
    for j = 1:length(T)
        T(j).joint = eval(['@forward_' T(j).joint]);
    end
    
    for frame = 1:f
        % put stuff in places
        X(frame, :, :) = place_objects(squeeze(X(frame, :, :)), T, [1]);
        
        if frame < f
            % nudge parameters randomly
            X(frame+1, 1, :) = X(frame, 1, :) ...  % randomly nudge root
                               + 0*unifrnd(-.2, .2, [1, 1, dims]);
            for j = 1:length(T)
                bit = diff(T(j).bounds)/10;
                T(j).state = T(j).state + unifrnd(-bit, bit);
                T(j).state = max(min(T(j).state, ...
                                     T(j).bounds(2,:)), ...
                                 T(j).bounds(1,:));
            end
        end
    end
end

function X = place_objects(X, T, parent)
    for joint = find(horzcat(T.a) == parent)
        child = T(joint).b;
        
        % place object
        X(child, :) = T(joint).joint(X(parent, :), ...
                                     T(joint).params, ...
                                     T(joint).state);
        
        % place children
        X = place_objects(X, T, child);
    end
end

function x = forward_prismatic(from, params, state)
    offset = params(1:2);
    theta = params(3);
    u = [cos(theta) sin(theta)];
    pos = state;
    
    x = from + offset + u*pos;
end

function x = forward_revolute(from, params, state) %#ok<DEFNU>
    center = params(1:2);
    radius = params(3);
    theta = state;
    
    x = forward_prismatic(from, [center theta], radius);
end
