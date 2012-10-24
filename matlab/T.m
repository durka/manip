function t = T(params)
    if length(params) == 2
        [x y] = subsref(num2cell(params), substruct('{}', {':'})); % i.e. [x y] = num2cell(params){:}
        t = [1 0 x
             0 1 y
             0 0 1];
    elseif length(params) == 3
        [x y z] = subsref(num2cell(params), substruct('{}', {':'})); % i.e. [x y z] = num2cell(params){:}
        t = [1 0 0 x
             0 1 0 y
             0 0 1 z
             0 0 0 1];
    else
        error('I can only think in 2 or 3 dimensinos');
    end
end