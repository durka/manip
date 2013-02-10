% manip_visualize(X, 'prismatic', 2, 3, figure_handle)
%   leave out figure_handle and I will create one
%   leave out a and b and I will default to 1 and 2

function [H, before, after, se] = manip_visualize(X, joint, a, b, f)

    switch nargin
        case 2
            a = 1;
            b = 2;
            f = figure;
        case 3
            f = a;
            a = 1;
            b = 2;
        case 4
            f = figure;
        case 5
            % well we're all good then
        otherwise
            error('Need to pass at least X and joint. Then a+b, f or both');
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
    %options = optimset(options, 'GradObj', 'on');
    %options = optimset(options, 'GradConstr', 'on');
    %options = optimset(options, 'DerivativeCheck', 'on');
    options = optimset(options, 'MaxFunEvals', 1e10);
    options = optimset(options, 'MaxIter', 1e10);
    options = optimset(options, 'Display', 'off');
    options = optimset(options, 'Diagnostics', 'on');
    
    before = feval(['guess_' joint], deltas, t1, r1, t2, r2, t3, r3);
    [after, err] = fmincon(...
                         @(p) jointfit(deltas, ...
                                       p, ...
                                       eval(['@mex_forward_' joint]), eval(['@mex_inverse_' joint]), ...
                                       eval(['@(p) unpack_' joint '(p, 3)']), ...
                                       @gen_jacobians, @gen_jacobians, ...
                                       false), ...
                         before, ...
                         [], [], [], [], ... % no linear constraints
                         -lims, ...
                          lims, ...
                         [], ... % no nonlinear constraints
                         options);
    
    subplot(2,1,1);
    Hb = visualize('GUESSED', joint, a, b, deltas, se, feval(['unpack_' joint], before, 3));
    subplot(2,1,2);
    Ha = visualize(sprintf('LEARNED (%g)', err), joint, a, b, deltas, se, feval(['unpack_' joint], after, 3));
    
    H = {H Hb Ha};
end

function H = visualize(tag, joint, a, b, deltas, se, p)
    
    cellind = @(c,s) cellfun(@(d) subsref(d, substruct('()', s)), c);
    
    % plot the data
    H = {  quiver3(cellind(deltas, {1,4}), cellind(deltas, {2,4}), cellind(deltas, {3,4}), ...
                   cellind(deltas, {1,1}), cellind(deltas, {2,1}), cellind(deltas, {3,1}), 0, 'b')};
    hold on;
    
    % plot the 3 sample points
    H = {H quiver3(deltas{1}(1,4), deltas{1}(2,4), deltas{1}(3,4), ...
                   deltas{1}(1,1), deltas{1}(2,1), deltas{1}(3,1), 0, 'r') ...
           quiver3(deltas{floor(end/2)}(1,4), deltas{floor(end/2)}(2,4), deltas{floor(end/2)}(3,4), ...
                   deltas{floor(end/2)}(1,1), deltas{floor(end/2)}(2,1), deltas{floor(end/2)}(3,1), 0, 'g') ...
           quiver3(deltas{end}(1,4), deltas{end}(2,4), deltas{end}(3,4), ...
                   deltas{end}(1,1), deltas{end}(2,1), deltas{end}(3,1), 0, 'k')};
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
            
            [~, plane] = guess_revolute(deltas, se{1}{1}, se{1}{2}, se{2}{1}, se{2}{2}, se{3}{1}, se{3}{2});
            
            H = {H quiver3(plane(1), plane(2), plane(3),      ... % plane
                           plane(4), plane(5), plane(6), 'c') ...
                   quiver3(plane(1), plane(2), plane(3),      ...
                           plane(7), plane(8), plane(9), 'b') ...
                                                              ...
                   plot_se(p{1})}; % circumcenter and rotation axes
            
            % TODO how to show p{2}
            
    end
    
    axis equal;
    hold off;
    title(sprintf('%s %s joint model for %d-%d', tag, joint, a, b));
    xlabel('X');
    ylabel('Y');
    zlabel('Z');

end

function [H, t, r] = plot_se(se)

    d = size(se,1) - 1;
    t = se(1:d, d+1);
    r = se(1:d, 1:d);

    H = {plot3(t(1), t(2), t(3), '.', 'MarkerSize', 20) ...
         quiver3(t(1), t(2), t(3), r(1,1), r(2,1), r(3,1), 'r') ...
         quiver3(t(1), t(2), t(3), r(1,2), r(2,2), r(3,2), 'g') ...
         quiver3(t(1), t(2), t(3), r(1,3), r(2,3), r(3,3), 'b')};
               
end
