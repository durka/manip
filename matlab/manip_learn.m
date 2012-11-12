function S = manip_learn(X, dbg)
    if dbg
        dbg = @fprintf;
    else
        dbg = @(varargin) fprintf('');
    end
    
    dbg('Begin learning\n');
    tic;
    profile on;
    
    S = struct('a', {}, 'b', {}, 'joint', {}, 'params', {}, 'state', {}, 'bounds', {});

    f = size(X, 1);
    n = size(X, 2);
    dims = size(X, 3) - 1;
    dbg('Detected f=%d, n=%d, dims=%d\n', f, n, dims);
    
    dbg('Computing jacobians...');
    dbg(' Dq ');   
    A = sym('a%d%d', [dims dims]); A = sym(A, 'real');
    B = sym('b%d%d', [dims dims]); B = sym(B, 'real');
    s = evalc('simplify(jacobian(2*acos((trace(A\B)-1)/2), A))');
    Dq = eval(sprintf('@(ur, vr) %s', regexprep(subsref(regexp(s, '\n', 'split'), substruct('{}', {4})), {'a(\d)(\d)', 'b(\d)(\d)'}, {'ur($1,$2)', 'vr($1,$2)'})));
    dbg(' Dr ');
    A = sym('a%d%d', [dims 1]); A = sym(A, 'real');
    B = sym('b%d%d', [dims 1]); B = sym(B, 'real');
    s = evalc('simplify(jacobian(feval(symengine, ''norm'', A - B, 2), A))');
    Dr = eval(sprintf('@(ut, vt) %s', regexprep(subsref(regexp(s, '\n', 'split'), substruct('{}', {4})), {'a(\d)(\d)', 'b(\d)(\d)'}, {'ut($1,$2)', 'vt($1,$2)'})));
    dbg('done.\n');
    
    dbg('Fitting all models to all possible joints...\n');
    for a = 1:n
        for b = a+1:n
            dbg('\tTrying joint %d-%d...\n', a, b);
            
            [t, r] = extract_SE(squeeze(X(1,a,:,:))\squeeze(X(1,b,:,:)));
            deltas = cell(f, 1);
            for frame = 1:f
                deltas{frame} = squeeze(X(frame, a, :,:))\squeeze(X(frame, b, :,:));
            end
            
            options = optimset('fmincon');
            options = optimset(options, 'Algorithm', 'active-set');
            options = optimset(options, 'GradObj', 'on');
            options = optimset(options, 'MaxFunEvals', 1e10);
            options = optimset(options, 'MaxIter', 1e10);
            options = optimset(options, 'Display', 'off');
            options = optimset(options, 'Diagnostics', 'off');
            
            [rigid_fit, err] = fmincon(...
                                 @(p) jointfit(deltas, ...
                                               p, ...
                                               @forward_rigid, @inverse_rigid, ...
                                               @(p) {T(p(1:dims))*R(p(dims+1:end))}, ...
                                               Dq, Dr), ...
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
                                               p, ...
                                               @forward_prismatic, @inverse_prismatic, ...
                                               @(p) unpack_prismatic(p, dims), ...
                                               Dq, Dr), ...
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
                                               p, ...
                                               @forward_revolute, @inverse_revolute, ...
                                               @(p) unpack_revolute(p, dims), ...
                                               Dq, Dr), ...
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

function [err, grad] = jointfit(deltas, p, forward, inverse, unpack, Dq, Dr)
    %fprintf('\t\t\t%s\n', format_SE(p{1}));
    err = 0;
    grad = zeros(size(p));
    
    % accumulate error at each frame
    for frame = 1:length(deltas)
        % perform IK to get the observed params
        [state, Dki] = inverse(deltas{frame}, unpack(p));
        
        % get error between real SE pose and observed-modeled SE pose
        [estimate, Dkr, Dkt] = forward(unpack(p), state);
        [e, Dd] = SE_dist(estimate, deltas{frame}, Dkr, Dkt, Dki, Dq, Dr);
        err = err + e;
        grad = grad + Dd;
    end
end

% returns "distance" between two elements of SE(n)
% also returns gradient of the distance WRT u
function [dist, grad] = SE_dist(u, v, Dkr, Dkt, Dki, Dq, Dr)
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

    if nargout == 2
        if nargin ~= 7
            error('To calculate a gradient SE_dist needs gradient inputs');
        else
            %fprintf('SIZES: Dq[%d %d] Dr[%d %d] Dkr[%d %d] Dkt[%d %d] Dki[%d %d]\n', size(Dq(ur,vr),1),size(Dq(ur,vr),2), size(Dr(ut,vt),1),size(Dr(ut,vt),2), size(Dkr,1),size(Dkt,2), size(Dkt,1),size(Dkt,2), size(Dki,1),size(Dki,2));
            grad = c*Dq(ur,vr)*Dkr*Dki + d*Dr(ut,vt)*Dkt*Dki;
        end
    end
end
