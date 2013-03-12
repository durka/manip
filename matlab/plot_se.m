function [H, t, r] = plot_se(se, scale, width)

    if ~exist('scale', 'var')
        scale = 1;
    end
    if ~exist('width', 'var')
        width = 1;
    end

    d = size(se,1) - 1;
    t = se(1:d, d+1);
    r = se(1:d, 1:d);

    H = {plot3(t(1), t(2), t(3), '.', 'MarkerSize', 20) ...
         quiver3(t(1), t(2), t(3), r(1,1), r(2,1), r(3,1), scale, 'r') ...
         quiver3(t(1), t(2), t(3), r(1,2), r(2,2), r(3,2), scale, 'g') ...
         quiver3(t(1), t(2), t(3), r(1,3), r(2,3), r(3,3), scale, 'b')};
     
   cellfun(@(h) set(h, 'LineWidth', width), H);
               
end
