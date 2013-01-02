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
            
            [t, r] = extract_SE(squeeze(X(1,b,:,:))\squeeze(X(1,a,:,:)));
            deltas = cell(f, 1);
            for frame = 1:f
                deltas{frame} = squeeze(X(frame, b, :,:))\squeeze(X(frame, a, :,:));
            end
            [t1, r1] = extract_SE(deltas{1});
            [t2, r2] = extract_SE(deltas{floor(end/2)});
            [t3, r3] = extract_SE(deltas{end});
            
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
                                               @forward_rigid, @inverse_rigid, ...
                                               @(p) {T(p(1:dims))*R(p(dims+1:end))}, ...
                                               Dq, Dr), ...
                                 [t1 r1], ...
                                 [], [], [], [], ... % no linear constraints
                                 [-inf(size(t)) -pi*ones(size(r))], ...
                                 [ inf(size(t))  pi*ones(size(r))], ...
                                 [], ... % no nonlinear constraints
                                 options);
            rigid_params = {T(rigid_fit(1:dims))*R(rigid_fit(dims+1:end))};
            dbg('\t\tRigid joint (%d steps, err=%g, flag=%d): o=%s\n', output.iterations, rigid_err, flag, format_SE(rigid_params{1}, 3));
            
            
            %dbg('\t%s\n', mat2str([t r, eye(1,dims)], 3));
            [prismatic_fit, prismatic_err, flag, output] = fmincon(...
                                 @(p) jointfit(deltas, ...
                                               p, ...
                                               @forward_prismatic, @inverse_prismatic, ...
                                               @(p) unpack_prismatic(p, dims), ...
                                               Dq, Dr), ...
                                 [t1 r1, (t3 - t1)/norm(t3 - t1)], ...
                                 [], [], [], [], ... % no linear constraints
                                 [-inf(size(t)) -pi*ones(size(r)) -ones(1,dims)], ...
                                 [ inf(size(t))  pi*ones(size(r))  ones(1,dims)], ...
                                 [],...%@(p) nonlcon_unit(p, dims), ... % constrain unit vector to unit length
                                 options);
            prismatic_params = unpack_prismatic(prismatic_fit, dims);
            dbg('\t\tPrismatic joint (%d steps, err=%g, flag=%d): o=%s u=%s\n', output.iterations, prismatic_err, flag, format_SE(prismatic_params{1}, 3), mat2str(prismatic_params{2}, 3));
            
            % TODO implement this for 2D
            nhat = cross(t3 - t1, t2 - t1);
            nhat = nhat/norm(nhat);
            % for the translation, use the circumcenter of the three points
            % (have to dance around projecting in and out of the plane)
            plane = createPlane(t1, t2, t3);
            in_plane = planePosition([t1; t2; t3], plane);
            ct = planePoint(plane, circumCenter(in_plane(1,:), in_plane(2,:), in_plane(3,:)));
            % for the rotation, the Z axis needs to go to n
            % and the X axis has to go to norm(t1 - ct)
            % so we can cross those to get the Y axis
            % and use the three axes to make up the rotation matrix?
            cr = zeros(3,3);
            cr(:,1) = (t1 - ct)/norm(t1 - ct);
            cr(:,2) = cross(nhat, cr(:,1));
            cr(:,3) = nhat;
            [~, cr] = extract_SE([cr, [0 0 0]'; 0 0 0 1]);
            dbg('\t\tinitial revolute params: %s\n', mat2str([-ct cr, ct-t1 r1], 3));
            [revolute_fit, revolute_err, flag, output] = fmincon(...
                                 @(p) jointfit(deltas, ...
                                               p, ...
                                               @forward_revolute, @inverse_revolute, ...
                                               @(p) unpack_revolute(p, dims), ...
                                               Dq, Dr), ...
                                 [-ct cr, ct-t1 r1], ...
                                 [], [], [], [], ... % no linear constraints
                                 [-inf(size(t)) -pi*ones(size(r)) -inf(1,dims) -pi*ones(1,dims)], ...
                                 [ inf(size(t))  pi*ones(size(r))  inf(1,dims)  pi*ones(1,dims)], ...
                                 [], ... % no nonlinear constraints
                                 options);
            revolute_params = unpack_revolute(revolute_fit, dims);
            dbg('\t\tRevolute joint (%d steps, err=%g, flag=%d): c=%s o=%s\n', output.iterations, revolute_err, flag, format_SE(revolute_params{1}, 3), format_SE(revolute_params{2}, 3));
            
            names = {'rigid', 'prismatic', 'revolute'};
            fits = {rigid_fit, prismatic_fit, revolute_fit};
            params = {rigid_params, prismatic_params, revolute_params};
            errs = [rigid_err, prismatic_err, revolute_err];
            crits = errs + 5*cellfun(@length, fits); % TODO need weights here
            [best_crit, best] = min(crits);
            dbg('\tBest: %s (bics %s)\n', names{best}, mat2str(crits, 3));
            i = length(S)+1;
            S(i).a = a;
            S(i).b = b;
            S(i).joint = names{best};
            S(i).params = params{best};
            S(i).bounds = [0;0];
            S(i).state = 0;
            S(i).cost = best_crit + SE_dist(eye(dims+1), feval(['forward_' S(i).joint], S(i).params, S(i).state));
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
        
        % might have to reverse the edge
        if S(i-1).a == b
            S(i-1).a = a;
            S(i-1).b = b;
            % TODO S(i-1).params = feval(['reverse_' S(i-1).joint], S(i-1).params);
        end
    end
    
    dbg('Removing rigid subclusters...\n');
    SS = S(strcmp({S.joint}, 'rigid'));
    S = S(~strcmp({S.joint}, 'rigid'));
    for i = 1:length(SS)
        % merge the nodes in S
        
        for j = find([S.b] == SS(i).b)
            S(j).b = SS(i).a;
            % TODO S(j).params = feval(['move_' S(j).joint], 'b', SS(i).params);
        end
        
        for j = find([S.a] == SS(i).b)
            S(j).a = SS(i).a;
            % TODO S(j).params = feval(['move_' S(j).joint], 'a', SS(i).params);
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

function [c,ceq,gc,gceq] = nonlcon_unit(p, dims)
    c = [];
    ceq = sum(p(end-dims+1).^2) - 1;
    gc = [];
    gceq = zeros(size(p'));
    gceq(end-dims+1:end) = 2*p(end-dims+1:end);
end
