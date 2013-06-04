function [origin, radius, caxis, pitch, plane, theta] = helfit2(X,a,b, opt) % X is FxNx4x4

figure(evalin('base', 'fhf2'));
clf;

if ~exist('opt', 'var')
    opt = false;
end

deltas = calc_deltas(X, a, b);
Y = cell2mat(cellfun(@(d) subsref((d*[0;0;0;1])', substruct('()', {1:3})), deltas, 'UniformOutput',false));

% new axis plan made up from scratch

% STEP 1: cylinder axis and radius
% first, find the cylinder axis
N = size(Y,1);
[basis proj] = princomp(Y); % run PCA to find the axes
n = size(basis,2);
plane = zeros(n, 9);
Y_p3 = zeros(N, 3, n);
Y_p2 = zeros(N, 2, n);
origin_p2 = zeros(2, n);
origin = zeros(3, n);
radius = zeros(1, n);
thickness = zeros(1, n);
err = zeros(1, n);
for i=1:n
    c = basis\mean(proj)';
    c(i) = min(Y(:,i));
    plane(i,:) = createPlane(c', basis(:,i)');
    Y_p3(:,:,i) = projPointOnPlane(Y, plane(i,:));
    Y_p2(:,:,i) = planePosition(Y_p3(:,:,i), plane(i,:));
    
    [origin_p2(:,i), ~, err(i)] = find_center(Y_p2(:,:,i));
    origin(:,i) = planePoint(plane(i,:), origin_p2(:,i)');
    radius(i) = mean(sqrt(sum(bsxfun(@minus, Y_p2(:,:,i), origin_p2(:,i)').^2, 2)));
    thickness(i) = std(sqrt(sum(bsxfun(@minus, Y_p2(:,:,i), origin_p2(:,i)').^2, 2)));
end
[~,h] = min(err); % TODO WTF why radius instead of thickness % choose the axis that leads to the most-circular projection (lowest STD in the radius)
thickness
radius
err
h
%pause
caxis = basis(:,h)';
origin = origin(:,h);
origin_p2 = origin_p2(:,h);
radius = radius(h);
plane = plane(h,:);
Y_p3 = Y_p3(:,:,h);
Y_p2 = Y_p2(:,:,h);

% STEP 2: helix pitch
% departing from the paper here because it doesn't make any sense
% approach: find the angles of pY WRT pa, then divide by projected distance along H to get the pitch
theta = zeros(N,1);
for j=1:size(Y,1)
    theta(j) = atan2((Y_p2(j,2) - origin_p2(2)), (Y_p2(j,1) - origin_p2(1)));
end
p = polyfit(unwrap(theta), Y*caxis', 1);
pitch = p(1);

if opt
    % do the extra optimization (from Aqvist paper)
    
    do_plot(211, Y, Y_p3, origin, caxis, plane, theta, radius, pitch);
    
    origin, radius, caxis, pitch
    
    options = optimset('fmincon');
    options = optimset(options, 'Algorithm', 'active-set');
    %options = optimset(options, 'GradObj', 'on');
    %options = optimset(options, 'DerivativeCheck', 'on');
    %options = optimset(options, 'GradConstr', 'on');
    options = optimset(options, 'MaxFunEvals', 1e10);
    options = optimset(options, 'MaxIter', 1e10);
    options = optimset(options, 'Display', 'off');
    options = optimset(options, 'Diagnostics', 'off');

    [fit, err, flag, output] = fmincon(...
                         @(p) objective_thinair(p, Y), ...
                         ...%[mean(Y_p3) caxis], ...
                         [origin' caxis], ...
                         [], [], [], [], ... % no linear constraints
                         [min(Y(:,1)) min(Y(:,2)) min(Y(:,3)), -1 -1 -1]-10, ...
                         [max(Y(:,1)) max(Y(:,2)) max(Y(:,3)),  1  1  1]+10, ... % no upper limit
                         @constraint, ...
                         options);
    
   origin = fit(1:3)';
   caxis = fit(4:6)';
   
   % recalculate the stuff
   plane = createPlane(origin', caxis');
   Y_p3 = projPointOnPlane(Y, plane);
   Y_p2 = planePosition(Y_p3, plane);
   origin_p2 = planePosition(origin', plane);
   radius = mean(sqrt(sum(bsxfun(@minus, Y_p2, origin_p2).^2, 2)));
   
   % STEP 2: helix pitch
   % departing from the paper here because it doesn't make any sense
   % approach: find the angles of pY WRT pa, then divide by projected distance along H to get the pitch
   %circ = enclosingCircle(pY);
   %pa = circ(1:2);
   %a = planePoint(plane, pa)';
   theta = zeros(N,1);
   for j=1:size(Y,1)
       theta(j) = atan2((Y_p2(j,2) - origin_p2(2)), (Y_p2(j,1) - origin_p2(1)));
   end
   p = polyfit(unwrap(theta), Y*caxis, 1);
   pitch = p(1);
   
end

do_plot(212, Y, Y_p3, origin, caxis, plane, theta, radius, pitch);

%if ~opt
    subplot(211);
    %plot(1:N, unwrap(theta), 1:N, Y*caxis');
    plot(cellfun(@(d) dot(d(1:3,1), caxis), deltas));
%end

origin, radius, caxis, pitch

end

function do_plot(sp, y, yp, or, ca, pl, th, ra, pit)

    if dot(ca, y(1,:)) < 0
        ca = -ca;
    end

    % some hacky forward kinematics up in here
    th = unwrap(th);
    th = th - min(th);
    fprintf('theta goes from %g to %g\n', min(th), max(th));
    th = linspace(min(th), 2*max(th)-min(th), 1000)';
    x = [cos(th)*ra sin(th)*ra th*pit];
    x = x*vrrotvec2mat([cross([0 0 1], ca) real(acos(dot([0 0 1], ca)))])'; % rotate it so the z-axis is correct by rotating around cross(current Z, target Z) by acos(dot(current Z, target Z))
    x = bsxfun(@plus, or', x); % make the  helix
    
    subplot(sp);
    hold on;
    plot3(y(:,1), y(:,2), y(:,3), '.', yp(:,1), yp(:,2), yp(:,3), '.', x(:,1), x(:,2), x(:,3), 'LineWidth',2);
    
    plot3(or(1), or(2), or(3), 'r.', 'MarkerSize',5);
    quiver3(or(1), or(2), or(3), ca(1), ca(2), ca(3), 30, 'r', 'LineWidth',3);
    %drawPlane3d(pl);
    hold off;
    axis equal;

end

function a = dd(varargin)
    for i=1:length(varargin)-1
        disp(varargin{i});
    end
    a = varargin{end};
end

function f = objective_thinair(p, Y)
    % new idea: optimize for circularity of projection
    
    r = p(1:3);
    a = p(4:6);
    
    plane = createPlane(r, a);
    Y_p3 = projPointOnPlane(Y, plane);
    Y_p2 = planePosition(Y_p3, plane);
    o = find_center(Y_p2);
    
    x = sqrt(sum(bsxfun(@minus, Y_p2, o).^2, 2));
    f = std(x);
end

function [f, grad] = objective_paper(p, Y)
    % from Aqvist paper
    
    r = p(1:3);
    a = p(4:6)';
    
    d = bsxfun(@minus, Y, bsxfun(@plus, r, (Y*a)*a'));
    dm = sqrt(sum(d.^2, 2));
    dmm = dm - mean(dm);
    
    dd = zeros(size(Y,1), 6);
    dd(:,1:3) = -bsxfun(@rdivide, d, dm);
    dd(:,4:6) = -bsxfun(@times, dd(:,1:3), Y*a);
    dd = bsxfun(@minus, dd, mean(dd));
    
    f = sum(dmm.^2);
    grad = 2 * sum(bsxfun(@times, dmm, dd));
end

function [c, ceq] = constraint(p)
    r = p(1:3);
    a = p(4:6);

    c = [];
    ceq = [0*dot(r,a); norm(a) - 1];
end