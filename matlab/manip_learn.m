function S = manip_learn(X, dbg)
    if dbg
        dbg = @fprintf;
    else
        dbg = @(varargin) fprintf('');
    end
    
    clc;
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
    s = evalc('simplify(jacobian(feval(symengine, ''norm'', A - B, 2)^2, A))');
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
            options = optimset(options, 'Algorithm', 'sqp');
            options = optimset(options, 'GradObj', 'on');
            options = optimset(options, 'GradConstr', 'on');
            options = optimset(options, 'MaxFunEvals', 1e10);
            options = optimset(options, 'MaxIter', 1e10);
            %options = optimset(options, 'Display', 'off');
            %options = optimset(options, 'Diagnostics', 'off');
            
            [rigid_fit, err, ~, output] = fmincon(...
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
            dbg('\t\tRigid joint (%d steps, err=%g): o=%s\n', output.iterations, err, format_SE(rigid_params, 3));
            
            
            dbg('\t%s\n', mat2str([t r, eye(1,dims)], 3));
            [prismatic_fit, err, ~, output] = fmincon(...
                                 @(p) jointfit(deltas, ...
                                               p, ...
                                               @forward_prismatic, @inverse_prismatic, ...
                                               @(p) unpack_prismatic(p, dims), ...
                                               Dq, Dr), ...
                                 [t r, eye(1,dims)], ...
                                 [], [], [], [], ... % no linear constraints
                                 [-inf(size(t)) -pi*ones(size(r)) -ones(1,dims)], ...
                                 [ inf(size(t))  pi*ones(size(r))  ones(1,dims)], ...
                                 @(p) nonlcon_unit(p, dims), ... % constrain unit vector to unit length
                                 options);
            prismatic_params = unpack_prismatic(prismatic_fit, dims);
            dbg('\t\tPrismatic joint (%d steps, err=%g): o=%s u=%s\n', output.iterations, err, format_SE(prismatic_params{1}, 3), mat2str(prismatic_params{2}, 3));
            
            
            [revolute_fit, err, ~, output] = fmincon(...
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
            dbg('\t\tRevolute joint (%d steps, err=%g): c=%s o=%s\n', output.iterations, err, format_SE(revolute_params{1}, 3), format_SE(revolute_params{2}, 3));
        end
    end
    
    dbg('Done learning (%g sec)\n\n', toc);
    profile viewer;
end

function [c,ceq,gc,gceq] = nonlcon_unit(p, dims)
    c = [];
    ceq = sum(p(end-dims+1).^2) - 1;
    gc = [];
    gceq = zeros(size(p'));
    gceq(end-dims+1:end) = 2*p(end-dims+1:end);
end
