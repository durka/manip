function [a, r, p, theta] = helfit2(Y) % Y is Nx3

% new axis plan made up from scratch
% assumption: helix origin is at (0, 0, 0)

% STEP 1: cylinder axis and radius
% first, find the cylinder axis
N = size(Y,1);
[coeff, score] = princomp(Y); % run PCA to find the axes
coeff
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
[~,h] = min(s) % choose the axis that leads to the most-circular projection (lowest STD in the radius)
H = coeff(:,h)';
a = a(:,h);
r = r(h);

% STEP 2: helix pitch
% departing from the paper here because it doesn't make any sense
% approach: find the angles of pY WRT pa, then divide by projected distance along H to get the pitch
theta = zeros(N,1);
for j=1:size(Y,1)
    theta(j) = atan2((pY(j,2) - pa(2)), (pY(j,1) - pa(1)));
end
p = polyfit(unwrap(theta), Y*H', 1);
p = abs(p(1));

subplot(211); plot(1:N, unwrap(theta), 1:N, Y*H');
subplot(212); plot3(Y(:,1), Y(:,2), Y(:,3), '.', prY(:,1), prY(:,2), prY(:,3), '.');

end
