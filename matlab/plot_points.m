function plot_points(X, T)
    colors = 'bgrk';

    % plot the first frame
    h = zeros(1, length(T));
    clf;
    hold on;
        for j = 1:length(T)
            if size(X,3) == 2
                h(j) = plot([X(1,T(j).a,1), X(1,T(j).b,1)], ...
                            [X(1,T(j).a,2), X(1,T(j).b,2)], ...
                            [colors(j) '.-']);
            else
                h(j) = plot3([X(1,T(j).a,1), X(1,T(j).b,1)], ...
                             [X(1,T(j).a,2), X(1,T(j).b,2)], ...
                             [X(1,T(j).a,3), X(1,T(j).b,3)], ...
                             [colors(j) '.-']);
            end
        end
    hold off;
    axis(repmat([-5 5], 1, size(X,3)));
    
    for f = 2:size(X, 1)
        % update the data
        for j = 1:length(T)
            if size(X,3) == 2
                set(h(j)', 'XData',[X(f,T(j).a,1), X(f,T(j).b,1)], ...
                           'YData',[X(f,T(j).a,2), X(f,T(j).b,2)]);
            else
                set(h(j)', 'XData',[X(f,T(j).a,1), X(f,T(j).b,1)], ...
                           'YData',[X(f,T(j).a,2), X(f,T(j).b,2)], ...
                           'ZData',[X(f,T(j).a,3), X(f,T(j).b,3)]);
            end
        end
        pause(0.1);
        drawnow;
    end
end
