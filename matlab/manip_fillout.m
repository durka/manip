% given a tree and data, back out the states and bounds
% modifies the tree in place
% OVERWRITES S.bounds, S.state, S.trajectory
% correspondences can remap the node IDs HACK HACK HACK

% can pass X or cell array of deltas

function S = manip_fillout(S, X, correspondences)
    fprintf('Filling out states...\n');
    
    if ~exist('correspondences', 'var')
        m = max([S.a S.b]);
        correspondences = 1:m;
    end

    for joint=1:length(S)
        a = correspondences(S(joint).a);
        b = correspondences(S(joint).b);
        
        fprintf('\tJoint %d-%d (%s)\n', a, b, S(joint).joint);
        
        if iscell(X)
            deltas = X{joint};
        else
            deltas = calc_deltas(X, a, b);
        end
        
        S(joint).trajectory = zeros(size(deltas));
        for frame=1:length(deltas)
            S(joint).trajectory(frame) = feval(['inverse_' S(joint).joint], deltas{frame}, S(joint).params);
        end
        
        S(joint).state = S(joint).trajectory(1);
        S(joint).bounds(1) = min(S(joint).trajectory);
        S(joint).bounds(2) = max(S(joint).trajectory);
    end

end
