function s = format_SE(se, p)
    if ~exist('p', 'var')
        p = 4;
    end

    [t, r] = extract_SE(se);
    
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
