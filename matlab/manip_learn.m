function S = manip_learn(X, dbg)
    if dbg
        dbg = @fprintf;
    else
        dbg = @(varargin) fprintf('');
    end
    
    dbg('Begin learning\n');
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
            rigid_params = fminsearch(@(p) jointfit(X(:,[a b],:,:), ...
                                                    {T(p(1:dims))*R(p(dims+1:end))}, ...
                                                    @forward_rigid, @inverse_rigid), ...
                                      [t r]);
            rigid_params = T(rigid_params(1:dims))*R(rigid_params(dims+1:end));
            dbg('\t\tRigid joint: %s\n', format_SE(rigid_params));
        end
    end
    
    warning('on', 'MATLAB:funm:nonPosRealEig');
    dbg('Done learning\n\n');
end

function err = jointfit(X, p, forward, inverse)
    %fprintf('\t\t\t%s\n', format_SE(p{1}));
    err = 0;
    
    % accumulate error at each frame
    for frame = 1:size(X, 1)
        % perform IK to get the observed params
        parent = squeeze(X(frame, 1, :,:));
        child = squeeze(X(frame, 2, :,:));
        obs_p = inverse(parent\child);
        
        % get error between real SE pose and observed-modeled SE pose
        err = err + SE_dist(forward(p), ...
                            forward(obs_p));
    end
end

function dist = SE_dist(u, v)
    % magic scale factors (see, e.g. Park 1995)
    c = 1;
    d = 1;

    n = size(u,1)-1; % n as in SE(n)
    
    ut = u(1:n, n+1);
    vt = v(1:n, n+1);
    ur = u(1:n, 1:n);
    vr = v(1:n, 1:n);
    
    dist = sqrt(c*norm(logm(ur\vr))^2 + d*norm(ut - vt)^2);
end
