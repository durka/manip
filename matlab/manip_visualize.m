% manip_visualize(X, 'prismatic', 2, 3, figure_handle)
%   pass figure_handle=0 and I will create one
%   plot 1: guess
%   plot 2: learned
%   if p is provided:
%       if mode='sim', p comes from design tree, use it to make a third plot
%       if mode='learn', p comes from learned tree, use it for plot 2 instead of running jointfit

function [H, before, after, se] = manip_visualize(X, joint, a, b, f, p, mode)

    if exist('p', 'var')
        if strcmp(mode, 'sim')
            psim = p;
        elseif strcmp(mode, 'learn')
            after = p;
        end
    end
    
    % calculate the deltas
    [deltas, t1, r1, t2, r2, t3, r3] = calc_deltas(X, a, b);
    se = {{t1, r1}, {t2, r2}, {t3, r3}};
    
    figure(f);
    clf;
    H = {f};
    
    switch joint
        case 'rigid'
            lims = [ inf(size(t1))  pi*ones(size(r1))];
        case 'prismatic'
            lims = [ inf(size(t1))  pi*ones(size(r1))  ones(1,3)];
        case 'revolute'
            lims = [ inf(size(t1))  pi*ones(size(r1))  inf(size(t1))  pi*ones(size(r1))];
    end

    options = optimset('fmincon');
    options = optimset(options, 'Algorithm', 'sqp');
    options = optimset(options, 'GradObj', 'on');
    %options = optimset(options, 'GradConstr', 'on');
    %options = optimset(options, 'DerivativeCheck', 'on');
    options = optimset(options, 'MaxFunEvals', 1e10);
    options = optimset(options, 'MaxIter', 1e10);
    options = optimset(options, 'Display', 'off');
    options = optimset(options, 'Diagnostics', 'on');

    objective = @(p) jointfit(deltas, ...
                              p, ...
                              eval(['@forward_' joint]), eval(['@inverse_' joint]), ...
                              @gen_jacobians, @gen_jacobians, ...
                              false);

    before = feval(['guess_' joint], deltas, t1, r1, t2, r2, t3, r3);
        
    if ~exist('after', 'var')
        [after, err] = fmincon(...
                             objective, ...
                             before, ...
                             [], [], [], [], ... % no linear constraints
                             -lims, ...
                              lims, ...
                             [], ... % no nonlinear constraints
                             options);
    else
        err = objective(after);
    end
    
    if exist('psim', 'var')
        plots = [2 2];
    else
        plots = [2 1];
    end
    
    subplot(plots(1), plots(2), 1);
    H = {H visualize(sprintf('GUESSED (%g)', objective(before)), joint, a, b, deltas, se, before)};
    subplot(plots(1), plots(2), 2);
    H = {H visualize(sprintf('LEARNED (%g)', err), joint, a, b, deltas, se, after)};
    if exist('psim', 'var')
        subplot(plots(1), plots(2), 3);
        H = {H visualize(sprintf('DESIGNED (%g)', objective(psim)), joint, a, b, deltas, se, psim)};
    end

end

function H = visualize(tag, joint, a, b, deltas, se, p)
    
    cellind = @(c,s) cellfun(@(d) subsref(d, substruct('()', s)), c);
    
    if ~iscell(p)
        p = feval(['unpack_' joint], p);
    end
    
    % plot the data
    H = {  quiver3(cellind(deltas, {1,4}), cellind(deltas, {2,4}), cellind(deltas, {3,4}), ...
                   cellind(deltas, {1,1}), cellind(deltas, {2,1}), cellind(deltas, {3,1}), 1, 'b')};
    hold on;
    
    % plot the 3 sample points
    H = {H quiver3(deltas{1}(1,4), deltas{1}(2,4), deltas{1}(3,4), ...
                   deltas{1}(1,1), deltas{1}(2,1), deltas{1}(3,1), 1, 'r') ...
           quiver3(deltas{floor(end/2)}(1,4), deltas{floor(end/2)}(2,4), deltas{floor(end/2)}(3,4), ...
                   deltas{floor(end/2)}(1,1), deltas{floor(end/2)}(2,1), deltas{floor(end/2)}(3,1), 1, 'g') ...
           quiver3(deltas{end}(1,4), deltas{end}(2,4), deltas{end}(3,4), ...
                   deltas{end}(1,1), deltas{end}(2,1), deltas{end}(3,1), 1, 'k')};
    set(get(H{2}, 'Children'), 'LineWidth',2);
    set(get(H{3}, 'Children'), 'LineWidth',2);
    set(get(H{4}, 'Children'), 'LineWidth',2);
    
    switch joint
        case 'rigid'
            
            H = {H plot_se(p{1})}; % anchor point
            
        case 'prismatic'
            
            [Hap, t, ~] = plot_se(p{1}); % anchor point
            u = p{2};
            
            H = {H Hap ...
                   quiver3(t(1), t(2), t(3), u(1), u(2), u(3), 'c')}; % unit vector
            
        case 'revolute'
            
            S = struct('a', {1}, 'b', {2}, 'joint', {joint}, 'params', {p});
            S = manip_fillout(S, {deltas});
            
            [~, plane] = guess_revolute(deltas, se{1}{1}, se{1}{2}, se{2}{1}, se{2}{2}, se{3}{1}, se{3}{2});
            circ = arrayfun(@(th) forward_revolute(p, th), S(1).trajectory, 'UniformOutput',false);
            
            H = {H quiver3(plane(1), plane(2), plane(3),      ... % plane
                           plane(4), plane(5), plane(6), 'c') ...
                   quiver3(plane(1), plane(2), plane(3),      ...
                           plane(7), plane(8), plane(9), 'b') ...
                                                              ...
                   plot_se(p{1}) ... % circumcenter and rotation axes
                                                              ...
                   quiver3(cellind(circ, {1,4}), cellind(circ, {2,4}), cellind(circ, {3,4}), ...
                           cellind(circ, {1,1}), cellind(circ, {2,1}), cellind(circ, {3,1}), 0.5, 'r')}; % radius
            
    end
    
    axis equal;
    hold off;
    title(sprintf('%s %s joint model for %d-%d', tag, joint, a, b));
    xlabel('X');
    ylabel('Y');
    zlabel('Z');

end
