%% 2D tests

% TODO

%% 3D tests

close all;

simple = false;
if ~simple
    S = struct('a',       {1                          2                  3},                        ...
               'b',       {2                          3                  4},                        ...
               'joint',   {'prismatic',               'rigid',           'revolute'},               ...
               'params',  {{T([.1 .2 .4]) [0 0 1]}    {T([1 -1 1]/3)}    {T([0 0 1]) T([0 0 .2])}}, ...
               'state',   {0                          0                  0},                        ...
               'bounds',  {[0; 5]                     [0; 0]             [0; pi]});
else
    S = struct('a',       {1},                        ...
               'b',       {2},                        ...
               'joint',   {'revolute'},               ...
               'params',  {{T([0 0 0]) T([0 0 1])}}, ...
               'state',   {0},                        ...
               'bounds',  {[0; 2*pi]});
end
           
X = manip_simulate(3, max([S.a S.b]), 50, S);

plot_points(X, S);
