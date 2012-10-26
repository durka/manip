function s = format_SE(se)
    dims = size(se,1) - 1;
    if dims == 2
        % extract translation
        t = se(1:2, 3)';
        
        % extract rotation
        r = atan2(se(2,1), se(1,1));
    elseif dims == 3
        % extract translation
        t = se(1:3, 4)';
        
        % extract rotation
        % 3-1-3 Euler Angles http://en.wikipedia.org/wiki/Rotation_formalisms_in_three_dimensions#Conversion_formulae_between_formalisms
        r = [-atan2(se(2,3), se(1,3)) acos(se(3,3)) atan2(se(3,2), se(3,1))];
    else
        error('I can only think in 2 or 3 dimensions.');
    end
    
    % format string
    s = '';
    if ~all(abs(t) < eps)
        s = ['T(' mat2str(t) ')'];
    end
    if isempty(s) || ~all(abs(r) < eps)
        if ~isempty(s)
            s = [s '*'];
        end
        s = [s 'R(' mat2str(r) ')'];
    end
end
