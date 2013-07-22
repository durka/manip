function r = R(params)
    if length(params) == 1
        r = [cos(params(1)) -sin(params(1)) 0
             sin(params(1))  cos(params(1)) 0
             0               0              1];
    elseif length(params) == 3
        %[a b c] = subsref(num2cell(params), substruct('{}', {':'})); % i.e. [a b c] = num2cell(params){:}
        a = params(1);
        b = params(2);
        c = params(3);
        % 3-1-3 Euler Angles http://en.wikipedia.org/wiki/Rotation_formalisms_in_three_dimensions#Conversion_formulae_between_formalisms
        ca = cos(a); cb = cos(b); cc = cos(c);
        sa = sin(a); sb = sin(b); sc = sin(c);
        %r = [  ca -sa  0  0
        %       sa  ca  0  0
        %       0   0   1  0
        %       0   0   0  1]*[ cb 0 -sb  0
        %                       0  1  0   0
        %                       sb 0  cb  0
        %                       0  0  0   1 ]*[  cc -sc  0  0
        %                                        sc  cc  0  0
        %                                        0   0   1  0
        %                                        0   0   0  1 ];
        r = [  ca*cb*cc - sa*sc, -cc*sa - ca*cb*sc, -ca*sb, 0
               ca*sc + cb*cc*sa,  ca*cc - cb*sa*sc, -sa*sb, 0
               cc*sb,            -sb*sc,             cb,    0
                   0,                 0,             0,     1 ];
    else
        error('I can only think in 2 or 3 dimensions');
    end
end
