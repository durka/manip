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
        X(frame,:, :,:) = place_objects(squeeze(X(frame,:, :,:)), S, 1);
        
        if frame < f
            % nudge parameters randomly
            dX = eye(dims+1);%T(unifrnd(-.1, .1, [dims 1])) * R(unifrnd(-.3, .3, [1*(dims==2)+3*(dims==3) 1]));
            X(frame+1,1, :,:) = dX * squeeze(X(frame,1, :,:));  % randomly nudge root
                
            for j = 1:length(S)
                bit = diff(S(j).bounds)/10;
                S(j).state = S(j).state + unifrnd(-bit, bit);
                S(j).state = max(min(S(j).state, ...
                                     S(j).bounds(2,:)), ...
                                 S(j).bounds(1,:));
            end
        end
    end
end

% utility functions to generate rotations and translations
function r = R(params)
    if length(params) == 1
        r = [cos(params(1)) -sin(params(1)) 0
             sin(params(1))  cos(params(1)) 0
             0               0              1];
    elseif length(params) == 3
        [a b c] = subsref(num2cell(params), substruct('{}', {':'})); % i.e. [a b c] = num2cell(params){:}
        r = [cos(a)*cos(b) cos(a)*sin(b)*sin(c)-sin(a)*cos(c) cos(a)*sin(b)*cos(c)-sin(a)*sin(c) 0
             sin(a)*cos(b) sin(a)*sin(b)*sin(c)+cos(a)*cos(c) sin(a)*sin(b)*cos(c)-cos(a)*sin(c) 0
             -sin(b)       cos(b)*sin(c)                      cos(b)*cos(c)                      0
             0             0                                  0                                  1];
    else
        error('I can only think in 2 or 3 dimensions');
    end
end

function t = T(params)
    if length(params) == 2
        [x y] = subsref(num2cell(params), substruct('{}', {':'})); % i.e. [x y] = num2cell(params){:}
        t = [1 0 x
             0 1 y
             0 0 1];
    elseif length(params) == 3
        [x y z] = subsref(num2cell(params), substruct('{}', {':'})); % i.e. [x y z] = num2cell(params){:}
        t = [1 0 0 x
             0 1 0 y
             0 0 1 z
             0 0 0 1];
    else
        error('I can only think in 2 or 3 dimensinos');
    end
end

% helper function to do the forward kinematics
% X here is just a single frame, i.e. n x dims+1 x dims+1
function X = place_objects(X, S, parent)
    for joint = find(horzcat(S.a) == parent)
        child = S(joint).b;
        
        % place object
        X(child, :,:) = S(joint).joint(S(joint).params, S(joint).state) * squeeze(X(parent, :,:));
        
        % place children
        X = place_objects(X, S, child);
    end
end

% in 2D and 3D
%   params{1} SE(n) is the offset from the from-object center to prismatic joint
%   params{2] R(n)  is the unit vector pointing in the direction of prismaticness
%   state     R     is the extension of the joint
function x = forward_prismatic(params, state) %#ok<DEFNU>
    offset = params{1};
    u = params{2};
    pos = state;
    
    x = T(u*pos) * offset;
end

% in 2D and 3D
%   params{1} SE(n) is the center of rotation (WRT from-object center)
%   params{2} SE(n) is the offset from the center to the moving part at theta=0
%   state     R     is the angle around the circle
function x = forward_revolute(params, state) %#ok<DEFNU>
    center = params{1};
    radius = params{2};
    theta = state;
    
    x = radius * R([theta 0 0]) * center;
end

% in 2D and 3D
%   params{1} SE(n) is the offset from the from-object center to the to-object center
function x = forward_rigid(params, ~) %#ok<DEFNU>
    x = params{1};
end
