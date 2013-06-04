function S = manip_learn(X, dbg, pairs, check)
    if dbg
        dbg = @fprintf;
    else
        dbg = @(varargin) fprintf('');
    end
    
    if nargin < 4
        check = false;
    end
    
    dbg('Begin learning\n');
    tic;
    %profile on;
    
    S = struct('a', {}, 'b', {}, 'joint', {}, 'params', {}, 'state', {}, 'bounds', {}, 'cost', {});

    f = size(X, 1);
    n = size(X, 2);
    dims = size(X, 3) - 1;
    dbg('Detected f=%d, n=%d, dims=%d\n', f, n, dims);

    if nargin == 3
        dbg('Fitting all models to given joints...\n');
        for i = 1:size(pairs,2)
            S = [S, learn_joint(X,f,dims,dbg, pairs(1,i),pairs(2,i), check)];
        end
    else
        dbg('Fitting all models to all possible joints...\n');
        for a = 1:n
            parfor b = a+1:n
                S = [S, learn_joint(X,f,dims,dbg, a,b, check)];
            end
        end
    end
    
    dbg('Fixing up the indices...\n');
    S = fixup_indices(S, dbg);
    
    dbg('Finding minimum spanning tree...\n');
    %[S.a; S.b; S.cost]
    %{S.joint}
    G = sparse([S.a], [S.b], [S.cost], max([S.a S.b]), max([S.a S.b]));
    G = tril(G + G'); % convert to undirected
    [MST, pred] = graphminspantree(G);
    SS = S;
    S = struct('a', {}, 'b', {}, 'joint', {}, 'params', {}, 'state', {}, 'bounds', {}, 'cost', {});
    for i = 2:length(pred)
        a = pred(i);
        b = i;
        S(i-1) = SS(([SS.a] == a & [SS.b] == b) | ([SS.a] == b & [SS.b] == a));
        
        dbg('\tinserting %s joint from %d to %d ', S(i-1).joint, a, b);
        
        % might have to reverse the edge
        if S(i-1).a == b
            dbg('reversed');
            S(i-1).a = a;
            S(i-1).b = b;
            S(i-1).params = feval(['reverse_' S(i-1).joint], S(i-1).params);
            S(i-1).bounds = -S(i-1).bounds;
            S(i-1).state = -S(i-1).state;
        end
        dbg('\n');
    end
    
    dbg('NOT Removing rigid subclusters...\n');
    %S = remove_rigid_subclusters(S, dbg);
    
    dbg('Fixing up the indices again...\n');
    S = fixup_indices(S, dbg);
    
    dbg('Done learning (%g sec)\n\n', toc);
    %profile viewer;
end

function s = learn_joint(X,f,dims,dbg, a,b, check)
    dbg('\tTrying joint %d-%d...\n', a, b);

    [deltas, t1, r1, t2, r2, t3, r3] = calc_deltas(X, a, b);

    options = optimset('fmincon');
    options = optimset(options, 'Algorithm', 'sqp');
    %options = optimset(options, 'GradObj', 'on');
    %options = optimset(options, 'DerivativeCheck', 'on');
    %options = optimset(options, 'GradConstr', 'on');
    options = optimset(options, 'MaxFunEvals', 1e10);
    options = optimset(options, 'MaxIter', 1e10);
    options = optimset(options, 'Display', 'off');
    options = optimset(options, 'Diagnostics', 'off');

    if false
    [rigid_fit, rigid_err, flag, output] = fmincon(...
                         @(p) jointfit(deltas, ...
                                       p, ...
                                       @forward_rigid, @inverse_rigid, ...
                                       @gen_jacobians, @gen_jacobians, ...
                                       check), ...
                         guess_rigid(deltas, t1, r1, t2, r2, t3, r3), ...
                         [], [], [], [], ... % no linear constraints
                         [-inf(size(t1)) -pi*ones(size(r1))], ...
                         [ inf(size(t1))  pi*ones(size(r1))], ...
                         [], ... % no nonlinear constraints
                         options);
    rigid_params = {T(rigid_fit(1:dims))*R(rigid_fit(dims+1:end))};
    dbg('\t\tRigid joint (%d steps, err=%g, flag=%d): o=%s\n', output.iterations, rigid_err, flag, format_SE(rigid_params{1}, 3));


    %dbg('\t%s\n', mat2str([t r, eye(1,dims)], 3));
    [prismatic_fit, prismatic_err, flag, output] = fmincon(...
                         @(p) jointfit(deltas, ...
                                       p, ...
                                       @forward_prismatic, @inverse_prismatic, ...
                                       @gen_jacobians, @gen_jacobians, ...
                                       check), ...
                         guess_prismatic(deltas, t1, r1, t2, r2, t3, r3), ...
                         [], [], [], [], ... % no linear constraints
                         [-inf(size(t1)) -pi*ones(size(r1)) -ones(1,dims)], ...
                         [ inf(size(t1))  pi*ones(size(r1))  ones(1,dims)], ...
                         [],...%@(p) nonlcon_unit(p, dims), ... % constrain unit vector to unit length
                         options);
    prismatic_params = unpack_prismatic(prismatic_fit);
    dbg('\t\tPrismatic joint (%d steps, err=%g, flag=%d): o=%s u=%s\n', output.iterations, prismatic_err, flag, format_SE(prismatic_params{1}, 3), mat2str(prismatic_params{2}, 3));

    [revolute_fit, revolute_err, flag, output] = fmincon(...
                         @(p) jointfit(deltas, ...
                                       p, ...
                                       @mex_forward_revolute, @mex_inverse_revolute, ...
                                       @gen_jacobians, @gen_jacobians, ...
                                       check), ...
                         guess_revolute(deltas, t1, r1, t2, r2, t3, r3), ...
                         [], [], [], [], ... % no linear constraints
                         [-inf(size(t1)) -pi*ones(size(r1)) -inf(size(t1)) -pi*ones(size(r1))], ...
                         [ inf(size(t1))  pi*ones(size(r1))  inf(size(t1))  pi*ones(size(r1))], ...
                         [], ... % no nonlinear constraints
                         options);
    revolute_params = unpack_revolute(revolute_fit);
    dbg('\t\tRevolute joint (%d steps, err=%g, flag=%d): c=%s o=%s\n', output.iterations, revolute_err, flag, format_SE(revolute_params{1}, 3), format_SE(revolute_params{2}, 3));
    end
    
    [screw_fit, screw_err, flag, output] = fmincon(...
                         @(p) jointfit(deltas, ...
                                       p, ...
                                       @forward_screw, @inverse_screw, ...
                                       @gen_jacobians, @gen_jacobians, ...
                                       check), ...
                         guess_screw(deltas, t1, r1, t2, r2, t3, r3), ...
                         [], [], [], [], ... % no linear constraints
                         [-inf(size(t1)) -pi*ones(size(r1)) -inf(size(t1)) -pi*ones(size(r1))], ...
                         [ inf(size(t1))  pi*ones(size(r1))  inf(size(t1))  pi*ones(size(r1))], ...
                         [], ... % no nonlinear constraints
                         options);
    screw_params = unpack_screw(screw_fit);
    dbg('\t\tScrew joint (%d steps, err=%g, flag=%d): c=%s o=%s p=%g\n', output.iterations, screw_err, flag, format_SE(screw_params{1}, 3), format_SE(screw_params{2}, 3), screw_params{3});
    
    names = {'rigid', 'prismatic', 'revolute', 'screw'};
    fits = cellfun(@(f) evalin('caller', [f '_fit']), names, 'UniformOutput',false);
    params = cellfun(@(f) evalin('caller', [f '_params']), names, 'UniformOutput',false);
    errs = cellfun(@(f) evalin('caller', [f '_err']), names);
    crits = errs + cellfun(@length, fits); % TODO need weights here
    [best_crit, best] = min(crits);
    dbg('\tBest %d-%d: %s (bics %s)\n', a, b, names{best}, mat2str(crits, 3));
    s = struct('a',      a, ...
               'b',      b, ...
               'joint',  names{best}, ...
               'params', params(best), ...
               'bounds', [0;0], ...
               'state',  0, ...
               'cost',   best_crit);
    %s.cost = s.cost + SE_dist(eye(dims+1), feval(['forward_' s.joint], s.params, s.state)); % forest-tree problem
end

function [c,ceq,gc,gceq] = nonlcon_unit(p, dims)
    c = [];
    ceq = sum(p(end-dims+1).^2) - 1;
    gc = [];
    gceq = zeros(size(p'));
    gceq(end-dims+1:end) = 2*p(end-dims+1:end);
end
