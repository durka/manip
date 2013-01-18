function S = manip_learn(X, dbg, pairs)
    if dbg
        dbg = @fprintf;
    else
        dbg = @(varargin) fprintf('');
    end
    
    dbg('Begin learning\n');
    tic;
    profile on;
    
    S = struct('a', {}, 'b', {}, 'joint', {}, 'params', {}, 'state', {}, 'bounds', {}, 'cost', {});

    f = size(X, 1);
    n = size(X, 2);
    dims = size(X, 3) - 1;
    dbg('Detected f=%d, n=%d, dims=%d\n', f, n, dims);

    if nargin == 3
        dbg('Fitting all models to given joints...\n');
        for i = 1:size(pairs,2)
            S = [S, learn_joint(X,f,dims,dbg, pairs(1,i),pairs(2,i))];
        end
    else
        dbg('Fitting all models to all possible joints...\n');
        for a = 1:n
            parfor b = a+1:n
                S = [S, learn_joint(X,f,dims,dbg, a,b)];
            end
        end
    end
    
    dbg('Finding minimum spanning tree...\n');
    [S.a; S.b; S.cost]
    {S.joint}
    G = sparse([S.a], [S.b], [S.cost], max([S.a S.b]), max([S.a S.b]));
    G = tril(G + G'); % convert to undirected
    [MST, pred] = graphminspantree(G)
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
    
    dbg('Removing rigid subclusters...\n');
    SS = S(strcmp({S.joint}, 'rigid'));
    S = S(~strcmp({S.joint}, 'rigid'));
    dbg('\trigid part\n\t\t%s\n\t\t%s\n\tnonrigid part\n\t\t%s\n\t\t%s\n', mat2str([SS.a]), mat2str([SS.b]), mat2str([S.a]), mat2str([S.b]));
    for i = 1:length(SS)
        % merge the nodes in S
        
        for j = find([S.b] == SS(i).a)
            dbg('\tadding transform after joint %d-%d\n', S(j).a, S(j).b);
            S(j).b = SS(i).a;
            S(j).params = feval(['move_' S(j).joint], S(j).params, 'b', SS(i).params{1});
        end
        
        for j = find([S.a] == SS(i).b)
            dbg('\tadding transform before joint %d-%d\n', S(j).a, S(j).b);
            S(j).a = SS(i).a;
            S(j).params = feval(['move_' S(j).joint], S(j).params, 'a', SS(i).params{1});
        end
    end
    
    dbg('Fixing up the indices...\n');
    for i = 1:max([S.a S.b])
        j = i;
        
        if j > [S.a S.b]
            break
        end
        
        while j ~= [S.a S.b]
            j = j + 1;
        end
        
        if j ~= i
            dbg('\t%d >= %d\n', j, i);
            dbg('\t\t%s\n\t\t%s\n', mat2str([S.a]), mat2str([S.b]));
            for k = find([S.a] == j)
                S(k).a = i;
            end
            for k = find([S.b] == j)
                S(k).b = i;
            end
            dbg('\t\t%s\n\t\t%s\n', mat2str([S.a]), mat2str([S.b]));
        end
    end
    
    dbg('Done learning (%g sec)\n\n', toc);
    profile viewer;
end

function s = learn_joint(X,f,dims,dbg, a,b)
    dbg('\tTrying joint %d-%d...\n', a, b);

    [deltas, t1, r1, t2, r2, t3, r3] = calc_deltas(X, a, b);

    options = optimset('fmincon');
    options = optimset(options, 'Algorithm', 'sqp');
    options = optimset(options, 'GradObj', 'on');
    options = optimset(options, 'GradConstr', 'on');
    options = optimset(options, 'MaxFunEvals', 1e10);
    options = optimset(options, 'MaxIter', 1e10);
    options = optimset(options, 'Display', 'off');
    options = optimset(options, 'Diagnostics', 'off');

    [rigid_fit, rigid_err, flag, output] = fmincon(...
                         @(p) jointfit(deltas, ...
                                       p, ...
                                       @mex_forward_rigid, @mex_inverse_rigid, ...
                                       @(p) {Tmex(p(1:dims))*Rmex(p(dims+1:end))}, ...
                                       @gen_jacobians, @gen_jacobians), ...
                         guess_rigid(t1, r1, t2, r2, t3, r3), ...
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
                                       @mex_forward_prismatic, @mex_inverse_prismatic, ...
                                       @(p) unpack_prismatic(p, dims), ...
                                       @gen_jacobians, @gen_jacobians), ...
                         guess_prismatic(t1, r1, t2, r2, t3, r3), ...
                         [], [], [], [], ... % no linear constraints
                         [-inf(size(t1)) -pi*ones(size(r1)) -ones(1,dims)], ...
                         [ inf(size(t1))  pi*ones(size(r1))  ones(1,dims)], ...
                         [],...%@(p) nonlcon_unit(p, dims), ... % constrain unit vector to unit length
                         options);
    prismatic_params = unpack_prismatic(prismatic_fit, dims);
    dbg('\t\tPrismatic joint (%d steps, err=%g, flag=%d): o=%s u=%s\n', output.iterations, prismatic_err, flag, format_SE(prismatic_params{1}, 3), mat2str(prismatic_params{2}, 3));

    [revolute_fit, revolute_err, flag, output] = fmincon(...
                         @(p) jointfit(deltas, ...
                                       p, ...
                                       @mex_forward_revolute, @mex_inverse_revolute, ...
                                       @(p) unpack_revolute(p, dims), ...
                                       @gen_jacobians, @gen_jacobians), ...
                         guess_revolute(t1, r1, t2, r2, t3, r3), ...
                         [], [], [], [], ... % no linear constraints
                         [-inf(size(t1)) -pi*ones(size(r1)) -inf(size(t1)) -pi*ones(size(r1))], ...
                         [ inf(size(t1))  pi*ones(size(r1))  inf(size(t1))  pi*ones(size(r1))], ...
                         [], ... % no nonlinear constraints
                         options);
    revolute_params = unpack_revolute(revolute_fit, dims);
    dbg('\t\tRevolute joint (%d steps, err=%g, flag=%d): c=%s o=%s\n', output.iterations, revolute_err, flag, format_SE(revolute_params{1}, 3), format_SE(revolute_params{2}, 3));

    names = {'rigid', 'prismatic', 'revolute'};
    fits = {rigid_fit, prismatic_fit, revolute_fit};
    params = {rigid_params, prismatic_params, revolute_params};
    errs = [rigid_err, prismatic_err, revolute_err];
    crits = errs + cellfun(@length, fits); % TODO need weights here
    [best_crit, best] = min(crits);
    dbg('\tBest: %s (bics %s)\n', names{best}, mat2str(crits, 3));
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
