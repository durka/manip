function [t, r] = extract_SE(se)

    dims = size(se,1) - 1;
    if dims == 2
        % extract translation
        t = se(1:2, 3)';
        
        % extract rotation
        r = atan2(se(2,1), se(1,1))*1;
    elseif dims == 3
        % extract translation
        t = se(1:3, 4)';
        
        % extract rotation
        % 3-1-3 Euler Angles http://en.wikipedia.org/wiki/Rotation_formalisms_in_three_dimensions#Conversion_formulae_between_formalisms
        if se(3,3) == 1 % i.e. sin(b) = 0
            r = [0 0 atan2(se(1,2), se(1,1))];
        else
            r = [0 0 0];
            r(2) = atan2(sqrt(se(1,3)^2+se(2,3)^2), se(3,3))*1;
            if r(2) < 0
                r(1) = atan2(se(2,3), se(1,3))*1;
                r(3) = atan2(se(3,2), se(3,1))*1;
            else
                r(1) = atan2(-se(2,3), -se(1,3))*1;
                r(3) = atan2(-se(3,2),  se(3,1))*1;
            end
        end
    else
        error('I can only think in 2 or 3 dimensions.');
    end
    
end