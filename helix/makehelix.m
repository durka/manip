function X = makehelix(theta, phi, radius, pitch, rate, T)

t = linspace(0, rate, T)';

X = [radius*cos(phi)*cos(theta)*cos(t) - radius*sin(phi)*sin(t) - pitch*t*cos(phi)*sin(theta), ...
     radius*sin(phi)*cos(theta)*cos(t) + radius*cos(phi)*sin(t) - pitch*t*sin(phi)*sin(theta), ...
                                         radius*sin(theta)*cos(t) + pitch*t*cos(theta)            ];
                                         
end