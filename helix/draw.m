function draw(sp, y, yp, or, ca, pl, th, ra, pit, off)

    %th = th(1:end/4);
    %y = y(1:end/4,:);

    %if dot(ca, y(1,:)) < 0
    %    ca = -ca;
    %end

    % some hacky forward kinematics up in here
    rotvec = cross([0 0 1], ca)';
    rotvec = rotvec/norm(rotvec);
    theta = real(acos(dot([0 0 1], ca)));
    rot = expm(crossm(rotvec*theta));
    james = pi/2%real(acos(rs(1)))
    th = unwrap(th);
    %th = th - min(th);
    fprintf('theta goes from %g to %g (offset %g)\n', min(th), max(th), off);
    th = linspace(min(th), max(th), 1000)';
    x = [cos(th+james)*ra sin(th+james)*ra th*pit+off];
    assignin('base', 'r', rot);
    assignin('base', 'v', rotvec);
    assignin('base', 't', theta);
    x = (rot*x')'; % rotate it so the z-axis is correct by rotating around cross(current Z, target Z) by acos(dot(current Z, target Z))
    x = bsxfun(@plus, x, or'); % make the  helix

    figure(sp);
    clf;
    hold on;
    plot3(y(:,1), y(:,2), y(:,3), 'b.');
    plot3(yp(:,1), yp(:,2), yp(:,3), 'g.');
    plot3(x(:,1), x(:,2), x(:,3), 'r');%, 'LineWidth',1);

    plot3(or(1), or(2), or(3), 'r.', 'MarkerSize',5);
    quiver3(or(1), or(2), or(3), ca(1), ca(2), ca(3), 30, 'LineWidth',3);
    h = drawPlane3d(pl);
    assignin('base', 'h', h);
    hold off;
    axis equal;
end


