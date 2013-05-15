function [a, r, p, plane] = helfit2(Y, opt) % Y is Nx3

if ~exist('opt', 'var')
    opt = false;
end

% new axis plan made up from scratch
% assumption: helix origin is at (0, 0, 0)

% STEP 1: cylinder axis and radius
% first, find the cylinder axis
N = size(Y,1);
coeff = princomp(Y); % run PCA to find the axes
plane = zeros(3, 9);
prY = zeros(N, 3, 3);
pY = zeros(N, 2, 3);
pa = zeros(2, 3);
a = zeros(3, 3);
r = zeros(1, 3);
s = zeros(1, 3);
for i=1:3
    plane(i,:) = createPlane([0 0 0], coeff(:,i)');
    prY(:,:,i) = projPointOnPlane(Y, plane(i,:));
    pY(:,:,i) = planePosition(prY(:,:,i), plane(i,:));
    
    circ = enclosingCircle(pY(:,:,i));
    pa(:,i) = circ(1:2);
    a(:,i) = planePoint(plane(i,:), pa(:,i)');
    r(i) = mean(sqrt(sum(bsxfun(@minus, prY(:,:,i), a(:,i)').^2, 2)));
    s(i) = std(sqrt(sum(bsxfun(@minus, prY(:,:,i), a(:,i)').^2, 2)));
end
[~,h] = min(s); % choose the axis that leads to the most-circular projection (lowest STD in the radius)
H = coeff(:,h)';
a = a(:,h);
r = r(h);
plane = plane(h,:);
prY = prY(:,:,h);
pY = pY(:,:,h);

% STEP 2: helix pitch
% departing from the paper here because it doesn't make any sense
% approach: find the angles of pY WRT pa, then divide by projected distance along H to get the pitch
theta = zeros(N,1);
for j=1:size(Y,1)
    theta(j) = atan2((pY(j,2) - pa(2)), (pY(j,1) - pa(1)));
end
p = polyfit(unwrap(theta), Y*H', 1);
p = abs(p(1));

if opt
    % do the extra optimization (from Aqvist paper)
    
    subplot(211); plot3(Y(:,1), Y(:,2), Y(:,3), '.', prY(:,1), prY(:,2), prY(:,3), '.'); axis equal;
    
    a, r, p
    
    options = optimset('fmincon');
    options = optimset(options, 'Algorithm', 'active-set');
    %options = optimset(options, 'GradObj', 'on');
    %options = optimset(options, 'DerivativeCheck', 'on');
    %options = optimset(options, 'GradConstr', 'on');
    options = optimset(options, 'MaxFunEvals', 1e10);
    options = optimset(options, 'MaxIter', 1e10);
    %options = optimset(options, 'Display', 'off');
    %options = optimset(options, 'Diagnostics', 'off');

    [fit, err, flag, output] = fmincon(...
                         @(p) objective_thinair(p, Y), ...
                         [mean(prY) a'], ...
                         [], [], [], [], ... % no linear constraints
                         [], ... % no lower limit
                         [], ... % no upper limit
                         @constraint, ...
                         options)
    
   a = fit(4:6)';
   
   % recalculate the stuff
   plane = createPlane(fit(1:3), a');
   prY = projPointOnPlane(Y, plane);
   pY = planePosition(prY, plane);
   pa = planePosition(a', plane);
   r = mean(sqrt(sum(bsxfun(@minus, pY, pa).^2, 2)));
   
   % STEP 2: helix pitch
   % departing from the paper here because it doesn't make any sense
   % approach: find the angles of pY WRT pa, then divide by projected distance along H to get the pitch
   %circ = enclosingCircle(pY);
   %pa = circ(1:2);
   %a = planePoint(plane, pa)';
   theta = zeros(N,1);
   for j=1:size(Y,1)
       theta(j) = atan2((pY(j,2) - pa(2)), (pY(j,1) - pa(1)));
   end
   p = polyfit(unwrap(theta), Y*H', 1);
   p = abs(p(1));
   
end

if ~opt
    subplot(211); plot(1:N, unwrap(theta), 1:N, Y*H');
end
subplot(212); plot3(Y(:,1), Y(:,2), Y(:,3), '.', prY(:,1), prY(:,2), prY(:,3), '.'); axis equal;

end

function f = objective_thinair(p, Y)
    % new idea: optimize for circularity of projection
    
    r = p(1:3);
    a = p(4:6);
    
    plane = createPlane(r, a);
    prY = projPointOnPlane(Y, plane);
    
    x = sqrt(sum(bsxfun(@minus, prY, a).^2, 2));
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
    ceq = [dot(r,a); norm(a) - 1];
end