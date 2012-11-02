function [s, t, r] = format_SE(se, p)
    if ~exist('p', 'var')
        p = 4;
    end

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
            r = [-atan2(se(2,3), se(1,3)) acos(se(3,3)) atan2(se(3,2), se(3,1))]*eye(3); % multiply by I to remove -0
        end
    else
        error('I can only think in 2 or 3 dimensions.');
    end
    
    % format string
    s = '';
    if ~all(abs(t) < eps)
        s = ['T(' mat2str(t, p) ')'];
    end
    if isempty(s) || ~all(abs(r) < eps)
        if ~isempty(s)
            s = [s '*'];
        end
        s = [s 'R(' mat2str(r, p) ')'];
    end
end
