% simulates the motion of featuers

% inputs:
%   dims:      2 or 3, for 2D or 3D motion
%   n:         number of features
%   f:         number of frames
%   S:         kinematic tree edges (feature 1 is always the root)
%               e.g. if dims=2 and n=3
%                 [ struct('links', [1 2], ...
%                          'joint', 'prismatic', ...
%                          'params', {[0.1 0.2], [0 1]}, ...
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
%   X:         motion over time, f x n x dims+1 x dims+1 matrix (i.e. f x n array of homogeneous transformation matrices)

function X = manip_simulate(dims, n, f, S)
    X = zeros(f, n, dims+1, dims+1);
    X(1,1, :,:) = T(unifrnd(-5, 5, [dims 1])) * R(unifrnd(-2*pi, 2*pi, [1*(dims==2)+3*(dims==3) 1])); % randomly initialize root
    
    % turn the joint types into function pointers
    for j = 1:length(S)
        S(j).joint = eval(['@forward_' S(j).joint]);
    end
    
    for frame = 1:f
        % put stuff in places
        X(frame,:, :,:) = place_objects(squeeze(X(frame,:, :,:)), S, 1, squeeze(X(frame,1, :,:)));
        
        if frame < f
            % nudge parameters randomly
            dX = T(unifrnd(-.05, .05, [dims 1])) * R(unifrnd(-.3, .3, [dims*(dims-1)/2 1]));
            origin = squeeze(X(frame,1, :,:));
            X(frame+1,1, :,:) = origin * dX / origin * squeeze(X(frame,1, :,:));  % randomly nudge root
                
            for j = 1:length(S)
                bit = diff(S(j).bounds)/10;
                S(j).state = S(j).state + unifrnd(-bit, bit);
                S(j).state = max(min(S(j).state, ...
                                     S(j).bounds(2,:)), ...
                                 S(j).bounds(1,:));
            end
        end
    end
    
    % a little Gaussian noise never hurt anybody
    for frame = 1:f
        origin = squeeze(X(frame,1, :,:));
        for i = 1:n
            dX = eye(dims+1);%T(unifrnd(-.025, .025, [dims 1])) * R(unifrnd(-.05, .05, [dims*(dims-1)/2 1]));
            X(frame,i, :,:) = origin * dX / origin * squeeze(X(frame,i, :,:));
        end
    end
end

% helper function to do the forward kinematics
% X here is just a single frame, i.e. n x dims+1 x dims+1
function X = place_objects(X, S, parent, origin)
    for joint = find(horzcat(S.a) == parent)
        child = S(joint).b;
        
        % place object
        X(child, :,:) = origin * S(joint).joint(S(joint).params, S(joint).state) / origin * squeeze(X(parent, :,:));
        
        % place children
        X = place_objects(X, S, child, origin);
    end
end
