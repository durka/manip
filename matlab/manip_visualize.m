% manip_visualize(X, 'prismatic', 2, 3, figure_handle)
%   leave out figure_handle and I will create one
%   leave out a and b and I will default to 1 and 2

function [H, params, se] = manip_visualize(X, joint, a, b, f)

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
    
    [deltas, t1, r1, t2, r2, t3, r3] = calc_deltas(X, a, b);
    se = {{t1, r1}, {t2, r2}, {t3, r3}};
    
    figure(f);
    clf;
    H = {f};
    
    cellind = @(c,s) cellfun(@(d) subsref(d, substruct('()', s)), c);
    
    % plot the data
    H = {H quiver3(cellind(deltas, {1,4}), cellind(deltas, {2,4}), cellind(deltas, {3,4}), ...
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
            params = guess_rigid(t1, r1, t2, r2, t3, r3);
            
        case 'prismatic'
            params = guess_prismatic(t1, r1, t2, r2, t3, r3);
            
        case 'revolute'
            [params, plane] = guess_revolute(t1, r1, t2, r2, t3, r3);
            
            ct = params(1:3);
            cr = params(4:6);
            Rcr = R(cr);
            
            % plane
            H = {H quiver3(plane([1 1]), plane([2 2]), plane([3 3]), ...
                           plane([4 7]), plane([5 8]), plane([6 9]), 'c')};
            
            % circumcenter and rotation axes
            H = {H plot3(ct(1), ct(2), ct(3), '.', 'MarkerSize', 20) ...
                   quiver3(ct(1), ct(2), ct(3), Rcr(1,1), Rcr(2,1), Rcr(3,1), 'r') ...
                   quiver3(ct(1), ct(2), ct(3), Rcr(1,2), Rcr(2,2), Rcr(3,2), 'g') ...
                   quiver3(ct(1), ct(2), ct(3), Rcr(1,3), Rcr(2,3), Rcr(3,3), 'b')};
    end
    
    axis equal;
    hold off;
    title(sprintf('%s joint model for %d-%d', joint, a, b));
    xlabel('X');
    ylabel('Y');
    zlabel('Z');

end
