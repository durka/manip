% flexible type-verifier function
%
% this function is reversible, like a coat
%    if 'in' is a string, it will be evaluated, verified and returned
%    if 'in' is an empty string, a default value for the type will be returned
%    if 'in' is a not a string, it will be verified, converted to a string, and returned

function ret = verifier(in, type, dims)
    TOL = 1e-3;

    types = struct('name',     { 'SE'                    'R'                             'U'                            }, ...
                   'regex',    { '^SE\((?<i>n|\d+)\)$'   '^R(?<i>)$|^R\[(?<i>n|\d+)\]$'  '^U(?<i>)$|^U\[(?<i>n|\d+)\]$' }, ...
                   'tostring', { @format_SE              @(x) mat2str(x, 4)              @(x) mat2str(x, 4)             }, ...
                   'default',  { @(t) eye(t+1),          @(t) zeros(1,t)                 @(t) eye(1,t)                  }, ...
                   'verifier', { @(x, t) isa(x, 'double')                                                                  ...
                                      && all(size(x) == [t+1 t+1])                                                         ...
                                      && abs(det(x) - 1) < TOL                                                             ...
                                      && all(abs(x(t+1,1:t)) < TOL)                                                        ...
                                      && abs(x(t+1,t+1) - 1) < TOL                                                         ...
                                                                                                                           ...
                                 @(x, t) isa(x, 'double')                                                                  ...
                                      && or(all(size(x) == [1 t]),                                                         ...
                                            all(size(x) == [t 1]))                                                         ...
                                                                                                                           ...
                                 @(x, t) isa(x, 'double')                                                                  ...
                                      && or(all(size(x) == [1 t]),                                                         ...
                                            all(size(x) == [t 1]))                                                         ...
                                      && abs(norm(x) - 1) < TOL                                                         });
    
    for i = 1:length(types)
        t = regexp(type, types(i).regex, 'names');

        if ~isempty(t)
            if strcmp(t.i, 'n')
                t = dims;
            else
                if isempty(t.i)
                    t = 1;
                else
                    t = eval(t.i);
                end
            end
            
            switch class(in)
                case 'char'
                    if isempty(in)
                        ret = types(i).default(t);
                    else
                        thing = eval(in);
                        if types(i).verifier(thing, t)
                            ret = thing;
                        else
                            error('KA:type', 'Type error: input not %s', type);
                        end
                    end
                otherwise
                    thing = in;
                    if types(i).verifier(thing, t)
                        ret = types(i).tostring(thing);
                    else
                        error('KA:type', 'Type error: input not %s', type);
                    end
            end

            break;
        end
    end
end
