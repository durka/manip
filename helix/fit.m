function [origin, radius, caxis, pitch, plane, theta, offset] = fit(Y, fig1, fig2)

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
        c = mean(Y)'; %c = basis\mean(proj)'; % this is stupid???
        %c(i) = min(Y(:,i)); % this isn't needed???
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
    caxis = basis(:,h)'
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
    for j=1:N
        theta(j) = atan2((Y_p2(j,2) - origin_p2(2)), (Y_p2(j,1) - origin_p2(1)));
    end
    p = polyfit(unwrap(theta), Y*caxis', 1);
    pitch = p(1)
    offset = p(2)
    %pause

    % do the extra optimization (from Aqvist paper)

    draw(fig1, Y, Y_p3, origin, caxis, plane, theta, radius, pitch, offset);

    origin, radius, caxis, pitch, norm(caxis)-1

    [fit, err, flag, output] = nonlin_min(...
                                       @(p) objective_thinair(p, Y), ...
                                       [origin' caxis]', ...
                                       optimset(%'Algorithm', 'siman', ...
                                                %'stoch_regain_constr', true, ...
                                                'lbound', [min(Y(:,1)) min(Y(:,2)) min(Y(:,3)), -1 -1 -1]'-100, ...
                                                'ubound', [max(Y(:,1)) max(Y(:,2)) max(Y(:,3)),  1  1  1]'+100, ...
                                                'equc'  , {@constraint}));

    origin = fit(1:3)';
    caxis = fit(4:6)';
    'the fit is', fit

    % recalculate the stuff
    plane = createPlane(origin, caxis);
    Y_p3 = projPointOnPlane(Y, plane);
    Y_p2 = planePosition(Y_p3, plane);
    %origin_p2 = planePosition(origin', plane);
    origin_p2 = find_center(Y_p2);
    origin = planePoint(plane, origin_p2)';
    radius = mean(sqrt(sum(bsxfun(@minus, Y_p2, origin_p2).^2, 2)));

    % slide the origin "down" along the axis
    'sliding from', origin
    origin = origin' + caxis*min(bsxfun(@minus, Y, origin')*caxis');
    'slid to', origin
    plane = createPlane(origin, caxis);
    Y_p3 = projPointOnPlane(Y, plane);
    Y_p2 = planePosition(Y_p3, plane);
    %origin_p2 = planePosition(origin', plane);
    origin_p2 = find_center(Y_p2);
    origin = planePoint(plane, origin_p2)';
    radius = median(sqrt(sum(bsxfun(@minus, Y_p2, origin_p2).^2, 2)));

    % STEP 2: helix pitch
    % departing from the paper here because it doesn't make any sense
    % approach: find the angles of pY WRT pa, then divide by projected distance along H to get the pitch
    %circ = enclosingCircle(pY);
    %pa = circ(1:2);
    %a = planePoint(plane, pa)';
    theta = zeros(N,1);
    thetac = zeros(N,1);
    thetas = zeros(N,1);
    for j=1:size(Y,1)
        theta(j) = atan2((Y_p2(j,2) - origin_p2(2)), (Y_p2(j,1) - origin_p2(1)));
        thetac(j) = real(acos((Y_p2(j,1) - origin_p2(1))/radius));
        thetas(j) = real(asin((Y_p2(j,2) - origin_p2(2))/radius));
    end
    p = polyfit(sort(unwrap(theta)), sort(bsxfun(@minus, Y, origin')*caxis'), 1);
    pitch = p(1);
    offset = p(2);

    figure(fig1);
    plot(unwrap(theta), bsxfun(@minus, Y, origin')*caxis', unwrap(theta), pitch*unwrap(theta)+offset, unwrap(theta), unwrap(thetac), unwrap(theta), unwrap(thetas), unwrap(theta), Y_p2(:,2) - origin_p2(2), unwrap(theta), Y_p2(:,1) - origin_p2(1));
    title(sprintf('pitch=%g     offset=%g', pitch, offset));



    draw(fig2, Y, Y_p3, origin, caxis, plane, theta, radius, pitch, offset);

    origin, radius, caxis, pitch

end

function f = objective_thinair(p, Y)
    % new idea: optimize for circularity of projection

    r = p(1:3);
    a = p(4:6);

    plane = createPlane(r', a');
    Y_p3 = projPointOnPlane(Y, plane);
    Y_p2 = planePosition(Y_p3, plane);
    o = find_center(Y_p2);

    x = sqrt(sum(bsxfun(@minus, Y_p2, o).^2, 2));
    f = std(x);

    disp([num2str(p') ' = ' num2str(f)]);
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

function ceq = constraint(p)
    r = p(1:3);
    a = p(4:6);

    ceq = norm(a) - 1;
end
