function [center, radius, err] = find_center(xy)

    %circ = enclosingCircle(y);
    %o = circ(1:2);
    
    DEBUG = false;
    
    %m = mean(xy);
    %uv = bsxfun(@minus, xy, m);
    %Suu = sum(uv(:,1).^2);
    %Suuu = sum(uv(:,1).^3);
    %Svv = sum(uv(:,2).^2);
    %Svvv = sum(uv(:,2).^3);
    %Suv = dot(uv(:,1), uv(:,2));
    %Suvv = dot(uv(:,1), uv(:,2).^2);
    %Suuv = dot(uv(:,1).^2, uv(:,2));
    
    %b = [(Suuu*Svv + Suvv*Svv - Suv*(Suuv + Svvv))/(2*Suu*Svv - 2*Suv^2); (Suu*Suuv + Suu*Svvv - Suv*(Suuu + Suvv))/(2*Suu*Svv - 2*Suv^2)];
    %center = b';
    %if DEBUG || nargout > 1
    %    radius = sqrt(center(1)^2 + center(2)^2 + (Suu+Svv)/size(xy,1));
    %end
    %center = center + m;
    
    [center(1), center(2), radius] = circfit(xy(:,1), xy(:,2));
    
    if DEBUG || nargout > 2
        err = sum( (sqrt(sum(bsxfun(@minus, xy, center).^2, 2)) - radius).^2 );
    end
    
    if DEBUG
        fp = gcf;
        ffc = evalin('base', 'ffc');
        figure(ffc);
        vis(@plot, xy, 'b.', center, 'r.');
        title(sprintf('radius = %g, err = %g', radius, err));
        disp(dbstack(1));
        pause;
        figure(fp);
    end
    
end
