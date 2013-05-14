function [a, r, p, theta] = helfit(Y) % Y is Nx3

% this is all from HELFIT, Enkhbayar 2008
% assumption: helix origin is at (0, 0, 0)

% STEP 1: cylinder axis and radius
% first, find the cylinder axis using the method of Kahn 1989b
N = size(Y,1);
i = randi([2 N-1], [1 2]);
i = [i(1)-1 i(1) i(1)+1 i(2)-1 i(2) i(2)+1]
P1 = Y(i(2),:);
V1 = normalize(Y(i(1),:)-P1 + Y(i(3),:)-P1);
P2 = Y(i(5),:);
V2 = normalize(Y(i(4),:)-P2 + Y(i(6),:)-P2);
H = normalize(cross(V1, V2)) % H is the cylinder axis!
plane = createPlane([0 0 0], H);

% second, project all the points onto a plane perpendicular to the axis
prY = projPointOnPlane(Y, plane);
pY = planePosition(prY, plane);
pa = circumCenter(pY(i(1),:), pY(i(3),:), pY(i(6),:))
a = planePoint(plane, pa);
r = mean(sqrt(sum(bsxfun(@minus, prY, a).^2, 2)));

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
subplot(212); plot3(Y(:,1), Y(:,2), Y(:,3), prY(:,1), prY(:,2), prY(:,3), Y(i,1), Y(i,2), Y(i,3), '.');

end
