function [params, plane] = guess_revolute(deltas, t1, r1, t2, ~, t3, ~)

    % TODO implement this for 2D
    %nhat = cross(t3 - t1, t2 - t1);
    %nhat = nhat/norm(nhat);
    % for the translation, use the circumcenter of the three points
    % (have to dance around projecting in and out of the plane)
    %plane = createPlane(t1, t2, t3);
    plane = fitPlane(cell2mat(cellfun(@(se) se(1:3,4)', deltas, 'UniformOutput',false)));
    in_plane = planePosition([t1; t2; t3], plane);
    ct = planePoint(plane, circumCenter(in_plane(1,:), in_plane(2,:), in_plane(3,:)));
    % for the rotation, the Z axis needs to go to nhat
    % and the X axis has to go to norm(t1 - ct)
    % so we can cross those to get the Y axis
    % and use the three axes to make up the rotation matrix?
    cr = zeros(3,3);
    %cr(:,1) = t1 - ct;                cr(:,1) = cr(:,1)/norm(cr(:,1));
    cr(1,:) = plane(4:6);
    cr(2,:) = plane(7:9);
    %cr(:,2) = cross(nhat, cr(:,1));   cr(:,2) = cr(:,2)/norm(cr(:,2));
    cr(3,:) = cross(cr(1,:),cr(2,:));
    %ct = -ct;
    [~, cr] = extract_SE([cr, [0 0 0]'; 0 0 0 1]);
    
    center = T(ct)*R(cr);
    radius = T(t1)*R(r1)/center;
    
    %[ct, cr] = extract_SE(center);
    [rt, rr] = extract_SE(radius);
    
    params = [ct cr, rt rr];
    
end
