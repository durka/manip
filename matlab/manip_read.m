% parses data into X (see manip_simulate for definition of X)
% data came from uiimport of output from cpp/*_tracker

% data columns:
% 2D:   FRAME_INDEX OBJECT_ID Tx Ty R
% 3D:   FRAME_INDEX OBJECT_ID Tx Ty Tz Rx Ry Rz

function X = manip_read(data)
    switch size(data,2)
        case 5
            dims = 2;
        case 8
            dims = 3;
        otherwise
            error('I can only think in 2 or 3 dimensions');
    end
    f = length(unique(data(:,1))); % number of frames
    ids = unique(data(:,2)); % object ids
    n = length(ids); % number of objects
    
    X = zeros(f, n, dims+1, dims+1);
    interp = zeros(f, n);
    
    % parse data
    for frame = 1:f
        for obj = 1:n
            coords = data(data(:,1) == frame & data(:,2) == ids(obj), 3:end);
            if isempty(coords)
                % uh oh, we have some interpolation to do
                interp(frame, obj) = 1;
            else
                if dims == 2
                    X(frame,obj, :,:) = T(coords(1:2))*R(coords(3));
                else
                    X(frame,obj, :,:) = T(coords(1:3))*R([pi/2 coords(4) -pi/2])*R([0 coords(5) 0])*R([0 0 coords(6)]); % shenanigans to get Rxyz out of Rzyz
                end
            end
        end
    end
    
    % interpolate
    % TODO instead of interpolating, throw out non-full frames
    X = X(~any(interp, 2), :,:,:);
end