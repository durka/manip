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
            
            options = optimset('fmincon');
            options = optimset(options, 'Algorithm', 'trust-region-reflective');
            options = optimset(options, 'MaxFunEvals', 1e10);
            options = optimset(options, 'MaxIter', 1e10);
            
            [rigid_fit, err] = fmincon(...
                                 @(p) jointfit(deltas, ...
                                               {T(p(1:dims))*R(p(dims+1:end))}, ...
                                               @forward_rigid, @inverse_rigid), ...
                                 [t r], ...
                                 [], [], [], [], ... % no linear constraints
                                 [-inf(size(t)) -pi*ones(size(r))], ...
                                 [ inf(size(t))  pi*ones(size(r))], ...
                                 [], ... % no nonlinear constraints
                                 options);
            rigid_params = T(rigid_fit(1:dims))*R(rigid_fit(dims+1:end));
            dbg('\t\tRigid joint (err=%g): o=%s\n', err, format_SE(rigid_params, 3));
            
            
            [prismatic_fit, err] = fmincon(...
                                 @(p) jointfit(deltas, ...
                                               unpack_prismatic(p, dims), ...
                                               @forward_prismatic, @inverse_prismatic), ...
                                 [t r, eye(1,dims)], ...
                                 [], [], [], [], ... % no linear constraints
                                 [-inf(size(t)) -pi*ones(size(r)) -ones(1,dims)], ...
                                 [ inf(size(t))  pi*ones(size(r))  ones(1,dims)], ...
                                 @(p) nonlcon_unit(p(end-dims+1:end)), ... % constrain unit vector to unit length
                                 options);
            prismatic_params = unpack_prismatic(prismatic_fit, dims);
            dbg('\t\tPrismatic joint (err=%g): o=%s u=%s\n', err, format_SE(prismatic_params{1}, 3), mat2str(prismatic_params{2}, 3));
            
            
            [revolute_fit, err] = fmincon(...
                                 @(p) jointfit(deltas, ...
                                               unpack_revolute(p, dims), ...
                                               @forward_revolute, @inverse_revolute), ...
                                 [t r, eye(1,dims) zeros(1,dims)], ...
                                 [], [], [], [], ... % no linear constraints
                                 [-inf(size(t)) -pi*ones(size(r)) -inf(1,dims) -pi*ones(1,dims)], ...
                                 [ inf(size(t))  pi*ones(size(r))  inf(1,dims)  pi*ones(1,dims)], ...
                                 [], ... % no nonlinear constraints
                                 options);
            revolute_params = unpack_revolute(revolute_fit, dims);
            dbg('\t\tRevolute joint (err=%g): c=%s o=%s\n', err, format_SE(revolute_params{1}, 3), format_SE(revolute_params{2}, 3));
        end
    end
    
    warning('on', 'MATLAB:funm:nonPosRealEig');
    dbg('Done learning (%g sec)\n\n', toc);
    profile viewer;
end

function [c,ceq] = nonlcon_unit(p)
    c = [];
    ceq = sum(p.^2) - 1;
end

function params = unpack_prismatic(p, dims)
	i = 1;
    
    t = p(i:i+dims-1); i = i+dims;
    r = p(i:end-dims);
    params{1} = T(t)*R(r);
    
    params{2} = p(end-dims+1:end);
end

function params = unpack_revolute(p, dims)
    i = 1;
    n = dims*(dims-1)/2;
    
    t = p(i:i+dims-1); i = i+dims;
    r = p(i:i+n-1);    i = i+n;
    params{1} = T(t)*R(r);
    
    t = p(i:i+dims-1); i = i+dims;
    r = p(i:i+n-1);    i = i+n;
    params{2} = T(t)*R(r);
end

function [err, grad] = jointfit(deltas, p, forward, inverse)
    %fprintf('\t\t\t%s\n', format_SE(p{1}));
    err = 0;
    grad = 0;
    
    % accumulate error at each frame
    for frame = 1:length(deltas)
        % perform IK to get the observed params
        state = inverse(deltas{frame}, p);
        
        % get error between real SE pose and observed-modeled SE pose
        e, g = SE_dist(forward(p, state), ...
                       deltas{frame});
        err = err + e;
        grad = grad + g;
    end
end

% returns "distance" between two elements of SE(n)
% also returns gradient of the distance WRT u
function [dist, grad] = SE_dist(u, v)
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
    
    grad = 0;
end
