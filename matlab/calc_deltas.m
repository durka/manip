function [deltas, t1, r1, t2, r2, t3, r3] = calc_deltas(X, a, b)

    deltas = cell(size(X,1), 1);
    for frame = 1:size(X,1)
        deltas{frame} = squeeze(X(frame, b, :,:))/squeeze(X(frame, a, :,:));
    end
    [t1, r1] = extract_SE(deltas{1});
    [t2, r2] = extract_SE(deltas{floor(end/2)});
    [t3, r3] = extract_SE(deltas{end});
    
end
