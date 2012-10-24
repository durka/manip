function r = R(params)
    if length(params) == 1
        r = [cos(params(1)) -sin(params(1)) 0
             sin(params(1))  cos(params(1)) 0
             0               0              1];
    elseif length(params) == 3
        [a b c] = subsref(num2cell(params), substruct('{}', {':'})); % i.e. [a b c] = num2cell(params){:}
        r = [cos(a)*cos(b) cos(a)*sin(b)*sin(c)-sin(a)*cos(c) cos(a)*sin(b)*cos(c)-sin(a)*sin(c) 0
             sin(a)*cos(b) sin(a)*sin(b)*sin(c)+cos(a)*cos(c) sin(a)*sin(b)*cos(c)-cos(a)*sin(c) 0
             -sin(b)       cos(b)*sin(c)                      cos(b)*cos(c)                      0
             0             0                                  0                                  1];
    else
        error('I can only think in 2 or 3 dimensions');
    end
end
