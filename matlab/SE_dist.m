% returns "distance" between two elements of SE(n)
% also returns gradient of the distance WRT u
function [dist, grad] = SE_dist(u, v, Dkr, Dkt, Dki, Dq, Dr)
    % magic scale factors (see, e.g. Park 1995)
    c = 2;
    d = 1;

    n = size(u,1)-1; % n as in SE(n)
    
    ut = u(1:n, n+1);
    vt = v(1:n, n+1);
    ur = u(1:n, 1:n);
    vr = v(1:n, 1:n);
    
    %dr = ur\vr;
    dt = ut - vt;
    %L = logm_so3(dr);
    %C = c*norm(L)^2;
    if n == 3
        tr = (ur(1,1)*ur(2,2)*vr(3,3) - ur(1,1)*ur(2,3)*vr(3,2) - ur(1,1)*ur(3,2)*vr(2,3) + ur(1,1)*ur(3,3)*vr(2,2) - ur(1,2)*ur(2,1)*vr(3,3) + ur(1,2)*ur(2,3)*vr(3,1) + ur(1,2)*ur(3,1)*vr(2,3) - ur(1,2)*ur(3,3)*vr(2,1) + ur(1,3)*ur(2,1)*vr(3,2) - ur(1,3)*ur(2,2)*vr(3,1) - ur(1,3)*ur(3,1)*vr(2,2) + ur(1,3)*ur(3,2)*vr(2,1) + ur(2,1)*ur(3,2)*vr(1,3) - ur(2,1)*ur(3,3)*vr(1,2) - ur(2,2)*ur(3,1)*vr(1,3) + ur(2,2)*ur(3,3)*vr(1,1) + ur(2,3)*ur(3,1)*vr(1,2) - ur(2,3)*ur(3,2)*vr(1,1))/(ur(1,1)*ur(2,2)*ur(3,3) - ur(1,1)*ur(2,3)*ur(3,2) - ur(1,2)*ur(2,1)*ur(3,3) + ur(1,2)*ur(2,3)*ur(3,1) + ur(1,3)*ur(2,1)*ur(3,2) - ur(1,3)*ur(2,2)*ur(3,1));
    else
        tr = (ur(1,1)*vr(2,2) - ur(1,2)*vr(2,1) - ur(2,1)*vr(1,2) + ur(2,2)*vr(1,1))/(ur(1,1)*ur(2,2) - ur(1,2)*ur(2,1));
    end
    C = c*2*acos((tr-1)/2); % from http://en.wikipedia.org/wiki/Axis-angle_representation#Log_map_from_SO.283.29_to_so.283.29
    D = d*norm(dt)^2;
    dist = C + D;

    if nargout == 2
        if nargin ~= 7
            error('To calculate a gradient SE_dist needs gradient inputs');
        else
            %fprintf('SIZES: Dq[%d %d] Dr[%d %d] Dkr[%d %d] Dkt[%d %d] Dki[%d %d]\n', size(Dq(ur,vr),1),size(Dq(ur,vr),2), size(Dr(ut,vt),1),size(Dr(ut,vt),2), size(Dkr,1),size(Dkr,2), size(Dkt,1),size(Dkt,2), size(Dki,1),size(Dki,2));
            grad = c*Dq(ur,vr)*Dkr*Dki + d*Dr(ut,vt)*Dkt*Dki;
            if any(isnan(grad))
                fprintf('thar be nannnns up in heer: nan(%d %d %d %d %d %d %d) inf(%d %d %d %d %d %d %d) ', any(isnan(u)), any(isnan(u)), any(any(isnan(Dkr))), any(any(isnan(Dkt))), any(any(isnan(Dki))), any(any(isnan(Dq(ur,vr)))), any(any(isnan(Dr(ut,vt)))), any(isinf(u)), any(isinf(u)), any(any(isinf(Dkr))), any(any(isinf(Dkt))), any(any(isinf(Dki))), any(any(isinf(Dq(ur,vr)))), any(any(isinf(Dr(ut,vt)))));
            end
        end
    end
end
