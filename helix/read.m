% parses data into X (see manip_simulate for definition of X)
% for the old format, data came from uiimport of output from cpp/*_tracker
% for the new format, data is the filename of output from cpp/*_tracker

% there are two formats (auto-detected):
% OLD FORMAT (data is a matrix)
% data columns:
% 2D:   FRAME_INDEX OBJECT_ID Tx Ty R
% 3D:   FRAME_INDEX OBJECT_ID Tx Ty Tz Rx Ry Rz
% NEW FORMAT (data is a filename)
% 2D:   FRAME_INDEX TIMESTAMP: (OBJECT_ID Tx Ty R | )*
% 3D:   FRAME_INDEX TIMESTAMP: (OBJECT_ID Tx Ty Tz Rx Ry Ryz | )*

function [X, interp] = read(data, filtB, filtA)
    if ischar(data)
        data = new2old(data);
    end

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
    
    % sort data
    points = arrayfun(@(n) data(data(:,2)==n, :), ids, 'UniformOutput',false);
    
    % parse data
    for obj = 1:n
        if nargin == 3
            points{obj}(:, 3:end) = filter(filtB, filtA, points{obj}(:, 3:end), mean(points{obj}(1:round(length(points{obj})/50), 3:end)));
        end
        for frame = 1:f
            coords = points{obj}(points{obj}(:,1)==frame, 3:end);
            if isempty(coords)
                % uh oh, we have some interpolation to do
                interp(frame, obj) = 1;
            else
                if dims == 2
                    X(frame,obj, :,:) = T(coords(1:2))*R(coords(3));
                else
                    %X(frame,obj, :,:) = T(coords(1:3))*R([pi/2 coords(4) -pi/2])*R([0 coords(5) 0])*R([0 0 coords(6)]); % shenanigans to get Rxyz out of Rzyz
                    th = sqrt(sum(coords(4:6).^2));
                    v = coords(4:6)/th;
                    X(frame,obj, :,:) = T(coords(1:3)) * [(eye(3)*cos(th) + [0 -v(3) v(2); v(3) 0 -v(1); -v(2) v(1) 0]*sin(th) + v'*v*(1-cos(th))) [0;0;0]; 0 0 0 1];
                end
            end
        end
    end
    
    % interpolate
    % TODO instead of interpolating, throw out non-full frames
    X = X(~any(interp, 2), :,:,:);
end

function data = new2old(filename)
    data = [];
    f = fopen(filename, 'r');
    tline = fgetl(f);
    while ischar(tline)
        parts = regexp(tline, ':', 'split');
        prefix_parts = regexp(parts{1}, ' ', 'split');
        suffix_parts = regexp(parts{2}, '\|', 'split');
        index = str2double(prefix_parts{1});
        stamp = str2double(prefix_parts{2}); % TODO don't swallow the timestamp
        for i=1:length(suffix_parts)
            if ~all(isspace(suffix_parts{i}))
                data = [data; [index str2num(suffix_parts{i})]];
            end
        end
        tline = fgetl(f);
    end
    fclose(f);
end

