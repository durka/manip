function S = manip_learn(X, dbg)
    if dbg
        dbg = @fprintf;
    else
        dbg = @(varargin) fprintf('');
    end
    
    dbg('Begin learning\n');
    tic;
    profile on;
    warning('off', 'MATLAB:funm:nonPosRealEig'); % shut up already about logm

    S = struct('a', {}, 'b', {}, 'joint', {}, 'params', {}, 'state', {}, 'bounds', {});

    f = size(X, 1);
    n = size(X, 2);
    dims = size(X, 3) - 1;
    dbg('Detected f=%d, n=%d, dims=%d\n', f, n, dims);
    
    dbg('Fitting all models to all possible joints...\n');
    for a = 1:n
        for b = a+1:n
            dbg('\tTrying joint %d-%d...\n', a, b);
            
            [~, t, r] = format_SE(squeeze(X(1,a,:,:))\squeeze(X(1,b,:,:)));
            deltas = cell(f, 1);
            for frame = 1:f
                deltas{frame} = squeeze(X(frame, a, :,:))\squeeze(X(frame, b, :,:));
            end
            
            [rigid_fit, err] = fminsearch(...
                                 @(p) jointfit(deltas, ...
                                               {T(p(1:dims))*R(p(dims+1:end))}, ...
                                               @forward_rigid, @inverse_rigid), ...
                                 [t r]);
            rigid_params = T(rigid_fit(1:dims))*R(rigid_fit(dims+1:end));
            dbg('\t\tRigid joint (err=%g): %s\n', err, format_SE(rigid_params, 3));
            
            
            [prismatic_fit, err] = fminsearch(...
                                 @(p) jointfit(deltas, ...
                                               {T(p(1:dims))*R(p(dims+1:end-dims)) ...
                                                p(end-dims+1:end)}, ...
                                               @forward_prismatic, @inverse_prismatic), ...
                                 [t r zeros(1, dims)]);
            prismatic_params = T(prismatic_fit(1:dims))*R(prismatic_fit(dims+1:end-dims));
            prismatic_state = prismatic_fit(end-dims+1:end); % hmm, have to record the full range during fitting somehow, or do a max afterwards
            dbg('\t\tPrismatic joint (err=%g, state=%g): %s\n', err, prismatic_state, format_SE(prismatic_params, 3));
        end
    end
    
    warning('on', 'MATLAB:funm:nonPosRealEig');
    dbg('Done learning (%g sec)\n\n', toc);
    profile viewer;
end

function err = jointfit(deltas, p, forward, inverse)
    %fprintf('\t\t\t%s\n', format_SE(p{1}));
    err = 0;
    
    % accumulate error at each frame
    for frame = 1:length(deltas)
        % perform IK to get the observed params
        state = inverse(deltas{frame}, p);
        
        % get error between real SE pose and observed-modeled SE pose
        err = err + SE_dist(forward(p, state), ...
                            deltas{frame});
    end
end

function dist = SE_dist(u, v)
    % magic scale factors (see, e.g. Park 1995)
    c = 2;
    d = 1;

    n = size(u,1)-1; % n as in SE(n)
    
    ut = u(1:n, n+1);
    vt = v(1:n, n+1);
    ur = u(1:n, 1:n);
    vr = v(1:n, 1:n);
    
    %dr = ur\vr;
    dt = ut - vt;
    %L = logm_so3(dr);
    %C = c*norm(L)^2;
    if n == 3
        tr = (ur(1,1)*ur(2,2)*vr(3,3) - ur(1,1)*ur(2,3)*vr(3,2) - ur(1,1)*ur(3,2)*vr(2,3) + ur(1,1)*ur(3,3)*vr(2,2) - ur(1,2)*ur(2,1)*vr(3,3) + ur(1,2)*ur(2,3)*vr(3,1) + ur(1,2)*ur(3,1)*vr(2,3) - ur(1,2)*ur(3,3)*vr(2,1) + ur(1,3)*ur(2,1)*vr(3,2) - ur(1,3)*ur(2,2)*vr(3,1) - ur(1,3)*ur(3,1)*vr(2,2) + ur(1,3)*ur(3,2)*vr(2,1) + ur(2,1)*ur(3,2)*vr(1,3) - ur(2,1)*ur(3,3)*vr(1,2) - ur(2,2)*ur(3,1)*vr(1,3) + ur(2,2)*ur(3,3)*vr(1,1) + ur(2,3)*ur(3,1)*vr(1,2) - ur(2,3)*ur(3,2)*vr(1,1))/(ur(1,1)*ur(2,2)*ur(3,3) - ur(1,1)*ur(2,3)*ur(3,2) - ur(1,2)*ur(2,1)*ur(3,3) + ur(1,2)*ur(2,3)*ur(3,1) + ur(1,3)*ur(2,1)*ur(3,2) - ur(1,3)*ur(2,2)*ur(3,1));
    else
        tr = (ur(1,1)*vr(2,2) - ur(1,2)*vr(2,1) - ur(2,1)*vr(1,2) + ur(2,2)*vr(1,1))/(ur(1,1)*ur(2,2) - ur(1,2)*ur(2,1));
    end
    C = c*2*acos((tr-1)/2); % from http://en.wikipedia.org/wiki/Axis-angle_representation#Log_map_from_SO.283.29_to_so.283.29
    D = d*norm(dt)^2;
    dist = C + D;
end
